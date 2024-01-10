
local final_opts = {}
local options  = {
  guicursor = "i:ver35-blinkwait1-blinkoff600-blinkon600-InsertModeCursor,r:hor20-InsertMode,v:block-blinkwait1-blinkoff200-blinkon1000-VisualModeCursor",

  autoindent = true,
  relativenumber = true,

  backspace = "indent,eol,start",
  smarttab = true,

  showcmd = true,
  autowrite = true,
  autoread = true,

  incsearch = true,
  inccommand = "nosplit",

  scrolloff = 1,
  sidescrolloff = 5,

  wrap = false,
  list = true,
  listchars = "tab:» ,extends:►,precedes:◄,nbsp:·,trail:▒,",

  -- This helps `projections` fully restore the session
  sessionoptions = vim.opt.sessionoptions:append("localoptions")
  -- cmdheight = 20,
  -- cmdwinheight = 20,
}

-- Is windows?
vim.g.is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win32unix") == 1

-- Set shell to bash or powershell
if vim.g.is_windows then
  local woptions = {}

  -- USE BASH! (WSL)
  if true then
    woptions = { shell = "bash", shellcmdflag = "-c" }
  else
    woptions = {
      shell = "powershell",
      shellquote = "shellpipe=| shellxquote=",
      shellcmdflag = "-NoLogo -ExecutionPolicy RemoteSigned",
      shellredir = "| Out-File -Encoding UTF8",
    }
  end
  final_opts = vim.tbl_extend("force", options, woptions)
else
  final_opts = options
end

-- Set all options
for k,v in pairs(final_opts) do
  vim.opt[k] = v
end


