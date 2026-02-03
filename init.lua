-- 1. BOOTSTRAP LAZY.NVIM
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- 2. INSTALL PLUGINS (One single setup call)
require("lazy").setup({
  "neovim/nvim-lspconfig",
  "williamboman/mason.nvim",
  "williamboman/mason-lspconfig.nvim",
  { "NvChad/nvim-colorizer.lua", opts = { user_default_options = { tailwind = true } } },

  -- --- AUTOCOMPLETE PLUGINS ---
  "hrsh7th/nvim-cmp",         -- The engine that shows the popup menu
  "hrsh7th/cmp-nvim-lsp",     -- Gets suggestions from your Go/React LSPs
  "hrsh7th/cmp-buffer",       -- Gets suggestions from the current file
  "hrsh7th/cmp-path",         -- Gets suggestions for file paths
  "saadparwaiz1/cmp_luasnip", -- Connects snippets to the menu
  {
    "L3MON4D3/LuaSnip",       -- The snippet engine
    dependencies = { "rafamadriz/friendly-snippets" }, -- The "Library" of actual snippets
    config = function()
      -- This line loads the library (React, Go, etc.)
      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },
})

-- 3. MASON & LSP CONFIGURATION
require("mason").setup()
require("mason-lspconfig").setup({
    -- Added the web servers here so Mason installs them automatically!
    ensure_installed = { "gopls", "vtsls", "tailwindcss", "emmet_language_server" }
})

-- GO Setup
vim.lsp.config("gopls", {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  root_markers = { "go.work", "go.mod", ".git" },
})
vim.lsp.enable("gopls")

-- React & Node.js (vtsls)
vim.lsp.config("vtsls", {
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  root_markers = { "package.json", "tsconfig.json", ".git" },
})
vim.lsp.enable("vtsls")

-- Tailwind CSS
vim.lsp.config("tailwindcss", {
  root_markers = { "tailwind.config.js", "tailwind.config.ts", "package.json" },
})
vim.lsp.enable("tailwindcss")

-- Emmet
vim.lsp.config("emmet_language_server", {
  filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less" },
})
vim.lsp.enable("emmet_language_server")

-- 4. AUTO-COMMANDS (Go Auto-import)
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.go",
  callback = function()
    local params = vim.lsp.util.make_range_params()
    params.context = {only = {"source.organizeImports"}}
    local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params)
    for cid, res in pairs(result or {}) do
      for _, r in pairs(res.result or {}) do
        if r.edit then
          vim.lsp.util.apply_workspace_edit(r.edit, "utf-16")
        else
          vim.lsp.buf.execute_command(r.command)
        end
      end
    end
    vim.lsp.buf.format({async = false})
  end,
})

-- 5. SETTINGS & KEYMAPS
vim.opt.number = true
vim.opt.mouse = 'a'
vim.opt.clipboard = 'unnamedplus'
vim.opt.wildmenu = true
vim.opt.wildmode = "longest:list,full"

-- Save with Ctrl + S (All modes)
vim.keymap.set({'n', 'i', 'v'}, '<C-s>', '<Cmd>w<CR>', { silent = true })

-- Terminal Escape
vim.keymap.set('t', '<Esc>', [[<C-\><C-n>]], { desc = 'Exit terminal mode' })

-- 6. AUTOCOMPLETE SETUP
local cmp = require('cmp')
local luasnip = require('luasnip')

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-Space>'] = cmp.mapping.complete(), -- Trigger menu manually
    ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Enter to select
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' }, -- Sugestions from gopls, vtsls, etc.
    { name = 'luasnip' },  -- Snippets (like log -> console.log)
    { name = 'buffer' },   -- Text from current file
    { name = 'path' },     -- File paths
  })
})