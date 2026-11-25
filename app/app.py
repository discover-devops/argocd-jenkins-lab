import os
from http.server import BaseHTTPRequestHandler, HTTPServer

VERSION = os.getenv("APP_VERSION", "local")
ENV_NAME = os.getenv("ENV_NAME", "local")
WELCOME = os.getenv("WELCOME_MESSAGE", "Hello from QuickKart")
SECRET = os.getenv("SECRET_MESSAGE", "(no secret yet)")
COLOR = {"dev": "#e3f2fd", "prod": "#e8f5e9"}.get(ENV_NAME, "#ffffff")


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            body, ctype = b"ok", "text/plain"
        else:
            html = f"""<html><body style="font-family:Arial;background:{COLOR};text-align:center;padding-top:60px">
<h1>QuickKart</h1>
<h2>Environment: {ENV_NAME}</h2>
<h2>Version: {VERSION}</h2>
<p>{WELCOME}</p>
<p>Secret from Sealed Secret: {SECRET}</p>
</body></html>"""
            body, ctype = html.encode(), "text/html"
        self.send_response(200)
        self.send_header("Content-Type", ctype)
        self.end_headers()
        self.wfile.write(body)


print(f"QuickKart {VERSION} starting on port 8080, environment {ENV_NAME}")
HTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
