require'nvim-treesitter.configs'.setup {
  -- A list of parser names, or "all" (the listed parsers MUST always be installed)
  ensure_installed = { "c", "bash", "cmake", "clojure", "css", "comment","dockerfile", "diff", "editorconfig", "go", "rust", "graphql", "helm", "http", "jq", "json", "mermaid", "sway", "terraform", "tmux", "xml", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline", "python", "ruby" },
  sync_install = false,
  auto_install = true,
  ignore_install = { "javascript" },
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
}
