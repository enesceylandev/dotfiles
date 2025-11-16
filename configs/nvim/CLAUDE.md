# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a **Neovim configuration** project that sets up a fully-featured development environment. It uses the **Lazy.nvim** plugin manager to organize and load plugins dynamically. The configuration is written in **Lua** and is structured into core settings and modular plugin configurations.

## Project Structure

```
nvim/
├── init.lua                 # Entry point - loads core settings and plugins via Lazy
├── lazy-lock.json          # Plugin version lockfile (managed by Lazy)
├── lua/
│   ├── core/               # Core Neovim settings and keymaps
│   │   ├── options.lua     # Neovim global options (line numbers, mouse, clipboard, etc.)
│   │   └── keymaps.lua     # Global keybindings
│   └── plugins/            # Plugin specifications and configurations
│       ├── lspConfig.lua   # Language Server Protocol setup (Mason, LSP, keymaps)
│       ├── none-ls.lua     # Formatters and linters via null-ls
│       ├── treesitter.lua  # Syntax highlighting and parsing
│       ├── telescope.lua   # Fuzzy finder for files, buffers, etc.
│       └── [23 other plugins]  # Individual plugin configs
└── CLAUDE.md               # This file
```

## Architecture

The configuration follows these key architectural patterns:

### 1. **Plugin Manager: Lazy.nvim**
- All plugins are specified in `lua/plugins/*.lua` as Lua tables
- `init.lua` calls `lazy.setup()` with all plugin specs
- Lazy handles installation, updates, and lazy-loading via `event` or other triggers
- Plugin lock versions are stored in `lazy-lock.json`

### 2. **Modular Plugin Organization**
Each plugin file returns a single plugin spec (or array of specs) that includes:
- Plugin repository URL
- Dependencies (other plugins needed)
- `config` function for setup and keybindings
- Optional `event`, `cmd`, or other lazy-load triggers

### 3. **Core Settings**
- `lua/core/options.lua`: Vim options (indentation, line numbers, mouse, etc.)
- `lua/core/keymaps.lua`: Global key mappings with space as leader key

### 4. **Development Tools Chain**
- **LSP**: Mason + mason-lspconfig + nvim-lspconfig
  - Manages language servers: html, lua_ls, ts_ls, eslint, harper_ls
  - Provides: Go to definition, references, hover, code actions, rename
- **Formatting & Linting**: none-ls.nvim with Prettier (JS/TS), Stylua (Lua), ESLint
- **Code Completion**: nvim-cmp with LuaSnip snippets
- **Syntax Highlighting**: Treesitter with language parsers
- **File Explorer**: Neo-tree.nvim
- **Fuzzy Finding**: Telescope.nvim with FZF support
- **Terminal**: Toggleterm.nvim (Ctrl+Esc to toggle)

## Common Development Tasks

### Viewing/Editing Configuration

**View core settings:**
```bash
nvim lua/core/options.lua
```

**View/edit global keymaps:**
```bash
nvim lua/core/keymaps.lua
```

**View/edit specific plugin config:**
```bash
nvim lua/plugins/[plugin-name].lua
```

### Managing Plugins

**Sync plugins (install missing, remove unused):**
```
:Lazy sync
```

**Update all plugins to latest versions:**
```
:Lazy update
```

**Check plugin status:**
```
:Lazy
```

**View plugin lockfile:**
```bash
cat lazy-lock.json
```

### Key Keybindings Reference

**Core Navigation:**
- `<Space>` = Leader key
- `<C-Left>` / `<C-Right>` = Next/previous buffer
- `<C-w>` = Close buffer
- `<C-Esc>` = Toggle terminal
- `<Tab>` / `<S-Tab>` = Navigate buffers

**Window Management:**
- `<leader>sv` = Split vertical
- `<leader>sh` = Split horizontal
- `<leader>se` = Equalize splits
- `<leader>w` = Close window
- `<M-Arrow>` = Resize windows

**Text Editing:**
- `<M-S-Up>` / `<M-S-Down>` = Move lines
- `<C-s>` = Save
- `<C-f>` = Forward search
- `<C-d>` = Backward search
- `<C-g>` = Replace (`:s/`)

