#!/bin/bash

# Set up error handling
set -e

# Define variables
PROJECT_NAME="odoo_project"
PROJECT_DIR="/opt/$PROJECT_NAME"
DOCKER_COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Create project directory and set permissions
create_project_structure() {
    sudo mkdir -p "$PROJECT_DIR"
    sudo mkdir -p "$PROJECT_DIR/odoo-data"
    sudo mkdir -p "$PROJECT_DIR/odoo-config"
    sudo mkdir -p "$PROJECT_DIR/odoo-addons"
    sudo mkdir -p "$PROJECT_DIR/postgres-data"
    sudo mkdir -p "$PROJECT_DIR/portainer-data"
    sudo chown -R $USER:$USER "$PROJECT_DIR"
    echo "Project directory structure created."
}

# Install dependencies
install_dependencies() {
    sudo apt update
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

    # Install Docker if not already installed
    if ! command_exists docker; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        echo "Docker installed successfully."
    else
        echo "Docker is already installed."
    fi

    # Install Docker Compose if not already installed
    if ! command_exists docker-compose; then
        sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        echo "Docker Compose installed successfully."
    else
        echo "Docker Compose is already installed."
    fi
}

# Create Docker Compose file
create_docker_compose_file() {
    cat << EOF > "$DOCKER_COMPOSE_FILE"
version: '3.8'
services:
  odoo:
    image: odoo:17
    user: root
    depends_on:
      - db
    ports:
      - "8069:8069"
    volumes:
      - ./odoo-data:/var/lib/odoo
      - ./odoo-config:/etc/odoo
      - ./odoo-addons:/mnt/extra-addons
    environment:
      - HOST=db
      - USER=odoo
      - PASSWORD=odoo_password
    restart: unless-stopped
    command: ["--limit-memory-hard", "0", "--limit-memory-soft", "0"]
  db:
    image: postgres:16
    environment:
      - POSTGRES_DB=postgres
      - POSTGRES_PASSWORD=odoo_password
      - POSTGRES_USER=odoo
    volumes:
      - ./postgres-data:/var/lib/postgresql/data
    restart: unless-stopped
  portainer:
    image: portainer/portainer-ce:latest
    ports:
      - "9000:9000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./portainer-data:/data
    restart: unless-stopped
EOF
    echo "Docker Compose file created."
}

# Main execution
echo "Starting Odoo project setup..."

create_project_structure
install_dependencies
create_docker_compose_file

echo "Setup complete. Your Odoo project is ready at $PROJECT_DIR"
echo "To start the services, run: cd $PROJECT_DIR && docker-compose up -d"
echo "Remember to change the default passwords in the docker-compose.yml file before deploying in production."
