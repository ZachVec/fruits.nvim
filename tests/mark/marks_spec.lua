describe("MarkTest", function()
  local Mark = require("fruits.mark.marks")
  local Path = require("plenary.path")

  --- @type Path
  local Data = Path:new(require("plenary.path"):new(""):absolute()):joinpath("testdata")
  Data:mkdir({ parents = true, exist_ok = true })
  --- @type Path
  local File = Data:joinpath("mark.txt")

  local ns_id

  before_each(function()
    local content = { "Hello World" }
    File:write(table.concat(content, "\n"), "w")
    ns_id = vim.api.nvim_create_namespace("MarkTest")
  end)

  after_each(function()
    ns_id = nil
  end)

  it("SimpleTest", function()
    vim.cmd.edit(File:absolute())
    local mark = Mark.new(File:absolute(), "Mark", 0, 6)
    mark:attach(ns_id, 0)
    assert.are_equal(File:absolute(), mark.path)

    -- Delete "Hello ", now we get "World"
    vim.api.nvim_buf_set_text(0, 0, 0, 0, ("Hello "):len(), {})
    local texts = vim.api.nvim_buf_get_lines(0, 0, 1, true)
    assert.are.True(#texts > 0)
    assert.are.equal(texts[1], "World")
    assert.are.True(mark:detach(ns_id))
    assert.are.equal(mark.lnum, 0)
    assert.are.equal(mark.cnum, 0)
  end)

  Data:rm({ recursive = true })
end)
