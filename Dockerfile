# Dockerfile für AllTalk TTS V2 (Beta, CUDA 11.8, Fix für Pip)
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=$CUDA_HOME/bin:$PATH
ENV LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH

# Systempakete (inkl. git-lfs, Build-Tools)
RUN apt-get update && apt-get install -y \
    python3 python3-pip git git-lfs wget curl build-essential \
    ffmpeg libsndfile1 libsndfile1-dev pkg-config libaio-dev \
    libblas-dev liblapack-dev gfortran libatlas-base-dev \
    && git lfs install \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN python3 -m pip install --upgrade pip setuptools wheel

RUN python3 -m pip install --no-cache-dir \
    torch==2.1.2 torchvision==0.16.2 torchaudio==2.1.2 --index-url https://download.pytorch.org/whl/cu118

# AllTalk V2 klonen
RUN git clone --branch alltalkbeta https://github.com/erew123/alltalk_tts.git /app/alltalk_tts

WORKDIR /app/alltalk_tts

# Pip cache purge + separate Installs
RUN pip cache purge
RUN python3 -m pip install --no-cache-dir TTS==0.21.3  # Fallback zu kompatibler Version
RUN sed -i 's/onnxruntime-gpu/onnxruntime/g' system/requirements/requirements_standalone.txt  # CPU für Build
RUN python3 -m pip install --no-cache-dir -r system/requirements/requirements_standalone.txt || true
RUN python3 -m pip install --no-cache-dir -r system/requirements/requirements_finetune.txt || true

# Upgrades
RUN python3 -m pip install --no-cache-dir --upgrade \
    numpy>=1.24 pandas>=2.0 scipy gradio transformers datasets tqdm

# Modell
RUN python3 -c "from transformers import pipeline; pipeline('text-to-speech', model='coqui/XTTS-v2')"

# Entry-Point
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]
