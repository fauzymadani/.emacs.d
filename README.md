<div align="center">
  <img src="https://www.gnu.org/software/emacs/images/emacs.png" height="80" alt="Emacs">
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="https://orgmode.org/resources/img/org-mode-unicorn.svg" height="80" alt="Org Mode">

  # .emacs.d

  Personal Emacs config for math note-taking with Org mode and LaTeX preview.
</div>

> 60+ packages, still a fast startup. Almost everything is deferred
> (`:defer` / `:hook` / `:bind`), so packages load on first use instead of at
> launch, and `early-init.el` suspends GC and file-name handlers during init.

![preview](preview.png)

https://github.com/user-attachments/assets/79fcb056-3b84-4de0-b281-b8b73a2ab7db

## Highlights

- **Org + LaTeX preview**: tecosaur's org fork with live SVG math rendering
- **cdlatex**: fast math input with custom symbol bindings
- **Mixed pitch**: Crimson Pro for prose (switch live with `C-c f`), Latin Modern Math for equations
- **Olivetti**: focused writing column
- **Consult + Embark + Marginalia**: enhanced navigation and search
- **YASnippet**: math snippets (`frac`, `int`, `sum`, `lim`, `mat`, `begin`)
- **Dated exercise files**: `C-c x` opens a templated math exercise, `C-u C-c x` per topic
- **Cheatsheet panel**: keybinding reference in a side window on startup
- **RSS reader**: elfeed with categorized feeds (`C-c w`), daily sources (Kottke, APOD, Aeon, Longreads, MetaFilter, The Marginalian); `e` opens an entry full-page in eww
- **Dired tree**: expand directories inline with `TAB` (dired-subtree), filter with `/`, collapse deep chains, copy/move across buffers (dired-ranger)
- **Git**: magit (`C-x g`)
- **Mail**: notmuch, tag-based email with PGP sign/encrypt (`C-c M`); see [Mail](#mail-notmuch)
- **Terminal**: vterm, a real libvterm terminal (`C-c v`)
- **Notes**: denote for linked plain-text notes (`C-c N`)
- **keycast**: shows the last key and command in the mode line
- **casual**: transient menus for dired, isearch, Info, ibuffer, calc (`C-o`)
- **Themes**: modus-vivendi (dark) and modus-operandi / mindre (light), toggle with `C-c t`
- **Editing extras**: duplicate line, move line, multiple cursors, smart line start, expand-region (`C-=`), rainbow-delimiters in code
- **Languages**: C (clangd) and Go (gopls), completion via corfu + eglot

## Performance

Two things keep 60+ packages feeling light:

**Deferred loading.** Almost every package uses `:defer` / `:hook` / `:bind`, so
it loads the first time you actually use it rather than at launch. The startup
cost is spread across your session instead of paid all at once.

**Garbage collection (gcmh).** Emacs GC is stop-the-world: when enough garbage
piles up, Emacs freezes to collect it. With a fixed threshold that freeze can
land mid-keystroke. [gcmh](https://github.com/koral/gcmh) fixes the *timing*:

- While you're working it holds `gc-cons-threshold` at 128 MB, so GC almost
  never fires during typing or scrolling.
- After each command it arms an idle timer; when you pause, it collects then,
  then raises the threshold back up.
- `gcmh-idle-delay` is `auto`, so the idle wait adapts to how long the last
  collection took.

So collection still happens — it just waits for the gaps between your actions.

`early-init.el` suspends GC and file-name handlers during init for a faster
launch, then an `after-init-hook` restores a safe 16 MB threshold. That restore
runs even if `init.el` errors and before gcmh takes over, so GC is never left
disabled: worst case falls back to the fixed 16 MB, best case gcmh smooths it.

## Requirements

Fonts (install to `~/.local/share/fonts`, then `fc-cache -f`):

| Font | Role | Required? |
|------|------|-----------|
| Martian Mono | default + code | yes |
| Crimson Pro | default prose (Org) | yes |
| EB Garamond, STIX Two Text, Charis | prose alternatives (`C-c f`) | optional |
| Latin Modern Math | math previews and export | ships with TeX Live |

Tools:

| Tool | For |
|------|-----|
| TeX Live | LaTeX preview and PDF export |
| clangd | C completion and errors |
| Go + gopls | Go completion and errors |
| isync (mbsync) | fetch mail into a local Maildir |
| notmuch | index, tag, and search mail |
| msmtp | send mail |
| gnupg | PGP sign / encrypt / verify |

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

## Mail (notmuch)

notmuch is a tag-based mail reader: no folders, everything is one pool you slice
with saved searches (`tag:inbox`, `tag:unread`). It does not fetch or send mail
itself, so the setup is four small tools glued together:

```
mbsync  ->  ~/Mail  ->  notmuch  ->  notmuch-emacs      (read/search/tag)
(fetch)     Maildir     (index)      msmtp              (send)
                                     gnupg              (sign/encrypt)
```

Open it with `C-c M`. `G` inside notmuch runs `~/.local/bin/mailsync`
(fetch + index). Press `j` then a letter to jump to a saved search
(`i` inbox, `u` unread, `f` flagged, `t` today, `s` sent, `e` emacs list,
`a` all mail). Outgoing mail is auto-signed with your PGP key; encrypt a message
with `C-c C-m c p` (needs the recipient's public key imported).

### Setup

The config in `init.el` is machine-agnostic; the account details live in
**gitignored `$HOME` files** so no address, password, or key is ever committed:

- `~/.mbsyncrc` — IMAP server, folders, Maildir path
- `~/.msmtprc` — SMTP server (chmod 600)
- `~/.notmuch-config` — database path, your name/email, tag rules
- `~/.config/mail-pass` — the mail password, read by both mbsync and msmtp (chmod 600)
- `~/.local/bin/mailsync` — `mbsync -a && notmuch new`, plus tag rules (bound to `G`)
- `~/.local/bin/mail-purge` — permanently delete mail tagged `deleted` (see below)

Install the tools and do the first sync:

```sh
sudo pacman -S isync notmuch msmtp gnupg

# fill in the four config files above for your provider, then:
mbsync -a          # first sync, downloads everything (slow once)
notmuch new        # index it
```

Then `C-c M` in Emacs. For signing/encryption you also need a GnuPG key whose
UID matches your From address (`gpg --quick-generate-key "Name <you@host>"`).

### Deleting mail

Deletion is two deliberate steps so a stray key never loses mail:

- `d` on a thread **marks** it `deleted` and hides it (reversible with
  `notmuch tag -deleted -- tag:deleted`). Files stay on disk.
- `mail-purge` in a terminal **permanently** removes everything tagged
  `deleted` — deletes the local files and `mbsync` expunges them from the
  server. It counts and asks for confirmation first.

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
| `C-c N` | Denote notes (`n` new, `o` find, `l` link, `b` backlinks, `r` rename) |
| `C-c w` | Open RSS reader (elfeed) |
| `C-x g` | Git status (magit) |
| `C-c M` | Open mail (notmuch) |
| `C-c v` | Open a terminal (vterm) |
| `C-o` | Casual menu (in dired / Info / ibuffer / calc) |
| `TAB` | Expand/collapse directory inline (dired-subtree) |
| `/` | Filter the listing (dired-narrow) |
| `W` / `X` / `Y` | Copy / move / paste files across dired buffers (dired-ranger) |
| `e` | Open the current feed entry full-page in eww (elfeed) |
| `C-=` | Expand selection by semantic unit (expand-region) |
| `C-c f` | Switch prose font (Crimson Pro / EB Garamond / STIX / Charis) |
| `C-c t` | Toggle dark/light theme |
| `C-c P` | Present slides (org-tree-slide) |
| `C-c L` | Distraction-free reading (logos) |
| `C-c T` | Start a timer (tmr) |
| `` C-` `` | Toggle popup buffers (popper) |
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
