-- 1. BOOTSTRAP LAZY.NVIM (The Plugin Manager)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- 2. INSTALL PLUGINS
require("lazy").setup({
  "neovim/nvim-lspconfig", -- Required for your Go Auto-import code
  "williamboman/mason.nvim", -- The "App Store" for servers
  "williamboman/mason-lspconfig.nvim", -- Bridges Mason and Lspconfig
})

-- 3. SETUP THE GO BRAIN (gopls)
require("mason").setup()
require("mason-lspconfig").setup({
    ensure_installed = { "gopls" }
})
require("lspconfig").gopls.setup({})

-- 4. YOUR AUTO-IMPORT LOGIC
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
vim.opt.clipboard = 'unnamedplus' -- Makes Ctrl+C/V work with Windows!

-- Save with Ctrl + S (All modes)
vim.keymap.set({'n', 'i', 'v'}, '<C-s>', '<Cmd>w<CR>', { silent = true })

-- Terminal Escape
vim.keymap.set('t', '<Esc>', [[<C-\><C-n>]], { desc = 'Exit terminal mode' })

-- Folder filtering
vim.opt.wildmenu = true
vim.opt.wildmode = "longest:list,full"