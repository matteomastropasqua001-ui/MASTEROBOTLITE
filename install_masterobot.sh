#!/bin/bash
# Installer per MASTEROBOT – Raspberry Pi Zero WH
# Scarica script Python, installa dipendenze, compila whisper.cpp e llama.cpp, scarica modelli e voci Piper

set -e
cd ~

echo ">>> Aggiorno pacchetti..."
sudo apt update && sudo apt upgrade -y

echo ">>> Installo dipendenze base..."
sudo apt install -y \
  build-essential cmake git wget curl sox jq \
  alsa-utils libsndfile1 \
  piper espeak-ng \
  bluetooth network-manager \
  pipewire pipewire-pulse wireplumber libspa-0.2-bluetooth \
  python3 python3-pip python3-venv python3-serial

mkdir -p ~/.masterobot/tmp
mkdir -p ~/piper_models

# -------------------
# Script Python
# -------------------
echo ">>> Scarico masterobot_full.py..."
wget -O ~/masterobot_full.py https://pastebin.com/raw/GjTVw5LP
chmod +x ~/masterobot_full.py

# -------------------
# Whisper.cpp (ASR)
# -------------------
if [ ! -d ~/whisper.cpp ]; then
  echo ">>> Clono whisper.cpp..."
  git clone https://github.com/ggerganov/whisper.cpp ~/whisper.cpp
fi
cd ~/whisper.cpp
make -j2
mkdir -p models
if [ ! -f models/ggml-tiny.bin ]; then
  echo ">>> Scarico modello whisper tiny..."
  wget -O models/ggml-tiny.bin https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin
fi

# -------------------
# llama.cpp (LLM)
# -------------------
if [ ! -d ~/llama.cpp ]; then
  echo ">>> Clono llama.cpp..."
  git clone https://github.com/ggerganov/llama.cpp ~/llama.cpp
fi
cd ~/llama.cpp
make -j2
mkdir -p models
if [ ! -f models/TinyLlama-1.1B-Chat-v1.0.Q4_K_M.gguf ]; then
  echo ">>> Scarico modello TinyLlama..."
  wget -O models/TinyLlama-1.1B-Chat-v1.0.Q4_K_M.gguf \
    https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/TinyLlama-1.1B-Chat-v1.0.Q4_K_M.gguf
fi

# -------------------
# Piper (TTS) voci
# -------------------
cd ~/piper_models
declare -A VOICES
VOICES[it]="https://huggingface.co/rhasspy/piper-voices/resolve/main/it/it_IT/riccardo/x_low/it_IT-riccardo-x_low.onnx"
VOICES[en]="https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/amy/medium/en_US-amy-medium.onnx"
VOICES[es]="https://huggingface.co/rhasspy/piper-voices/resolve/main/es/es_ES/davefx/medium/es_ES-davefx-medium.onnx"

for lang in it en es; do
  fname=$(basename ${VOICES[$lang]})
  if [ ! -f "$fname" ]; then
    echo ">>> Scarico voce Piper $lang..."
    wget -O "$fname" "${VOICES[$lang]}"
  fi
done

echo "✔ Installazione completata!"
echo ""
echo "Puoi avviare il bot con:"
echo "  python3 ~/masterobot_full.py"
echo ""
echo "Per installarlo come servizio systemd utente:"
echo "  python3 ~/masterobot_full.py --install-service"
echo "  systemctl --user start masterobot"
