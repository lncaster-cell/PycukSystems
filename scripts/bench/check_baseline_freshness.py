#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from datetime import datetime, timezone
from pathlib import Path


def main() -> int:
    path = Path(sys.argv[1])
    try:
        text = path.read_text(encoding="utf-8")
    except OSError:
        print("BLOCKED|baseline file not found")
        return 0

    match = re.search(r"- Дата:\s*\*\*(.+?)\*\*", text)
    if not match:
        print("BLOCKED|baseline date field is missing")
        return 0

    raw = match.group(1).strip()
    if raw.upper() == "N/A":
        print("BLOCKED|baseline date is N/A")
        return 0

    try:
        baseline_date = datetime.strptime(raw, "%Y-%m-%d").replace(tzinfo=timezone.utc)
    except ValueError:
        print(f"BLOCKED|baseline date format is invalid: {raw}")
        return 0

    age_days = (datetime.now(timezone.utc) - baseline_date).days
    if age_days > 14:
        print(f"BLOCKED|baseline older than 14 days ({age_days} days)")
    else:
        print(f"FRESH|baseline age {age_days} days")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
