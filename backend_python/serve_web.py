from http.server import SimpleHTTPRequestHandler, HTTPServer
import os

class NoCacheHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        self.send_header("Access-Control-Allow-Origin", "*")
        super().end_headers()

if __name__ == "__main__":
    web_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "sozegitim-frontend_temel-2", "build", "web"))
    os.chdir(web_dir)
    server = HTTPServer(("0.0.0.0", 3000), NoCacheHandler)
    print(f"Serving Flutter Web from {web_dir} at http://localhost:3000 with NO CACHE...")
    server.serve_forever()
