-- debug.lua
--
-- DAP plugin configuration to debug your code.

return {
  'mfussenegger/nvim-dap',
  keys = {
    {
      '<leader>dM',
      function()
        require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
      end,
      desc = 'Dap Breakpoint Condition',
    },
    {
      '<leader>dm',
      function()
        require('dap').toggle_breakpoint()
      end,
      desc = 'Dap Toggle Breakpoint',
    },
    {
      '<leader>dc',
      function()
        require('dap').continue()
      end,
      desc = 'Dap Continue',
    },
    {
      '<leader>dC',
      function()
        require('dap').run_to_cursor()
      end,
      desc = 'Dap Run to Cursor',
    },
    {
      '<leader>dg',
      function()
        require('dap').goto_()
      end,
      desc = 'Dap Go to line (no execute)',
    },
    {
      '<leader>di',
      function()
        require('dap').step_into()
      end,
      desc = 'Dap Step Into',
    },
    {
      '<leader>dj',
      function()
        require('dap').down()
      end,
      desc = 'Dap Down',
    },
    {
      '<leader>dk',
      function()
        require('dap').up()
      end,
      desc = 'Dap Up',
    },
    {
      '<leader>dl',
      function()
        require('dap').run_last()
      end,
      desc = 'Dap Run Last',
    },
    {
      '<leader>do',
      function()
        require('dap').step_out()
      end,
      desc = 'Dap Step Out',
    },
    {
      '<leader>dO',
      function()
        require('dap').step_over()
      end,
      desc = 'Dap Step Over',
    },
    {
      '<leader>dp',
      function()
        require('dap').pause()
      end,
      desc = 'Dap Pause',
    },
    {
      '<leader>dr',
      function()
        require('dap').repl.toggle()
      end,
      desc = 'Dap Toggle REPL',
    },
    {
      '<leader>ds',
      function()
        require('dap').session()
      end,
      desc = 'Dap Session',
    },
    {
      '<leader>dt',
      function()
        require('dap').terminate()
      end,
      desc = 'Dap Terminate',
    },
    {
      '<leader>dw',
      function()
        require('dap.ui.widgets').hover()
      end,
      desc = 'Dap Widgets',
    },
  },
  dependencies = {
    {
      'rcarriga/nvim-dap-ui',
      dependencies = 'mfussenegger/nvim-dap',
      keys = {
        {
          '<leader>de',
          function()
            require('dapui').eval()
          end,
          desc = 'Dap Eval',
          mode = { 'n', 'v' },
        },
        {
          '<leader>du',
          function()
            require('dapui').toggle {}
          end,
          desc = 'Dap Toggle UI',
        },
      },
      config = function()
        local dap = require 'dap'
        local dapui = require 'dapui'
        dapui.setup()
        dap.listeners.after.event_initialized['dapui_config'] = function()
          dapui.open()
        end
        dap.listeners.before.event_terminated['dapui_config'] = function()
          dapui.close()
        end
        dap.listeners.before.event_exited['dapui_config'] = function()
          dapui.close()
        end

        -- Dap UI setup
        dapui.setup {
          icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
          controls = {
            icons = {
              pause = '⏸',
              play = '▶',
              step_into = '⏎',
              step_over = '⏭',
              step_out = '⏮',
              step_back = 'b',
              run_last = '▶▶',
              terminate = '⏹',
              disconnect = '⏏',
            },
          },
        }
      end,
    },
    {
      'jay-babu/mason-nvim-dap.nvim',
      dependencies = {
        'williamboman/mason.nvim',
        'mfussenegger/nvim-dap',
      },
      config = function()
        require('mason-nvim-dap').setup {
          ensure_installed = {
            'delve',
            'codelldb',
          },
          automatic_setup = true,
          handlers = {
            function(config)
              require('mason-nvim-dap').default_setup(config)
            end,
          },
        }
        --Change icons
        local sign = vim.fn.sign_define
        sign('DapBreakpoint', { text = '●', texthl = 'DapBreakpoint', linehl = '', numhl = '' })
        sign('DapBreakpointCondition', { text = '●', texthl = 'DapBreakpointCondition', linehl = '', numhl = '' })
        sign('DapLogPoint', { text = '◆', texthl = 'DapLogPoint', linehl = '', numhl = '' })
        sign('DapStopped', { text = '󰁕 ', texthl = 'DiagnosticWarn', linehl = 'DapStoppedLine', numhl = '' })
      end,
    },
    {
      'theHamsta/nvim-dap-virtual-text',
      opts = {},
    },
    {
      'leoluz/nvim-dap-go',
      config = function()
        require('dap-go').setup()
      end,
    },
  },
  config = function() end,
}
