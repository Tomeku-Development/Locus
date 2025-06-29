#!/bin/bash

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                              ║
# ║    ██╗      ██████╗  ██████╗██╗   ██╗███████╗                               ║
# ║    ██║     ██╔═══██╗██╔════╝██║   ██║██╔════╝                               ║
# ║    ██║     ██║   ██║██║     ██║   ██║███████╗                               ║
# ║    ██║     ██║   ██║██║     ██║   ██║╚════██║                               ║
# ║    ███████╗╚██████╔╝╚██████╗╚██████╔╝███████║                               ║
# ║    ╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝ ╚══════╝                               ║
# ║                                                                              ║
# ║                    ERPNext 15 Professional Installer                        ║
# ║                         Powered by Tomeku.com                               ║
# ║                                                                              ║
# ║    Version: 1.0.0                    Compatible: Ubuntu 20/22/23            ║
# ║    License: MIT                       Support: support@tomeku.com           ║
# ║                                                                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -e  # Exit on any error

# Color palette for professional appearance
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly GRAY='\033[0;90m'
readonly NC='\033[0m' # No Color

# Professional branding
readonly BRAND_COLOR='\033[1;36m'  # Cyan for Tomeku branding
readonly SUCCESS_COLOR='\033[1;32m'
readonly ERROR_COLOR='\033[1;31m'
readonly WARNING_COLOR='\033[1;33m'
readonly INFO_COLOR='\033[1;34m'

# Configuration variables
ERPNEXT_USER="erpnext"
SITE_NAME="localhost"
MYSQL_ROOT_PASSWORD=""
ERPNEXT_USER_PASSWORD=""
INSTALL_LOCATION="/opt/bench"
INSTALLER_VERSION="1.0.0"
COMPANY_NAME="Tomeku.com"
PROJECT_NAME="Locus"

# Professional output functions
print_logo() {
    clear
    echo -e "${BRAND_COLOR}"
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                              ║"
    echo "║    ██╗      ██████╗  ██████╗██╗   ██╗███████╗                               ║"
    echo "║    ██║     ██╔═══██╗██╔════╝██║   ██║██╔════╝                               ║"
    echo "║    ██║     ██║   ██║██║     ██║   ██║███████╗                               ║"
    echo "║    ██║     ██║   ██║██║     ██║   ██║╚════██║                               ║"
    echo "║    ███████╗╚██████╔╝╚██████╗╚██████╔╝███████║                               ║"
    echo "║    ╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝ ╚══════╝                               ║"
    echo "║                                                                              ║"
    echo "║                    ERPNext 15 Professional Installer                        ║"
    echo "║                         Powered by Tomeku.com                               ║"
    echo "║                                                                              ║"
    echo "║    Version: $INSTALLER_VERSION                    Compatible: Ubuntu 20/22/23            ║"
    echo "║    License: MIT                       Support: support@tomeku.com           ║"
    echo "║                                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo
}

print_status() {
    echo -e "${SUCCESS_COLOR}✓${NC} ${WHITE}$1${NC}"
}

print_warning() {
    echo -e "${WARNING_COLOR}⚠${NC} ${YELLOW}$1${NC}"
}

print_error() {
    echo -e "${ERROR_COLOR}✗${NC} ${RED}$1${NC}"
}

print_info() {
    echo -e "${INFO_COLOR}ℹ${NC} ${CYAN}$1${NC}"
}

print_step() {
    echo -e "${PURPLE}▶${NC} ${WHITE}$1${NC}"
}

print_header() {
    echo
    echo -e "${BRAND_COLOR}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BRAND_COLOR}║${NC} ${WHITE}$1${NC} ${BRAND_COLOR}║${NC}"
    echo -e "${BRAND_COLOR}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo
}

print_separator() {
    echo -e "${GRAY}─────────────────────────────────────────────────────────────────${NC}"
}

