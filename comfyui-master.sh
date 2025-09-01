#!/bin/bash

# Crie pastas necessárias
mkdir -p /workspace/ComfyUI
cd /workspace

# Clone do ComfyUI (se ainda não existir)
if [ ! -d "ComfyUI" ]; then
    echo "📦 Clonando ComfyUI..."
    git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI
else
    echo "🔄 Atualizando ComfyUI..."
    cd /ComfyUI
    git pull
    pip install -r requirements.txt
fi

echo "🔁 Iniciando ComfyUI..."
cd /workspace/ComfyUI
python main.py --port 8188 --host 0.0.0.0


