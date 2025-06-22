Bash

#!/bin/bash
cd /workspace

# --- 1. Verificação e Ativação do Ambiente Python (Crucial!) ---
# A imagem Vast.ai/comfy geralmente usa Conda.
# Vamos tentar detectar o ambiente ComfyUI corretamente.

CONDA_BASE_PATH=$(conda info --base 2>/dev/null)
if [ -n "$CONDA_BASE_PATH" ]; then
    source "$CONDA_BASE_PATH"/etc/profile.d/conda.sh # Importa as funções do conda
    echo "Conda base path: $CONDA_BASE_PATH"
    if conda activate comfy; then
        echo "Ambiente 'comfy' ativado."
    elif conda activate base; then
        echo "Ambiente 'base' ativado (ambiente 'comfy' não encontrado)."
    else
        echo "Nenhum ambiente Conda detectado ou ativado. Verifique a instalação do Conda."
    fi
else
    echo "Conda não encontrado no sistema. Assumindo ambiente de sistema para pip."
fi

# Verifica se o ComfyUI existe. Se não, clona.
COMFYUI_DIR="/workspace/ComfyUI"
if [ ! -d "$COMFYUI_DIR" ]; then
    echo "ComfyUI não encontrado em $COMFYUI_DIR. Clonando..."
    git clone https://github.com/comfyanonymous/ComfyUI.git "$COMFYUI_DIR"
    echo "ComfyUI clonado."
fi

# **FORÇAR ATUALIZAÇÃO DO COMFYUI AQUI**
echo "Forçando atualização do ComfyUI via git pull e pip install..."
cd "$COMFYUI_DIR"
git config pull.rebase false # Evita problemas de rebase em caso de conflitos
# Força a reinstalação de todas as dependências e atualiza as existentes
pip install -r requirements.txt --no-cache-dir --upgrade --force-reinstall
pip install xformers --upgrade # Garante que xformers esteja atualizado
echo "ComfyUI backend e dependências forçadas."

apt-get update

apt install ffmpeg


# **LIMPEZA DE DEPENDÊNCIAS ANTIGAS**
echo "Removendo dependências Python não utilizadas..."
pip autoremove -y # Remove pacotes que não são mais necessários por nenhum pacote instalado
echo "Limpeza de dependências concluída."
