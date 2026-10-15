# Ink

A writing room in Neovim. `ink` opens a draft in the terminal you're in, whether that's herdr, an SSH session from the Mac, or anything else. The text sits in a centred column in your own colours. The paragraph you're on stays bright, the line you're writing stays mid-screen, and markdown syntax stays out of the way.

## Start

- `ink` opens the newest draft in `~/writing`, or today's (`~/writing/YYYY-MM-DD.md`) if there's none.
- `ink file.md` opens that file. `INK_DIR` changes the drafts folder.
- Inside it's normal Neovim: `:w` saves, `:q` leaves.

Install with `stow --no-folding ink`, which puts `ink` on your PATH. The Neovim side lives in `nvim/.config/nvim/lua/ink/` and only loads when `ink` starts Neovim.

## Writing

| Key | What it does |
|---|---|
| `<leader>mf` | Focus on or off: paragraph dimming and typewriter scrolling. Turn it off to read the piece back |
| `<leader>mw` | Full width, for wide tables |
| `<leader>mr` | Raw markdown |
| `u` | In text you typed, undoes a sentence or clause at a time |
| `Ctrl-h/j/k/l` | Move to the neighbouring herdr pane |

- Markup (`*italic*`, `**bold**`, `~~strike~~`, `` `code` ``, links) shows its raw syntax only while the cursor is inside it.
- Paste a URL over a selection, with Ctrl+Shift+V or `p`, to make it a link.
- Heading markers sit in the left margin, next to relative line numbers.
- Tables are fitted to the column. The table under the cursor shows raw so you can edit it.
- Bottom right: words in the draft and words written this session, e.g. `1318 words · +42`.

## Alternatives

Keep several versions of a word, sentence or paragraph and switch between them.

| Key | What it does |
|---|---|
| `ga{motion}` (`gaiw`, `gais`, `gaip`, `gac`), visual `ga` | Like `c`, but the old text is kept as an alternative. On text that already has alternatives, it adds another version |
| `]v` / `[v` | Next / previous version |
| `<leader>vk` | Keep this version, drop the others |
| `<leader>vd` | Drop this version |

- Text with alternatives has a dotted underline. Resting on it lists the versions, and the ruler shows `2/3`.
- `u`, `<C-r>` and `.` work as they do with `c`: one `u` removes a new version, `<C-r>` brings it back, and `.` repeats the last `ga` change elsewhere.
- `ga` on one word inside a sentence that has alternatives adds a version of the whole sentence with that word changed.

## Stash

A place for text you cut but might want back, kept with the draft.

| Key | What it does |
|---|---|
| `gs{motion}` (`gsis`, `gsip`), `gss`, visual `gs` | Like `d`, but the text goes to the stash |
| `<leader>vs` | Pick something to put back at the cursor, the way `p` would. `ctrl-x` in the picker discards it |

- `u` puts stashed text back where it was, and `.` stashes the next piece.
- The ruler shows how many pieces are stashed.

## Where it's saved

Alternatives and the stash are saved at the end of the file, in an HTML comment (`<!-- ink_buffer … -->`). Ink hides the comment while you write, and GitHub and other renderers don't show it. If you edit the file somewhere else, Ink finds the alternatives again as long as their text is still there.