print_progress() {
    local current=$1
    local total=$2
    local step_name=$3
    local percentage=$((current * 100 / total))
    local filled=$((percentage / 5))
    local empty=$((20 - filled))
    
    printf "\r${BRAND_COLOR}Progress: [${NC}"
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "${BRAND_COLOR}] ${WHITE}%3d%% ${NC}${CYAN}%s${NC}" "$percentage" "$step_name"
    
    if [ $current -eq $total ]; then
        echo
    fi
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_logo
        print_error "This installer must be run with root privileges"
        print_info "Please run: ${WHITE}sudo bash $0${NC}"
        exit 1
    fi
}

# Function to check system requirements
check_system_requirements() {
    print_step "Checking system requirements..."
    
    # Check Ubuntu version
    if ! grep -q "Ubuntu" /etc/os-release; then
        print_error "This installer is designed for Ubuntu Server"
        exit 1
    fi
    
    # Check available disk space (minimum 10GB)
    available_space=$(df / | awk 'NR==2 {print $4}')
    if [ $available_space -lt 10485760 ]; then
        print_warning "Less than 10GB free space available"
        read -p "Continue anyway? (y/N): " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # Check RAM (minimum 2GB recommended)
    total_ram=$(free -m | awk 'NR==2 {print $2}')
    if [ $total_ram -lt 2048 ]; then
        print_warning "Less than 2GB RAM detected. ERPNext may run slowly."
    fi
    
    print_status "System requirements check completed"
}

