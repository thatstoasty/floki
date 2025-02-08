from floki.address import TCPAddr, AddressFamily, NetworkType
from floki.connection import TCPConnection, Connection, create_connection
from floki._logger import LOGGER
from mojo_tlse.bindings import c_int, c_char, c_uchar, TLSContext, TLSCertificate, TLSE
from mojo_tlse.enums import Result
from memory import UnsafePointer


fn validate_certificate(
    context: UnsafePointer[TLSContext], certificate_chain: UnsafePointer[UnsafePointer[TLSCertificate]], len: c_int
) -> c_int:
    try:
        var tlse = TLSE()

        if certificate_chain:
            for i in range(len):
                var certificate = certificate_chain[i]
                # check validity date
                var err = tlse.tls_certificate_is_valid(certificate)
                if err < 0:
                    LOGGER.debug(err)
                    return err
                # check certificate in certificate->bytes of length certificate->len
                # the certificate is in ASN.1 DER format
        # check if chain is valid
        var err = tlse.tls_certificate_chain_is_valid(certificate_chain, len)
        if err < 0:
            LOGGER.debug(err)
            return err

        var sni = tlse.tls_sni(context)
        if len > 0 and sni:
            err = tlse.tls_certificate_valid_subject(certificate_chain[0], sni)
            if err < 0:
                LOGGER.debug(err)
                return err

        return Result.NO_ERROR.value
    except:
        return Result.NO_ERROR.value


fn establish_tls_context(tlse: TLSE, owned host: String) raises -> UnsafePointer[TLSContext]:
    var context = tlse.tls_create_context(0, 0x0304)  # Hardcoded to TLS/1.3

    # Exportable is only needed if you want to serialize the connection context or kTLS is used
    tlse.tls_make_exportable(context, 1)
    if tlse.tls_sni_set(context, host.unsafe_cstr_ptr().origin_cast[mut=False]()) < 0:
        raise Error("Failed to set SNI for TLS context.")

    if tlse.tls_client_connect(context) < 0:
        raise Error("Failed to establish TLS client connection.")
    return context


@fieldwise_init
struct TLSConnection(Connection, Movable):
    var _context: UnsafePointer[TLSContext]
    var _connection: TCPConnection
    var _tlse: TLSE

    fn __init__(out self, owned host: String, port: UInt16) raises:
        self._tlse = TLSE()
        self._connection = create_connection(host^, port)
        self._context = establish_tls_context(self._tlse, host^)
        _ = self.send_pending()

    fn __init__(out self, owned connection: TCPConnection, owned host: String) raises:
        self._tlse = TLSE()
        self._connection = connection^
        self._context = establish_tls_context(self._tlse, host^)
        _ = self.send_pending()

    fn __del__(owned self):
        if self._context:
            self._tlse.tls_destroy_context(self._context)

    fn send_pending(self) raises -> Int:
        var length: UInt32 = 0
        var buffer = self._tlse.tls_get_write_buffer(self._context, UnsafePointer(to=length))
        var bytes_sent = 0
        while buffer and length > 0:
            bytes_sent = self._connection.write(Span(ptr=buffer, length=UInt(length)))
            if bytes_sent <= 0:
                break
            length -= bytes_sent
        self._tlse.tls_buffer_clear(self._context)
        return bytes_sent

    fn write(self, data: Span[Byte]) raises -> Int:
        var buffer = List[Byte, True](capacity=65535)

        # Read the encrypted data from the connection.
        _ = self._connection.read(buffer)
        LOGGER.debug("Processing handshake...")

        if self._tlse.tls_consume_stream(self._context, buffer.unsafe_ptr(), len(buffer), validate_certificate) <= 0:
            raise Error("Couldn't consume tls stream into context.")

        var tls_established = self._tlse.tls_established(self._context)
        if tls_established < 0:
            raise Error("TLS connection not established. Status code: ", tls_established)

        LOGGER.debug("sending request")
        LOGGER.debug(StringSlice(unsafe_from_utf8=data))
        # If the connection can't use kTLS use the regular send method.
        if self._tlse.tls_make_ktls(self._context, self._connection.socket.fd.value) == 0:
            # call send as on regular TCP sockets
            # TLS record layer is handled by the kernel
            return self._connection.write(data)

        var bytes_sent = self._tlse.tls_write(self._context, data.unsafe_ptr(), len(data))
        var bytes_from_pending = self.send_pending()
        return Int(bytes_sent) + bytes_from_pending

    fn read(self, mut buffer: List[Byte, True]) raises -> Int:
        var tls_buffer = List[Byte, True](capacity=65535)

        _ = self._connection.read(tls_buffer)
        if (
            self._tlse.tls_consume_stream(self._context, tls_buffer.unsafe_ptr(), len(tls_buffer), validate_certificate)
            <= 0
        ):
            raise Error("Couldn't consume tls stream into context.")

        var bytes_read = 0
        if self._tlse.tls_established(self._context) == 1:
            bytes_read = Int(
                self._tlse.tls_read(
                    self._context,
                    buffer.unsafe_ptr().offset(len(buffer)),
                    buffer.capacity - len(buffer),
                )
            )
            if bytes_read == 0:
                return bytes_read
            buffer._len += bytes_read

        return bytes_read

    fn close(mut self) raises:
        self._connection.close()

    fn shutdown(mut self) raises -> None:
        self._connection.shutdown()

    fn teardown(mut self) raises:
        self._connection.teardown()

    # fn local_addr(self) -> TCPAddr[network]:
    #     return self._connection.local_addr()

    # fn remote_addr(self) -> TCPAddr[network]:
    #     return self._connection.remote_addr()
