#!/usr/bin/env bash
set -e

# Startscript für den Container.
# Default: Startet finetune.py und bindet an 0.0.0.0:7052
# Wenn MODE=interactive dann startet /bin/bash

MODE="${MODE:-finetune}"    # default: finetune
PORT_FT="${FINETUNE_PORT:-7052}"

# Ensure environment uses cuda-11.8 libs first
export PATH=/usr/local/cuda-11.8/bin:$PATH || true
export LD_LIBRARY_PATH=/usr/local/cuda-11.8/lib64:$LD_LIBRARY_PATH || true

cd /app/alltalk_tts

if [ "$MODE" = "interactive" ]; then
  echo "[start-alltalk] Interactive mode: drop to shell"
  exec /bin/bash
fi

if [ "$MODE" = "finetune" ]; then
  echo "[start-alltalk] Starting Finetune Web UI on 0.0.0.0:${PORT_FT}"
  # Sicherstellen, dass server_name in finetune.py auf 0.0.0.0 gesetzt ist
  if grep -q "server_name *= *\"127.0.0.1\"" finetune.py 2>/dev/null; then
    sed -i "s/server_name *= *\"127.0.0.1\"/server_name=\"0.0.0.0\"/g" finetune.py || true
  fi
  # Falls finetune.py akzeptiert, setze port var (falls es eine Variable server_port gibt)
  sed -i "s/server_port *= *.*/server_port=${PORT_FT}/g" finetune.py 2>/dev/null || true

  # Starte finetune (stdout/stdin bleiben im Container-Log)
  exec python3 finetune.py
fi

# Fallback: Bash
exec /bin/bash
