local glob_require = require("functions.globRequire").glob_require

-- Find all files in plugins dir and merge
return glob_require("plugins", true)
