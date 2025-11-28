#!/bin/bash

# LazyVim Setup Script - Automated installation of your exact LazyVim configuration
# This script will install all dependencies and set up your LazyVim environment
#
# PREREQUISITES (must be installed before running this script):
#   - git (for cloning repositories and plugin management)
#   - curl (for downloading Neovim binary from GitHub releases)
#   - tar (for extracting the Neovim binary tarball)
#   - sudo access (for installing to system directories when running as root)
#
# INSTALLATION METHOD:
#   This script downloads and installs the latest stable Neovim directly from
#   GitHub releases (binary tarball). This method is more reliable than using
#   package managers (which often have outdated versions) or AppImages (which
#   require FUSE).
#
# All other dependencies (neovim >= 0.11.2) will be automatically installed by this script.

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

# Function to check if Neovim command exists (handles both regular commands and AppImages)
nvim_command_exists() {
    local nvim_cmd="${1:-nvim}"
    
    # Check if it's a command in PATH
    if command_exists "$nvim_cmd"; then
        return 0
    fi
    
    # Check if it's an absolute path to an executable file
    if [ -f "$nvim_cmd" ] && [ -x "$nvim_cmd" ]; then
        return 0
    fi
    
    return 1
}

# Function to check Neovim version
check_neovim_version() {
    local min_version="0.11.2"
    local nvim_cmd="${1:-nvim}"
    
    if ! nvim_command_exists "$nvim_cmd"; then
        return 1
    fi
    
    # Get version string (first line of nvim --version)
    # Use absolute path if it's a file, otherwise use as-is
    # Capture both stdout and stderr, as some versions output to stderr
    local version_line
    if [ -f "$nvim_cmd" ] && [ -x "$nvim_cmd" ]; then
        # It's a file path, run it directly
        version_line=$("$nvim_cmd" --version 2>&1 | head -n 1)
    else
        # It's a command in PATH
        version_line=$("$nvim_cmd" --version 2>&1 | head -n 1)
    fi
    
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
    
    if ! nvim_command_exists "$nvim_cmd"; then
        echo "not installed"
        return
    fi
    
    local version_line
    # Use absolute path if it's a file, otherwise use as-is
    # Capture both stdout and stderr, as some versions output to stderr
    if [ -f "$nvim_cmd" ] && [ -x "$nvim_cmd" ]; then
        # It's a file path, run it directly
        version_line=$("$nvim_cmd" --version 2>&1 | head -n 1)
    else
        # It's a command in PATH
        version_line=$("$nvim_cmd" --version 2>&1 | head -n 1)
    fi
    
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

# Function to detect system architecture
detect_architecture() {
    local arch
    arch=$(uname -m 2>/dev/null || echo "unknown")
    
    case "$arch" in
        x86_64|amd64)
            echo "x86_64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        *)
            print_warning "Unknown architecture: $arch, defaulting to x86_64"
            echo "x86_64"
            ;;
    esac
}

