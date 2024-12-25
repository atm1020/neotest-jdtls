local lazypath = vim.fn.stdpath('data') .. '/lazy'
vim.notify = print
vim.opt.rtp:append('.')
vim.opt.rtp:append(lazypath .. '/plenary.nvim')
vim.opt.rtp:append(lazypath .. '/nvim-nio')
vim.opt.rtp:append(lazypath .. '/neotest')

vim.opt.swapfile = false
vim.cmd('runtime! plugin/plenary.vim')
A = function(...)
	print(vim.inspect(...))
end
