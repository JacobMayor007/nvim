local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    vim.fn.system({"git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable",
                   lazypath})
end
vim.opt.rtp:prepend(lazypath)

-- =========================================================================
-- SET LEADER KEY FIRST! (This must come before any <leader> keymaps)
-- =========================================================================
vim.g.mapleader = " " -- Set Space as the leader key
vim.g.maplocalleader = " "

-- 2. INSTALL PLUGINS
require("lazy").setup({"neovim/nvim-lspconfig", {
    "williamboman/mason.nvim",
    config = function()
        require("mason").setup()
    end
}, {
    "williamboman/mason-lspconfig.nvim",
    config = function()
        require("mason-lspconfig").setup({
            ensure_installed = {"gopls", "ts_ls", "tailwindcss", "emmet_language_server"}
        })
    end
}, {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    config = function()
        require("mason-tool-installer").setup({
            ensure_installed = {"prettier"}
        })
    end
}, {
    "NvChad/nvim-colorizer.lua",
    opts = {
        user_default_options = {
            tailwind = true
        }
    }
}, -- --- AUTOCOMPLETE PLUGINS ---
"hrsh7th/nvim-cmp", "hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-buffer", "hrsh7th/cmp-path", "saadparwaiz1/cmp_luasnip", {
    "L3MON4D3/LuaSnip",
    dependencies = {"rafamadriz/friendly-snippets"},
    config = function()
        require("luasnip.loaders.from_vscode").lazy_load()
    end
}, {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = {"nvim-tree/nvim-web-devicons"},
    config = function()
        require("nvim-tree").setup({
            filters = {
                dotfiles = false, -- This shows .env, .gitignore, etc.
                git_ignored = false -- This shows files even if they are in .gitignore
            },
            view = {
                width = 35,
                relativenumber = true
            },
            renderer = {
                group_empty = true,
                highlight_opened_files = "all"
            }
        })
    end
}, "nvimtools/none-ls.nvim", "nvim-lua/plenary.nvim", -- ========== ADD THIS: TOGGLETERM (Better Terminal!) ==========
{
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
        require("toggleterm").setup({
            size = 20,
            open_mapping = [[<c-\>]], -- Ctrl + \ to toggle terminal
            hide_numbers = true,
            shade_terminals = true,
            start_in_insert = true,
            insert_mappings = true,
            terminal_mappings = true,
            persist_size = true,
            direction = "float", -- Options: 'vertical' | 'horizontal' | 'tab' | 'float'
            close_on_exit = true,
            shell = vim.o.shell,
            float_opts = {
                border = "curved", -- Options: 'single' | 'double' | 'shadow' | 'curved'
                width = 120,
                height = 30
            }
        })
    end
}})

-- =========================================================================
-- DIAGNOSTICS CONFIGURATION - SHOW ERRORS IN INSERT MODE TOO!
-- =========================================================================
vim.diagnostic.config({
    virtual_text = true,
    signs = true,
    underline = true,
    update_in_insert = true,
    severity_sort = true
})

-- Error icons in the gutter
local signs = {
    Error = "E",
    Warn = "W",
    Hint = "H",
    Info = "I"
}
for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, {
        text = icon,
        texthl = hl,
        numhl = hl
    })
end

-- =========================================================================
-- 3. GET LSP CAPABILITIES
-- =========================================================================
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- 4. LSP SERVER CONFIGURATION
-- GO Setup
vim.lsp.config("gopls", {
    cmd = {"gopls"},
    filetypes = {"go", "gomod", "gowork", "gotmpl"},
    root_markers = {"go.work", "go.mod", ".git"},
    capabilities = capabilities
})
vim.lsp.enable("gopls")

-- React & Node.js (ts_ls)
vim.lsp.config("ts_ls", {
    filetypes = {"javascript", "javascriptreact", "typescript", "typescriptreact"},
    root_markers = {"package.json", "tsconfig.json", ".git"},
    capabilities = capabilities
})
vim.lsp.enable("ts_ls")

-- Tailwind CSS
vim.lsp.config("tailwindcss", {
    root_markers = {"tailwind.config.js", "tailwind.config.ts", "package.json"},
    capabilities = capabilities
})
vim.lsp.enable("tailwindcss")

-- Emmet
vim.lsp.config("emmet_language_server", {
    filetypes = {"html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less"},
    capabilities = capabilities
})
vim.lsp.enable("emmet_language_server")

-- =========================================================================
-- PRETTIER SETUP (Auto-format on save for JS/TS/React)
-- =========================================================================
local null_ls = require("null-ls")
null_ls.setup({
    sources = {null_ls.builtins.formatting.prettier.with({
        filetypes = {"javascript", "javascriptreact", "typescript", "typescriptreact", "css", "scss", "html", "json",
                     "yaml", "markdown"}
    })}
})

-- Auto-format on save for JS/TS/React files
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = {"*.js", "*.jsx", "*.ts", "*.tsx", "*.css", "*.scss", "*.html", "*.json"},
    callback = function()
        vim.lsp.buf.format({
            async = false
        })
    end
})

-- =========================================================================
-- AUTO-COMMANDS (Go Auto-import & format)
-- =========================================================================
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*.go",
    callback = function()
        local params = vim.lsp.util.make_range_params()
        params.context = {
            only = {"source.organizeImports"}
        }
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
        vim.lsp.buf.format({
            async = false
        })
    end
})