# Function to install Neovim from GitHub releases binary tarball
install_neovim_binary() {
    print_status "Installing Neovim from GitHub releases (binary tarball)..."
    
    # Detect system architecture
    local arch
    arch=$(detect_architecture)
    print_status "Detected architecture: $arch"
    
    # Determine install location
    local install_dir
    local nvim_path
    
    if [ "$EUID" -eq 0 ]; then
        install_dir="/usr/local"
        nvim_path="/usr/local/bin/nvim"
    else
        install_dir="$HOME/.local"
        nvim_path="$HOME/.local/bin/nvim"
        mkdir -p "$HOME/.local/bin"
    fi
    
    # Ensure install directory is in PATH for non-root users
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
    
    # Set up cleanup trap to ensure temp directory is removed on exit
    trap "rm -rf '$temp_dir'" EXIT
    
    # Get latest release tag from GitHub API
    print_status "Getting latest Neovim release version from GitHub..."
    local latest_tag
    latest_tag=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest 2>/dev/null | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' || echo "")
    
    # Determine correct filename based on architecture
    local tarball_filename="nvim-linux-${arch}.tar.gz"
    local extracted_dirname="nvim-linux-${arch}"
    
    if [ -z "$latest_tag" ]; then
        print_warning "Failed to get latest release tag from GitHub API, trying direct download..."
        # Fallback: try the /latest/download/ pattern
        local download_url="https://github.com/neovim/neovim/releases/latest/download/${tarball_filename}"
    else
        print_status "Latest release: $latest_tag"
        # Construct download URL with version tag and correct architecture
        local download_url="https://github.com/neovim/neovim/releases/download/${latest_tag}/${tarball_filename}"
    fi
    
    local tarball_path="$temp_dir/${tarball_filename}"
    
    # Download with progress and error checking
    print_status "Downloading Neovim binary from: $download_url"
    if ! curl -L -f -o "$tarball_path" "$download_url" 2>&1; then
        print_error "Failed to download Neovim binary tarball"
        print_error "URL attempted: $download_url"
        print_error "Please check your internet connection and try again"
        # Check if file exists and show first few lines (might be an error page)
        if [ -f "$tarball_path" ]; then
            print_error "Downloaded file contents (first 200 chars):"
            head -c 200 "$tarball_path" 2>/dev/null | cat
            echo ""
        fi
        rm -rf "$temp_dir"
        trap - EXIT
        return 1
    fi
    
    # Check if file was downloaded and has reasonable size (at least 1MB)
    if [ ! -f "$tarball_path" ]; then
        print_error "Downloaded file not found"
        rm -rf "$temp_dir"
        return 1
    fi
    
    local file_size
    file_size=$(stat -c%s "$tarball_path" 2>/dev/null || stat -f%z "$tarball_path" 2>/dev/null || echo "0")
    if [ "$file_size" -lt 1048576 ]; then
        print_error "Downloaded file is too small (${file_size} bytes), may be an error page"
        print_error "File contents (first 500 chars):"
        head -c 500 "$tarball_path" 2>/dev/null | cat
        echo ""
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Verify the download is a valid tarball (check magic bytes or use file command)
    # Check for gzip magic bytes: 1f 8b
    local magic_bytes
    magic_bytes=$(head -c 2 "$tarball_path" | od -An -tx1 2>/dev/null | tr -d ' \n' || echo "")
    if [ "$magic_bytes" != "1f8b" ]; then
        # Try file command as fallback
        if command_exists file; then
            if ! file "$tarball_path" 2>/dev/null | grep -qE "(gzip|compressed)"; then
                print_error "Downloaded file is not a valid gzip archive"
                print_error "File type: $(file "$tarball_path" 2>/dev/null || echo 'unknown')"
                print_error "File contents (first 500 chars):"
                head -c 500 "$tarball_path" 2>/dev/null | cat
                echo ""
                rm -rf "$temp_dir"
                return 1
            fi
        else
            print_warning "Cannot verify file type (file command not available), proceeding anyway..."
        fi
    fi
    
    # Extract the tarball
    print_status "Extracting Neovim binary..."
    if ! tar -xzf "$tarball_path" -C "$temp_dir" 2>/dev/null; then
        print_error "Failed to extract Neovim tarball"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Find the extracted directory (should be nvim-linux-{arch})
    local extracted_dir="$temp_dir/${extracted_dirname}"
    if [ ! -d "$extracted_dir" ]; then
        print_error "Extracted directory not found: $extracted_dir"
        print_error "Expected directory name: $extracted_dirname"
        rm -rf "$temp_dir"
        trap - EXIT
        return 1
    fi
    
    # Remove existing Neovim installation if present
    if [ -f "$nvim_path" ]; then
        print_status "Removing existing Neovim installation at $nvim_path"
        rm -f "$nvim_path"
    fi
    
    # Remove any existing nvim-linux-{arch} directory in install location
    if [ -d "$install_dir/${extracted_dirname}" ]; then
        print_status "Removing existing ${extracted_dirname} directory..."
        rm -rf "$install_dir/${extracted_dirname}"
    fi
    
    # Move the extracted directory to install location
    print_status "Installing Neovim to $install_dir..."
    if ! mv "$extracted_dir" "$install_dir/" 2>/dev/null; then
        print_error "Failed to move Neovim directory to $install_dir"
        print_error "Please check permissions and disk space"
        # Clean up temp directory before returning
        rm -rf "$temp_dir"
        # Remove trap since we're cleaning up manually
        trap - EXIT
        return 1
    fi
    
    # Verify the move was successful
    if [ ! -d "$install_dir/${extracted_dirname}" ]; then
        print_error "Neovim directory not found at $install_dir/${extracted_dirname} after move"
        # Clean up temp directory before returning
        rm -rf "$temp_dir"
        # Remove trap since we're cleaning up manually
        trap - EXIT
        return 1
    fi
    
    # Create symlink to the binary
    if [ "$EUID" -eq 0 ]; then
        if ! ln -sf "$install_dir/${extracted_dirname}/bin/nvim" "$nvim_path" 2>/dev/null; then
            print_error "Failed to create symlink at $nvim_path"
            # Clean up installed directory and temp directory
            rm -rf "$install_dir/${extracted_dirname}"
            rm -rf "$temp_dir"
            trap - EXIT
            return 1
        fi
    else
        if ! ln -sf "$install_dir/${extracted_dirname}/bin/nvim" "$nvim_path" 2>/dev/null; then
            print_error "Failed to create symlink at $nvim_path"
            # Clean up installed directory and temp directory
            rm -rf "$install_dir/${extracted_dirname}"
            rm -rf "$temp_dir"
            trap - EXIT
            return 1
        fi
    fi
    
    # Clean up temp directory (trap will also handle this, but explicit cleanup is good)
    rm -rf "$temp_dir"
    # Remove trap since we've cleaned up successfully
    trap - EXIT
    
    # Verify installation
    if [ -L "$nvim_path" ] || [ -f "$nvim_path" ]; then
        if [ -x "$install_dir/${extracted_dirname}/bin/nvim" ]; then
            print_success "Neovim binary installed successfully at $nvim_path"
            
            # Test version
            local installed_version
            installed_version=$(get_neovim_version "$nvim_path")
            if [ "$installed_version" = "unknown" ] || [ "$installed_version" = "not installed" ]; then
                print_error "Failed to get Neovim version"
                print_error "The binary may not be working correctly"
                # Clean up installation since it's not working
                rm -f "$nvim_path"
                rm -rf "$install_dir/nvim-linux64"
                return 1
            fi
            print_status "Installed Neovim version: $installed_version"
            
            # Verify version meets requirements
            if check_neovim_version "$nvim_path"; then
                print_success "Neovim version $installed_version meets requirements (>= 0.11.2)"
                return 0
            else
                print_error "Installed version $installed_version does not meet requirements (>= 0.11.2)"
                # Clean up installation since version is insufficient
                rm -f "$nvim_path"
                rm -rf "$install_dir/${extracted_dirname}"
                return 1
            fi
        else
            print_error "Neovim binary is not executable"
            # Clean up installation since binary is not executable
            rm -f "$nvim_path"
            rm -rf "$install_dir/${extracted_dirname}"
            return 1
        fi
    else
        print_error "Failed to install Neovim binary (symlink not created)"
        # Clean up installation since symlink creation failed
        rm -rf "$install_dir/${extracted_dirname}"
        return 1
    fi
}