**LSP:**
- `gd` = Go to definition
- `gr` = Go to references
- `<leader>h` = Hover info
- `<leader>ca` = Code actions
- `<leader>r` = Rename symbol
- `<leader>ci` = Remove unused imports

**Telescope (Fuzzy Finding):**
- `<leader>ff` = Find files
- `<leader>fw` = Live grep (search text)
- `<leader>fb` = Find buffers
- `<leader>fh` = Help tags
- `<leader>fd` = LSP references (customizable)

**Editor Features:**
- `x` = Delete without yanking
- `p` (visual) = Paste without replacing clipboard
- `n` / `N` = Next/previous search (centered)

## Plugin Configuration Details

### LSP Configuration (`lua/plugins/lspConfig.lua`)
- Uses **Mason** to install language servers automatically
- Ensures these servers are installed: html, lua_ls, ts_ls, eslint, harper_ls
- Provides standard LSP keymaps for definition, references, hover, actions, rename
- ESLint is configured but can be selectively disabled per file type if needed

### Formatting (`lua/plugins/none-ls.lua`)
- **Prettier** for JavaScript/TypeScript (configured with specific options: 2-space tabs, trailing commas, 80-char lines)
- **Stylua** for Lua formatting
- **ESLint** for linting (when not conflicting with formatters)
- Format-on-save is enabled via BufWritePre autocmd
- Only null-ls performs formatting to avoid conflicts with LSP servers

### Autocompletion (`lua/plugins/autocompilation.lua`)
- **nvim-cmp** for completion popup
- **LuaSnip** for snippet expansion
- Completes from: LSP, buffer, file paths, and snippets
- Icons for different completion types (Function, Variable, Class, etc.)

### Treesitter (`lua/plugins/treesitter.lua`)
- Provides syntax highlighting and AST-based features
- Auto-installs parsers for common languages
- Enables folding, incremental selection, and indentation-based features

### File Navigation
- **Neo-tree**: File explorer toggle (usually `<leader>e` or similar)
- **Telescope**: Fuzzy finder for files, buffers, grep, git files
- **Yazi**: File manager integration

### Visual Enhancements
- **Tokyonight** colorscheme
- **Bufferline**: Visual buffer/tab bar
- **Lualine**: Status line (currently disabled in init.lua)
- **Indent-blankline**: Visual indent guides
- **Colorizer**: Hex color previews

## Important Notes

### Plugin Dependencies
Some plugins depend on others:
- LSP ecosystem: Mason depends on mason-lspconfig, which depends on nvim-lspconfig
- Completion: nvim-cmp depends on LuaSnip and various source plugins
- Telescope: Depends on plenary, telescope-fzf-native for performance

### Currently Disabled Plugins
- `harpoon`: Navigation plugin (commented out in init.lua:27)
- `lualine`: Status line (commented out in init.lua:38)
- `chatgpt`: ChatGPT integration (commented out in init.lua:39)
- `persistence`: Session persistence (commented out in init.lua:40)

These can be re-enabled by uncommenting and running `:Lazy sync`.

### Formatter Configuration
Prettier is pre-configured for consistent formatting:
- Tab width: 2 spaces
- No tabs (use spaces)
- Double quotes for strings
- Trailing commas in ES5 style
- 80-character line width
- Bracket spacing enabled
- Unix line endings (LF)

Comment format options are customized (comments don't auto-insert on new lines).

### Indentation
- Tab width: 2 spaces (see `lua/core/options.lua` lines 22-24)
- Smart indent enabled
- Relative line numbers enabled for easier navigation

## Extending This Configuration

**To add a new plugin:**
1. Create `lua/plugins/my-plugin.lua` with the plugin spec
2. Add `require 'plugins.my-plugin'` to the plugin list in `init.lua`
3. Run `:Lazy sync` to install

**To modify keymaps:**
- Global keymaps: Edit `lua/core/keymaps.lua`
- Plugin-specific keymaps: Edit the plugin's config function in `lua/plugins/[plugin].lua`

**To configure an LSP server:**
- Edit `lua/plugins/lspConfig.lua` in the `lspconfig.SERVERNAME.setup {}` section
- Add to `ensure_installed` in mason-lspconfig for auto-installation

**To add a formatter/linter:**
- Add to `ensure_installed` in `lua/plugins/none-ls.lua`
- Add to `sources` table with any custom configuration
