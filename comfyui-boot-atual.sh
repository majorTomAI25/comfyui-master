#!/bin/bash
# ComfyUI QuickPod GPU Server Startup Script
# Updated with latest ComfyUI components and dependencies

SSH_USER=${SSH_USER:-root}
COMFYUI_DIR="/workspace/ComfyUI"
JUPYTER_PORT=${JUPYTER_PORT:-8888}
COMFYUI_PORT=${COMFYUI_PORT:-8188}

# Create user if it doesn't exist
if ! id "$SSH_USER" &>/dev/null; then
    useradd -m -s /bin/bash $SSH_USER
    echo "Created user: $SSH_USER"
fi

# Configure SSH access
if [ -n "$SSH_PASSWORD" ]; then
    echo "Configuring SSH password authentication..."
    sed -i 's/^#*PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
    echo "$SSH_USER:$SSH_PASSWORD" | chpasswd
    echo "Password set for $SSH_USER"
fi

if [ -n "$PUBLIC_KEY" ]; then
    echo "Configuring SSH key authentication..."
    HOME_DIR=$(getent passwd "$SSH_USER" | cut -d: -f6)
    mkdir -p $HOME_DIR/.ssh
    echo "$PUBLIC_KEY" > $HOME_DIR/.ssh/authorized_keys
    chown -R $SSH_USER:$SSH_USER $HOME_DIR/.ssh
    chmod 700 $HOME_DIR/.ssh
    chmod 600 $HOME_DIR/.ssh/authorized_keys
    echo "SSH key configured for $SSH_USER"
fi

# Update ComfyUI and components
echo "Updating ComfyUI and components..."
cd $COMFYUI_DIR

# Update main ComfyUI
git pull

pip install -r requirements.txt


# Update or install essential components
COMPONENTS=(
    git clone https://github.com/Comfy-Org/ComfyUI_frontend.git
cd ComfyUI_frontend
workflow_templates:
git clone https://github.com/Comfy-Org/workflow_templates.git

git clone https://github.com/comfyanonymous/ComfyUI-frontend-package)

for component in "${COMPONENTS[@]}"; do
    folder_name=$(basename $component)
    if [ -d "custom_nodes/$folder_name" ]; then
        echo "Updating $folder_name..."
        cd "custom_nodes/$folder_name"
        git pull
        cd $COMFYUI_DIR
    else
        echo "Installing $folder_name..."
        git clone $component "custom_nodes/$folder_name"
    fi
done

# Install Python dependencies
echo "Installing Python dependencies..."
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# Install component-specific dependencies
for component in "${COMPONENTS[@]}"; do
    folder_name=$(basename $component)
    if [ -f "custom_nodes/$folder_name/requirements.txt" ]; then
        echo "Installing dependencies for $folder_name..."
        pip install -r "custom_nodes/$folder_name/requirements.txt"
    fi
done

# Start services
echo "Starting services..."

# Start SSH server
/usr/sbin/sshd -D &

# Start Jupyter Lab
nohup jupyter-lab \
    --allow-root \
    --ip=0.0.0.0 \
    --port=$JUPYTER_PORT \
    --NotebookApp.token='' \
    --notebook-dir=$COMFYUI_DIR \
    --NotebookApp.allow_origin='*' \
    --NotebookApp.allow_remote_access=1 &

# Start ComfyUI
python main.py \
    --listen \
    --port=$COMFYUI_PORT \
    --enable-cors-header \
    --auto-launch

echo "All services started successfully!"
