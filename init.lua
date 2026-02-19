-- This is working fine
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
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
        vim.cmd([[colorscheme tokyonight-night]])
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
                dotfiles = false,
                git_ignored = false
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
}, "nvimtools/none-ls.nvim", "nvim-lua/plenary.nvim", -- ========== TOGGLETERM ==========
{
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
        require("toggleterm").setup({
            size = 20,
            open_mapping = [[<c-\>]],
            hide_numbers = true,
            shade_terminals = true,
            start_in_insert = true,
            insert_mappings = true,
            terminal_mappings = true,
            persist_size = true,
            direction = "float",
            close_on_exit = true,
            shell = vim.o.shell,
            float_opts = {
                border = "curved",
                width = 120,
                height = 30
            }
        })
    end
}})

-- =========================================================================
-- DIAGNOSTICS CONFIGURATION
-- =========================================================================
vim.diagnostic.config({
    virtual_text = true,
    signs = true,
    underline = true,
    update_in_insert = false, -- CHANGED FROM true TO false
    severity_sort = true
})

-- Error icons
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
-- 3. LSP SERVER CONFIGURATION
-- =========================================================================
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- GO Setup
vim.lsp.config("gopls", {
    cmd = {"gopls"},
    filetypes = {"go", "gomod", "gowork", "gotmpl"},
    root_markers = {"go.work", "go.mod", ".git"},
    capabilities = capabilities
})
vim.lsp.enable("gopls")

-- React & Node.js
-- React & Node.js (vtsls)
vim.lsp.config("ts_ls", {
    filetypes = {"javascript", "javascriptreact", "typescript", "typescriptreact"},
    root_markers = {"package.json", "tsconfig.json", ".git"},
    capabilities = capabilities,
    settings = {
        typescript = {
            updateImportsOnFileMove = {
                enabled = "always"
            }
        },
        javascript = {
            updateImportsOnFileMove = {
                enabled = "always"
            }
        }
    }
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
-- PRETTIER & FORMATTING
-- =========================================================================
local null_ls = require("null-ls")
null_ls.setup({
    sources = {null_ls.builtins.formatting.prettier.with({
        filetypes = {"javascript", "javascriptreact", "typescript", "typescriptreact", "css", "scss", "html", "json",
                     "yaml", "markdown"}
    })}
})

-- Auto-format JS/TS/React on save
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = {"*.js", "*.jsx", "*.ts", "*.tsx", "*.css", "*.scss", "*.html", "*.json"},
    callback = function()
        vim.lsp.buf.format({
            async = false
        })
    end
})

-- =========================================================================
-- AUTO-COMMANDS
-- =========================================================================

-- 1. Go Auto-import & format
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

-- 2. AUTO-JUMP TO ERROR ON SAVE (The feature you asked for!)
vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = "*",
    callback = function()
        -- Check if there are any 'Error' level diagnostics
        local diagnostics = vim.diagnostic.get(0, {
            severity = vim.diagnostic.severity.ERROR
        })
        if #diagnostics > 0 then
            -- If errors found, jump to the first one
            vim.diagnostic.goto_next({
                severity = vim.diagnostic.severity.ERROR,
                wrap = true
            })
            -- Optional: Force open the float window so you see the message immediately
            vim.diagnostic.open_float()
        end
    end
})

-- =========================================================================
-- 6. SETTINGS
-- =========================================================================
vim.opt.number = true
vim.opt.mouse = 'a'
vim.opt.clipboard = 'unnamedplus'
vim.opt.wildmenu = true
vim.opt.wildmode = "longest:list,full"
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

-- =========================================================================
-- 7. AUTOCOMPLETE SETUP
-- =========================================================================
local cmp = require('cmp')
local luasnip = require('luasnip')

