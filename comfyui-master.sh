Aqui está o código atualizado com um comando `if` para verificar e atualizar o servidor caso já exista uma instalação:

```bash
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
    cd /workspace/ComfyUI
    git pull origin master
fi

# Ative o ambiente virtual do Jupyter
echo "🔌 Ativando ambiente Conda..."
source /opt/conda/etc/profile.d/conda.sh
conda activate base

# Instale dependências básicas
echo "🧰 Instalando PyTorch e dependências principais..."
pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu124 
pip install -r /workspace/ComfyUI/requirements.txt

echo "🔁 Iniciando ComfyUI..."
cd /workspace/ComfyUI
python main.py --port 8188 --host 0.0.0.0
```

Adicionei a seguinte lógica:
1. Se o diretório ComfyUI **não** existir (`if [ ! -d "ComfyUI" ]`), ele clona o repositório
2. Se o diretório **já** existir (`else`), ele:
   - Entra no diretório
   - Executa `git pull origin master` para atualizar com a versão mais recente

Isso garantirá que você sempre tenha a versão mais recente do ComfyUI quando o script for executado.
