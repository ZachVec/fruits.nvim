# 🍇 fruit.nvim

A collection of QoL plugins for NeoVim!

## Moduels

| Fruit | Description |
| --------------- | --------------- |
| [highlight](https://github.com/ZachVec/fruits.nvim/blob/master/docs/highlight.md) | highlight lines in normal mode or by visual selection. |
| [mark](https://github.com/ZachVec/fruits.nvim/blob/master/docs/mark.md) | Create persistent marks for different repos and branches, integrated with neo-tree by default.  |

## Installation

```lua
{
  "ZachVec/fruits.nvim",
  opts = {
    highlight = { enable = true },
    mark = { enable = true }
  }
}
```

The configuration above is to enable the plugins, for more configurations, check
the hyperlinks in `Modules` section.
