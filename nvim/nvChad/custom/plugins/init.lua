
local glob_require = require("custom.functions.globRequire").glob_require

-- Find all files in plugins dir and merge
return glob_require("custom/plugins")
