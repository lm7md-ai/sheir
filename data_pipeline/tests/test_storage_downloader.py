#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
اختبارات وحدة التخزين والتحميل الشبكي القابل للاستئناف وفحص السعة
"""

import pytest

def test_disk_space_check_threshold():
    """التحقق من معادلة التحقق من كفاية المساحة وهامش الأمان"""
    def check_space(available_mb: int, required_mb: int, safety_margin_mb: int = 50) -> bool:
        return available_mb >= (required_mb + safety_margin_mb)

    # حالة مساحة كافية
    assert check_space(available_mb=1000, required_mb=85, safety_margin_mb=50) is True
    # حالة مساحة غير كافية
    assert check_space(available_mb=100, required_mb=85, safety_margin_mb=50) is False
    # حالة حد حرج
    assert check_space(available_mb=135, required_mb=85, safety_margin_mb=50) is True
    assert check_space(available_mb=134, required_mb=85, safety_margin_mb=50) is False

def test_http_range_offset_calculation():
    """التحقق من حساب إزاحة البايتات لاستئناف التحميل"""
    def calculate_range_header(existing_bytes: int, total_bytes: int):
        if existing_bytes <= 0:
            return None
        return f"bytes={existing_bytes}-"

    assert calculate_range_header(0, 1000) is None
    assert calculate_range_header(500, 1000) == "bytes=500-"
    assert calculate_range_header(999, 1000) == "bytes=999-"

def test_exponential_backoff_delays():
    """التحقق من متوالية التراجع الأسي لإعادة المحاولة (1s, 2s, 4s)"""
    def get_retry_delay(attempt: int) -> int:
        return 1 << (attempt - 1)

    assert get_retry_delay(1) == 1
    assert get_retry_delay(2) == 2
    assert get_retry_delay(3) == 4
