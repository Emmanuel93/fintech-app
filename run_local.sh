#!/bin/bash
# Uso:
#   ./run_local.sh               → simulador (localhost, sin config extra)
#   ./run_local.sh <device-udid> → iPhone físico (detecta IP de la Mac)

SIMULATOR_ID="280BA0D6-F4F9-4B61-A71C-299EAF739917"
cd "$(dirname "$0")/packages/fa_shell" || exit 1

if [ -z "$1" ]; then
  xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || true
  open -a Simulator
  flutter run -t lib/main_local.dart -d "$SIMULATOR_ID"
else
  MAC_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)
  echo "▶ Dispositivo → BFF en http://$MAC_IP:8085"
  flutter run -t lib/main_local.dart -d "$1" \
    --dart-define="BFF_URL=http://$MAC_IP:8085"
fi
