# Omar's Emacs config

My Emacs configuration, built on [emacs-bedrock](https://codeberg.org/ashton314/emacs-bedrock) 2.0.0 with a custom IDE layer.

## Requirements

- **Emacs 31.1+** — bedrock 2.0 refuses 30 or older
  - For the embedded WebKit browser (`SPC o b`), Emacs must be built with `--with-ns --with-xwidgets`
  - LSP servers: `gopls`, `rust-analyzer`, `typescript-language-server`
- **Fonts**: [Berkeley Mono](https://berkeleygraphics.com/typefaces/berkeley-mono/) and [Symbols Nerd Font Mono](https://www.nerdfonts.com/) for treemacs/nerd-icons glyphs

On macOS (Homebrew):

```sh
brew install emacs gopls typescript-language-server
brew install rust-analyzer   # or rustup component add rust-analyzer
brew install --cask font-symbols-only-nerd-font
```

## Setup

```sh
git clone git@github.com:omarestrella/emacs.git ~/.emacs-bedrock
ln -s ~/.emacs-bedrock ~/.emacs.d
```

Packages install automatically on first launch (`use-package-always-ensure` + MELPA). Install tree-sitter grammars when prompted, or up front:

```sh
emacs --batch --eval "(dolist (lang '(rust go gomod javascript typescript tsx json yaml)) (unless (treesit-language-available-p lang) (treesit-install-language-grammar lang)))"
```

`~/.emacs.d` is a symlink into the repo. One caveat: the box building this binary dumped a loaddefs that ships without the `xwidget-webkit-browse-url` autoload, so `extras/ide.el` registers it explicitly.

## Stack

Layered on bedrock's `base.el`, `dev.el`, and `vim-like.el` extras. My additions live in [`extras/ide.el`](extras/ide.el):

- **Evil + `SPC` leader** (`general.el`) with a Doom-style which-key panel (`M-SPC` in insert/emacs state)
- **Project.el** with treemacs opening on project switch; the known-project list shows at startup
- **treemacs** sidebar (`SPC o p`) with nerd-icons
- **Ghostel terminal** (`SPC o t`) — libghostty-vt powered
- **Eglot LSP** for Go, Rust, TypeScript (`go-ts-mode`, `rust-ts-mode`, `typescript-ts-mode`, `tsx-ts-mode`, `js-ts-mode`)
- **`SPC o b`** — embedded WebKit (WKWebView via xwidgets)
- Per-project workspace tabs (`SPC TAB p`); default font Berkeley Mono 14pt

## Keybindings

Leader is `SPC` (normal/visual/motion) or `M-SPC` (insert/emacs). Press `SPC` and wait for the panel.

| Key | Group |
|-----|-------|
| `SPC SPC` / `SPC :` | M-x |
| `SPC p` | project: `p` switch `f` find-file `b` buffers `g` grep `c` compile `t` terminal |
| `SPC f` | files: `f` find-file `r` recent `e` this config |
| `SPC b` | buffers: `b` switch `k` kill `i` ibuffer |
| `SPC w` | windows: `v/s` split `d` delete `o` only `h/j/k/l` move |
| `SPC g` | git: `s` magit `d` diff `b` blame `l` log |
| `SPC s` / `SPC /` | search: `s` line `p` ripgrep `o` outline |
| `SPC o` | open: `p` treemacs `t` ghostel `n` next terminal `e` eshell `b` webkit |
| `SPC TAB` | tabs: `n` new `d` close `r` rename `]/[` cycle `p` tab for current project |
| `SPC h` | help: `f` `v` `k` |
| `SPC q` | quit: `q` save+exit `f` delete frame |

## Updating bedrock upstream

```sh
git fetch bedrock && git rebase bedrock/main   # remotes: bedrock = upstream, origin = here
```

## License

Bedrock carries its own GPL-3.0 LICENSE (see [LICENSE](LICENSE)); my additions are GPL-3.0 too.
