#!/usr/bin/env bash
# my-cli-config — install every component on this machine (safe to re-run).
#   git clone <your-remote> ~/workspace/my-cli-config && ~/workspace/my-cli-config/install.sh
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
for component in "$here"/*/install.sh; do
  echo "▶ ${component#"$here"/}"
  bash "$component"
done
