return {

	{ "nvim-tree/nvim-web-devicons", lazy = true },
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate", -- Ensures parsers are updated on installation
		opts = {
			highlight = { enable = true },
			indent = { enable = true },
			-- Add other features like folds, textobjects, etc. as needed
		},
		config = function(_, opts)
			require("nvim-treesitter.configs").setup(opts)
		end,
	},
	{
		'nvim-telescope/telescope.nvim', tag = '0.1.8',
		opts = {},
		dependencies = { 'nvim-lua/plenary.nvim' }
	},
	{ "neovim/nvim-lspconfig", lazy = false },
	         
}
