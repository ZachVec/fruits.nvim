# neo-tree-backtrace

neo-tree-backtrace is a Neovim plugin to track your chain of thought.
You can create any number of workflows and marks to track the codes
being executed at runtime.

## installation

lazy plugin manager:

```lua
return {
  {
    dir = "ZachVec/backtrace.nvim",
    dependencies = {
      "nvim-neo-tree/neo-tree.nvim",
      "stevearc/aerial.nvim",
    },
    keys = {
      -- map <leader>et to toggle MarkExplorer
      {
        "<leader>et",
        function()
          require("neo-tree.command").execute({
            source = "backtrace",
            toggle = true,
          })
        end,
        desc = "MarkExplorer",
      },
      -- map <leader>cm to add mark into flow
      {
        "<leader>cm",
        function()
          require("neo-tree.sources.backtrace").add_mark()
        end,
        desc = "Add Mark",
      },
    },
  },

  -- add backtrace into neo-tree sources
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = function(_, opts)
      table.insert(opts.sources, "backtrace")
      return opts
    end,
  },
}
```

## Usage

1. Create flow: press `a` in explorer to create flow on default.
2. Choose flow: press `c` in explorer to choose flow.
3. Add marks: press the key you configured to add marks to the selected flow.
4. Add, rename, delete the flows or marks in the explorer as you wish!

## TODO

- [ ] bugfix
