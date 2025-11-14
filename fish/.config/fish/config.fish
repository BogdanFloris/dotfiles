set -gx EDITOR nvim

if type -q direnv
  direnv hook fish | source
end

function fish_user_key_bindings
  bind ctrl-space forward-char
end

fish_add_path "$HOME/.local/bin"

function today
  set -l dir ~/daily
  mkdir -p $dir
  cd $dir
  set -l today_file (date +%F).md
  if not test -e $today_file
    printf "# Daily List – %s\n\n" (date "+%A, %d %b %Y") > $today_file
  end
  nvim $today_file
end

atuin init fish --disable-up-arrow | source
zoxide init fish | source
