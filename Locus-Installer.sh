#!/bin/bash

# Locus-Installer.sh - ERPNext 15 Custom Apps Installation Script
# A comprehensive installer for ERPNext 15 with HRMS and custom applications
# Author: Locus ERPNext Installer
# Version: 1.0

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to get user input with default value
get_input() {
    local prompt="$1"
    local default="$2"
    local input
    
    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " input
        echo "${input:-$default}"
    else
        read -p "$prompt: " input
        echo "$input"
    fi
}

# Function to validate email
validate_email() {
    local email="$1"
    if [[ $email =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to validate domain
validate_domain() {
    local domain="$1"
    if [[ $domain =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to create apps.json
create_apps_json() {
    print_status "Creating apps.json configuration..."
    
    cat > apps.json << 'EOF'
[
  {
    "url": "https://github.com/frappe/erpnext",
    "branch": "version-15"
  },
  {
    "url": "https://github.com/frappe/hrms",
    "branch": "version-15"
  }
]
EOF

    print_status "Default apps.json created with ERPNext 15 and HRMS"
    
    echo -e "\nCurrent apps.json content:"
    cat apps.json
    
    echo -e "\nWould you like to add custom apps? (y/n)"
    read -r add_custom
    
    if [[ $add_custom =~ ^[Yy]$ ]]; then
        print_status "You can add custom apps by editing the apps.json file manually after installation"
        print_status "Or modify the apps.json file now before continuing..."
        echo "Press Enter to continue with current configuration or Ctrl+C to exit and modify"
        read -r
    fi
}

# Main installation function
main() {
    print_header "ERPNext 15 Locus Installer"
    echo -e "${PURPLE}A comprehensive installer for ERPNext 15 with HRMS and custom applications${NC}\n"
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root for security reasons"
        print_error "Please run as a regular user with sudo privileges"
        exit 1
    fi
    
    # Check sudo privileges
    if ! sudo -n true 2>/dev/null; then
        print_status "This script requires sudo privileges. You may be prompted for your password."
    fi
    
    # Get user inputs
    print_header "Configuration Setup"
    
    while true; do
        ADMIN_EMAIL=$(get_input "Enter admin email" "admin@example.com")
        if validate_email "$ADMIN_EMAIL"; then
            break
        else
            print_error "Invalid email format. Please try again."
        fi
    done
    
    while true; do
        SITE_NAME=$(get_input "Enter site name (domain)" "example.local")
        if validate_domain "$SITE_NAME"; then
            break
        else
            print_error "Invalid domain format. Please try again."
        fi
    done
    
    DOCKER_USER=$(get_input "Enter Docker Hub username" "myuser")
    DOCKER_REPO=$(get_input "Enter Docker repository name" "erpnext-custom")
    DOCKER_TAG=$(get_input "Enter Docker tag" "v15.5.0")
    
    print_status "Configuration Summary:"
    echo "  Admin Email: $ADMIN_EMAIL"
    echo "  Site Name: $SITE_NAME"
    echo "  Docker Image: $DOCKER_USER/$DOCKER_REPO:$DOCKER_TAG"
    echo ""
    
    read -p "Continue with installation? (y/n): " -r confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        print_warning "Installation cancelled by user"
        exit 0
    fi
    
    # Step 1: Update and upgrade system
    print_header "Step 1: Updating System"
    print_status "Updating package lists and upgrading system..."
    sudo apt update && sudo apt upgrade -y
    
    # Step 2: Reboot prompt
    print_header "Step 2: System Reboot"
    print_warning "System needs to be rebooted for updates to take effect"
    read -p "Reboot now? (y/n): " -r reboot_confirm
    
    if [[ $reboot_confirm =~ ^[Yy]$ ]]; then
        print_status "Rebooting system... Please reconnect and re-run this script with --continue flag"
        # Create a continue marker
        echo "CONTINUE_FROM=step3" > ~/.locus_installer_state
        echo "ADMIN_EMAIL=$ADMIN_EMAIL" >> ~/.locus_installer_state
        echo "SITE_NAME=$SITE_NAME" >> ~/.locus_installer_state
        echo "DOCKER_USER=$DOCKER_USER" >> ~/.locus_installer_state
        echo "DOCKER_REPO=$DOCKER_REPO" >> ~/.locus_installer_state
        echo "DOCKER_TAG=$DOCKER_TAG" >> ~/.locus_installer_state
        sudo reboot
    fi
    
    continue_installation
}

# Function to continue installation after reboot
continue_installation() {
    # Step 3: Install Git and clone frappe_docker
    print_header "Step 3: Cloning Frappe Docker Repository"
    
    if ! command_exists git; then
        print_status "Installing Git..."
        sudo apt-get install -y git
    fi
    
    if [ ! -d "frappe_docker" ]; then
        print_status "Cloning frappe_docker repository..."
        git clone https://github.com/frappe/frappe_docker
    else
        print_status "frappe_docker directory already exists, pulling latest changes..."
        cd frappe_docker && git pull && cd ..
    fi
    
    cd frappe_docker
    
    # Step 4: Install Docker
    print_header "Step 4: Installing Docker"
    
    if ! command_exists docker; then
        print_status "Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        
        # Add user to docker group
        sudo usermod -aG docker $USER
        print_status "Added user to docker group"
        
        # Test Docker installation
        print_status "Testing Docker installation..."
        if sudo docker run hello-world; then
            print_status "Docker installed successfully!"
        else
            print_error "Docker installation failed!"
            exit 1
        fi
    else
        print_status "Docker is already installed"
    fi
    
    # Step 5: Create apps.json
    print_header "Step 5: Creating Apps Configuration"
    create_apps_json
    
    # Export apps.json as base64
    export APPS_JSON_BASE64=$(base64 -w 0 ./apps.json)
    print_status "Apps configuration exported as base64"
    
    # Step 6: Build the container
    print_header "Step 6: Building Custom Docker Container"
    print_status "Building Docker image: $DOCKER_USER/$DOCKER_REPO:$DOCKER_TAG"
    print_warning "This step may take 10-30 minutes depending on your internet connection..."
    
    docker build \
        --build-arg=FRAPPE_PATH=https://github.com/frappe/frappe \
        --build-arg=FRAPPE_BRANCH=version-15 \
        --build-arg=PYTHON_VERSION=3.10.12 \
        --build-arg=NODE_VERSION=18.12.0 \
        --build-arg=APPS_JSON_BASE64=$APPS_JSON_BASE64 \
        --tag=$DOCKER_USER/$DOCKER_REPO:$DOCKER_TAG \
        --file=images/custom/Containerfile .
    
    if [ $? -eq 0 ]; then
        print_status "Docker image built successfully!"
    else
        print_error "Docker build failed!"
        exit 1
    fi
    
    # Step 7: Get easy install script
    print_header "Step 7: Getting Easy Install Script"
    cd ..
    
    if [ ! -f "easy-install.py" ]; then
        print_status "Downloading easy-install.py..."
        wget https://raw.githubusercontent.com/frappe/bench/develop/easy-install.py
    else
        print_status "easy-install.py already exists"
    fi
    
    # Step 8: Run the easy install script
    print_header "Step 8: Running Easy Install Script"
    print_status "Installing ERPNext with custom image..."
    print_warning "This step may take several minutes..."
    
    python3 easy-install.py \
        --prod \
        --image $DOCKER_USER/$DOCKER_REPO:$DOCKER_TAG \
        --email $ADMIN_EMAIL \
        --sitename $SITE_NAME
    
    # Step 9: Handle 404 error (optional)
    print_header "Step 9: Domain Configuration Check"
    
    if [ -f "frappe-compose.yml" ]; then
        print_status "Checking domain configuration..."
        
        if grep -q "site1.localhost" frappe-compose.yml; then
            print_warning "Found default localhost configuration"
            read -p "Update domain configuration to $SITE_NAME? (y/n): " -r update_domain
            
            if [[ $update_domain =~ ^[Yy]$ ]]; then
                print_status "Updating domain configuration..."
                sed -i "s/site1.localhost/$SITE_NAME/g" frappe-compose.yml
                print_status "Domain configuration updated"
            fi
        else
            print_status "Domain configuration looks correct"
        fi
    else
        print_warning "frappe-compose.yml not found, skipping domain check"
    fi
    
    # Step 10: Start containers and install HRMS
    print_header "Step 10: Starting Containers and Installing HRMS"
    
    print_status "Starting Docker containers..."
    docker compose -p frappe down 2>/dev/null || true
    docker compose -p frappe -f frappe-compose.yml up -d
    
    # Wait for containers to be ready
    print_status "Waiting for containers to be ready..."
    sleep 30
    
    # Install HRMS app
    print_status "Installing HRMS app..."
    docker exec -it frappe-backend-1 bash -c "bench --site $SITE_NAME install-app hrms"
    
    # Final status check
    print_header "Installation Complete!"
    
    print_status "ERPNext 15 with HRMS has been installed successfully!"
    echo ""
    echo -e "${GREEN}Access your ERPNext installation at:${NC}"
    echo -e "${CYAN}  http://$SITE_NAME${NC}"
    echo ""
    echo -e "${GREEN}Admin Credentials:${NC}"
    echo -e "${CYAN}  Email: $ADMIN_EMAIL${NC}"
    echo -e "${CYAN}  Password: Check the installation output above${NC}"
    echo ""
    print_status "Useful commands:"
    echo "  View logs: docker compose -p frappe logs -f"
    echo "  Stop containers: docker compose -p frappe down"
    echo "  Start containers: docker compose -p frappe -f frappe-compose.yml up -d"
    echo "  Access backend: docker exec -it frappe-backend-1 bash"
    echo ""
    
    # Clean up
    if [ -f ~/.locus_installer_state ]; then
        rm ~/.locus_installer_state
    fi
    
    print_status "Installation completed successfully!"
}

# Handle script arguments
case "${1:-}" in
    --continue)
        if [ -f ~/.locus_installer_state ]; then
            source ~/.locus_installer_state
            print_status "Continuing installation from previous state..."
            continue_installation
        else
            print_error "No previous installation state found"
            exit 1
        fi
        ;;
    --help|-h)
        echo "Locus ERPNext Installer"
        echo ""
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --continue    Continue installation after reboot"
        echo "  --help, -h    Show this help message"
        echo ""
        echo "Run without arguments to start fresh installation"
        exit 0
        ;;
    "")
        main
        ;;
    *)
        print_error "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac
