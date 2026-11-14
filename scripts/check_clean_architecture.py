#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
أداة الفحص المعماري الصارم (Clean Architecture & Design System Linter)
يتحقق من:
1. طبقة النطاق (domain) نقية في Dart تماماً ولا تستورد حزم Flutter.
2. طبقة العرض (presentation) لا تستورد طبقة البيانات (data) مباشرة.
3. حزمة diwan_core مستقلة ونقية تماماً بدون أي تبعية لفلاتر.
4. خلو الكود من الألوان أو الأيقونات أو الخطوط الافتراضية (Gate 2).
"""

import os
import re
import sys

def check_architecture(repo_root: str = ".") -> int:
    app_lib = os.path.join(repo_root, "app", "lib")
    features_dir = os.path.join(app_lib, "features")
    diwan_core_lib = os.path.join(repo_root, "app", "packages", "diwan_core", "lib")
    violations = []

    print("=" * 65)
    print("🔍 بدء الفحص المعماري الصارم (Clean Architecture Guard)...")
    print("=" * 65)

    # 1. فحص حزمة diwan_core
    if os.path.exists(diwan_core_lib):
        for root, _, files in os.walk(diwan_core_lib):
            for file in files:
                if file.endswith(".dart"):
                    path = os.path.join(root, file)
                    with open(path, "r", encoding="utf-8") as f:
                        for idx, line in enumerate(f, 1):
                            if "package:flutter/" in line or "package:flutter_" in line:
                                violations.append(f"[diwan_core] {path}:{idx} حظر استيراد Flutter داخل حزمة Dart النقية: {line.strip()}")

    # 2. فحص طبقات features: domain و presentation
    if os.path.exists(features_dir):
        for feature in os.listdir(features_dir):
            feat_path = os.path.join(features_dir, feature)
            if not os.path.isdir(feat_path):
                continue

            # (أ) فحص طبقة domain: حظر Flutter
            domain_path = os.path.join(feat_path, "domain")
            if os.path.exists(domain_path):
                for root, _, files in os.walk(domain_path):
                    for file in files:
                        if file.endswith(".dart"):
                            p = os.path.join(root, file)
                            with open(p, "r", encoding="utf-8") as f:
                                for idx, line in enumerate(f, 1):
                                    if "package:flutter/" in line or "package:flutter_" in line:
                                        violations.append(f"[Domain Layer] {p}:{idx} حظر استيراد Flutter في طبقة domain: {line.strip()}")

            # (ب) فحص طبقة presentation: حظر استيراد data مباشرة
            pres_path = os.path.join(feat_path, "presentation")
            if os.path.exists(pres_path):
                for root, _, files in os.walk(pres_path):
                    for file in files:
                        if file.endswith(".dart"):
                            p = os.path.join(root, file)
                            with open(p, "r", encoding="utf-8") as f:
                                for idx, line in enumerate(f, 1):
                                    if re.search(r"import\s+['\"].*\/data\/.*['\"]", line) or re.search(r"import\s+['\"].*\.\.\/data\/.*['\"]", line):
                                        violations.append(f"[Presentation Layer] {p}:{idx} حظر استيراد data مباشرة في presentation: {line.strip()}")

    # 3. فحص معايير المظهر (Gate 2: No Default Flutter Look)
    banned_tokens = [
        ("Colors.blue", "حظر استخدام اللون الأزرق الافتراضي لـ Material"),
        ("Icons.flutter_dash", "حظر استخدام أيقونات فلاتر الافتراضية"),
        ("fontFamily: 'Roboto'", "حظر استخدام خط Roboto الافتراضي؛ يجب استخدام الخطوط العربية المضمنة"),
        ("fontFamily: \"Roboto\"", "حظر استخدام خط Roboto الافتراضي؛ يجب استخدام الخطوط العربية المضمنة"),
    ]

    if os.path.exists(app_lib):
        for root, _, files in os.walk(app_lib):
            for file in files:
                if file.endswith(".dart"):
                    p = os.path.join(root, file)
                    with open(p, "r", encoding="utf-8") as f:
                        for idx, line in enumerate(f, 1):
                            # تجاهل التعليقات التوضيحية
                            stripped = line.strip()
                            if stripped.startswith("//") or stripped.startswith("*"):
                                continue
                            for token, reason in banned_tokens:
                                if token in line:
                                    violations.append(f"[Gate 2 Theme] {p}:{idx} {reason}: {line.strip()}")

    if violations:
        print("\n❌ تم العثور على مخالفات معمارية:")
        for v in violations:
            print("  - " + v)
        print(f"\nإجمالي المخالفات: {len(violations)}")
        return 1
    else:
        print("\n✅ اجتاز المشروع كافة اختبارات المعمارية النظيفة وحظر المظهر الافتراضي بنجاح (100% Pass)!")
        return 0

if __name__ == "__main__":
    sys.exit(check_architecture("."))
