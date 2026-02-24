# Compile/Bugscan contract

## Scope

`scripts/compile.sh` supports four modes:

- `check`
- `build`
- `optimize`
- `bugscan`

Script is intended for **GitHub Actions Windows runner** only (`GITHUB_ACTIONS=true`, `RUNNER_OS=Windows`).

## Pipeline stages

`compile.sh` runs in explicit stages:

1. **Include preparation**
   - refreshes `.ci/nwn2_stock_scripts` from `third_party/nwn2_stock_scripts`;
   - normalizes `nwscript.NSS -> nwscript.nss`;
   - prepares ordered `-i` include arguments from static include roots and discovered `src/**/*.nss` directories.

2. **Compilation + log collection**
   - `check/build/optimize`: direct sequential compile;
   - `bugscan`: compile each `src/**/*.nss` file with `-a -y`, saving per-file logs to `.ci/bugscan_logs/*.log`.

3. **Bugscan analysis**
   - `scripts/compile_bugscan_analyze.py` parses bugscan logs;
   - creates machine artifact `.ci/bugscan_summary.json`;
   - prints text summary to stdout grouped by source file.

## Input artifacts

Bugscan analyzer expects one or more log files with metadata header:

- `__BUGSCAN_SOURCE__=<absolute-or-repo-path-to-source-file>`
- `__BUGSCAN_EXIT_CODE__=<compiler-exit-code>`
- `__BUGSCAN_OUTPUT_BEGIN__`
- compiler stdout/stderr lines

## Summary format (`.ci/bugscan_summary.json`)

```json
{
  "status": "ok|failed",
  "totals": {
    "files": 0,
    "warnings": 0,
    "errors": 0
  },
  "files": {
    "<source-file>": {
      "warnings": ["..."],
      "errors": ["..."],
      "logs": [".ci/bugscan_logs/000001.log"],
      "non_zero_exits": [1]
    }
  }
}
```

Notes:
- each matched output line containing `warning` (case-insensitive) increments warning count;
- each matched output line containing `error` (case-insensitive) increments error count;
- if compiler returned non-zero and no explicit error lines were found, analyzer injects
  synthetic error: `compiler exited with code <N>`.

## Return codes

### `scripts/compile.sh`

- `0` — success;
- `1` — runtime/validation failure (for bugscan includes analyzer-reported errors);
- `2` — invalid CLI mode or invalid `BUGSCAN_JOBS` value.

### `scripts/compile_bugscan_analyze.py`

- `0` — parsed logs successfully and total errors is `0`;
- `1` — parsed logs successfully and at least one error exists in summary;
- non-zero (python exception) — invalid input (missing log file, malformed metadata).

## Parallel bugscan control

Bugscan parallelism is controlled by environment variable:

- `BUGSCAN_JOBS` (default: `1`)
- must be a positive integer

`compile.sh bugscan` runs compiles in bounded parallel batches (`wait -n` worker pool pattern),
never exceeding `BUGSCAN_JOBS` active compiler processes.
