-- Bootstrap packer.nvim if not installed
local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({ 'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path })
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

-- Plugin manager setup
require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'
   use {
    'lewis6991/gitsigns.nvim',
    requires = { 'nvim-lua/plenary.nvim' },
    config = function()
      require('gitsigns').setup({
        current_line_blame = true, -- optional setting
      })
    end
  }
  use 'nvim-lua/plenary.nvim'
  use 'nvim-telescope/telescope.nvim'
  use 'ThePrimeagen/harpoon'
  use 'folke/zen-mode.nvim'
  use 'tpope/vim-fugitive'
  use 'neovim/nvim-lspconfig'
  use 'hrsh7th/nvim-cmp'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'L3MON4D3/LuaSnip'
  use 'mattn/emmet-vim'
  use 'tpope/vim-surround'
  use 'windwp/nvim-autopairs'
  use { "rose-pine/neovim", as = "rose-pine" }
  -- .NET Support
  use 'nvim-neotest/nvim-nio'
  use 'williamboman/mason.nvim'
  use 'williamboman/mason-lspconfig.nvim'
  use 'jay-babu/mason-null-ls.nvim'
  use 'nvimtools/none-ls.nvim'
  use 'mfussenegger/nvim-dap'
  use 'rcarriga/nvim-dap-ui'
  use { source = "rose-pine/neovim", as = "rose-pine" }
  if packer_bootstrap then
    require('packer').sync()
  end
end)

vim.cmd [[highlight Normal guibg=NONE]]
-- Basic settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.termguicolors = true
vim.opt.wildignore:append({ "C:/ProgramData/Sophos/**" })

-- Key mappings
vim.api.nvim_set_keymap('n', 'ff', ':Telescope find_files<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'tf', ':Telescope live_grep<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'zm', ':ZenMode<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'tb', ':Telescope buffers<CR>', { noremap = true, silent = true })

vim.api.nvim_set_keymap('x', '<leader>{', [[<Esc><i{<Esc>>a}<Esc>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('x', '<leader>(', [[<Esc><i(<Esc>>a)<Esc>]], { noremap = true, silent = true })

vim.g.user_emmet_leader_key = '<C-y>,'
vim.g.user_emmet_mode = 'jsx'

-- LSP settings
local lspconfig = require('lspconfig')
lspconfig.ts_ls.setup {}
lspconfig.pyright.setup {}
lspconfig.rust_analyzer.setup {}

-- Autopairs
require('nvim-autopairs').setup({
  disable_filetype = { "TelescopePrompt", "vim" },
})

-- Autocompletion setup
local cmp = require('cmp')
cmp.setup({
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body)
    end,
  },
     mapping = {
    ['<Up>'] = cmp.mapping.select_prev_item(),
    ['<Down>'] = cmp.mapping.select_next_item(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
    ['<Tab>'] = cmp.mapping.confirm({ select = true }),
    ['<C-e>'] = cmp.mapping.close(),
  },

   sources = {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  },

})

-- Harpoon setup
require('harpoon').setup()

-- Zen Mode setup
require('zen-mode').setup()

-- Mason setup
require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = { "omnisharp" }
})

-- OmniSharp LSP setup
local capabilities = require('cmp_nvim_lsp').default_capabilities()
require('lspconfig').omnisharp.setup({
  capabilities = capabilities,
  cmd = { "omnisharp" },
  enable_roslyn_analyzers = true,
  organize_imports_on_format = true,
  enable_import_completion = true,
})

-- Null-ls for formatting
local null_ls = require("null-ls")
null_ls.setup({
  sources = {
    null_ls.builtins.formatting.csharpier
  },
})
require("mason-null-ls").setup({
  ensure_installed = { "csharpier" },
  automatic_installation = true,
})

require("rose-pine").setup({
  variant = "moon", -- "main", "moon", or "dawn"
  dark_variant = "main",
  bold_vert_split = false,
  dim_nc_background = true,
  disable_background = true,
  disable_float_background = true,
  disable_italics = false,
})


vim.cmd("colorscheme rose-pine")

-- DAP for .NET Core
local dap = require("dap")
dap.adapters.coreclr = {
  type = 'executable',
  command = 'C:/tools/netcoredbg/netcoredbg.exe', -- Change this to your debugger path
  args = {'--interpreter=vscode'}
}
dap.configurations.cs = {
  {
    type = "coreclr",
    name = "Launch - netcoredbg",
    request = "launch",
    program = function()
      return vim.fn.input('Path to DLL > ', vim.fn.getcwd() .. '/bin/Debug/', 'file')
    end,
  },
}

vim.diagnostic.config({
  virtual_text = false,
  signs = true,
  underline = true,
  update_in_insert = true, -- update diagnostics while typing
  severity_sort = true,
  float = {
    border = "rounded",
    source = "always",
    focusable = false,
  },
})

-- Function to show diagnostics automatically
local function show_diagnostics()
  vim.defer_fn(function()
    vim.diagnostic.open_float(nil, { focusable = false })
  end, 100) -- slight delay to avoid flicker
end

-- Auto open diagnostic float when entering insert mode
vim.api.nvim_create_autocmd("InsertEnter", {
  callback = show_diagnostics,
})

-- Also auto show diagnostic float when holding the cursor (normal mode)
vim.api.nvim_create_autocmd("CursorHold", {
  callback = show_diagnostics,
})



require("dapui").setup()
vim.keymap.set("n", "<F5>", require'dap'.continue)
vim.keymap.set("n", "<F10>", require'dap'.step_over)
vim.keymap.set("n", "<F11>", require'dap'.step_into)
vim.keymap.set("n", "<F12>", require'dap'.step_out)
vim.keymap.set("n", "<leader>du", require'dapui'.toggle)


