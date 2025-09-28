#!/usr/bin/env bash
set -euo pipefail

docker stop swiftbible-ngrok >/dev/null 2>&1 || true
