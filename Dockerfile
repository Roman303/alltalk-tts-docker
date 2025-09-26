# Dockerfile für AllTalk TTS Finetuning (CUDA 11.8 + cuDNN8)
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

LABEL maintainer="deinname <email@example.com>"
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV PYTHONUNBUFFERED=1
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=$CUDA_HOME/bin:$PATH
ENV LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH

# --- Systempakete (leichtgewichtig, keine GUI) ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-venv python3-dev \
    git git-lfs wget curl ca-certificates build-essential \
    ffmpeg libsndfile1 libsndfile1-dev pkg-config \
    unzip zip locales \
    && rm -rf /var/lib/apt/lists/*

# set locale
RUN locale-gen en_US.UTF-8 || true

WORKDIR /app

# Upgrade pip
RUN python3 -m pip install --upgrade pip setuptools wheel

# Installiere PyTorch (CUDA 11.8) - verwende offiziellen Index
# (wird die passende cu118-build ziehen)
RUN python3 -m pip install --no-cache-dir \
    "torch" "torchvision" "torchaudio" --extra-index-url https://download.pytorch.org/whl/cu118

# Klone AllTalk in /app/alltalk_tts
RUN git clone https://github.com/erew123/alltalk_tts.git /app/alltalk_tts

# Installiere Python dependencies (core + finetune). Manche Pakete können fehlschlagen; wir versuchen trotzdem weiter.
WORKDIR /app/alltalk_tts
RUN python3 -m pip install --no-cache-dir -r requirements.txt || true
RUN python3 -m pip install --no-cache-dir -r requirements_finetune.txt || true

# Optional: Wenn du Deepspeed brauchst, installiere es nach Bedarf (manchmal Plattformabhängig)
# RUN python3 -m pip install --no-cache-dir deepspeed

# Modelle/Tokenizer vorbereiten (XTTS-v2). Wir versuchen, HF LFS clone, fallback auf wget.
RUN mkdir -p /app/alltalk_tts/models
WORKDIR /app/alltalk_tts/models

# git-lfs init (nicht immer nützlich im CI, aber gut zu haben)
RUN git lfs install --skip-repo || true

# try clone model (ok wenn LFS nicht verfügbar — wir liefern zusätzlich wget fallback)
RUN git clone https://huggingface.co/coqui/XTTS-v2 || true

# Always attempt to download minimal tokenizer files (vocab + config) so finetune nicht fehlschlägt
RUN mkdir -p /app/alltalk_tts/models/XTTS-v2 \
 && wget -q -nc -P /app/alltalk_tts/models/XTTS-v2/ https://huggingface.co/coqui/XTTS-v2/resolve/main/vocab.json \
 && wget -q -nc -P /app/alltalk_tts/models/XTTS-v2/ https://huggingface.co/coqui/XTTS-v2/resolve/main/config.json

WORKDIR /app/alltalk_tts

# Setze server_name in finetune.py auf 0.0.0.0, falls vorhanden (vereinfachter patch)
RUN if [ -f finetune.py ]; then \
      sed -i "s/server_name *= *\"127.0.0.1\"/server_name=\"0.0.0.0\"/g" finetune.py || true; \
    fi

# Erstelle ein Start-Skript (siehe next)
COPY start-alltalk.sh /usr/local/bin/start-alltalk.sh
RUN chmod +x /usr/local/bin/start-alltalk.sh

# Exponiere die üblichen Ports (7051 AllTalk, 7052 Finetune, 6006 Tensorboard, 1111 open-button etc.)
EXPOSE 7051 7052 6006 1111 8080

# Standard-Arbeitsordner
WORKDIR /app/alltalk_tts

# Default: starte das Start-Skript (kann beim docker run überschrieben werden)
ENTRYPOINT ["/usr/local/bin/start-alltalk.sh"]
