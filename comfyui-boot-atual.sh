#!/bin/bash
# Crie pastas necessárias
mkdir -p /workspace/ComfyUI
cd /workspace

# Clone do ComfyUI (se ainda não existir)
if [ ! -d "ComfyUI" ]; then
    echo "📦 Clonando ComfyUI..."
    git clone https://github.com/comfyanonymous/ComfyUI.git  /workspace/ComfyUI
fi

# Ative o ambiente virtual do Jupyter
echo "🔌 Ativando ambiente Conda..."
source /opt/conda/etc/profile.d/conda.sh
conda activate base

# Instale dependências básicas
echo "🧰 Instalando PyTorch e dependências principais..."
pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu124 
pip install -r /workspace/ComfyUI/requirements.txt
