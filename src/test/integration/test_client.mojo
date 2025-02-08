# import testing
# from floki.session import Session
# from floki.response import StatusCode
# from floki._logger import LOGGER


# struct IntegrationTest:
#     var client: Session
#     var results: Dict[String, String]

#     fn __init__(out self):
#         self.client = Session(allow_redirects=True)
#         self.results = Dict[String, String]()

#     fn mark_successful(mut self, name: String):
#         self.results[name] = "✅"

#     fn mark_failed(mut self, name: String):
#         self.results[name] = "❌"

#     fn test_redirect(mut self):
#         alias name = "test_redirect"
#         print("\n~~~ Testing redirect ~~~")
#         try:
#             var response = self.client.get(
#                 "https://httpbin.org/redirect/1",
#                 {"connection": "keep-alive"},
#             )
#             testing.assert_equal(response.status_code, StatusCode.OK.value)
#             # testing.assert_equal(response.body.as_string_slice(), "yay you made it")
#             testing.assert_equal(response.headers["connection"], "keep-alive")
#             self.mark_successful(name)
#         except e:
#             LOGGER.error("IntegrationTest.test_redirect has run into an error.")
#             LOGGER.error(e)
#             self.mark_failed(name)
#             return

#     # fn test_close_connection(mut self):
#     #     alias name = "test_close_connection"
#     #     print("\n~~~ Testing close connection ~~~")
#     #     try:
#     #         var response = self.client.get(
#     #             "close-connection",
#     #             {"connection": "close"},
#     #         )
#     #         testing.assert_equal(response.status_code, StatusCode.OK.value)
#     #         testing.assert_equal(response.body.as_string_slice(), "connection closed")
#     #         testing.assert_equal(response.headers["connection"], "close")
#     #         self.mark_successful(name)
#     #     except e:
#     #         LOGGER.error("IntegrationTest.test_close_connection has run into an error.")
#     #         LOGGER.error(e)
#     #         self.mark_failed(name)
#     #         return

#     # fn test_server_error(mut self):
#     #     alias name = "test_server_error"
#     #     print("\n~~~ Testing internal server error ~~~")
#     #     try:
#     #         var response = self.client.get("error")
#     #         testing.assert_equal(response.status_code, StatusCode.INTERNAL_ERROR.value)
#     #         testing.assert_equal(response.reason, "Internal Server Error")
#     #         self.mark_successful(name)
#     #     except e:
#     #         LOGGER.error("IntegrationTest.test_server_error has run into an error.")
#     #         LOGGER.error(e)
#     #         self.mark_failed(name)
#     #         return

#     fn run_tests(mut self) -> Dict[String, String]:
#         LOGGER.info("Running Session Integration Tests...")
#         self.test_redirect()
#         # self.test_close_connection()
#         # self.test_server_error()

#         return self.results


# fn main():
#     var test = IntegrationTest()
#     var results = test.run_tests()
#     for test in results.items():
#         print(test.key + ":", test.value)
