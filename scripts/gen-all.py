"""Regenerate every Focus theme, for every editor, from the one palette table.

The three generators are independent and can be run on their own; this runs all
of them in one go so a palette change cannot land on two platforms and miss the
third.

Usage:  python scripts/gen-all.py
"""
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

GENERATORS = [
    ("Visual Studio", os.path.join("FocusThemes", "Themes", "gen-themes.py")),
    ("VS Code / Cursor", os.path.join("vscode", "gen-vscode.py")),
    ("Rider / PyCharm", os.path.join("jetbrains", "gen-jetbrains.py")),
]


def main():
    failed = []
    for label, relative in GENERATORS:
        print("=== %s" % label)
        result = subprocess.run([sys.executable, os.path.join(ROOT, relative)],
                                cwd=ROOT)
        if result.returncode:
            failed.append(label)
        print("")

    if failed:
        print("FAILED: %s" % ", ".join(failed))
        return 1
    print("all %d generator(s) clean" % len(GENERATORS))
    return 0


if __name__ == "__main__":
    sys.exit(main())