cmp.setup({
    snippet = {
        expand = function(args)
            luasnip.lsp_expand(args.body)
        end
    },
    mapping = cmp.mapping.preset.insert({
        ['<C-Space>'] = cmp.mapping.complete(), -- The standard one
        ['<C-n>'] = cmp.mapping.complete(), -- BACKUP: Ctrl + n
        ['<A-Space>'] = cmp.mapping.complete(), -- BACKUP: Alt + Space

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
    -- This ensures the list pops up automatically as you type
    completion = {
        completeopt = 'menu,menuone,noinsert'
    },
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
-- KEYMAPS
-- =========================================================================

-- Navigation
vim.keymap.set('n', '<C-CR>', vim.lsp.buf.definition, {
    desc = 'Go to definition'
})

vim.keymap.set('n', '<C-o>', '<C-o>', {
    desc = 'Jump back'
})
vim.keymap.set('n', 'K', vim.lsp.buf.hover, {
    desc = 'Show hover info'
})

vim.keymap.set('n', 'gr', vim.lsp.buf.references, {
    desc = 'Find references'
})

vim.keymap.set('n', '<F2>', vim.lsp.buf.rename, {
    desc = 'Rename symbol'
})

-- Diagnostics (Manual Jumping)
vim.keymap.set('n', '<C-e>', vim.diagnostic.open_float, {
    desc = 'Show error details'
})
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, {
    desc = 'Next error'
})
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, {
    desc = 'Previous error'
})
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, {
    desc = 'Show all errors'
})

-- Terminal (ToggleTerm)
vim.keymap.set({'n', 'i', 't'}, '<C-S-`>', '<cmd>ToggleTerm direction=float<cr>', {
    desc = 'Toggle terminal'
})
vim.keymap.set({'n', 'i', 't'}, '<C-~>', '<cmd>ToggleTerm direction=float<cr>', {
    desc = 'Toggle terminal'
})

-- Editing Shortcuts
vim.keymap.set('n', '<C-s>', '<Cmd>w<CR>', {
    silent = true
})
vim.keymap.set('i', '<C-s>', '<Cmd>w<CR>', {
    silent = true
})

-- Undo/Redo
vim.keymap.set('i', '<C-z>', '<Cmd>undo<CR>', {
    desc = 'Undo'
})
vim.keymap.set('i', '<C-y>', '<Cmd>redo<CR>', {
    desc = 'Redo'
})

-- Cut/Copy/Paste
vim.keymap.set({'n', 'i', 'v'}, '<C-a>', '<Esc>ggVG', {
    desc = 'Select All'
})
vim.keymap.set({'n', 'v'}, '<C-x>', '"+d', {
    desc = 'Cut'
})
vim.keymap.set({'n', 'v'}, '<C-c>', '"+y', {
    desc = 'Copy'
})

-- File Tree
vim.keymap.set('n', '<C-n>', ':NvimTreeToggle<CR>', {
    silent = true
})

vim.keymap.set('n', '<C-q>', '<C-u>', {
    desc = 'Scroll up half page'
})

vim.keymap.set('n', '<leader><space>', ':nohlsearch<CR>', {
    desc = "Clear search highlights"
})

vim.keymap.set('i', '<A-\\>', '<Esc>:', {
    desc = "Run command from insert mode"
})

-- 1. Word Navigation (Ctrl + Left/Right)
-- We use <C-o> to run one normal mode command (b=back, w=word) then stay in insert
vim.keymap.set('i', '<C-Left>', '<C-o>b', {
    desc = 'Jump back word'
})
vim.keymap.set('i', '<C-Right>', '<C-o>w', {
    desc = 'Jump forward word'
})

-- 2. Line Navigation (Home/End)
-- Note: We use <C-o>^ for start (ignoring whitespace) and <C-o>$ for end
vim.keymap.set('i', '<Home>', '<C-o>^', {
    desc = 'Go to start of text'
})
vim.keymap.set('i', '<End>', '<C-o>$', {
    desc = 'Go to end of line'
})

-- 3. Selection / Visual Behavior (Shift + Arrows)
-- These allow you to start selecting text immediately from Insert Mode
-- Note: <Esc>v enters Visual Mode, then we move the cursor
vim.keymap.set('i', '<S-Left>', '<Esc>v<Left>', {
    desc = 'Select Left'
})

vim.keymap.set('i', '<S-Right>', '<Esc>v<Right>', {
    desc = 'Select Right'
})

-- In Normal Mode, press Space + r
-- This prompts you: Enter old word, Enter new word
vim.keymap.set('n', '<leader>r', ":%s/<C-r><C-w>//g<Left><Left>", {
    desc = "Rename word under cursor"
})

-- =========================================================================
-- TRIGGER CMP IN NORMAL MODE
-- =========================================================================

-- We use cmp.mapping.complete() to open the menu
vim.keymap.set('n', '<A-m>', function()
    require('cmp').complete()
end, {
    desc = 'Trigger completion menu'
})

