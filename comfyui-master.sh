#!/bin/bash

# Clone do ComfyUI (se ainda não existir)
echo "🔄 Instalando ComfyUI..."
if [ ! -d "ComfyUI" ]; then
    git clone https://github.com/comfyanonymous/ComfyUI.git
fi

cd ComfyUI/custom_nodes
echo "📥 Instalando ComfyUI-Manager..."
git clone https://github.com/Comfy-Org/ComfyUI-Manager.git

cd ..
echo "📦 Instalando dependências do ComfyUI..."
pip install -r requirements.txt
pip install triton
pip install sageattention

echo "🔁 Iniciando ComfyUI..."
cd /workspace/ComfyUI
python main.py --port 8188 --host 0.0.0.0



