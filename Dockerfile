# Perfektes Dockerfile für AllTalk TTS Finetuning (CUDA 11.8, fokussiert auf Voice Cloning)
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

LABEL maintainer="deinname <email@example.com>"
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV PYTHONUNBUFFERED=1
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=$CUDA_HOME/bin:$PATH
ENV LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH

# Systempakete installieren (inkl. libaio-dev für DeepSpeed)
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-venv python3-dev \
    git git-lfs wget curl ca-certificates build-essential \
    ffmpeg libsndfile1 libsndfile1-dev pkg-config \
    unzip zip locales libaio-dev \
    && rm -rf /var/lib/apt/lists/*

# Locale setzen
RUN locale-gen en_US.UTF-8 || true

WORKDIR /app

# Pip upgraden
RUN python3 -m pip install --upgrade pip setuptools wheel

# PyTorch für CUDA 11.8 installieren (kompatibel mit DeepSpeed)
RUN python3 -m pip install --no-cache-dir \
    torch==2.1.2 torchvision==0.16.2 torchaudio==2.1.2 --index-url https://download.pytorch.org/whl/cu118

# AllTalk TTS klonen (neueste Version)
RUN git clone https://github.com/erew123/alltalk_tts.git /app/alltalk_tts

# Requirements installieren (core + finetune)
WORKDIR /app/alltalk_tts
RUN python3 -m pip install --no-cache-dir -r requirements.txt \
    && python3 -m pip install --no-cache-dir -r requirements_finetune.txt

# Weitere Pakete upgraden/updaten (vermeide Konflikte, z.B. Numpy 1.24+)
RUN python3 -m pip install --no-cache-dir --upgrade \
    numpy>=1.24 \
    pandas>=2.0 \
    scipy \
    gradio \
    transformers \
    datasets \
    tqdm \
    TTS

# Vollständiges XTTS-v2-Modell herunterladen (via Transformers, für Finetuning)
RUN python3 -c "from transformers import pipeline; pipeline('text-to-speech', model='coqui/XTTS-v2', device='cuda')"

# Entry-Point-Script für Setup und Start (DeepSpeed nachinstallieren)
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]
