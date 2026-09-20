#!/usr/bin/env python3
import os
import sys
import re

BANNED_KEYWORDS = [
    r"extends\s+Node2D",
    r"extends\s+Control",
    r"extends\s+Node3D",
    r"extends\s+CanvasItem",
    r"get_node\(",
    r"get_parent\(",
    r"get_tree\(",
    r"Owner",
    r"\$\"",
    r"load\(\".*\.tscn\"\)",
    r"preload\(\".*\.tscn\"\)"
]

BANNED_CLASS_SUFFIXES = [
    "Manager",
    "Handler",
    "Processor",
    "Controller",
    "Helper",
    "Util"
]

def check_file(filepath):
    violations = []

    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    class_name = None
    for i, line in enumerate(lines):
        line_num = i + 1

        # Check for banned keywords
        for keyword in BANNED_KEYWORDS:
            if re.search(keyword, line):
                violations.append((line_num, f"Banned keyword or pattern found: {keyword}"))

        # Extract class name if present
        class_match = re.match(r"^class_name\s+([a-zA-Z0-9_]+)", line.strip())
        if class_match:
            class_name = class_match.group(1)

    # Check class name suffix
    if class_name:
        for suffix in BANNED_CLASS_SUFFIXES:
            if class_name.endswith(suffix):
                violations.append((0, f"Banned class name suffix found: '{class_name}' ends with '{suffix}'"))

    return violations

def main():
    repo_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    directories_to_check = [
        os.path.join(repo_root, "core"),
        os.path.join(repo_root, "domain")
    ]

    all_violations = False

    for directory in directories_to_check:
        if not os.path.exists(directory):
            print(f"Warning: Directory not found: {directory}")
            continue

        for root, _, files in os.walk(directory):
            for file in files:
                if file.endswith(".gd"):
                    filepath = os.path.join(root, file)
                    violations = check_file(filepath)

                    if violations:
                        all_violations = True
                        print(f"\n[VIOLATION] in {filepath}:")
                        for line_num, msg in violations:
                            if line_num == 0:
                                print(f"  - (Class Name) {msg}")
                            else:
                                print(f"  - Line {line_num}: {msg}")

    if all_violations:
        print("\nBoundary checks FAILED. See violations above.")
        sys.exit(1)
    else:
        print("Boundary checks PASSED cleanly.")
        sys.exit(0)

if __name__ == "__main__":
    main()
