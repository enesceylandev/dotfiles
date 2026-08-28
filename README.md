# dotfiles

Kişisel terminal/araç yapılandırması — `mac` branch'i üzerinden makineler
arasında senkronlanır. Hedef: yeni bir makinede `./install.sh` çalıştırınca bu
makinedeki kurulumun aynısına ulaşmak.

## Yapı

```
install.sh              Bootstrap: brew bundle + symlink'ler + submodule'ler + herdr integrations
Brewfile                Homebrew paketleri (tmux, herdr, neovim, gh, …)
configs/kitty           -> ~/.config/kitty
configs/herdr           -> ~/.config/herdr   (config.toml; runtime .wt/ slotları hariç)
configs/nvim            -> ~/.config/nvim
configs/tmux            -> ~/.config/tmux
configs/git             -> ~/.config/git     (+ ~/.gitconfig)
configs/gh              -> ~/.config/gh
configs/opencode        -> ~/.config/opencode
configs/zsh             .zshrc / .zprofile (+ plugins/ altında iki submodule)
```

`install.sh` her adımı idempotent yazıldı; mevcut bir kurulumda tekrar
çalıştırmak güvenli.

## Neler senkronlanır, neler senkronlanmaz

| Yüzey                 | Durum                                                                                                                                    |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| opencode config       | `opencode.json` + `tui.json` tracked.                                                                                                     |
| herdr opencode plugin | `configs/opencode/plugins/herdr-agent-state.js` **bilerek gitignore'lı** (herdr her güncellemede yeniden yazar). `install.sh` Step 6'daki `herdr integration install opencode` onu geri yaratır; dosyayı elle commit etmeyin. |
| opencode runtime      | `node_modules`, `package.json`, marker dosyaları gitignore'lı — plugin yalnız `node:net` import ettiği için bunlar runtime için gerekmez.  |
| herdr `.wt/` slotları | Makine-yerel worktree slotları (`.gitignore`'da).                                                                                        |
| zsh plugin submodules | `git submodule update --init --recursive` ile iner (Step 5, dosya-varlığı kontrolüyle) ve `.zshrc` sonunda source edilir (syntax-highlighting en sonda — upstream sözleşmesi). |
| boemar-hr wt completion | `.zshrc`, `~/Documents/boemar-hr/scripts/wt-completion.zsh` dosyasını VARLIK kontrolüyle source eder. O repo kendi git remote'u üzerinden senkronlanır (dotfiles'a ait değildir). |

## Yeni makine kurulumu

```bash
git clone git@github.com:enesceylandev/dotfiles.git ~/Documents/dotfiles
cd ~/Documents/dotfiles && ./install.sh
```

1. Homebrew paketleri (`brew bundle --no-upgrade`)
2. `~/.dotfiles -> ~/Documents/dotfiles` bağlantısı
3. `~/.config/*` symlink'leri + `~/.zshrc`, `~/.zprofile`, `~/.gitconfig`
4. zsh plugin submodule'leri
5. herdr integrations (`opencode`, `claude`) — gitignore'lı plugin dosyasını geri yaratır

Terminali yeniden başlatın: `source ~/.zshrc`.
