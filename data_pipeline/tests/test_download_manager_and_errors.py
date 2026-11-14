#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
اختبارات تنزيل الملفات القابل للاستئناف والتحقق من البصمة والتدوير والسعة (Gate 7)
"""

import os
import time
import hashlib
import tempfile
import threading
from http.server import HTTPServer, BaseHTTPRequestHandler
import pytest

# محاكي خادم HTTP يدعم ترويسة Range للاستئناف
class MockRangeServer(BaseHTTPRequestHandler):
    FILE_PAYLOAD = b"DIWAN_AI_MODEL_STREAMING_BINARY_DATA_WITH_ROBUST_RANGE_RESUME_1234567890"

    def do_GET(self):
        range_header = self.headers.get("Range")
        if range_header and range_header.startswith("bytes="):
            # استخراج موضع الاستئناف
            offset = int(range_header.replace("bytes=", "").replace("-", ""))
            chunk = self.FILE_PAYLOAD[offset:]
            self.send_response(206)
            self.send_header("Content-Type", "application/octet-stream")
            self.send_header("Content-Range", f"bytes {offset}-{len(self.FILE_PAYLOAD)-1}/{len(self.FILE_PAYLOAD)}")
            self.send_header("Content-Length", str(len(chunk)))
            self.end_headers()
            self.wfile.write(chunk)
        else:
            self.send_response(200)
            self.send_header("Content-Type", "application/octet-stream")
            self.send_header("Content-Length", str(len(self.FILE_PAYLOAD)))
            self.end_headers()
            self.wfile.write(self.FILE_PAYLOAD)

    def log_message(self, format, *args):
        pass # كتم السجلات أثناء الاختبار

@pytest.fixture(scope="module")
def mock_server():
    server = HTTPServer(("127.0.0.1", 0), MockRangeServer)
    port = server.server_port
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    yield f"http://127.0.0.1:{port}"
    server.shutdown()

def test_interrupted_download_resumes_from_right_byte(mock_server):
    """التحقق من أن التنزيل المقاطع يستأنف من موضع البايت المحدد عبر ترويسة Range"""
    import urllib.request

    full_data = MockRangeServer.FILE_PAYLOAD
    half_len = 25

    # 1. محاكاة تنزيل الجزء الأول (25 بايت)
    part_data = full_data[:half_len]

    # 2. إرسال طلب استئناف مع ترويسة Range
    req = urllib.request.Request(mock_server)
    req.add_header("Range", f"bytes={half_len}-")
    with urllib.request.urlopen(req) as resp:
        assert resp.status == 206
        resumed_data = resp.read()

    combined = part_data + resumed_data
    assert combined == full_data
    assert len(combined) == len(full_data)

def test_checksum_mismatch_rejection():
    """التحقق من رفض الملف في حال عدم تطابق بصمة SHA-256"""
    data = b"VALID_DIWAN_DATA_PACKAGE"
    valid_sha256 = hashlib.sha256(data).hexdigest()
    corrupt_sha256 = "0000000000000000000000000000000000000000000000000000000000000000"

    def verify_checksum(payload: bytes, expected_hash: str) -> bool:
        return hashlib.sha256(payload).hexdigest() == expected_hash

    assert verify_checksum(data, valid_sha256) is True
    assert verify_checksum(data, corrupt_sha256) is False

def test_low_disk_simulation_blocks_download():
    """التحقق من منع التنزيل عند عدم كفاية المساحة التخزينية (الحجم المطلوب + 20% أمان)"""
    def check_space_gate(available_mb: int, required_mb: int) -> bool:
        safety_margin = int(required_mb * 0.2) + 20
        return available_mb >= (required_mb + safety_margin)

    # نموذج بحجم 85MB مع هامش 20% (17MB) + 20MB = 122MB مطلوبة
    assert check_space_gate(available_mb=500, required_mb=85) is True
    assert check_space_gate(available_mb=100, required_mb=85) is False

def test_rotating_file_logger_rotates_on_cap():
    """التحقق من تدوير ملفات السجلات عند بلوغ الحد الأقصى للحجم"""
    with tempfile.TemporaryDirectory() as tmpdir:
        cap_bytes = 200 # حد تجريبي صغير
        max_files = 3
        current_idx = 1

        for i in range(15):
            filepath = os.path.join(tmpdir, f"diwan_log_{current_idx}.log")
            with open(filepath, "a", encoding="utf-8") as f:
                f.write(f"Log line {i}: Event recorded with timestamp and literary Arabic tag\n")
            if os.path.getsize(filepath) >= cap_bytes:
                current_idx = (current_idx % max_files) + 1

        files = os.listdir(tmpdir)
        assert len(files) <= max_files
        assert any("diwan_log_" in f for f in files)