# Function to get user input with professional styling
get_user_input() {
    print_logo
    print_header "INSTALLATION CONFIGURATION"
    
    echo -e "${WHITE}Welcome to the ${BRAND_COLOR}Locus${NC} ${WHITE}ERPNext 15 Professional Installer${NC}"
    echo -e "${GRAY}This installer will set up a complete ERPNext environment on your server.${NC}"
    echo
    print_separator
    echo
    
    # ERPNext User Configuration
    print_info "Configure ERPNext System User"
    echo -e "${GRAY}This user will own the ERPNext installation and processes.${NC}"
    read -p "$(echo -e ${CYAN}Enter ERPNext username ${GRAY}[default: erpnext]${NC}: )" input_user
    ERPNEXT_USER=${input_user:-$ERPNEXT_USER}
    
    echo
    # Site Configuration
    print_info "Configure ERPNext Site"
    echo -e "${GRAY}This will be your ERPNext site domain/hostname.${NC}"
    read -p "$(echo -e ${CYAN}Enter site name ${GRAY}[default: localhost]${NC}: )" input_site
    SITE_NAME=${input_site:-$SITE_NAME}
    
    echo
    # Database Configuration
    print_info "Configure Database Security"
    while [[ -z "$MYSQL_ROOT_PASSWORD" ]]; do
        echo -e "${GRAY}Set a strong password for MySQL root user (required for security).${NC}"
        read -s -p "$(echo -e ${CYAN}Enter MySQL root password${NC}: )" MYSQL_ROOT_PASSWORD
        echo
        if [[ -z "$MYSQL_ROOT_PASSWORD" ]]; then
            print_warning "MySQL root password cannot be empty"
        elif [[ ${#MYSQL_ROOT_PASSWORD} -lt 8 ]]; then
            print_warning "Password should be at least 8 characters long"
            MYSQL_ROOT_PASSWORD=""
        fi
    done
    
    echo
    # ERPNext User Password
    while [[ -z "$ERPNEXT_USER_PASSWORD" ]]; do
        echo -e "${GRAY}Set password for the ERPNext system user.${NC}"
        read -s -p "$(echo -e ${CYAN}Enter password for user ${WHITE}$ERPNEXT_USER${NC}: )" ERPNEXT_USER_PASSWORD
        echo
        if [[ -z "$ERPNEXT_USER_PASSWORD" ]]; then
            print_warning "ERPNext user password cannot be empty"
        elif [[ ${#ERPNEXT_USER_PASSWORD} -lt 6 ]]; then
            print_warning "Password should be at least 6 characters long"
            ERPNEXT_USER_PASSWORD=""
        fi
    done
    
    echo
    print_separator
    echo
    print_info "Installation Summary"
    echo -e "${WHITE}ERPNext User:${NC} ${GREEN}$ERPNEXT_USER${NC}"
    echo -e "${WHITE}Site Name:${NC} ${GREEN}$SITE_NAME${NC}"
    echo -e "${WHITE}Install Location:${NC} ${GREEN}$INSTALL_LOCATION${NC}"
    echo -e "${WHITE}Project:${NC} ${BRAND_COLOR}$PROJECT_NAME${NC} ${WHITE}by${NC} ${BRAND_COLOR}$COMPANY_NAME${NC}"
    echo
    print_separator
    echo
    
    read -p "$(echo -e ${SUCCESS_COLOR}Proceed with installation? ${GRAY}[y/N]${NC}: )" confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        print_info "Installation cancelled by user"
        exit 0
    fi
    
    print_status "Configuration completed. Starting installation..."
    sleep 2
}

# Function to update system
update_system() {
    print_header "SYSTEM UPDATE"
    print_step "Updating package database and system packages..."
    
    apt-get update >/dev/null 2>&1 &
    local pid=$!
    
    # Show spinner while updating
    local spinner='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while kill -0 $pid 2>/dev/null; do
        for i in $(seq 0 9); do
            printf "\r${BRAND_COLOR}${spinner:$i:1}${NC} Updating package database..."
            sleep 0.1
        done
    done
    
    printf "\r${SUCCESS_COLOR}✓${NC} Package database updated                    \n"
    
    apt-get upgrade -y >/dev/null 2>&1
    print_status "System packages updated successfully"
    
    print_progress 1 12 "System Update Complete"
    sleep 1
}

# Function to install Python and dependencies
install_python() {
    print_header "PYTHON ENVIRONMENT SETUP"
    print_step "Installing Python 3.11 and development tools..."
    
    apt-get install -y python3-dev python3.11-dev python3-setuptools python3-pip python3-distutils \
        software-properties-common xvfb libfontconfig wkhtmltopdf libmysqlclient-dev python3.11-venv \
        python-is-python3 >/dev/null 2>&1
    
    # Verify Python installation
    python_version=$(python3 -V 2>&1)
    print_status "Python environment configured: ${GREEN}$python_version${NC}"
    
    print_progress 2 12 "Python Installation Complete"
    sleep 1
}

# Function to install Node.js
install_nodejs() {
    print_header "NODE.JS RUNTIME SETUP"
    print_step "Installing Node.js 20.x LTS..."
    
    apt-get update >/dev/null 2>&1 && apt-get install -y ca-certificates curl gnupg >/dev/null 2>&1
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg 2>/dev/null
    NODE_MAJOR=20
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list >/dev/null
    apt-get update >/dev/null 2>&1 && apt-get install -y nodejs >/dev/null 2>&1
    
    node_version=$(node --version 2>&1)
    print_status "Node.js runtime installed: ${GREEN}$node_version${NC}"
    
    print_progress 3 12 "Node.js Installation Complete"
    sleep 1
}

# Function to install Redis
install_redis() {
    print_header "REDIS CACHE SERVER SETUP"
    print_step "Installing and configuring Redis server..."
    
    apt-get install -y redis-server >/dev/null 2>&1
    systemctl enable redis-server >/dev/null 2>&1
    systemctl start redis-server >/dev/null 2>&1
    
    # Test Redis connection
    if redis-cli ping >/dev/null 2>&1; then
        print_status "Redis server installed and running"
    else
        print_warning "Redis server installed but may not be running properly"
    fi
    
    print_progress 4 12 "Redis Installation Complete"
    sleep 1
}

# Function to install Git and Cron
install_git_cron() {
    print_header "DEVELOPMENT TOOLS SETUP"
    print_step "Installing Git version control and Cron scheduler..."
    
    apt-get install -y cron git >/dev/null 2>&1
    systemctl enable cron >/dev/null 2>&1
    systemctl start cron >/dev/null 2>&1
    
    git_version=$(git --version 2>&1)
    print_status "Development tools installed: ${GREEN}$git_version${NC}"
    
    print_progress 5 12 "Development Tools Complete"
    sleep 1
}

# Function to install NPM packages
install_npm_packages() {
    print_header "PACKAGE MANAGERS SETUP"
    print_step "Installing NPM and Yarn package managers..."
    
    npm install -g yarn >/dev/null 2>&1
    
    npm_version=$(npm --version 2>&1)
    yarn_version=$(yarn --version 2>&1)
    print_status "Package managers installed - NPM: ${GREEN}$npm_version${NC}, Yarn: ${GREEN}$yarn_version${NC}"
    
    print_progress 6 12 "Package Managers Complete"
    sleep 1
}

# Function to install MariaDB
install_mariadb() {
    print_header "MARIADB DATABASE SETUP"
    print_step "Installing MariaDB server and client..."
    
    apt-get install -y mariadb-server mariadb-client >/dev/null 2>&1
    systemctl enable mariadb >/dev/null 2>&1
    systemctl start mariadb >/dev/null 2>&1
    
    print_step "Securing MariaDB installation..."
    
    # Set root password non-interactively
    mysql -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$MYSQL_ROOT_PASSWORD');" 2>/dev/null
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "DELETE FROM mysql.user WHERE User='';" 2>/dev/null
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');" 2>/dev/null
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "DROP DATABASE IF EXISTS test;" 2>/dev/null
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';" 2>/dev/null
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;" 2>/dev/null
    
    print_step "Optimizing MariaDB for ERPNext..."
    cat > /etc/mysql/mariadb.conf.d/99-erpnext.cnf << EOF
[mysqld]
innodb-file-format=barracuda
innodb-file-per-table=1
innodb-large-prefix=1
character-set-client-handshake = FALSE
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

[mysql]
default-character-set = utf8mb4
EOF
    
    systemctl restart mariadb >/dev/null 2>&1
    print_status "MariaDB database server configured and secured"
    
    print_progress 7 12 "Database Setup Complete"
    sleep 1
}

# Function to create ERPNext user
create_erpnext_user() {
    print_header "USER ACCOUNT SETUP"
    print_step "Creating dedicated ERPNext system user..."
    
    # Create user if doesn't exist
    if ! id "$ERPNEXT_USER" &>/dev/null; then
        useradd -m -s /bin/bash "$ERPNEXT_USER" >/dev/null 2>&1
        echo "$ERPNEXT_USER:$ERPNEXT_USER_PASSWORD" | chpasswd >/dev/null 2>&1
        usermod -aG sudo "$ERPNEXT_USER" >/dev/null 2>&1
        print_status "System user ${GREEN}$ERPNEXT_USER${NC} created with sudo privileges"
    else
        print_status "System user ${GREEN}$ERPNEXT_USER${NC} already exists"
    fi
    
    # Configure user environment
    echo 'PATH=$PATH:~/.local/bin/' >> /home/$ERPNEXT_USER/.bashrc
    
    # Create and configure bench directory
    mkdir -p $INSTALL_LOCATION >/dev/null 2>&1
    chown -R $ERPNEXT_USER:$ERPNEXT_USER $INSTALL_LOCATION >/dev/null 2>&1
    print_status "Installation directory prepared at ${GREEN}$INSTALL_LOCATION${NC}"
    
    print_progress 8 12 "User Setup Complete"
    sleep 1
}

# Function to install node-sass and frappe-bench
install_frappe_bench() {
    print_header "FRAPPE FRAMEWORK SETUP"
    print_step "Installing Frappe development framework..."
    
    # Remove EXTERNALLY-MANAGED file if it exists
    if [ -f "/usr/lib/python3.11/EXTERNALLY-MANAGED" ]; then
        rm -f /usr/lib/python3.11/EXTERNALLY-MANAGED >/dev/null 2>&1
        print_info "Python environment restrictions removed"
    fi
    
    # Install node-sass
    cd $INSTALL_LOCATION
    print_step "Installing CSS preprocessor (node-sass)..."
    sudo -u $ERPNEXT_USER yarn add node-sass >/dev/null 2>&1
    
    # Install frappe-bench
    print_step "Installing Frappe Bench management tool..."
    sudo -u $ERPNEXT_USER pip3 install frappe-bench >/dev/null 2>&1
    
    # Install honcho process manager
    print_step "Installing process management tools..."
    sudo -u $ERPNEXT_USER pip3 install honcho >/dev/null 2>&1
    
    print_status "Frappe framework and tools installed successfully"
    
    print_progress 9 12 "Framework Setup Complete"
    sleep 1
}

# Function to initialize bench
initialize_bench() {
    print_header "FRAPPE BENCH INITIALIZATION"
    print_step "Initializing Frappe Bench environment..."
    
    cd $INSTALL_LOCATION
    sudo -u $ERPNEXT_USER bench init frappe-bench --frappe-branch version-15 >/dev/null 2>&1
    
    cd $INSTALL_LOCATION/frappe-bench
    sudo -u $ERPNEXT_USER sed -i '/web:/ s/$/ --noreload/' Procfile >/dev/null 2>&1
    
    print_status "Frappe Bench environment initialized for ERPNext v15"
    
    print_progress 10 12 "Bench Initialization Complete"
    sleep 1
}
        useradd -m -s /bin/bash "$ERPNEXT_USER"
        echo "$ERPNEXT_USER:$ERPNEXT_USER_PASSWORD" | chpasswd
        usermod -aG sudo "$ERPNEXT_USER"
        print_status "User $ERPNEXT_USER created and added to sudo group"
    else
        print_status "User $ERPNEXT_USER already exists"
    fi
    
    # Add PATH to .bashrc
    echo 'PATH=$PATH:~/.local/bin/' >> /home/$ERPNEXT_USER/.bashrc
    
    # Create bench directory
    mkdir -p $INSTALL_LOCATION
    chown -R $ERPNEXT_USER:$ERPNEXT_USER $INSTALL_LOCATION
    print_status "Bench directory created at $INSTALL_LOCATION"
}

# Function to install node-sass and frappe-bench
install_frappe_bench() {
    print_header "Installing Frappe Bench"
    
    # Remove EXTERNALLY-MANAGED file if it exists
    if [ -f "/usr/lib/python3.11/EXTERNALLY-MANAGED" ]; then
        rm -f /usr/lib/python3.11/EXTERNALLY-MANAGED
        print_status "Removed Python EXTERNALLY-MANAGED restriction"
    fi
    
    # Install node-sass
    cd $INSTALL_LOCATION
    sudo -u $ERPNEXT_USER yarn add node-sass
    
    # Install frappe-bench
    sudo -u $ERPNEXT_USER pip3 install frappe-bench
    
    # Install honcho
    sudo -u $ERPNEXT_USER pip3 install honcho
    
    print_status "Frappe Bench installed successfully"
}

# Function to initialize bench
initialize_bench() {
    print_header "Initializing Frappe Bench"
    
    cd $INSTALL_LOCATION
    sudo -u $ERPNEXT_USER bench init frappe-bench --frappe-branch version-15
    
    cd $INSTALL_LOCATION/frappe-bench
    sudo -u $ERPNEXT_USER sed -i '/web:/ s/$/ --noreload/' Procfile
    
    print_status "Frappe Bench initialized"
}

# Function to display professional completion message
display_completion() {
    clear
    print_logo
    
    echo -e "${SUCCESS_COLOR}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${SUCCESS_COLOR}║${NC}                   ${WHITE}INSTALLATION COMPLETED!${NC}                   ${SUCCESS_COLOR}║${NC}"
    echo -e "${SUCCESS_COLOR}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    # Get server IP
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    echo -e "${WHITE}🎉 Congratulations! ERPNext 15 has been successfully installed.${NC}"
    echo
    print_separator
    echo
    
    echo -e "${INFO_COLOR}📋 ACCESS INFORMATION${NC}"
    echo -e "${WHITE}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}│${NC} ${CYAN}Web Interface:${NC} ${SUCCESS_COLOR}http://$SERVER_IP:8000${NC} ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC} ${CYAN}Site Name:${NC}     ${WHITE}$SITE_NAME${NC} ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC} ${CYAN}Username:${NC}      ${WHITE}Administrator${NC} ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC} ${CYAN}Password:${NC}      ${WHITE}admin${NC} ${WHITE}│${NC}"
    echo -e "${WHITE}└─────────────────────────────────────────────────────────────┘${NC}"
    echo
    
    echo -e "${INFO_COLOR}⚙️ SYSTEM INFORMATION${NC}"
    echo -e "${WHITE}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}│${NC} ${CYAN}ERPNext User:${NC}  ${WHITE}$ERPNEXT_USER${NC} ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC} ${CYAN}Install Path:${NC}  ${WHITE}$INSTALL_LOCATION/frappe-bench${NC} ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC} ${CYAN}Service Name:${NC}  ${WHITE}erpnext${NC} ${WHITE}│${NC}"
    echo -e "${WHITE}│${NC} ${CYAN}Project:${NC}       ${BRAND_COLOR}$PROJECT_NAME${NC} ${WHITE}by${NC} ${BRAND_COLOR}$COMPANY_NAME${NC} ${WHITE}│${NC}"
    echo -e "${WHITE}└─────────────────────────────────────────────────────────────┘${NC}"
    echo
    
    echo -e "${INFO_COLOR}🔧 MANAGEMENT COMMANDS${NC}"
    echo -e "${GRAY}Service Management:${NC}"
    echo -e "  ${WHITE}Start Service:${NC}   ${YELLOW}sudo systemctl start erpnext${NC}"
    echo -e "  ${WHITE}Stop Service:${NC}    ${YELLOW}sudo systemctl stop erpnext${NC}"
    echo -e "  ${WHITE}Restart Service:${NC} ${YELLOW}sudo systemctl restart erpnext${NC}"
    echo -e "  ${WHITE}Check Status:${NC}    ${YELLOW}sudo systemctl status erpnext${NC}"
    echo
    echo -e "${GRAY}Log Management:${NC}"
    echo -e "  ${WHITE}View Logs:${NC}       ${YELLOW}sudo journalctl -u erpnext -f${NC}"
    echo -e "  ${WHITE}Error Logs:${NC}      ${YELLOW}sudo journalctl -u erpnext --since today${NC}"
    echo
    echo -e "${GRAY}Bench Commands (run as $ERPNEXT_USER):${NC}"
    echo -e "  ${WHITE}Switch User:${NC}     ${YELLOW}sudo su - $ERPNEXT_USER${NC}"
    echo -e "  ${WHITE}Bench Directory:${NC} ${YELLOW}cd $INSTALL_LOCATION/frappe-bench${NC}"
    echo -e "  ${WHITE}Update Apps:${NC}     ${YELLOW}bench update${NC}"
    echo -e "  ${WHITE}Backup Site:${NC}     ${YELLOW}bench backup${NC}"
    echo
    
    print_separator
    echo
    
    echo -e "${WARNING_COLOR}🔐 IMPORTANT SECURITY NOTES${NC}"
    echo -e "  ${RED}• Change the default Administrator password immediately${NC}"
    echo -e "  ${RED}• Configure SSL/HTTPS for production use${NC}"
    echo -e "  ${RED}• Review firewall settings for your environment${NC}"
    echo -e "  ${RED}• Set up regular automated backups${NC}"
    echo
    
    echo -e "${INFO_COLOR}📞 SUPPORT & RESOURCES${NC}"
    echo -e "  ${WHITE}Documentation:${NC} ${CYAN}https://docs.erpnext.com${NC}"
    echo -e "  ${WHITE}Community:${NC}     ${CYAN}https://discuss.frappe.io${NC}"
    echo -e "  ${WHITE}Professional Support:${NC} ${BRAND_COLOR}support@tomeku.com${NC}"
    echo -e "  ${WHITE}Project Repository:${NC} ${BRAND_COLOR}https://github.com/tomeku/${PROJECT_NAME,,}${NC}"
    echo
    
    print_separator
    echo
    
    echo -e "${BRAND_COLOR}Thank you for choosing ${WHITE}$PROJECT_NAME${NC} ${BRAND_COLOR}by ${WHITE}$COMPANY_NAME${NC}"
    echo -e "${GRAY}This installer was created with ❤️ to make ERPNext deployment simple and reliable.${NC}"
    echo
    
    # Final recommendations
    echo -e "${SUCCESS_COLOR}🚀 NEXT STEPS:${NC}"
    echo -e "  ${WHITE}1.${NC} Access ERPNext at ${SUCCESS_COLOR}http://$SERVER_IP:8000${NC}"
    echo -e "  ${WHITE}2.${NC} Login with ${WHITE}Administrator${NC} / ${WHITE}admin${NC}"
    echo -e "  ${WHITE}3.${NC} Complete the ERPNext setup wizard"
    echo -e "  ${WHITE}4.${NC} Change the default password"
    echo -e "  ${WHITE}5.${NC} Configure your company settings"
    echo
    
    read -p "$(echo -e ${SUCCESS_COLOR}Press Enter to complete the installation...${NC})"
}

# Main installation orchestrator
main() {
    # Initialize installation
    print_logo
    
    # Pre-flight checks
    check_root
    check_system_requirements
    
    # Get configuration from user
    get_user_input
    
    # Installation progress tracking
    local start_time=$(date +%s)
    
    print_header "INSTALLATION IN PROGRESS"
    print_info "Starting ERPNext 15 Professional Installation..."
    print_info "Estimated time: 15-20 minutes depending on internet speed"
    echo
    
    # Execute installation steps with progress tracking
    update_system
    install_python
    install_nodejs
    install_redis
    install_git_cron
    install_npm_packages
    install_mariadb
    create_erpnext_user
    install_frappe_bench
    initialize_bench
    setup_erpnext_site
    create_systemd_service
    
    # Post-installation configuration
    configure_firewall
    start_erpnext
    
    # Verification and testing
    run_post_install_tests
    
    # Calculate installation time
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    # Create installation log
    create_installation_log "$duration"
    
    # Display completion message
    display_completion
    
    print_info "Total installation time: ${SUCCESS_COLOR}${minutes}m ${seconds}s${NC}"
    print_status "Installation completed successfully!"
}

# Function to create installation log
create_installation_log() {
    local duration=$1
    local log_file="/var/log/locus-erpnext-install.log"
    
    cat > "$log_file" << EOF
================================================================================
LOCUS ERPNext 15 Installation Log
Powered by Tomeku.com
================================================================================

Installation Date: $(date)
Installation Duration: $duration seconds
Server IP: $(hostname -I | awk '{print $1}')
Hostname: $(hostname)
Ubuntu Version: $(lsb_release -d | cut -f2)

Configuration:
- ERPNext User: $ERPNEXT_USER
- Site Name: $SITE_NAME
- Install Location: $INSTALL_LOCATION
- Project: $PROJECT_NAME
- Company: $COMPANY_NAME

Access Information:
- URL: http://$(hostname -I | awk '{print $1}'):8000
- Username: Administrator
- Default Password: admin

System Services:
- ERPNext Service: erpnext
- Database: MariaDB
- Cache: Redis
- Web Server: Built-in (Port 8000)

Support:
- Documentation: https://docs.erpnext.com
- Professional Support: support@tomeku.com
- Project Repository: https://github.com/tomeku/${PROJECT_NAME,,}

================================================================================
Installation completed successfully!
================================================================================
EOF
    
    print_info "Installation log saved to: ${WHITE}$log_file${NC}"
}

# Error handling and cleanup
cleanup_on_error() {
    print_error "Installation failed. Performing cleanup..."
    
    # Stop services if they were started
    systemctl stop erpnext 2>/dev/null || true
    systemctl stop mariadb 2>/dev/null || true
    systemctl stop redis-server 2>/dev/null || true
    
    # Remove systemd service
    rm -f /etc/systemd/system/erpnext.service 2>/dev/null || true
    systemctl daemon-reload 2>/dev/null || true
    
    print_info "Cleanup completed. Check the error messages above for troubleshooting."
    print_info "For support, contact: ${BRAND_COLOR}support@tomeku.com${NC}"
    exit 1
}

# Set up error handling
trap cleanup_on_error ERR

# Script entry point validation
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being executed directly
    main "$@"
else
    # Script is being sourced
    print_error "This script should be executed directly, not sourced."
    exit 1
fi
