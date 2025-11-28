#!/bin/bash

# LazyVim Setup Script - Automated installation of your exact LazyVim configuration
# This script will install all dependencies and set up your LazyVim environment
#
# PREREQUISITES (must be installed before running this script):
#   - git (for cloning repositories and plugin management)
#   - curl (for downloading LazyVim bootstrap script)
#   - sudo access (for installing system packages)
#
# IMPORTANT FOR ARCH LINUX USERS:
#   - This script does NOT perform a full system upgrade (pacman -Syu) to avoid
#     potential system bricking if interrupted or if disk space is insufficient.
#   - You should update your Arch system manually BEFORE running this script:
#     sudo pacman -Syu
#   - The script will check for sufficient disk space (2GB minimum) before
#     installing packages on Arch Linux.
#
# All other dependencies (neovim) will be automatically installed by this script.

set -e  # Exit on any error

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# Function to check available disk space
check_disk_space() {
    local required_gb=${1:-2}  # Default to 2GB if not specified
    local available_kb
    
    # Get available space in KB (works on Linux)
    # Use -k flag to force 1KB blocks, avoiding POSIXLY_CORRECT 512-byte block issue
    if command_exists df; then
        available_kb=$(df -k / | tail -1 | awk '{print $4}')
        if [ -z "$available_kb" ]; then
            print_warning "Could not determine available disk space, skipping check"
            return 0
        fi
        
        # Convert KB to GB (approximately)
        local available_gb=$((available_kb / 1024 / 1024))
        
        if [ "$available_gb" -lt "$required_gb" ]; then
            print_error "Insufficient disk space: ${available_gb}GB available, ${required_gb}GB required"
            print_error "Please free up disk space before continuing"
            return 1
        else
            print_status "Disk space check passed: ${available_gb}GB available"
            return 0
        fi
    else
        print_warning "df command not found, skipping disk space check"
        return 0
    fi
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
        # NOTE: We use -S (not -Syu) to avoid full system upgrade which can brick
        # the system if interrupted or if disk space is insufficient. Users should
        # update their system manually with 'sudo pacman -Syu' before running this script.
        print_status "Using pacman package manager (Arch Linux)"
        print_warning "For Arch Linux, ensure your system is up to date before running this script"
        print_warning "Run 'sudo pacman -Syu' manually if needed"
        
        # Check disk space before installing (critical for Arch)
        if ! check_disk_space 2; then
            print_error "Disk space check failed. Aborting package installation."
            exit 1
        fi
        
        sudo pacman -S --needed --noconfirm neovim
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
        print_warning "The installation script will handle this. Continuing..."
    fi
    
    # Install LazyVim using the official bootstrap script
    bash <(curl -s https://raw.githubusercontent.com/LazyVim/LazyVim/starter/scripts/install.sh)
    
    print_success "LazyVim installed successfully"
}

# Function to create necessary directories
create_directories() {
    print_status "Creating necessary directories..."
    
    mkdir -p "$HOME/.config/nvim/lua/config"
    mkdir -p "$HOME/.cache"
    mkdir -p "$HOME/.local/share"
    
    print_success "Directories created successfully"
}

# Function to copy keymaps configuration
copy_keymaps() {
    print_status "Setting up custom keymaps configuration..."
    
    KEYMAPS_FILE="$SCRIPT_DIR/lua/config/keymaps.lua"
    
    # Check if keymaps.lua exists relative to script location
    if [ -f "$KEYMAPS_FILE" ]; then
        cp "$KEYMAPS_FILE" "$HOME/.config/nvim/lua/config/keymaps.lua"
        print_success "keymaps.lua copied from script directory"
    else
        print_error "No lua/config/keymaps.lua found in script directory!"
        print_error "Please ensure lua/config/keymaps.lua is in the same directory as this script."
        print_error "Script directory: $SCRIPT_DIR"
        print_error "Expected file: $KEYMAPS_FILE"
        print_error "You can download it from: https://github.com/IlanKog99/Nvim-Lazy-backup"
        exit 1
    fi
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
    
    # Start installation
    create_directories
    install_packages
    install_lazyvim
    copy_keymaps
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}    Installation Complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Open Neovim: nvim"
    echo "2. LazyVim will automatically install all plugins on first launch"
    echo "3. Your custom keymaps are now configured"
    echo ""
    echo -e "${BLUE}Your LazyVim setup includes:${NC}"
    echo "• LazyVim distribution with sensible defaults"
    echo "• Lazy.nvim plugin manager"
    echo "• Telescope fuzzy finder"
    echo "• Treesitter syntax highlighting"
    echo "• LSP support with Mason"
    echo "• Custom keybindings (Ctrl+E/A/Z, Ctrl+Arrow keys)"
    echo "• Which-key keybinding helper"
    echo ""
    echo -e "${YELLOW}Custom Keybindings:${NC}"
    echo "• Ctrl+E - Move to end of line"
    echo "• Ctrl+A - Move to start of line"
    echo "• Ctrl+Z - Undo"
    echo "• Ctrl+Right/Left Arrow - Navigate words"
    echo ""
    echo -e "${YELLOW}Cleanup (optional):${NC}"
    echo "You can now delete the downloaded files:"
    echo "  rm -rf Nvim-Lazy-backup/"
    echo ""
    echo -e "${GREEN}Enjoy your new LazyVim setup!${NC}"
}

# Run main function
main "$@"

