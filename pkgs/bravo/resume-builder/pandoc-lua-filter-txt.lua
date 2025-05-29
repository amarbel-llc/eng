
local columns = PANDOC_WRITER_OPTIONS.columns

function Pandoc(doc)
  local blocks = pandoc.List()
  blocks:insert(Banner())
  blocks:insert(HorizontalRule())
  blocks:insert(RawMarkdownBlock(""))
  blocks:extend(doc.blocks)
  doc.blocks = blocks
  doc.meta.trailer = Trailer()
  return doc
end

function Banner()
  -- local text = pandoc.pipe("figlet", {"-f", "threepoint", GetVar("name")}, "")
  return pandoc.Plain(
  RawMarkdownInline("\n" .. GetVar("name") .. "\n" .. GetVar("email"))
  )
end

function Header(el)
  return pandoc.List()
end

function CenterRaw(str)
  local padding = string.rep(" ", math.floor((columns - utf8.len(str)) / 2))
  return padding .. str .. padding
end

function Center(str)
  return pandoc.RawInline("markdown", CenterRaw(str))
end

function GetVar(key)
  return tostring(PANDOC_WRITER_OPTIONS.variables[key])
end

function RawMarkdownBlock(str)
  return pandoc.RawBlock("markdown", str)
end

function RawMarkdownInline(str)
  return pandoc.RawInline("markdown", str)
end

function Trailer()
  return pandoc.RawBlock(
  "markdown",
  table.concat(
  {
    HorizontalRuleRaw(),
    "",
    CenterRaw("last updated " .. GetVar("build-date")),
    CenterRaw(GetVar("github-url") .. "/releases/tag/v" .. GetVar("version")),
  },
  "\n"
  )
  )
end

function HorizontalRuleRaw()
  return string.rep("*", columns)
end

function HorizontalRule()
  return pandoc.RawInline("markdown", HorizontalRuleRaw())
end

function Span(s)
  return s.content
end

function RawBlock(s)
  return pandoc.List()
end

-- function BulletList(s)
--   local t = pandoc.List()

--   t:insert(RawMarkdownBlock("\n"))

--   for i, item in pairs(s.content) do
--     local t1 = pandoc.List()

--     for j, item1 in pairs(item) do
--       t1:insert(RawMarkdownBlock("- " .. pandoc.utils.stringify(item1)))
--     end

--     t:extend(t1)
--     -- t:extend{s.content, pandoc.Str("x"), pandoc.LineBreak()}
--   end

--   t:insert(RawMarkdownBlock("\n"))

--   return t
-- end

function TextWidth(x)
  local width = 0

  if x.t == "Str" then
    width = width + utf8.len(x.text)
  elseif x.t == "Space" then
    width = width + 1
  elseif x.t == "List" then
    for i, y in pairs(x) do
      width = width + TextWidth(y)
    end
  elseif type(x) == "table" then
    for i, y in pairs(x) do
      width = width + TextWidth(y)
    end
  else
    error("unknown type: " .. type(x))
  end

  return width
end

function Div(d)
  if not d.classes:includes("position-flex") then
    return d
  end

  local cells = d.content
  local buffer = pandoc.List()

  local each_cell = function(i, cell)
    local contents = cell.content

    if #contents ~= 1 then
      return
    end

    local local_buffer = pandoc.List()

    local_buffer:extend(cell.content[1].content)

    if i == 1 then
      local_buffer:insert(pandoc.Str(","))
    end

    buffer:insert(local_buffer)
  end

  for i, cell in pairs(cells) do
    each_cell(i, cell)
  end

  local row_width = TextWidth(buffer)
  local output = {}

  if row_width > columns then
    local new_buffer = {}

    for i, x in pairs(buffer) do
      if i == 1 then
        for j, y in pairs(x) do
          if y.t == "Str" then
            table.insert(output, y.text)
          elseif y.t == "Space" then
            table.insert(output, " ")
          end
        end

        table.insert(output, "\n")
      else
        table.insert(new_buffer, x)
      end
    end

    row_width = TextWidth(new_buffer)
    buffer = new_buffer
  end

  local adjusted_row_width = row_width + #buffer

  table.insert(
  buffer,
  #buffer,
  {pandoc.Str(string.rep(".", columns - adjusted_row_width))}
  )

  for i, x in pairs(buffer) do
    if i > 1 then
      table.insert(output, " ")
    end

    for j, y in pairs(x) do
      if y.t == "Space" then
        table.insert(output, " ")
      else
        table.insert(output, y.text)
      end
    end
  end

  return pandoc.RawBlock("markdown", table.concat(output, ""))
end
