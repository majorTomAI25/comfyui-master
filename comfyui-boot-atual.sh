#!/bin/bash

# pastas necessárias
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

# --- Baixe modelos do Sonic (opcional)

mkdir -p /workspace/ComfyUI/models/sonic
cd /workspace/ComfyUI/models/sonic

HUGGINGFACE_HUB_TOKEN="SEU_TOKEN_AQUI"

wget --header="Authorization: Bearer $HUGGINGFACE_HUB_TOKEN" \
  -O unet.pth https://huggingface.co/smthemex/Sonic/raw/main/unet.pth 

wget --header="Authorization: Bearer $HUGGINGFACE_HUB_TOKEN" \
  -O audio2bucket.pth https://huggingface.co/smthemex/Sonic/raw/main/audio2bucket.pth 

wget --header="Authorization: Bearer $HUGGINGFACE_HUB_TOKEN" \
  -O audio2token.pth https://huggingface.co/smthemex/Sonic/raw/main/audio2token.pth 

# --- Baixe modelos do ReActor (WAN2.1)

mkdir -p /workspace/ComfyUI/models/reactor
cd /workspace/ComfyUI/models/reactor

wget -O wav2lip_gan.pth https://cloud.tsinghua.edu.cn/f/f73b4dbee5fa4a93aae5c/download?dl=1
wget -O GFPGANv1.4.pth https://github.com/TencentARC/GFPGAN/releases/download/v1.3.4/GFPGANv1.4.pth
wget -O CodeFormer.cpkt https://github.com/sczhou/CodeFormer/releases/download/v0.1.0/CodeFormer.cpkt

# --- Instale os Custom Nodes 

cd /workspace/ComfyUI/custom_nodes

# ReActor Node (WAV2LIP ANIMATED / WAN2.1)
if [ ! -d "comfyui-reactor-node" ]; then
    echo "🔊 Clonando ReActor Node..."
    git clone https://github.com/chehongjie/comfyui-reactor-node.git 
    pip install -r comfyui-reactor-node/requirements.txt
else
    echo "⏩ ReActor Node já instalado."
fi

# Sonic Lip Sync
if [ ! -d "ComfyUI_Sonic" ]; then
    echo "🔊 Clonando ComfyUI_Sonic..."
    git clone https://github.com/smthemex/ComfyUI_Sonic.git 
    pip install -r ComfyUI_Sonic/requirements.txt
else
    echo "⏩ ComfyUI_Sonic já instalado."
fi

# --- Inicie o ComfyUI
echo "🔁 Iniciando ComfyUI..."
cd /workspace/ComfyUI
python main.py --port 8188 --host 0.0.0.0
