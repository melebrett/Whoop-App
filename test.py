from __future__ import annotations

import json
import os
from dotenv import load_dotenv
from datetime import datetime, time, timedelta
from typing import Any

from authlib.common.urls import extract_params
from authlib.integrations.requests_client import OAuth2Session

AUTH_URL = "https://api-7.whoop.com"
REQUEST_URL = "https://api.prod.whoop.com/developer"

def _auth_password_json(_client, _method, uri, headers, body):
    body = json.dumps(dict(extract_params(body)))
    headers["Content-Type"] = "application/json"

    return uri, headers, body

load_dotenv()

username = os.getenv('EMAIL')
password = os.getenv("PASSWORD")

_username = username
_password = password

TOKEN_ENDPOINT_AUTH_METHOD = "password_json" 

session = OAuth2Session(
    token_endpont=f"{AUTH_URL}/oauth/token",
    token_endpoint_auth_method=TOKEN_ENDPOINT_AUTH_METHOD,
)

session.register_client_auth_method(
    (TOKEN_ENDPOINT_AUTH_METHOD, _auth_password_json)
)

user_id = ""

def authenticate(**kwargs) -> None:
    """Authenticate OAuth2Session by fetching token.

    If `user_id` is `None`, it will be set according to the `user_id` returned with
    the token.

    Args:
        kwargs (dict[str, Any], optional): Additional arguments for `fetch_token()`.
    """
    session.fetch_token(
        url=f"{AUTH_URL}/oauth/token",
        username=_username,
        password=_password,
        grant_type="password",
        **kwargs,
    )

    # if not user_id:
    #     user_id = str(session.token.get("user", {}).get("id", ""))

authenticate()

response = session.request(
    method="GET",
    url=f"{REQUEST_URL}/v1/user/profile/basic",
)

response.json()