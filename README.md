<div align="center">
  <img src="https://www.gnu.org/software/emacs/images/emacs.png" height="80" alt="Emacs">
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="https://orgmode.org/resources/img/org-mode-unicorn.svg" height="80" alt="Org Mode">

  # .emacs.d

  Personal Emacs config for math note-taking with Org mode and LaTeX preview.
</div>

![preview](preview.png)

https://github.com/user-attachments/assets/79fcb056-3b84-4de0-b281-b8b73a2ab7db

## Highlights

- **Org + LaTeX preview**: tecosaur's org fork with live SVG math rendering
- **cdlatex**: fast math input with custom symbol bindings
- **Mixed pitch**: STIX Two Text for prose (switch live with `C-c f`), Latin Modern Math for equations
- **Olivetti**: focused writing column
- **Consult + Embark + Marginalia**: enhanced navigation and search
- **YASnippet**: math snippets (`frac`, `int`, `sum`, `lim`, `mat`, `begin`)
- **Dated exercise files**: `C-c x` opens a templated math exercise, `C-u C-c x` per topic
- **Themes**: Gruber Darker (dark) and leuven (light), toggle with `C-c t`
- **Editing extras**: duplicate line, move line, multiple cursors, smart line start
- **Languages**: C (clangd) and Go (gopls), completion via corfu + eglot

## Requirements

Fonts (install to `~/.local/share/fonts`, then `fc-cache -f`):

| Font | Role | Required? |
|------|------|-----------|
| Iosevka Nerd Font Mono | default + code | yes |
| STIX Two Text | default prose (Org) | yes |
| EB Garamond, Charis | prose alternatives (`C-c f`) | optional |
| Latin Modern Math | math previews and export | ships with TeX Live |

Tools:

| Tool | For |
|------|-----|
| TeX Live | LaTeX preview and PDF export |
| clangd | C completion and errors |
| Go + gopls | Go completion and errors |

## Setup

Completion, errors, and jump-to-definition come from eglot (LSP) plus corfu.
Install the language servers you need:

```sh
# C
sudo pacman -S clang                          # provides clangd

# Go
sudo pacman -S go
go install golang.org/x/tools/gopls@latest    # lands in ~/go/bin
```

Go uses the built-in tree-sitter mode. On first use, install the grammars:

```
M-x treesit-install-language-grammar RET go
M-x treesit-install-language-grammar RET gomod
```

Then open a `.c` or `.go` file. eglot starts on its own: completion pops up as
you type, errors show inline, `M-.` jumps to a definition. Go files also gofmt
and organize imports on save.

## Keybindings

| Key | Action |
|-----|--------|
| `C-c i` | Insert inline math `\(\)` |
| `C-c d` | Insert display math `\[\]` |
| `C-c a` | Insert align environment |
| `C-c c` | Org capture |
| `C-c x` | Open today's exercise file (`C-u` prefix: per topic) |
| `C-x a` | Org agenda |
| `C-c n` | New org-journal entry |
| `C-c f` | Switch prose font (STIX / EB Garamond / Charis) |
| `C-c t` | Toggle dark/light theme |
| `C-,` | Duplicate line (or region) |
| `M-p` / `M-n` | Move line/region up / down |
| `C->` / `C-<` | Add cursor at next / previous match |
| `C-c m` | Add cursor to all matches |
| `C-a` | Smart line start (indentation, then column 0) |
| `<f5>` / `C-<f5>` | Recompile / compile |
| `M-.` / `M-,` | Jump to definition / back (eglot) |
| `M-x eglot-rename` | Rename symbol across the project |
| `C-s` | Live search in buffer (consult) |
| `C-x b` | Switch buffer with preview (consult) |
| `M-g g` | Go to line (consult) |
| `C-.` | Action menu on thing at point (embark) |
| `C-;` | Quick action on thing at point (embark-dwim) |

## Snippets

Snippet files live in `snippets/org-mode/`. Add new ones by dropping files there.
