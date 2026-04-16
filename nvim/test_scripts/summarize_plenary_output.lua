-- Summarize Plenary busted stdout (one or more spec files).
--
-- Usage:
--   nvim --headless -u NONE -l summarize_plenary_output.lua -- <path> [<suite_name>]
--   nvim --headless -u NONE -l summarize_plenary_output.lua --
--       (no path: read stdin; default suite name)
--
-- Leading `--` entries in `arg` are ignored. If <suite_name> is omitted, the banner
-- uses the default name below.

local default_suite_name = "Plenary"

local esc = string.char(27)

-- Neovim may include `--` in `arg`; strip it so `nvim -l script.lua -- path suite` works.
local function argv_tokens()
  local t = {}
  if type(arg) ~= "table" then
    return t
  end
  for i = 1, #arg do
    local v = arg[i]
    if v and v ~= "" and v ~= "--" then
      t[#t + 1] = v
    end
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

local function sum_gmatch(s, pattern)
  local n = 0
  for v in s:gmatch(pattern) do
    n = n + tonumber(v)
  end
  return n
end

-- Match `grep -c 'Testing:'`: one count per line that contains the marker.
local function count_testing_lines(s)
  local c = 0
  for line in s:gmatch("[^\r\n]+") do
    if line:find("Testing:", 1, true) then
      c = c + 1
    end
  end
  return c
end

local raw = read_all(input_path)
local clean = strip_ansi(raw)

local files = count_testing_lines(clean)
local pass = sum_gmatch(clean, "Success:%s+(%d+)")
local fail = sum_gmatch(clean, "Failed%s*:%s+(%d+)")
local errs = sum_gmatch(clean, "Errors%s*:%s+(%d+)")
local total = pass + fail

io.write(string.format("\n--- %s test summary ---\n", suite_name))
io.write(string.format("  Spec files:           %d\n", files))
io.write(string.format("  Passed (it blocks):   %d\n", pass))
io.write(string.format("  Failed (it blocks):   %d\n", fail))
io.write(string.format("  Errors (suite-level): %d\n", errs))
io.write(string.format("  Total it blocks:      %d\n", total))
io.write("-----------------------------\n")

vim.cmd("qa!")
