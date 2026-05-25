---
name: tmux
description: When requested by user to use tmux for long-running commands
---

# When the user has requested use of tmux for long-running commands

*   Long-running commands (eg m) should be run in a tmux pane. In this case
    create a pane (using `tmux create-pane`) if you haven't already and use the
    run_shell_tool tool to run `tmux send-keys -t <tmux pane> '<command>' C-m`.
    You need to escape some of the characters in the command when doing this.
*   Whilst the command is in progress, just check the last 10 lines of the tmux
    every 15 seconds (using tmux capture-pane) to avoid polluting your context.

*   **Note:** Always check the pane contents after sending keystrokes to verify
    the command execution.
