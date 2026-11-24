-- Rex configuration (home server: workstation)
-- Managed in ~/dotfiles/rex/.config/rex/init.lua (stowed to ~/.config/rex/init.lua)

-- === Remote hosts ============================================================
-- Explicit socket path skips SSH socket discovery (1 SSH connection instead of 2)
rex.host({ label = "ctop", endpoint = "ssh://ctop/run/user/1557118/rex/server.sock" })

-- === Prefix (ctrl+a) =========================================================
-- Forward ctrl+a to the terminal when pressed twice (e.g. bash/zsh start-of-line)
rex.bind("ctrl+a>ctrl+a", "pane.send_key", { key = "ctrl+a" })

-- Fuzzy picker ("Go to Anything...", equivalent to herdr-jump)
rex.bind("ctrl+a>o", "pane.go_to")

-- Tabs (Herdr: switch_tab = "prefix+1..9")
for i = 1, 9 do
  rex.bind("ctrl+a>" .. i, "client.tab.goto", { index = i })
end

-- Sessions / workspaces (Herdr: previous_workspace / next_workspace)
rex.bind("ctrl+a>[", "session.previous")
rex.bind("ctrl+a>]", "session.next")

-- Pane resize
rex.bind("ctrl+a>h", "pane.resize", { direction = "left", amount = 5 })
rex.bind("ctrl+a>j", "pane.resize", { direction = "down", amount = 5 })
rex.bind("ctrl+a>k", "pane.resize", { direction = "up", amount = 5 })
rex.bind("ctrl+a>l", "pane.resize", { direction = "right", amount = 5 })

-- Send ctrl+l (clear screen) since bare ctrl+l navigates panes below
rex.bind("ctrl+a>ctrl+l", "pane.send_key", { key = "ctrl+l" })

-- === Vim / Neovim-aware pane navigation (ctrl+h/j/k/l) =======================
-- Works across workstation, ctop, and local Mac via ctx.server.
-- Paired with the vim.env.REX_BLOCK check in ~/.config/nvim/lua/plugins.lua.
local vim_procs = {
  nvim = true,
  vim = true,
  vi = true,
  view = true,
  vimdiff = true,
  nvimdiff = true,
  gvim = true,
  lumen = true,
}

local dir_keys = {
  left = "ctrl+h",
  down = "ctrl+j",
  up = "ctrl+k",
  right = "ctrl+l",
}

local function matches_vim(proc_info)
  if not proc_info then
    return false
  end
  local name = (proc_info.name or ""):lower()
  if vim_procs[name] then
    return true
  end
  if proc_info.argv0 then
    local base = proc_info.argv0:match("([^/]+)$") or proc_info.argv0
    base = base:gsub("^%-", ""):lower()
    if vim_procs[base] then
      return true
    end
  end
  return false
end

local function is_vim_foreground(ctx)
  if not ctx.session_id or not ctx.block_id then
    return false
  end
  local target = ctx.server and rex.server(ctx.server) or rex
  local proc = target.call("com.superlogical.terminal.process", {
    session_id = ctx.session_id,
    block_id = ctx.block_id,
    args = {},
  })
  if not proc then
    return false
  end
  if matches_vim(proc.foreground) then
    return true
  end
  if proc.ancestors then
    for _, anc in ipairs(proc.ancestors) do
      if matches_vim(anc) then
        return true
      end
    end
  end
  return false
end

rex.action({
  name = "vim_aware_focus",
  title = "Focus Pane (Vim-Aware)",
  description = "Forward ctrl+h/j/k/l to Vim/Neovim/lumen, otherwise focus the adjacent Rex pane",
  args = { direction = "string" },
  run = function(ctx, args)
    local dir = args.direction
    local key = dir_keys[dir]
    if not key then
      error("unknown direction: " .. tostring(dir), 0)
    end
    if is_vim_foreground(ctx) then
      rex.client.queue("pane.send_key", { key = key })
    else
      rex.client.queue("pane.focus", { direction = dir })
    end
  end,
})

rex.bind("ctrl+h", "vim_aware_focus", { direction = "left" })
rex.bind("ctrl+j", "vim_aware_focus", { direction = "down" })
rex.bind("ctrl+k", "vim_aware_focus", { direction = "up" })
rex.bind("ctrl+l", "vim_aware_focus", { direction = "right" })
