#!/bin/bash

# LazyVim Setup Script - Automated installation of your exact LazyVim configuration
# This script will install all dependencies and set up your LazyVim environment
#
# PREREQUISITES (must be installed before running this script):
#   - git (for cloning repositories and plugin management)
#   - curl (for downloading dependencies)
#   - sudo access (for installing system packages)
#
# All other dependencies (neovim) will be automatically installed by this script.

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install packages based on distro
install_packages() {
    print_status "Detecting package manager and installing dependencies..."
    
    if command_exists apt; then
        # Debian/Ubuntu
        print_status "Using apt package manager (Debian/Ubuntu)"
        sudo apt update
        sudo apt install -y neovim
    elif command_exists yum; then
        # RHEL/CentOS/Fedora
        print_status "Using yum package manager (RHEL/CentOS/Fedora)"
        sudo yum update -y
        sudo yum install -y neovim
    elif command_exists dnf; then
        # Fedora
        print_status "Using dnf package manager (Fedora)"
        sudo dnf update -y
        sudo dnf install -y neovim
    elif command_exists pacman; then
        # Arch Linux
        print_status "Using pacman package manager (Arch Linux)"
        sudo pacman -Syu --noconfirm neovim
    elif command_exists zypper; then
        # openSUSE
        print_status "Using zypper package manager (openSUSE)"
        sudo zypper refresh
        sudo zypper install -y neovim
    else
        print_error "Unsupported package manager. Please install neovim manually."
        exit 1
    fi
}

# Function to install LazyVim
install_lazyvim() {
    print_status "Installing LazyVim..."
    
    # Check if LazyVim is already installed
    if [ -d "$HOME/.config/nvim" ] && [ -f "$HOME/.config/nvim/init.lua" ]; then
        print_warning "LazyVim configuration already exists at ~/.config/nvim"
        print_warning "Backing up existing configuration to ~/.config/nvim.backup"
        if [ -d "$HOME/.config/nvim.backup" ]; then
            rm -rf "$HOME/.config/nvim.backup"
        fi
        mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup"
    fi
    
    # Install LazyVim using the official bootstrap script
    print_status "Running LazyVim bootstrap script..."
    bash <(curl -s https://raw.githubusercontent.com/LazyVim/LazyVim/main/scripts/install.sh)
    
    print_success "LazyVim installed successfully"
}

# Function to copy keymaps configuration
copy_keymaps() {
    print_status "Setting up custom keymaps configuration..."
    
    # Check if keymaps.lua exists in current directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    KEYMAPS_FILE="$SCRIPT_DIR/lua/config/keymaps.lua"
    
    if [ -f "$KEYMAPS_FILE" ]; then
        # Ensure the target directory exists (should already exist from LazyVim install)
        mkdir -p "$HOME/.config/nvim/lua/config"
        cp "$KEYMAPS_FILE" "$HOME/.config/nvim/lua/config/keymaps.lua"
        print_success "Custom keymaps copied from current directory"
    else
        print_error "No lua/config/keymaps.lua found in current directory!"
        print_error "Please ensure keymaps.lua is in the lua/config/ directory relative to this script."
        exit 1
    fi
}

# Function to create necessary directories
create_directories() {
    print_status "Creating necessary directories..."
    
    mkdir -p "$HOME/.cache"
    mkdir -p "$HOME/.local/share"
    mkdir -p "$HOME/.config"
    
    print_success "Directories created successfully"
}

# Main installation function
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}    LazyVim Setup Script - Automated Install${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        print_warning "Running as root user detected."
        print_warning "This is not recommended for regular desktop systems."
        print_warning "If this is a container or minimal system, you can continue."
        print_status "Press Ctrl+C to cancel, or Enter to continue..."
        read -r
    fi
    
    # Check for required commands
    if ! command_exists git; then
        print_error "Git is required but not installed. Please install git first."
        exit 1
    fi
    
    if ! command_exists curl; then
        print_error "curl is required but not installed. Please install curl first."
        exit 1
    fi
    
    # Check if Neovim is already installed
    if command_exists nvim; then
        print_warning "Neovim is already installed"
        read -p "Do you want to reinstall Neovim? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_packages
        fi
    else
        install_packages
    fi
    
    # Start installation
    create_directories
    install_lazyvim
    copy_keymaps
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}    Installation Complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Open Neovim with: nvim"
    echo "2. LazyVim will automatically install plugins on first launch"
    echo ""
    echo -e "${BLUE}Your LazyVim setup includes:${NC}"
    echo "• LazyVim distribution with all default plugins"
    echo "• Custom keybindings:"
    echo "  - Ctrl+E: Move to end of line"
    echo "  - Ctrl+A: Move to start of line"
    echo "  - Ctrl+Z: Undo"
    echo "  - Ctrl+Arrow: Navigate words"
    echo ""
    echo -e "${GREEN}Enjoy your new LazyVim setup!${NC}"
}

# Run main function
main "$@"