# Function to install Neovim
install_packages() {
    print_status "Installing Neovim from GitHub releases..."
    print_status "LazyVim requires Neovim >= 0.11.2"
    
    # Remove any existing Neovim installations from package managers
    print_status "Checking for existing Neovim installations..."
    
    if command_exists apt && (command_exists nvim || dpkg -l 2>/dev/null | grep -q "^ii.*neovim"); then
        print_status "Removing existing Neovim installation from apt..."
        sudo apt remove -y neovim 2>/dev/null || true
        sudo apt purge -y neovim 2>/dev/null || true
    elif command_exists yum && rpm -q neovim >/dev/null 2>&1; then
        print_status "Removing existing Neovim installation from yum..."
        sudo yum remove -y neovim 2>/dev/null || true
    elif command_exists dnf && rpm -q neovim >/dev/null 2>&1; then
        print_status "Removing existing Neovim installation from dnf..."
        sudo dnf remove -y neovim 2>/dev/null || true
    elif command_exists pacman && pacman -Q neovim >/dev/null 2>&1; then
        print_status "Removing existing Neovim installation from pacman..."
        sudo pacman -R --noconfirm neovim 2>/dev/null || true
    elif command_exists zypper && zypper se -i neovim >/dev/null 2>&1; then
        print_status "Removing existing Neovim installation from zypper..."
        sudo zypper remove -y neovim 2>/dev/null || true
    fi
    
    # Install Neovim from GitHub releases binary tarball
    if ! install_neovim_binary; then
        print_error "Failed to install Neovim from GitHub releases"
        print_error "Please try installing Neovim manually from: https://github.com/neovim/neovim/releases"
        exit 1
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
    
    if ! command_exists tar; then
        print_error "tar is required but not installed. Please install tar first."
        exit 1
    fi
    
    # Start installation
    create_directories
    install_packages
    
    # Verify Neovim version after installation
    print_status "Verifying Neovim installation..."
    local nvim_cmd=""
    
    # Find Neovim installation - check the symlink locations first
    if [ "$EUID" -eq 0 ]; then
        # Root: check /usr/local/bin first (symlink location)
        if [ -L "/usr/local/bin/nvim" ] || [ -f "/usr/local/bin/nvim" ]; then
            nvim_cmd="/usr/local/bin/nvim"
        elif command_exists nvim; then
            nvim_cmd="nvim"
        fi
    else
        # Non-root: check ~/.local/bin first (symlink location)
        if [ -L "$HOME/.local/bin/nvim" ] || [ -f "$HOME/.local/bin/nvim" ]; then
            nvim_cmd="$HOME/.local/bin/nvim"
            export PATH="$HOME/.local/bin:$PATH"
        elif [ -L "/usr/local/bin/nvim" ] || [ -f "/usr/local/bin/nvim" ]; then
            nvim_cmd="/usr/local/bin/nvim"
        elif command_exists nvim; then
            nvim_cmd="nvim"
        fi
    fi
    
    if [ -z "$nvim_cmd" ]; then
        print_error "Neovim not found after installation!"
        print_error "Please check the installation logs above"
        exit 1
    fi
    
    if ! check_neovim_version "$nvim_cmd"; then
        local installed_version
        installed_version=$(get_neovim_version "$nvim_cmd")
        print_error "Neovim version check failed!"
        print_error "Neovim location: $nvim_cmd"
        print_error "Installed version: $installed_version"
        print_error "Required version: >= 0.11.2"
        print_error "LazyVim requires Neovim >= 0.11.2"
        print_error "Please install a newer version of Neovim manually"
        exit 1
    fi
    
    local installed_version
    installed_version=$(get_neovim_version "$nvim_cmd")
    print_success "Neovim version verified: $installed_version (>= 0.11.2)"
    print_status "Neovim location: $nvim_cmd"
    
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

