#!/bin/bash

echo "Iniciando meu script de provisionamento personalizado..."
cd /workspace
# Instale dependências básicas
echo "🧰 Instalando PyTorch e dependências principais..."
pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu124 
# Verifica se o ComfyUI existe e o atualiza
COMFYUI_DIR="/workspace/ComfyUI" # Vast.ai geralmente instala aqui
if [ -d "$COMFYUI_DIR" ]; then
    echo "ComfyUI encontrado em $COMFYUI_DIR. Atualizando..."
    cd "$COMFYUI_DIR"
    git pull
    pip install -r requirements.txt --no-cache-dir --upgrade
    echo "ComfyUI atualizado."
else
    echo "ComfyUI não encontrado em $COMFYUI_DIR. Clonando..."
    # Se por algum motivo o template base não tiver o ComfyUI, clone.
    git clone https://github.com/comfyanonymous/ComfyUI.git "$COMFYUI_DIR"
    cd "$COMFYUI_DIR"
    pip install -r requirements.txt --no-cache-dir
apt-get update

apt install ffmpeg

# Instale dependências básicas
echo "🧰 Instalando PyTorch e dependências principais..."
pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu124 
    
    echo "ComfyUI clonado e dependências instaladas."