-- =========================================================================
-- 6. SETTINGS & KEYMAPS
-- =========================================================================
vim.opt.number = true
vim.opt.mouse = 'a'
vim.opt.clipboard = 'unnamedplus'
vim.opt.wildmenu = true
vim.opt.wildmode = "longest:list,full"
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

-- Save with Ctrl + S (All modes)
vim.keymap.set({'n', 'i', 'v'}, '<C-s>', '<Cmd>w<CR>', {
    silent = true
})

-- 7. AUTOCOMPLETE SETUP
local cmp = require('cmp')
local luasnip = require('luasnip')

cmp.setup({
    snippet = {
        expand = function(args)
            luasnip.lsp_expand(args.body)
        end
    },
    mapping = cmp.mapping.preset.insert({
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<CR>'] = cmp.mapping.confirm({
            select = true
        }),
        ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
            else
                fallback()
            end
        end, {'i', 's'})
    }),
    sources = cmp.config.sources({{
        name = 'nvim_lsp'
    }, {
        name = 'luasnip'
    }, {
        name = 'buffer'
    }, {
        name = 'path'
    }})
})

-- =========================================================================
-- LSP KEYMAPS - NAVIGATION & DIAGNOSTICS
-- =========================================================================

-- Go to Definition
vim.keymap.set('n', '<C-CR>', vim.lsp.buf.definition, {
    desc = 'Go to definition'
})
vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {
    desc = 'Go to definition'
})

-- Go back after jumping
vim.keymap.set('n', '<C-o>', '<C-o>', {
    desc = 'Jump back'
})

-- Show hover info
vim.keymap.set('n', 'K', vim.lsp.buf.hover, {
    desc = 'Show hover info'
})

-- Find references
vim.keymap.set('n', 'gr', vim.lsp.buf.references, {
    desc = 'Find references'
})

-- Rename
vim.keymap.set('n', '<F2>', vim.lsp.buf.rename, {
    desc = 'Rename symbol'
})

-- Show error details
vim.keymap.set('n', '<C-e>', vim.diagnostic.open_float, {
    desc = 'Show error details'
})

-- Jump to next/previous error
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, {
    desc = 'Next error'
})
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, {
    desc = 'Previous error'
})

-- Show all errors in file
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, {
    desc = 'Show all errors'
})

-- Manual format
vim.keymap.set('n', '<S-A-f>', vim.lsp.buf.format, {
    desc = 'Format document'
})

-- =========================================================================
-- TERMINAL KEYMAPS (TOGGLETERM)
-- =========================================================================

-- Toggle floating terminal with Ctrl + \
-- (This is already set in toggleterm config, but you can add more)

-- Additional terminal shortcuts
vim.keymap.set({'n', 'i', 't'}, '<C-S-`>', '<cmd>ToggleTerm direction=float<cr>', {
    desc = 'Toggle terminal'
})

-- Alternative notation (some terminals prefer this)
vim.keymap.set({'n', 'i', 't'}, '<C-~>', '<cmd>ToggleTerm direction=float<cr>', {
    desc = 'Toggle terminal'
})

-- Additional options
vim.keymap.set('n', '<leader>tf', '<cmd>ToggleTerm direction=float<cr>', {
    desc = 'Floating terminal'
})
vim.keymap.set('n', '<leader>th', '<cmd>ToggleTerm direction=horizontal<cr>', {
    desc = 'Horizontal terminal'
})
vim.keymap.set('n', '<leader>tv', '<cmd>ToggleTerm direction=vertical<cr>', {
    desc = 'Vertical terminal'
})
-- =========================================================================
-- OTHER KEYMAPS
-- =========================================================================

-- Undo with Ctrl + Z in Insert Mode
vim.keymap.set('i', '<C-z>', '<Cmd>undo<CR>', {
    desc = 'Undo'
})

-- Redo with Ctrl + Y
vim.keymap.set('i', '<C-y>', '<Cmd>redo<CR>', {
    desc = 'Redo'
})

-- Select All
vim.keymap.set({'n', 'i', 'v'}, '<C-a>', '<Esc>ggVG', {
    desc = 'Select All'
})

-- Press Ctrl + n to open/close the file tree
vim.keymap.set('n', '<C-n>', ':NvimTreeToggle<CR>', {
    silent = true
})

vim.keymap.set('i', '<C-z>', '<Cmd>undo<CR>', {
    desc = 'Undo'
})

-- Redo with Ctrl + Y
vim.keymap.set('i', '<C-y>', '<Cmd>redo<CR>', {
    desc = 'Redo'
})

-- Select All
vim.keymap.set({'n', 'i', 'v'}, '<C-a>', '<Esc>ggVG', {
    desc = 'Select All'
})

-- CUT (Ctrl + X) - Works like VS Code!
vim.keymap.set('v', '<C-x>', '"+d', {
    desc = 'Cut to clipboard'
})
vim.keymap.set('n', '<C-x>', '"+dd', {
    desc = 'Cut line to clipboard'
})

-- COPY (Ctrl + C) - Already works with clipboard setting, but making it explicit
vim.keymap.set('v', '<C-c>', '"+y', {
    desc = 'Copy to clipboard'
})
vim.keymap.set('n', '<C-c>', '"+yy', {
    desc = 'Copy line to clipboard'
})

-- PASTE (Ctrl + V) - Paste from clipboard
vim.keymap.set({'n', 'v', 'i'}, '<C-v>', '<C-r>+', {
    desc = 'Paste from clipboard'
})

-- Press Ctrl + n to open/close the file tree
vim.keymap.set('n', '<C-n>', ':NvimTreeToggle<CR>', {
    silent = true
})
