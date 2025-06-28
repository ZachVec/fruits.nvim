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
    },
    keys = {
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
      {
        "<leader>;f",  -- configure this!
        function()
          require("neo-tree.sources.backtrace").selectFlow()
        end,
        desc = "select workflow",
      },
      {
        "<leader>;a",  -- configure this!
        function()
          require("neo-tree.sources.backtrace").addMark()
        end,
        desc = "add mark to current workflow",
      },
    },
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = function(_, opts)
      table.insert(opts.sources, "backtrace")
      opts.backtrace = {
        renderers = {
          flow = {
            { "indent" },
            { "icon" },
            { "name" },
          },
          mark = {
            { "indent" },
            { "icon" },
            { "name" },
          },
        },
      }
    end,
  },
}
```

## Usage

1. Create flow.
2. Select flow.
3. Add mark to the selected flow.
4. Add, rename, delete the flows or marks as you wish!

## TODO

- [ ] persistence the marks
- [ ] bugfix
