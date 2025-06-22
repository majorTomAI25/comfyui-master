Bash

#!/bin/bash
cd /workspace

# --- 1. Verificação e Ativação do Ambiente Python (Crucial!) ---
QUICK POD ATUALIZAÇAO APOS INICIAR


git clone git@github.com:comfyanonymous/ComfyUI.git

# Instale dependências básicas

# Instale dependências básicas
echo "🧰 Instalando PyTorch e dependências principais..."
pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu124 
 /workspace/ComfyUI/
pip install -r requirements.txt


apt-get update

apt install ffmpeg

cd custom_nodes/ComfyUI-Manager
git pull
