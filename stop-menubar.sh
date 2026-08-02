#!/bin/zsh
# Stop DeepWeather.
set -euo pipefail

if pkill -x DeepWeather 2>/dev/null; then
    echo "DeepWeather stopped."
else
    echo "DeepWeather is not running."
fi
