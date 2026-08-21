# Adwaita Dark for Chrome

Chrome on Linux takes its colours from GTK and Chrome on macOS takes its own, so
the two machines were never actually the same — and either default can be
restyled on upgrade (the 2026 look tints everything blue). Stating the colours
here makes them explicit: identical on both machines, and unaffected by whatever
Google changes next.

## Install

`chrome://extensions` → Developer mode → Load unpacked → pick this folder.
Same on macOS and Linux. Nothing applies it automatically; if an upgrade ever
drops it, load it again.

Then Settings → Appearance → Dark, which controls the `chrome://` pages
separately from the theme and syncs across devices on its own.

`--load-extension` on the command line does *not* work — branded Chrome ignores
it ("--load-extension is not allowed in Google Chrome"). It has to go through
the extensions page. Unpacked extensions also don't sync, which is why this
lives in the repo instead.

## Colours

Read out of GTK 3.24.52's Adwaita dark, so this reproduces what Chrome was
already showing rather than approximating it:

| Manifest key | GTK source | |
|---|---|---|
| `frame` | `headerbar`, a `#202020`→`#262626` gradient Chrome flattens | `#232323` |
| `frame_inactive` | `headerbar:backdrop` | `#303030` |
| `toolbar` | `theme_bg_color` | `#303030` |
| `tab_text`, `bookmark_text` | `theme_fg_color` | `#f3f3f1` |
| `tab_background_text` | `theme_unfocused_fg_color` | `#919190` |
| `omnibox_background`, `ntp_background` | `theme_base_color` | `#2d2d2d` |
| `ntp_link` | Adwaita link blue, the one non-grey | `#99c1f1` |

Retinting means editing the numbers — they're plain `[r, g, b]`.

## Caveats

Installing this stops Chrome from following GTK on Linux, which is the point of
having it, but does mean a future GTK theme change won't carry over.

Chrome validates theme colours at load: `google-chrome --pack-extension=.` will
reject bad values, which is a cheap way to check an edit before installing it.
It does *not* validate key names — a typo'd key is silently ignored, so check
new keys against the ones above.
