#!/usr/bin/env bash
# my-cli-config — install every component on this machine (safe to re-run).
#   git clone https://github.com/dutykh/my-cli-config.git ~/workspace/my-cli-config && ~/workspace/my-cli-config/install.sh
# Author : Dr. Denys Dutykh — Khalifa University, Abu Dhabi, UAE  <https://www.denys-dutykh.com/>
# License: MIT — see LICENSE at the repository root
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
for component in "$here"/*/install.sh; do
  echo "▶ ${component#"$here"/}"
  bash "$component"
done
