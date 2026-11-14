#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
خادم المعاينة الحية التفاعلية لمنظومة تصميم ديوان (Diwan Live Preview Server)
يربط بين واجهة المخطوطة الرقمية وقاعدتي بيانات poems.db و user_data.db
"""

import os
import json
import sqlite3
import mimetypes
from http.server import HTTPServer, SimpleHTTPRequestHandler
import urllib.parse

PORT = 8080
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
STATIC_DIR = os.path.join(BASE_DIR, "static")
POEMS_DB = os.path.abspath(os.path.join(BASE_DIR, "..", "app", "assets", "poems.db"))
USER_DB = os.path.abspath(os.path.join(BASE_DIR, "..", "app", "assets", "user_data.db"))

mimetypes.add_type("font/ttf", ".ttf")
mimetypes.add_type("image/svg+xml", ".svg")
mimetypes.add_type("application/javascript", ".js")
mimetypes.add_type("text/css", ".css")

def get_db_connection(path):
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    return conn

class DiwanRequestHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=STATIC_DIR, **kwargs)

    def end_headers(self):
        # السماح بالمعاينة داخل إطار iframe لبيئة e2b.app
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        query = urllib.parse.parse_qs(parsed.query)

        if path == "/api/poems":
            self._handle_get_poems()
            return
        elif path == "/api/search":
            q = query.get("q", [""])[0]
            self._handle_search(q)
            return
        elif path == "/api/stats":
            self._handle_get_stats()
            return

        super().do_GET()

    def _send_json(self, data, status=200):
        body = json.dumps(data, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _handle_get_poems(self):
        try:
            conn = get_db_connection(POEMS_DB)
            cur = conn.cursor()
            cur.execute("""
            SELECT p.id, p.title, p.era, p.meter_name, p.rawiy, p.theme, p.verse_count, pt.name as poet_name
            FROM poems p
            JOIN poets pt ON p.poet_id = pt.id
            ORDER BY p.id ASC
            """)
            poems = []
            for row in cur.fetchall():
                poem = dict(row)
                # جلب الأبيات
                v_cur = conn.cursor()
                v_cur.execute("""
                SELECT id, verse_order, sadr, ajuz 
                FROM verses 
                WHERE poem_id = ? 
                ORDER BY verse_order ASC
                """, (poem["id"],))
                poem["verses"] = [dict(v) for v in v_cur.fetchall()]
                poems.append(poem)
            conn.close()
            self._send_json({"status": "success", "poems": poems})
        except Exception as e:
            self._send_json({"status": "error", "message": str(e)}, 500)

    def _handle_search(self, q):
        try:
            if not q.strip():
                self._handle_get_poems()
                return

            conn = get_db_connection(POEMS_DB)
            cur = conn.cursor()
            from data_pipeline.build_databases import normalize_arabic
            norm_q = normalize_arabic(q)

            cur.execute("""
            SELECT verse_id, poem_id, sadr, ajuz, poem_title, poet_name
            FROM verses_fts
            WHERE sadr_norm MATCH ? OR ajuz_norm MATCH ? OR poem_title MATCH ? OR poet_name MATCH ?
            LIMIT 30
            """, (norm_q, norm_q, norm_q, norm_q))

            results = [dict(row) for row in cur.fetchall()]
            conn.close()
            self._send_json({"status": "success", "query": q, "results": results})
        except Exception as e:
            self._send_json({"status": "error", "message": str(e)}, 500)

    def _handle_get_stats(self):
        try:
            conn = get_db_connection(USER_DB)
            cur = conn.cursor()
            cur.execute("SELECT xp, streak_days, current_rank, last_practice_date FROM user_profile WHERE id = 1")
            row = cur.fetchone()
            profile = dict(row) if row else {"xp": 100, "streak_days": 1, "current_rank": "راوٍ مُبْتَدِئ"}

            cur.execute("SELECT COUNT(*) as due_count FROM srs_cards")
            due_count = cur.fetchone()["due_count"]
            profile["due_count"] = due_count

            conn.close()
            self._send_json({"status": "success", "profile": profile})
        except Exception as e:
            self._send_json({"status": "error", "message": str(e)}, 500)

def run():
    server_address = ("0.0.0.0", PORT)
    httpd = HTTPServer(server_address, DiwanRequestHandler)
    print(f"Diwan Showcase Server running on http://0.0.0.0:{PORT}...")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        httpd.server_close()
        print("Server stopped.")

if __name__ == "__main__":
    run()
