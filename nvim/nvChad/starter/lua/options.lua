
local final_opts = {}
local options  = {
  guicursor = "i:ver35-blinkwait1-blinkoff600-blinkon600-InsertModeCursor,r:hor20-InsertMode,v:block-blinkwait1-blinkoff200-blinkon1000-VisualModeCursor",

  linespace = 6,

  autoindent = true,
  relativenumber = true,
  statuscolumn="  %=%l %s ",

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
}

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


