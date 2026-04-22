-- Summarize Plenary busted stdout as a grouped, context-deduplicated tree.
--
-- Usage:
--   nvim --headless -u NONE -l summarize_plenary_output.lua -- <path> [<suite_name>]

local default_suite_name = "Plenary"
local esc = string.char(27)

local function argv_tokens()
  local t = {}
  if type(arg) ~= "table" then return t end
  for i = 1, #arg do
    local v = arg[i]
    if v and v ~= "" and v ~= "--" then t[#t + 1] = v end
  end
  return t
end

local tokens = argv_tokens()
local input_path = tokens[1]
local suite_name = (tokens[2] and tokens[2] ~= "") and tokens[2] or default_suite_name

local function read_all(path)
  if type(path) == "string" and path ~= "" then
    local f = assert(io.open(path, "rb"))
    local s = assert(f:read("*a"))
    f:close()
    return s
  end
  return assert(io.read("*a"))
end

local function strip_ansi(s)
  return (s:gsub(esc .. "%[[0-9;]*[A-Za-z]", ""))
end

-- ── path helpers ─────────────────────────────────────────────────────────────

local function short_path(full)
  local after = full:match("[/\\]tests[/\\](.+)$")
  if after then
    after = (after:gsub("\\", "/"))
    after = after:gsub("^menu_resolution/", "")
    after = after:gsub("%.lua$", "")
    return after
  end
  return (full:match("[^/\\]+$") or full):gsub("%.lua$", "")
end

-- ── string / prefix helpers ───────────────────────────────────────────────────

local function raw_lcp(a, b)
  local n = math.min(#a, #b)
  for i = 1, n do
    if a:sub(i, i) ~= b:sub(i, i) then return a:sub(1, i - 1) end
  end
  return a:sub(1, n)
end

-- Word-boundary LCP of exactly two strings.
local function word_lcp2(a, b)
  if a == "" or b == "" then return "" end
  local p = raw_lcp(a, b)
  -- When one string is an exact prefix of the other, p equals the shorter one —
  -- return it as-is so the prefix relationship is not lost by stripping its last word.
  if p == a or p == b then return p end
  return p:match("^(.*) ") or ""
end

-- Word-boundary LCP of a list of strings.
local function word_lcp(strs)
  if #strs < 2 then return "" end
  local p = strs[1]
  for i = 2, #strs do
    p = raw_lcp(p, strs[i])
    if p == "" then return "" end
  end
  return p:match("^(.*) ") or ""
end

local function strip_prefix(s, prefix)
  if prefix == "" then return s end
  local rest = s:sub(#prefix + 1)
  return rest:match("^%s*(.-)%s*$") or rest
end

-- ── section grouping ──────────────────────────────────────────────────────────
-- Two spec files belong in the same section when one file's context is a
-- word-boundary prefix of the other's (same outer describe, one has extra
-- inner-describe words baked in).  Merge iteratively; the section heading
-- narrows to the shorter of the two contexts.

local function merge_groups(specs)
  -- Each group: { section_ctx=string, files={spec,...} }
  local order = {}   -- insertion-ordered list of current section_ctx keys
  local groups = {}  -- section_ctx -> group

  local function find_and_merge(ctx)
    for _, key in ipairs(order) do
      if key == ctx then
        -- Exact match (includes both being "").
        return key, key
      end
      -- Only merge non-empty contexts where one is a word-boundary prefix of the other.
      if key ~= "" and ctx ~= "" then
        local lcp = word_lcp2(key, ctx)
        if lcp == key or lcp == ctx then
          return key, lcp   -- (old key, new narrowed key)
        end
      end
    end
    return nil, ctx
  end

  for _, s in ipairs(specs) do
    local old_key, new_key = find_and_merge(s.ctx)

    if old_key then
      local g = groups[old_key]
      if new_key ~= old_key then
        -- Re-key the group to the narrowed context.
        groups[new_key] = g
        groups[old_key] = nil
        for i, k in ipairs(order) do
          if k == old_key then order[i] = new_key; break end
        end
        g.section_ctx = new_key
      end
      g.files[#g.files + 1] = s
    else
      order[#order + 1] = new_key
      groups[new_key] = { section_ctx = new_key, files = { s } }
    end
  end

  local result = {}
  for _, key in ipairs(order) do
    result[#result + 1] = groups[key]
  end
  return result
end

-- ── sub-grouping within a spec file ──────────────────────────────────────────
-- After stripping the section context, consecutive test names that share a
-- word-boundary prefix get a sub-heading so the shared part isn't repeated.

local function subgroup(strs)
  local groups = {}
  local i = 1
  while i <= #strs do
    local run_end = i
    local run_pfx = nil
    for j = i + 1, #strs do
      -- Compute the prefix shared by strs[i] and strs[j], and ensure it is
      -- consistent across all items i..j collected so far.
      local p = word_lcp2(strs[i], strs[j])
      if p == "" then break end
      for k = i + 1, j - 1 do
        local q = word_lcp2(strs[i], strs[k])
        if q == "" then p = ""; break end
        if #q < #p then p = q end
      end
      if p == "" then break end
      run_end = j
      run_pfx = p
    end

    if run_pfx and run_end > i then
      local items = {}
      for k = i, run_end do
        items[#items + 1] = strip_prefix(strs[k], run_pfx)
      end
      groups[#groups + 1] = { heading = run_pfx, items = items }
      i = run_end + 1
    else
      groups[#groups + 1] = { heading = "", items = { strs[i] } }
      i = i + 1
    end
  end
  return groups
end

-- ── plenary output parser ─────────────────────────────────────────────────────

local function parse_blocks(clean)
  local blocks = {}
  local sep = "========================================"
  local current = nil
  for line in clean:gmatch("[^\r\n]+") do
    local t = line:match("^%s*(.-)%s*$")
    if t == sep then
      if current then blocks[#blocks + 1] = current end
      current = { lines = {} }
    elseif current then
      current.lines[#current.lines + 1] = line
    end
  end
  if current then blocks[#blocks + 1] = current end
  return blocks
end

local function parse_block(block)
  local r = { path = nil, pass = 0, fail = 0, errors = 0, tests = {} }
  for _, line in ipairs(block.lines) do
    local path = line:match("Testing:%s+(.-)%s*$")
    if path and path ~= "" then r.path = path end

    local status, name = line:match("^(Success)%s+%|%|%s+(.-)%s*$")
    if not status then status, name = line:match("^(Fail)%s+%|%|%s+(.-)%s*$") end
    if status and name and name ~= "" then
      r.tests[#r.tests + 1] = { ok = (status == "Success"), name = name }
    end

    local p = line:match("Success:%s+(%d+)")
    if p then r.pass = r.pass + tonumber(p) end
    local f = line:match("Failed%s*:%s+(%d+)")
    if f then r.fail = r.fail + tonumber(f) end
    local e = line:match("Errors%s*:%s+(%d+)")
    if e then r.errors = r.errors + tonumber(e) end
  end
  return r
end

-- ── main ──────────────────────────────────────────────────────────────────────

local raw   = read_all(input_path)
local clean = strip_ansi(raw)

local blocks = parse_blocks(clean)
local specs  = {}
for _, block in ipairs(blocks) do
  local r = parse_block(block)
  if r.path then
    -- Per-file context: word-boundary LCP of all test names in this file.
    local names = {}
    for _, t in ipairs(r.tests) do names[#names + 1] = t.name end
    r.ctx = word_lcp(names)
    specs[#specs + 1] = r
  end
end

local sections = merge_groups(specs)

local total_pass, total_fail, total_errors = 0, 0, 0

io.write(string.format("\n=== %s ===\n", suite_name))

for _, section in ipairs(sections) do
  local sctx = section.section_ctx

  if sctx ~= "" then
    io.write(string.format("\n%s\n", sctx))
  else
    io.write("\n")
  end

  for _, s in ipairs(section.files) do
    total_pass   = total_pass   + s.pass
    total_fail   = total_fail   + s.fail
    total_errors = total_errors + s.errors

    -- Strip the section context so all files within a section share the same
    -- stripping baseline.
    local short_names   = {}
    local short_statuses = {}
    for _, t in ipairs(s.tests) do
      short_names[#short_names + 1]    = strip_prefix(t.name, sctx)
      short_statuses[#short_statuses + 1] = t.ok
    end

    local grps = subgroup(short_names)
    local si   = 1
    for _, g in ipairs(grps) do
      if g.heading ~= "" then
        io.write(string.format("  %s\n", g.heading))
        for _, item in ipairs(g.items) do
          io.write(string.format("    %s  %s\n", short_statuses[si] and "o" or "x", item))
          si = si + 1
        end
      else
        for _, item in ipairs(g.items) do
          io.write(string.format("  %s  %s\n", short_statuses[si] and "o" or "x", item))
          si = si + 1
        end
      end
    end
  end
end

io.write(string.format("\n  %d/%d passed", total_pass, total_pass + total_fail))
if total_errors > 0 then
  io.write(string.format("  (%d suite error(s))", total_errors))
end
io.write(string.format("  ·  %d spec file(s)\n", #specs))

vim.cmd("qa!")
