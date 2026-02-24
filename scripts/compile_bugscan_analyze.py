#!/usr/bin/env python3
"""Analyze NWNScriptCompiler bugscan logs and produce structured summary."""

from __future__ import annotations

import argparse
import json
import re
from collections import defaultdict
from pathlib import Path
from typing import Any

WARNING_RE = re.compile(r"warning", re.IGNORECASE)
ERROR_RE = re.compile(r"error", re.IGNORECASE)
SOURCE_PREFIX = "__BUGSCAN_SOURCE__="
EXIT_PREFIX = "__BUGSCAN_EXIT_CODE__="
OUTPUT_MARKER = "__BUGSCAN_OUTPUT_BEGIN__"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Analyze bugscan compile logs and summarize warnings/errors by source file."
    )
    parser.add_argument("logs", nargs="+", help="Paths to bugscan log files.")
    parser.add_argument(
        "--format",
        choices=("json", "text"),
        default="json",
        help="Output format printed to stdout.",
    )
    parser.add_argument(
        "--json-out",
        default="",
        help="Optional path to write JSON summary artifact.",
    )
    return parser.parse_args()


def parse_log(log_path: Path) -> dict[str, Any]:
    lines = log_path.read_text(encoding="utf-8", errors="replace").splitlines()

    source = ""
    exit_code = 0
    output_start: int | None = None
    invalid_exit_code: str | None = None

    for idx, line in enumerate(lines):
        if line.startswith(SOURCE_PREFIX):
            source = line[len(SOURCE_PREFIX) :].strip()
        elif line.startswith(EXIT_PREFIX):
            raw_exit = line[len(EXIT_PREFIX) :].strip()
            if raw_exit:
                try:
                    exit_code = int(raw_exit)
                except ValueError:
                    exit_code = 1
                    invalid_exit_code = raw_exit
        elif line.strip() == OUTPUT_MARKER:
            output_start = idx + 1
            break

    if output_start is not None and output_start <= len(lines):
        output_lines = lines[output_start:]
    else:
        output_lines = []

    warnings: list[str] = []
    errors: list[str] = []

    if output_start is None:
        errors.append(f"log format error: missing marker {OUTPUT_MARKER}")

    if invalid_exit_code is not None:
        errors.append(f"log format error: invalid exit code '{invalid_exit_code}'")

    for line in output_lines:
        if WARNING_RE.search(line):
            warnings.append(line)
        if ERROR_RE.search(line):
            errors.append(line)

    if exit_code != 0 and not errors:
        errors.append(f"compiler exited with code {exit_code}")

    return {
        "log": str(log_path),
        "source": source,
        "exit_code": exit_code,
        "warnings": warnings,
        "errors": errors,
    }


def build_summary(records: list[dict[str, Any]]) -> dict[str, Any]:
    by_file: dict[str, dict[str, Any]] = defaultdict(
        lambda: {"warnings": [], "errors": [], "logs": [], "non_zero_exits": []}
    )

    total_warnings = 0
    total_errors = 0

    for record in records:
        source = record["source"] or "(unknown-source)"
        bucket = by_file[source]
        bucket["warnings"].extend(record["warnings"])
        bucket["errors"].extend(record["errors"])
        bucket["logs"].append(record["log"])

        if record["exit_code"] != 0:
            bucket["non_zero_exits"].append(record["exit_code"])

        total_warnings += len(record["warnings"])
        total_errors += len(record["errors"])

    status = "failed" if total_errors > 0 else "ok"

    return {
        "status": status,
        "totals": {
            "files": len(by_file),
            "warnings": total_warnings,
            "errors": total_errors,
        },
        "files": dict(sorted(by_file.items())),
    }


def print_text(summary: dict[str, Any]) -> None:
    print(f"Status: {summary['status']}")
    print(f"Total files: {summary['totals']['files']}")
    print(f"Total warnings: {summary['totals']['warnings']}")
    print(f"Total errors: {summary['totals']['errors']}")

    for source, data in summary["files"].items():
        print()
        print(f"FILE: {source}")
        print(f"  warnings: {len(data['warnings'])}")
        print(f"  errors: {len(data['errors'])}")

        if data["warnings"]:
            print("  warning_lines:")
            for line in data["warnings"]:
                print(f"    - {line}")

        if data["errors"]:
            print("  error_lines:")
            for line in data["errors"]:
                print(f"    - {line}")


def main() -> int:
    args = parse_args()

    records = []
    for raw_path in args.logs:
        path = Path(raw_path)
        if not path.is_file():
            raise FileNotFoundError(f"Log file not found: {path}")
        records.append(parse_log(path))

    summary = build_summary(records)

    if args.json_out:
        json_path = Path(args.json_out)
        json_path.parent.mkdir(parents=True, exist_ok=True)
        json_path.write_text(json.dumps(summary, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    if args.format == "text":
        print_text(summary)
    else:
        print(json.dumps(summary, indent=2, ensure_ascii=False))

    return 1 if summary["totals"]["errors"] > 0 else 0


if __name__ == "__main__":
    raise SystemExit(main())
