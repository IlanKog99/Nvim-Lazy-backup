# LazyVim Configuration Setup

A complete, automated LazyVim configuration setup script that replicates your custom Neovim environment with LazyVim distribution and custom keybindings.

## 🚀 Features

- **LazyVim** - Modern Neovim distribution with sensible defaults
- **Custom Keybindings** - Productivity-focused keyboard shortcuts
- **Automated Installation** - One-command setup script
- **Multi-Distribution Support** - Works on Ubuntu, Debian, Fedora, Arch, and more

## 📦 What's Included

### Custom Keybindings

The configuration includes the following custom keybindings:

- **Ctrl+E** - Move to end of line (Normal and Insert mode)
- **Ctrl+A** - Move to start of line (Normal and Insert mode)
- **Ctrl+Z** - Undo (Normal, Visual, and Insert mode)
- **Ctrl+Right Arrow** - Move forward one word (Normal and Insert mode)
- **Ctrl+Left Arrow** - Move backward one word (Normal and Insert mode)

### LazyVim Defaults

LazyVim comes with many plugins pre-configured:
- **Lazy.nvim** - Fast plugin manager
- **Telescope** - Fuzzy finder
- **Treesitter** - Syntax highlighting
- **LSP** - Language Server Protocol support
- **Mason** - LSP/DAP/Linter/Formatter installer
- **Which-key** - Keybinding helper
- And many more...

## 🛠️ Installation

### Prerequisites

Before running the installation script, ensure you have the following installed on your system:

#### Required (Must Have)
- **Git** - For cloning the repository and plugin management
- **curl** - For downloading LazyVim bootstrap script
- **sudo access** - For installing system packages

#### Optional (Auto-installed if missing)
The script will automatically install these if not present:
- **neovim** - The Neovim editor itself

**Important**: The script assumes `git` and `curl` are already installed. If you don't have them, install them first:

```bash
# Ubuntu/Debian
sudo apt update && sudo apt install -y git curl

# Fedora
sudo dnf install -y git curl

# Arch Linux
sudo pacman -S git curl

# openSUSE
sudo zypper install -y git curl
```

### Quick Setup

#### One-liner Installation
```bash
git clone https://github.com/IlanKog99/Nvim-Lazy-backup.git && cd Nvim-Lazy-backup && chmod +x setup_lazyvim.sh && ./setup_lazyvim.sh && cd .. && rm -rf Nvim-Lazy-backup
```

#### Step-by-step Installation
1. Clone and enter the repository:
```bash
git clone https://github.com/IlanKog99/Nvim-Lazy-backup.git
cd Nvim-Lazy-backup
```

2. Run the setup script:
```bash
chmod +x setup_lazyvim.sh
./setup_lazyvim.sh
```

3. Clean up (optional):
```bash
cd ..
rm -rf Nvim-Lazy-backup
```

4. Open Neovim:
```bash
nvim
```

**Note**: The script will install LazyVim and copy your custom `keymaps.lua` file to `~/.config/nvim/lua/config/keymaps.lua`. LazyVim will automatically install all plugins on first launch.

### Manual Setup
If you prefer to set up manually:

1. Install Neovim:
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install -y neovim

# Fedora
sudo dnf install -y neovim

# Arch Linux
sudo pacman -S neovim
```

2. Install LazyVim:
```bash
# Backup existing config if needed (with timestamp to prevent overwriting)
if [ -d ~/.config/nvim ] && ([ -f ~/.config/nvim/init.lua ] || [ -f ~/.config/nvim/init.vim ]); then
  mv ~/.config/nvim ~/.config/nvim.bak.$(date +%Y%m%d_%H%M%S)
fi

# Clone LazyVim starter repository
git clone --depth=1 https://github.com/LazyVim/starter.git ~/.config/nvim

# Remove .git directory to prevent conflicts
rm -rf ~/.config/nvim/.git
```

3. Copy the custom keymaps:
```bash
mkdir -p ~/.config/nvim/lua/config
cp lua/config/keymaps.lua ~/.config/nvim/lua/config/keymaps.lua
```

## 🎨 Customization

### Adding More Keybindings
Edit `~/.config/nvim/lua/config/keymaps.lua` to add more custom keybindings. The file uses the standard Neovim keymap API:

```lua
local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

map("n", "<your-key>", "<your-command>", opts)
```

### Adding Plugins
Create a new file in `~/.config/nvim/lua/plugins/` to add custom plugins. For example:

```lua
-- ~/.config/nvim/lua/plugins/myplugin.lua
return {
  "username/plugin-name",
  config = function()
    -- Plugin configuration
  end,
}
```

### Changing Colorscheme
LazyVim uses Tokyonight by default. To change it, edit `~/.config/nvim/lua/config/lazy.lua`:

```lua
require("lazy").setup({
  install = { colorscheme = { "your-colorscheme" } },
  -- ... rest of config
})
```

## 📁 Project Structure

```
Nvim-Lazy-backup/
├── README.md              # This file
├── setup_lazyvim.sh       # Automated installation script
└── lua/
    └── config/
        └── keymaps.lua    # Custom keybindings configuration
```

## 🔧 Configuration Details

### Keybinding Modes
- **Normal mode (n)** - Default editing mode
- **Insert mode (i)** - Text insertion mode
- **Visual mode (v)** - Text selection mode

### LazyVim Structure
After installation, your Neovim configuration will be at:
- `~/.config/nvim/` - Main configuration directory
- `~/.config/nvim/lua/config/` - Configuration files (options, keymaps, autocmds)
- `~/.config/nvim/lua/plugins/` - Custom plugin configurations
- `~/.local/share/nvim/lazy/` - Installed plugins

## 🐛 Troubleshooting

### Common Issues

**LazyVim not loading:**
- Ensure Neovim version is 0.9.0 or higher: `nvim --version`
- Check that `~/.config/nvim/init.lua` exists
- Run `nvim` and check for error messages

**Plugins not installing:**
- Check internet connection (LazyVim downloads plugins from GitHub)
- Run `:Lazy` in Neovim to see plugin status
- Check `~/.local/share/nvim/lazy/` for installed plugins

**Keybindings not working:**
- Ensure `~/.config/nvim/lua/config/keymaps.lua` exists
- Restart Neovim after making changes
- Check for conflicts with other keybindings using `:WhichKey`

**Installation script fails:**
- Ensure you have `git` and `curl` installed
- Check that you have `sudo` access
- Verify your package manager is supported (apt, dnf, yum, pacman, zypper)

### Getting Help
1. Check the [LazyVim documentation](https://lazyvim.github.io/)
2. Visit [LazyVim GitHub](https://github.com/LazyVim/LazyVim)
3. Review [Neovim documentation](https://neovim.io/doc/)

## ⭐ Acknowledgments

- [LazyVim](https://github.com/LazyVim/LazyVim) - The amazing Neovim distribution
- [folke](https://github.com/folke) - Creator of LazyVim and lazy.nvim
- [Neovim](https://neovim.io/) - The editor itself

## 📞 Support

If you find this project helpful, please give it a star ⭐!

For issues and questions, please open an issue on GitHub.
