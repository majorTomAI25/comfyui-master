#!/bin/bash

# Define o diretório persistente para Quickpod
PERSISTENT_DIR="/home/runner"
cd "$PERSISTENT_DIR"

# Causa o script a sair em caso de falha de qualquer comando.
set -eo pipefail

echo "Iniciando provisionamento COMPLETO de ComfyUI Master em imagem CUDA genérica..."

# --- 1. Instalação de Dependências Essenciais do Sistema ---
echo "Instalando dependências do sistema (git, wget, curl, ffmpeg, build-essential)..."
apt-get update -y && \
apt-get install -y git wget curl ffmpeg build-essential python3-pip && \
rm -rf /var/lib/apt/lists/*
echo "Dependências do sistema instaladas."

# --- 2. Instalação e Configuração do Ambiente Python (Conda) ---
# Vamos usar Miniconda para ter um ambiente mais gerenciável e robusto.
echo "Instalando Miniconda..."
MINICONDA_INSTALLER="$PERSISTENT_DIR/Miniconda3-latest-Linux-x86_64.sh"
if [ ! -f "$MINICONDA_INSTALLER" ]; then
    wget "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh" -O "$MINICONDA_INSTALLER"
fi
bash "$MINICONDA_INSTALLER" -b -p "$PERSISTENT_DIR/miniconda3"
rm "$MINICONDA_INSTALLER"

# Inicializa Conda no shell atual
source "$PERSISTENT_DIR/miniconda3/bin/activate"

# Cria e ativa um novo ambiente Conda para o ComfyUI e ferramentas
echo "Criando e ativando ambiente Conda 'comfy_env'..."
conda update -n base -c defaults conda -y
conda create -n comfy_env python=3.10 -y
conda activate comfy_env
echo "Ambiente 'comfy_env' ativado."

# --- 3. Clonar/Atualizar ComfyUI ---
COMFYUI_DIR="$PERSISTENT_DIR/ComfyUI"
if [ ! -d "$COMFYUI_DIR" ]; then
    echo "ComfyUI não encontrado em $COMFYUI_DIR. Clonando..."
    git clone https://github.com/comfyanonymous/ComfyUI.git "$COMFYUI_DIR"
    git config --global --add safe.directory "$COMFYUI_DIR"
    echo "ComfyUI clonado."
fi

echo "Forçando atualização do ComfyUI via git pull e pip install..."
cd "$COMFYUI_DIR"
git config --global --add safe.directory "$(pwd)"
git config pull.rebase false
git pull origin master

# Instalação das dependências PyTorch com CUDA (VERIFIQUE A VERSÃO CUDA DA IMAGEM GENÉRICA!)
# Por exemplo, se usar nvidia/cuda:12.4.0-cudnn8-devel-ubuntu22.04, use cu124.
echo "Instalando PyTorch com CUDA (cu124 - AJUSTE PARA A VERSÃO DA SUA IMAGEM CUDA GENÉRICA!)..."
pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu124 || \
echo "Aviso: Falha na instalação de PyTorch com cu124. Verifique a compatibilidade CUDA da sua imagem base."

echo "Instalando requisitos base do ComfyUI e pacotes adicionais essenciais..."
pip install -r requirements.txt --no-cache-dir --upgrade
pip install bitsandbytes>=0.43.0 gguf xformers --upgrade

echo "Limpeza de dependências: 'pip autoremove' não disponível, pulando."

# --- 4. Instalação de CUSTOM NODES (COMPLETA) ---
echo "Instalando Custom Nodes para ComfyUI..."
COMFYUI_CUSTOM_NODES_DIR="$COMFYUI_DIR/custom_nodes"
mkdir -p "$COMFYUI_CUSTOM_NODES_DIR"
cd "$COMFYUI_CUSTOM_NODES_DIR"

# Função auxiliar para clonar/atualizar custom nodes
clone_or_update_node() {
    NODE_REPO=$1
    NODE_NAME=$(basename "$NODE_REPO" .git)
    echo "Clonando/Atualizando $NODE_NAME..."
    if [ ! -d "$NODE_NAME" ]; then
        git clone "$NODE_REPO"
    fi
    git config --global --add safe.directory "$COMFYUI_CUSTOM_NODES_DIR/$NODE_NAME"

    cd "$NODE_NAME"
    git pull
    if [ -f "requirements.txt" ]; then
        echo "Instalando requisitos para $NODE_NAME..."
        pip install -r requirements.txt --no-cache-dir
    fi
    cd .. # Volta para custom_nodes
}

clone_or_update_node https://github.com/ltdrdata/ComfyUI-Manager.git
clone_or_update_node https://github.com/chrisgoringe/cg-use-everywhere.git
clone_or_update_node https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git
clone_or_update_node https://github.com/WASasquatch/was-node-suite-comfyui.git
clone_or_update_node https://github.com/rgthree/rgthree-comfy.git
clone_or_update_node https://github.com/city96/ComfyUI-GGUF
clone_or_update_node https://github.com/crystian/ComfyUI-Crystools.git
clone_or_update_node https://github.com/kijai/ComfyUI-KJNodes.git
clone_or_update_node https://github.com/11cafe/comfyui-workspace-manager.git

echo "Custom Nodes instalados e atualizados."

# --- 5. Instalação e Configuração do Sonic (ComfyUI_Sonic) e seus Modelos ---
echo "Instalando ComfyUI_Sonic e baixando modelos necessários..."
SONIC_NODE_DIR="$PERSISTENT_DIR/ComfyUI_Sonic" # Diretório do Custom Node
if [ ! -d "$SONIC_NODE_DIR" ]; then
    git clone --recursive https://github.com/smthemex/ComfyUI_Sonic.git "$SONIC_NODE_DIR" # --recursive para submodules
fi
git config --global --add safe.directory "$SONIC_NODE_DIR"
cd "$SONIC_NODE_DIR"
pip install -r requirements.txt --no-cache-dir

echo "Instalando gdown para download de arquivos do Google Drive..."
pip install gdown

# --- Baixar Modelos do Sonic para ComfyUI/models/sonic/ ---
SONIC_MODELS_DIR="$COMFYUI_DIR/models/sonic"
mkdir -p "$SONIC_MODELS_DIR"
echo "Baixando arquivos para $SONIC_MODELS_DIR (unet.pth, audio2token.pth, audio2bucket.pth, yoloface_v5m.pt)..."
gdown --id 1mjIqU-c5q3qMI74XZd3UrkZek0IDTUUh -O "$SONIC_MODELS_DIR/unet.pth" || echo "unet.pth já existe ou falhou ao baixar."
gdown --id 1vUY-b5NMvDA2XsxRZcB3nF3u1trOtK53h -O "$SONIC_MODELS_DIR/audio2token.pth" || echo "audio2token.pth já existe ou falhou ao baixar."
gdown --id 1RHWasbgUWZg-mFaQhDJtF1KhpUSecC5d -O "$SONIC_MODELS_DIR/audio2bucket.pth" || echo "audio2bucket.pth já existe ou falhou ao baixar."
gdown --id 13Hpfi-cBvlmNvTv6W4Oa7agWyzmvmofB4 -O "$SONIC_MODELS_DIR/yoloface_v5m.pt" || echo "yoloface_v5m.pt já existe ou falhou ao baixar."

# --- Baixar Modelos Whisper (para transcrição) ---
WHISPER_CACHE_DIR="$PERSISTENT_DIR/.cache/whisper"
echo "Limpando cache de modelos Whisper em $WHISPER_CACHE_DIR..."
rm -rf "$WHISPER_CACHE_DIR"
mkdir -p "$WHISPER_CACHE_DIR"

export HF_HOME="$PERSISTENT_DIR/.cache/huggingface"
mkdir -p "$HF_HOME"

echo "Baixando modelo OpenAI Whisper 'tiny.en' (forçando download via biblioteca)..."
pip install git+https://github.com/openai/whisper.git # Instala a biblioteca Whisper do GitHub
python -c "import whisper; print('Downloading Whisper tiny.en model...'); whisper.load_model('tiny.en'); print('Whisper tiny.en model downloaded successfully.');" 2>&1 | tee "$PERSISTENT_DIR/whisper_download_log.txt"

WHISPER_MODEL_PATH="$WHISPER_CACHE_DIR/tiny.en.pt"
if [ -f "$WHISPER_MODEL_PATH" ] && [ -s "$WHISPER_MODEL_PATH" ]; then
    echo "Verificação: Modelo Whisper tiny.en encontrado e não está vazio em $WHISPER_MODEL_PATH."
    file "$WHISPER_MODEL_PATH"
else
    echo "ATENÇÃO: Modelo Whisper tiny.en NÃO encontrado ou está vazio em $WHISPER_MODEL_PATH. O download pode ter falhado."
    echo "Verifique o log de download em $PERSISTENT_DIR/whisper_download_log.txt para mais detalhes."
fi

# --- Baixar Modelo Whisper-tiny (do Hugging Face) ---
echo "Baixando modelo Whisper-tiny (openai/whisper-tiny) do Hugging Face via biblioteca transformers..."
WHISPER_TINY_HF_MODEL_NAME="openai/whisper-tiny"
pip install transformers # Garante que transformers esteja instalado para este download
python -c "from transformers import WhisperProcessor, WhisperForConditionalGeneration; \
    processor = WhisperProcessor.from_pretrained('$WHISPER_TINY_HF_MODEL_NAME'); \
    model = WhisperForConditionalGeneration.from_pretrained('$WHISPER_TINY_HF_MODEL_NAME'); \
    print(f'Modelo $WHISPER_TINY_HF_MODEL_NAME baixado e carregado com sucesso.')" 2>&1 | tee "$PERSISTENT_DIR/whisper_tiny_hf_download_log.txt"

echo "ComfyUI_Sonic e modelos necessários instalados."

# --- RIFE (flownet.pkl) ---
RIFE_DIR="$COMFYUI_DIR/models/RIFE"
mkdir -p "$RIFE_DIR"
echo "Baixando flownet.pkl para ComfyUI/models/RIFE..."
gdown --id 1UnSd-s5DhPRZu4C23I4uOmmahH0J3Dkwl -O "$RIFE_DIR/flownet.pkl" || echo "flownet.pkl já existe ou falhou ao baixar."

# --- Instalação do VideoHelperSuite (VHS com vídeo combine) ---
echo "Configurando VideoHelperSuite..."
VIDEO_HELPER_SUITE_DIR="$COMFYUI_DIR/custom_nodes/ComfyUI-VideoHelperSuite" # É um Custom Node
mkdir -p "$VIDEO_HELPER_SUITE_DIR"
if [ ! -d "$VIDEO_HELPER_SUITE_DIR" ]; then
    git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git "$VIDEO_HELPER_SUITE_DIR"
fi
git config --global --add safe.directory "$VIDEO_HELPER_SUITE_DIR"
cd "$VIDEO_HELPER_SUITE_DIR"
pip install -r requirements.txt --no-cache-dir
echo "VideoHelperSuite configurado."

# --- 6. Baixar Modelos Essenciais (SDXL, SVD, Wan-AI/Wan2.1-T2V-14B) ---
echo "Baixando modelos essenciais para ComfyUI..."
COMFYUI_CHECKPOINTS_DIR="$COMFYUI_DIR/models/checkpoints"
COMFYUI_SVD_DIR="$COMFYUI_DIR/models/svd"
mkdir -p "$COMFYUI_CHECKPOINTS_DIR"
mkdir -p "$COMFYUI_SVD_DIR"

# Stable Diffusion XL Base
echo "Baixando Stable Diffusion XL Base..."
wget -nc -O "$COMFYUI_CHECKPOINTS_DIR/sd_xl_base_1.0.safetensors" "https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors" || echo "SDXL Base model already exists ou falhou ao baixar."

# SVD (Stable Video Diffusion) - Image-to-Video
echo "Baixando Stable Video Diffusion SVD_XT_1_1..."
if [ -z "$TOKEN_HF" ]; then
    echo "AVISO: Variável de ambiente TOKEN_HF não definida. Não será possível baixar modelos Hugging Face privados ou com Gated Access."
else
    wget -nc --header="Authorization: Bearer $TOKEN_HF" -O "$COMFYUI_SVD_DIR/svd_xt_1_1.safetensors" \
    "https://huggingface.co/stabilityai/stable-video-diffusion-img2vid-xt-1-1/resolve/main/svd_xt_1_1.safetensors" || \
    echo "SVD_XT_1_1 já existe ou download falhou (verifique token/rede)."

    wget -nc --header="Authorization: Bearer $TOKEN_HF" -O "$COMFYUI_SVD_DIR/svd_xt_image_decoder.safetensors" \
    "https://huggingface.co/stabilityai/stable-video-diffusion-img2vid-xt/resolve/main/svd_xt_image_decoder.safetensors" || \
    echo "SVD_XT_Image_Decoder já existe ou download falhou (verifique token/rede)."
fi

# Wan-AI/Wan2.1-T2V-14B
echo "Baixando modelo Wan-AI/Wan2.1-T2V-14B..."
WAN_AI_MODEL_URL="https://huggingface.co/Wan-AI/Wan2.1-T2V-14B.safetensors?download=true"
WAN_AI_MODEL_NAME="Wan2.1-T2V-14B.safetensors"
WAN_AI_MODEL_PATH="$COMFYUI_DIR/models/unet/$WAN_AI_MODEL_NAME"

mkdir -p "$(dirname "$WAN_AI_MODEL_PATH")"
wget -nc -O "$WAN_AI_MODEL_PATH" "$WAN_AI_MODEL_URL" || echo "Modelo Wan-AI/Wan2.1-T2V-14B já existe ou falhou ao baixar."

echo "Modelos essenciais instalados."

# --- 7. Script de Inicialização da Aplicação (ComfyUI e JupyterLab) ---
# Este script será chamado no final do provisionamento.
# Ele substitui o start.sh problemático da imagem base.
echo "Criando script de inicialização personalizado (start_app.sh)..."
cat << 'EOF' > "$PERSISTENT_DIR/start_app.sh"
#!/bin/bash

# Ativa o ambiente Conda criado pelo provisioning script
source "$PERSISTENT_DIR/miniconda3/bin/activate" comfy_env

echo "Iniciando serviços da aplicação (ComfyUI e JupyterLab)..."

# Iniciar SSHD (se a imagem base não fizer isso explicitamente)
# (O Dockerfile da imagem comfyui-minimal tem um setup-ssh.sh, então pode já estar rodando)
# /usr/sbin/sshd -D & # Descomente se precisar iniciar SSH aqui

# Iniciar JupyterLab em segundo plano
echo "Iniciando JupyterLab na porta 8888..."
nohup jupyter-lab --allow-root --ip=0.0.0.0 --port=8888 --no-browser --NotebookApp.token='' --NotebookApp.password='' --notebook-dir "$PERSISTENT_DIR/ComfyUI" &> "$PERSISTENT_DIR/jupyter_lab.log" &

# Iniciar ComfyUI em segundo plano
echo "Iniciando ComfyUI na porta 8188..."
cd "$PERSISTENT_DIR/ComfyUI"
# Ajuste --listen 0.0.0.0 para acesso externo
nohup python main.py --listen 0.0.0.0 --port 8188 --output-directory "$PERSISTENT_DIR/ComfyUI/output" &> "$PERSISTENT_DIR/comfyui.log" &

echo "Todos os serviços foram iniciados."
echo "JupyterLab está acessível na porta 8888 (sem token)."
echo "ComfyUI está acessível na porta 8188."

# Mantenha o contêiner em execução
tail -f /dev/null
EOF

chmod +x "$PERSISTENT_DIR/start_app.sh"

echo "Provisionamento personalizado concluído."

# Executa o script de inicialização principal
"$PERSISTENT_DIR/start_app.sh"
