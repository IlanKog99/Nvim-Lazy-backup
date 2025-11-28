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

# Function to check Neovim version
check_neovim_version() {
    local min_version="0.11.2"
    local nvim_cmd="${1:-nvim}"
    
    if ! command_exists "$nvim_cmd"; then
        return 1
    fi
    
    # Get version string (first line of nvim --version)
    local version_line
    version_line=$("$nvim_cmd" --version 2>/dev/null | head -n 1)
    
    if [ -z "$version_line" ]; then
        return 1
    fi
    
    # Extract version number (e.g., "NVIM v0.11.2" -> "0.11.2")
    local version
    version=$(echo "$version_line" | grep -oE 'v?[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 | sed 's/^v//')
    
    if [ -z "$version" ]; then
        return 1
    fi
    
    # Compare versions using sort -V (version sort)
    local min_version_padded
    local version_padded
    
    # Use printf to ensure consistent version format for comparison
    local version_major version_minor version_patch
    local min_major min_minor min_patch
    
    version_major=$(echo "$version" | cut -d. -f1)
    version_minor=$(echo "$version" | cut -d. -f2)
    version_patch=$(echo "$version" | cut -d. -f3)
    
    min_major=$(echo "$min_version" | cut -d. -f1)
    min_minor=$(echo "$min_version" | cut -d. -f2)
    min_patch=$(echo "$min_version" | cut -d. -f3)
    
    # Compare version components
    if [ "$version_major" -gt "$min_major" ]; then
        return 0
    elif [ "$version_major" -eq "$min_major" ]; then
        if [ "$version_minor" -gt "$min_minor" ]; then
            return 0
        elif [ "$version_minor" -eq "$min_minor" ]; then
            if [ "$version_patch" -ge "$min_patch" ]; then
                return 0
            fi
        fi
    fi
    
    return 1
}

# Function to get installed Neovim version string
get_neovim_version() {
    local nvim_cmd="${1:-nvim}"
    
    if ! command_exists "$nvim_cmd"; then
        echo "not installed"
        return
    fi
    
    local version_line
    version_line=$("$nvim_cmd" --version 2>/dev/null | head -n 1)
    
    if [ -z "$version_line" ]; then
        echo "unknown"
        return
    fi
    
    # Extract version number
    local version
    version=$(echo "$version_line" | grep -oE 'v?[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 | sed 's/^v//')
    
    if [ -z "$version" ]; then
        echo "unknown"
    else
        echo "$version"
    fi
}

# Function to install Neovim AppImage
install_neovim_appimage() {
    print_status "Installing Neovim AppImage (latest stable release)..."
    
    # Determine install location
    local install_dir
    local nvim_path
    
    if [ "$EUID" -eq 0 ]; then
        install_dir="/usr/local/bin"
        nvim_path="$install_dir/nvim"
    else
        install_dir="$HOME/.local/bin"
        nvim_path="$install_dir/nvim"
        mkdir -p "$install_dir"
    fi
    
    # Ensure install directory is in PATH
    if [ "$EUID" -ne 0 ]; then
        if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
            print_warning "~/.local/bin is not in PATH. Adding to ~/.bashrc and ~/.zshrc..."
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc" 2>/dev/null || true
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc" 2>/dev/null || true
            export PATH="$HOME/.local/bin:$PATH"
        fi
    fi
    
    # Create temporary directory for download
    local temp_dir
    temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT
    
    # Download latest stable AppImage
    print_status "Downloading latest Neovim AppImage from GitHub..."
    local download_url="https://github.com/neovim/neovim/releases/latest/download/nvim.appimage"
    local appimage_path="$temp_dir/nvim.appimage"
    
    if ! curl -L -o "$appimage_path" "$download_url" 2>/dev/null; then
        print_error "Failed to download Neovim AppImage"
        print_error "Please check your internet connection and try again"
        return 1
    fi
    
    # Make AppImage executable
    chmod +x "$appimage_path"
    
    # Move to install location
    if [ -f "$nvim_path" ]; then
        print_status "Removing existing Neovim installation at $nvim_path"
        rm -f "$nvim_path"
    fi
    
    mv "$appimage_path" "$nvim_path"
    
    # Verify installation
    if [ -f "$nvim_path" ] && [ -x "$nvim_path" ]; then
        print_success "Neovim AppImage installed successfully at $nvim_path"
        
        # Test version
        local installed_version
        installed_version=$(get_neovim_version "$nvim_path")
        print_status "Installed Neovim version: $installed_version"
        
        return 0
    else
        print_error "Failed to install Neovim AppImage"
        return 1
    fi
}

# Function to install packages based on distro
install_packages() {
    print_status "Detecting package manager and installing dependencies..."
    print_status "LazyVim requires Neovim >= 0.11.2"
    
    if command_exists apt; then
        # Debian/Ubuntu - Use Neovim PPA for latest stable version
        print_status "Using apt package manager (Debian/Ubuntu)"
        print_status "Setting up Neovim PPA for latest stable version..."
        
        # Check if add-apt-repository exists
        if ! command_exists add-apt-repository; then
            print_status "Installing software-properties-common for add-apt-repository..."
            sudo apt update
            sudo apt install -y software-properties-common
        fi
        
        # Add Neovim PPA
        if ! sudo add-apt-repository -y ppa:neovim-ppa/stable 2>/dev/null; then
            print_warning "Failed to add Neovim PPA using add-apt-repository"
            if command_exists lsb_release; then
                print_warning "Trying alternative PPA setup method..."
                # Alternative: try to add PPA manually
                echo "deb https://ppa.launchpadcontent.net/neovim-ppa/stable/ubuntu $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/neovim-ppa-stable.list >/dev/null
                sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 9DBB0BE9366964F134855E2255F96FCF8231B6DD 2>/dev/null || true
            else
                print_warning "lsb_release not available, will check version after installation and use AppImage if needed"
            fi
        fi
        
        sudo apt update
        sudo apt install -y neovim
        
        # Verify version
        if check_neovim_version nvim; then
            local installed_version
            installed_version=$(get_neovim_version nvim)
            print_success "Neovim installed successfully (version $installed_version)"
        else
            print_warning "Installed Neovim version may be insufficient, falling back to AppImage..."
            install_neovim_appimage
        fi
        
    elif command_exists yum; then
        # RHEL/CentOS/Fedora
        print_status "Using yum package manager (RHEL/CentOS/Fedora)"
        sudo yum update -y
        sudo yum install -y neovim
        
        # Check if version is sufficient
        if check_neovim_version nvim; then
            local installed_version
            installed_version=$(get_neovim_version nvim)
            print_success "Neovim installed successfully (version $installed_version)"
        else
            print_warning "Repository version is insufficient, installing AppImage..."
            install_neovim_appimage
        fi
        
    elif command_exists dnf; then
        # Fedora
        print_status "Using dnf package manager (Fedora)"
        sudo dnf update -y
        sudo dnf install -y neovim
        
        # Check if version is sufficient
        if check_neovim_version nvim; then
            local installed_version
            installed_version=$(get_neovim_version nvim)
            print_success "Neovim installed successfully (version $installed_version)"
        else
            print_warning "Repository version is insufficient, installing AppImage..."
            install_neovim_appimage
        fi
        
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
        
        # Check if version is sufficient (Arch usually has latest)
        if check_neovim_version nvim; then
            local installed_version
            installed_version=$(get_neovim_version nvim)
            print_success "Neovim installed successfully (version $installed_version)"
        else
            print_warning "Repository version is insufficient, installing AppImage..."
            install_neovim_appimage
        fi
        
    elif command_exists zypper; then
        # openSUSE
        print_status "Using zypper package manager (openSUSE)"
        print_status "Checking repository version first..."
        
        sudo zypper refresh
        sudo zypper install -y neovim
        
        # Check if version is sufficient
        if check_neovim_version nvim; then
            local installed_version
            installed_version=$(get_neovim_version nvim)
            print_success "Neovim installed successfully (version $installed_version)"
        else
            print_warning "Repository version is insufficient, installing AppImage..."
            install_neovim_appimage
        fi
        
    else
        # Unsupported package manager - use AppImage
        print_warning "Unsupported package manager detected. Installing Neovim AppImage..."
        install_neovim_appimage
    fi
}

# Function to install LazyVim
install_lazyvim() {
    print_status "Installing LazyVim..."
    
    local nvim_config="$HOME/.config/nvim"
    
    # Backup existing nvim config if it exists
    if [ -d "$nvim_config" ]; then
        if [ -f "$nvim_config/init.lua" ] || [ -f "$nvim_config/init.vim" ]; then
            print_warning "Existing Neovim configuration found at ~/.config/nvim"
            local backup_dir="${nvim_config}.bak.$(date +%Y%m%d_%H%M%S)"
            print_status "Backing up existing configuration to ${backup_dir}"
            mv "$nvim_config" "$backup_dir" || {
                print_error "Failed to backup existing configuration"
                exit 1
            }
            print_success "Backup created: ${backup_dir}"
        else
            # Directory exists but no config files, remove it
            print_status "Removing empty nvim directory"
            rm -rf "$nvim_config"
        fi
    fi
    
    # Clone LazyVim starter repository
    print_status "Cloning LazyVim starter repository..."
    if git clone --depth=1 https://github.com/LazyVim/starter.git "$nvim_config"; then
        print_success "LazyVim starter repository cloned successfully"
    else
        print_error "Failed to clone LazyVim starter repository"
        print_error "Please check your internet connection and try again"
        exit 1
    fi
    
    # Remove .git directory to prevent conflicts
    if [ -d "$nvim_config/.git" ]; then
        print_status "Removing .git directory to prevent version control conflicts"
        rm -rf "$nvim_config/.git"
    fi
    
    print_success "LazyVim installed successfully"
}

# Function to create necessary directories
create_directories() {
    print_status "Creating necessary directories..."
    
    # Only create directories that won't conflict with LazyVim installation
    # Don't create ~/.config/nvim/lua/config here as it will be created by LazyVim
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
        # Ensure the target directory exists (LazyVim should have created it, but be safe)
        mkdir -p "$HOME/.config/nvim/lua/config"
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
    
    # Verify Neovim version after installation
    print_status "Verifying Neovim installation..."
    local nvim_cmd="nvim"
    
    # Check if nvim is in PATH (might be in ~/.local/bin)
    if [ "$EUID" -ne 0 ] && [ -f "$HOME/.local/bin/nvim" ]; then
        nvim_cmd="$HOME/.local/bin/nvim"
        # Ensure it's in PATH for verification
        export PATH="$HOME/.local/bin:$PATH"
    fi
    
    if ! check_neovim_version "$nvim_cmd"; then
        local installed_version
        installed_version=$(get_neovim_version "$nvim_cmd")
        print_error "Neovim version check failed!"
        print_error "Installed version: $installed_version"
        print_error "Required version: >= 0.11.2"
        print_error "LazyVim requires Neovim >= 0.11.2"
        print_error "Please install a newer version of Neovim manually"
        exit 1
    fi
    
    local installed_version
    installed_version=$(get_neovim_version "$nvim_cmd")
    print_success "Neovim version verified: $installed_version (>= 0.11.2)"
    
    install_lazyvim
    copy_keymaps
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}    Installation Complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${BLUE}Installed Neovim version:${NC} $installed_version"
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

