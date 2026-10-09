local M = {}

local uv = vim.uv or vim.loop

local function canonical(path)
  if not path or path == "" then return path end
  local normalized = vim.fs.normalize(path)
  local real = uv and uv.fs_realpath(normalized)
  if real then
    return vim.fs.normalize(real)
  end
  local dir = vim.fs.dirname(normalized)
  if dir and dir ~= normalized then
    local real_dir = uv and uv.fs_realpath(dir)
    if real_dir then
      return vim.fs.normalize(real_dir) .. "/" .. vim.fs.basename(normalized)
    end
  end
  return normalized
end

-- Helper to replace a prefix case-insensitively while preserving remainder
local function try_replace(target, prefix, replacement)
  if not prefix or prefix == "" then return nil end
  local p_prefix = prefix:sub(-1) == "/" and prefix or (prefix .. "/")
  if target:lower() == prefix:lower() or target:lower() == (prefix .. "/"):lower() then
    return replacement
  end
  if vim.startswith(target:lower(), p_prefix:lower()) then
    return replacement .. "/" .. target:sub(#p_prefix + 1)
  end
  return nil
end

function M.collapse_home(path)
  if not path or path == "" then return "" end
  local p = vim.fs.normalize(path)

  local home = vim.fs.normalize(vim.fn.expand("~"))
  local c_home = canonical(home)

  -- 1. Known OneDrive CloudStorage folders on macOS (e.g. ~/Library/CloudStorage/OneDrive-.../Documents -> ~/Documents)
  local docs_real = canonical(home .. "/Documents")
  local desktop_real = canonical(home .. "/Desktop")
  local onedrive_real = canonical(home .. "/OneDrive")

  local replaced_known = try_replace(p, docs_real, "~/Documents")
    or try_replace(p, desktop_real, "~/Desktop")
    or try_replace(p, onedrive_real, "~/OneDrive")
  if replaced_known then
    p = replaced_known
  end

  -- 2. Collapse standard or canonical home to ~
  local replaced_home = try_replace(p, home, "~") or try_replace(p, c_home, "~")
  if replaced_home then
    p = replaced_home
  end

  -- 3. In case p still contains ~/Library/CloudStorage/OneDrive-<tenant>/...
  local cloud_docs = p:match("^~/[Ll]ibrary/[Cc]loud[Ss]torage/[Oo]ne[Dd]rive%-[^/]+/[Dd]ocuments/(.*)$")
  if cloud_docs then
    return "~/Documents/" .. cloud_docs
  end

  local cloud_desktop = p:match("^~/[Ll]ibrary/[Cc]loud[Ss]torage/[Oo]ne[Dd]rive%-[^/]+/[Dd]esktop/(.*)$")
  if cloud_desktop then
    return "~/Desktop/" .. cloud_desktop
  end

  local cloud_onedrive = p:match("^~/[Ll]ibrary/[Cc]loud[Ss]torage/[Oo]ne[Dd]rive%-[^/]+/(.*)$")
  if cloud_onedrive then
    return "~/OneDrive/" .. cloud_onedrive
  end

  return p
end

function M.is_external_repo(bufpath)
  if not bufpath or bufpath == "" then return false end
  local cwd = vim.fs.normalize(vim.fn.getcwd())
  local norm_path = vim.fs.normalize(bufpath)
  local c_cwd = canonical(cwd)
  local c_path = canonical(norm_path)

  local current_git = vim.fs.root(cwd, { ".git" })
  local c_current_git = vim.fs.root(c_cwd, { ".git" })
  local file_git = vim.fs.root(norm_path, { ".git" })
  local c_file_git = vim.fs.root(c_path, { ".git" })

  local git_root = current_git or c_current_git
  local buf_git_root = file_git or c_file_git

  if git_root then
    if buf_git_root then
      local same_git = (current_git and file_git and vim.fs.normalize(current_git):lower() == vim.fs.normalize(file_git):lower())
        or (c_current_git and c_file_git and vim.fs.normalize(c_current_git):lower() == vim.fs.normalize(c_file_git):lower())
      if not same_git then
        return true
      end
    end

    local norm_git = current_git and vim.fs.normalize(current_git)
    local norm_c_git = c_current_git and vim.fs.normalize(c_current_git)

    local is_inside_git = (norm_git and (vim.startswith(norm_path:lower(), (norm_git .. "/"):lower()) or norm_path:lower() == norm_git:lower()))
      or (norm_c_git and (vim.startswith(c_path:lower(), (norm_c_git .. "/"):lower()) or c_path:lower() == norm_c_git:lower()))

    return not is_inside_git
  end

  local is_inside_cwd = vim.startswith(norm_path:lower(), (cwd .. "/"):lower()) or norm_path:lower() == cwd:lower()
    or vim.startswith(c_path:lower(), (c_cwd .. "/"):lower()) or c_path:lower() == c_cwd:lower()

  return not is_inside_cwd
end

function M.get_relative_path(bufpath)
  if not bufpath or bufpath == "" then return "[No Name]" end
  local norm_path = vim.fs.normalize(bufpath)
  local cwd = vim.fs.normalize(vim.fn.getcwd())
  local c_norm_path = canonical(norm_path)
  local c_cwd = canonical(cwd)

  local git_root = vim.fs.root(cwd, { ".git" })
  local c_git_root = vim.fs.root(c_cwd, { ".git" })
  local root = git_root and vim.fs.normalize(git_root) or cwd
  local c_root = c_git_root and vim.fs.normalize(c_git_root) or c_cwd

  -- 1. Standard fnamemodify relative to cwd
  local rel = vim.fs.normalize(vim.fn.fnamemodify(bufpath, ":."))
  if rel ~= "" and rel ~= "." and not vim.startswith(rel, "../") and not vim.startswith(rel, "/") and not rel:find("^[a-zA-Z]:") then
    return rel
  end

  local function strip_prefix(p, prefix)
    local p_prefix = prefix:sub(-1) == "/" and prefix or (prefix .. "/")
    if vim.startswith(p:lower(), p_prefix:lower()) then
      local sub = p:sub(#p_prefix + 1)
      if sub ~= "" then
        return sub
      end
    end
    return nil
  end

  -- 2. Strip git root prefix (raw or canonical)
  if git_root then
    local sub = strip_prefix(norm_path, root)
    if sub then return sub end
  end

  if c_git_root then
    local sub = strip_prefix(c_norm_path, c_root)
    if sub then return sub end
  end

  -- 3. Strip cwd prefix (raw or canonical)
  local sub_cwd = strip_prefix(norm_path, cwd) or strip_prefix(c_norm_path, c_cwd)
  if sub_cwd then return sub_cwd end

  -- 4. Outside project / repo: collapse home to ~
  local collapsed = M.collapse_home(norm_path)
  if collapsed ~= norm_path then
    return collapsed
  end

  return rel ~= "" and M.collapse_home(rel) or vim.fs.basename(norm_path)
end

-- Files whose name alone says little, so their folder is shown as part of the name
local generic_stems = { init = true, index = true, __init__ = true, mod = true }

-- "a/b/c/file.lua" -> "file.lua", "a/b/c"; "a/b/c/init.lua" -> "c/init.lua", "a/b"
-- dir is "" when there's nothing left to show
function M.split_display(path)
  path = M.collapse_home(path)
  local dir, file = path:match("^(.*)/([^/]+)$")
  if not dir then return path, "" end

  local stem = file:match("^(.-)%.") or file
  if generic_stems[stem] then
    local parent_dir, parent = dir:match("^(.*)/([^/]+)$")
    if dir ~= "~" then
      file = (parent or dir) .. "/" .. file
      dir = parent_dir or ""
    end
  end

  return file, dir
end

-- "a/b/c/file.lua" -> "file.lua [a/b/c]", "a/b/c/init.lua" -> "c/init.lua [a/b]"
function M.format_display(path)
  local file, dir = M.split_display(path)
  return dir ~= "" and string.format("%s [%s]", file, dir) or file
end

-- Path to show for a buffer: relative to the project, or absolute if it's outside it
function M.display_path(bufname)
  if M.is_external_repo(bufname) then
    return M.collapse_home(bufname), true
  end
  return M.get_relative_path(bufname), false
end

return M
