#!/usr/bin/env bash
set -euo pipefail

echo "[ERROR] Local Linux/mono/wine/docker compilation is disabled in this repository."
echo "[INFO] Use GitHub Actions workflow '.github/workflows/compile.yml' on windows-latest to compile NWScript."
exit 1
