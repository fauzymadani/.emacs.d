<div align="center">
  <img src="https://www.gnu.org/software/emacs/images/emacs.png" height="80" alt="Emacs">
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="https://orgmode.org/resources/img/org-mode-unicorn.svg" height="80" alt="Org Mode">

  # .emacs.d

  Personal Emacs config — built for math note-taking with Org mode and LaTeX preview.
</div>

![preview](preview.png)

## Highlights

- **Org + LaTeX preview** — tecosaur's org fork with live SVG math rendering
- **cdlatex** — fast math input with custom symbol bindings
- **Mixed pitch** — Merriweather for prose, Latin Modern Math for equations
- **Olivetti** — focused writing column
- **Consult + Embark + Marginalia** — enhanced navigation and search
- **YASnippet** — math snippets (`frac`, `int`, `sum`, `lim`, `mat`, `begin`)

## Keybindings

| Key | Action |
|-----|--------|
| `C-c i` | Insert inline math `\(\)` |
| `C-c d` | Insert display math `\[\]` |
| `C-c a` | Insert align environment |
| `C-s` | Live search in buffer (consult) |
| `C-x b` | Switch buffer with preview (consult) |
| `M-g g` | Go to line (consult) |
| `C-.` | Action menu on thing at point (embark) |
| `C-;` | Quick action on thing at point (embark-dwim) |

## Snippets

Snippet files live in `snippets/org-mode/`. Add new ones by dropping files there.
