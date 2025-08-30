-- Luacheck configuration for beam.nvim
globals = {
  "vim",
  "_G",
}

read_globals = {
  "describe",
  "it",
  "before_each",
  "after_each",
  "assert",
  "package",
}

ignore = {
  "212", -- Unused argument
  "213", -- Unused loop variable
}

files["test/*_spec.lua"] = {
  std = "+busted",
}