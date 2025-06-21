#!/bin/bash

# Pasta principal
cd /workspace

# Garante ambiente Conda ativo
source /opt/conda/etc/profile.d/conda.sh
conda activate base

# Baixa e instala o ComfyUI (se não existir)
if [ ! -d "ComfyUI" ]; then
    echo "📦 Clonando ComfyUI..."
    git clone https://github.com/comfyanonymous/ComfyUI.git 
fi

# Entra na pasta ComfyUI
cd ComfyUI

# Atualiza o ComfyUI (se já clonado)
git pull origin master

# Cria pastas de modelos se necessário
mkdir -p models/reactor models/sonic custom_nodes

# Baixa modelos WAN2.1 (ReActor)
cd models/reactor
wget -nc https://cloud.tsinghua.edu.cn/f/f73b4dbee5fa4a93aae5c/download?dl=1 -O wav2lip_gan.pth
wget -nc https://github.com/TencentARC/GFPGAN/releases/download/v1.3.4/GFPGANv1.4.pth -O GFPGANv1.4.pth
wget -nc https://github.com/sczhou/CodeFormer/releases/download/v0.1.0/CodeFormer.cpkt -O CodeFormer.cpkt

# Vai para custom nodes 
cd ../../custom_nodes

# Clona o ReActor Node (funcional)
if [ ! -d "comfyui-reactor-node" ]; then
    git clone https://github.com/chehongjie/comfyui-reactor-node.git 
    pip install -r comfyui-reactor-node/requirements.txt
else
    cd comfyui-reactor-node && git pull origin main || git pull origin master
fi

# Clona o Sonic Lip Sync (se quiser usar também)
cd ..
if [ ! -d "ComfyUI_Sonic" ]; then
    git clone https://github.com/smthemex/ComfyUI_Sonic.git 
    cd ComfyUI_Sonic
    pip install -r requirements.txt
else
    cd ComfyUI_Sonic && git pull origin main || git pull origin master
fi

# Volta para a pasta principal do ComfyUI
cd ../..

# Inicia o ComfyUI
echo "🔁 Iniciando ComfyUI..."
python main.py --port 8188 --host 0.0.0.0
