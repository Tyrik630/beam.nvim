rockspec_format = "3.0"
package = "beam.nvim"
version = "scm-1"

source = {
  url = "git://github.com/Piotr1215/beam.nvim"
}

dependencies = {
  "lua >= 5.1",
}

test_dependencies = {
  "busted",
}

test = {
  type = "busted",
  busted = {
    root = "test",
  }
}

build = {
  type = "builtin",
  modules = {}
}