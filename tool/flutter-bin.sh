#!/bin/sh
# Source this helper; it changes no global shell configuration.
if [ -n "${FLUTTER_BIN:-}" ]; then
  :
elif command -v flutter >/dev/null 2>&1; then
  FLUTTER_BIN=$(command -v flutter)
elif [ -x "$HOME/Development/flutter/bin/flutter" ]; then
  FLUTTER_BIN="$HOME/Development/flutter/bin/flutter"
else
  echo 'Flutter is not installed. Set FLUTTER_BIN to its executable.' >&2
  exit 1
fi
