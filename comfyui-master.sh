#!/bin/bash

# Define o diretório persistente para Quickpod
PERSISTENT_DIR="/home/runner"
cd "$PERSISTENT_DIR"

# Causa o script a sair em caso de falha de qualquer comando.
set -eo pipefail

echo "Iniciando provisionamento personalizado para Quickpod (versão final)..."

# --- Instalações Iniciais do Sistema (se a imagem base não tiver) ---
# Embora a imagem ComfyUI_Qick25 deva ter muitos, é bom garantir o ffmpeg.
echo "Verificando e instalando dependências do sistema (ffmpeg)..."
apt-get update -y || echo "Aviso: apt-get update falhou."
apt-get install -y ffmpeg || echo "Aviso: ffmpeg já instalado ou falhou a instalar."
echo "Dependências do sistema verificadas/instaladas."


# --- Ativação do Ambiente Python (Prioriza venv, depois Conda) ---
echo "Tentando ativar ambiente Python..."
if [ -f "/venv/main/bin/activate" ]; then # Tenta venv se for o caso
    . /venv/main/bin/activate
    echo "Ambiente venv '/venv/main' ativado."
elif CONDA_BASE_PATH=$(conda info --base 2>/dev/null); then # Tenta Conda
    source "$CONDA_BASE_PATH"/etc/profile.d/conda.sh
    echo "Conda base path: $CONDA_BASE_PATH"
    if conda activate comfy; then
        echo "Ambiente 'comfy' ativado."
    elif conda activate base; then
        echo "Ambiente 'base' ativado."
    else
        echo "Nenhum ambiente Conda detectado ou ativado. Usando ambiente de sistema para pip."
    fi
else
    echo "Nenhum ambiente venv ou Conda detectado. Usando ambiente de sistema para pip."
fi

# --- Clonar/Atualizar ComfyUI ---
COMFYUI_DIR="$PERSISTENT_DIR/ComfyUI"
if [ ! -d "$COMFYUI_DIR" ]; then
    echo "ComfyUI não encontrado em $COMFYUI_DIR. Clonando..."
    git clone https://github.com/comfyanonymous/ComfyUI.git "$COMFYUI_DIR"
    git config --global --add safe.directory "$COMFYUI_DIR" # Adiciona o diretório à lista segura do Git
    echo "ComfyUI clonado."
fi

echo "Forçando atualização do ComfyUI via git pull e pip install..."
cd "$COMFYUI_DIR"
git config --global --add safe.directory "$(pwd)" # Garante que o diretório atual seja seguro
git config pull.rebase false
git pull origin master

# Instalação das dependências PyTorch com CUDA (cu124 - ajustado para o log)
echo "Instalando PyTorch com CUDA (cu124 - ajustado para o log)..."
pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu124 || \
echo "Aviso: Falha na instalação de PyTorch com cu124. Verifique a compatibilidade CUDA."

echo "Instalando requisitos base do ComfyUI e pacotes adicionais..."
pip install -r requirements.txt --no-cache-dir --upgrade --force-reinstall
pip install bitsandbytes>=0.43.0 gguf --upgrade # bitsandbytes e gguf

echo "Limpeza de dependências: 'pip autoremove' não disponível, pulando."




echo "Provisionamento personalizado concluído."
