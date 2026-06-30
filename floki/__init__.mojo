"""Floki: A HTTP client library for Mojo!"""
from floki.auth import Auth, BasicAuth, BearerAuth, NoAuth
from floki.forms import FormData
from floki.functions import delete, get, head, options, patch, post, put
from floki.http import Protocol, RequestMethod, Status
from floki.proxy import Proxy
from floki.retry import Retry
from floki.session import Session
from floki.timeout import Timeout
from floki.tls import TLS
