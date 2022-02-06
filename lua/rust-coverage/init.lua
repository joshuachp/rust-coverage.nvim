---
-- Reads the output file of the Tarpaulin tool and decodes it into a lua array
local M = {}

--- Utils to create a floating terminal
local utils = require("rust-coverage.utils")

local COVERAGE_COMMAND = "cargo tarpaulin"
local OUTPUT_OPTIONS = "-o json --output-dir"
local OUTPUT_PATH = "/tmp/tarpaulin_coverage/"

--- Global map of file path mapped to table of lines and times a test covered it
M.SIGN_MAP = {}

--- Places a sign on the given line
---
--- @param file string
--- @param line number
local function make_sign_dictionary(file, line)
  local opt = vim.empty_dict()

  opt["name"] = "rustCoverage"
  opt["buffer"] = file
  opt["lnum"] = line

  return opt
end

--- Loads a coverage file and returns the coverage data
---
--- @param input string
--- @return table?, string?
local function load_coverage(input)
  local json_file, err = io.open(input, "r")

  if json_file == nil then
    return nil, err
  end

  local content = json_file:read("*a")

  json_file:close()

  local coverage_data = vim.fn.json_decode(content)

  if coverage_data == nil then
    return nil, "Could not decode json file."
  end

  local sign_map = {}

  for _, file in ipairs(coverage_data["files"]) do
    local path = vim.fn.resolve(table.concat(file["path"], "/"):sub(2))
    local sign_list = {}

    for _, value in ipairs(file["traces"]) do
      local coverage = value["stats"]["Line"]

      if coverage > 0 then
        local line = value["line"]
        table.insert(sign_list, make_sign_dictionary(path, line))
      end
    end

    sign_map[path] = sign_list
  end

  return sign_map, nil
end

--- Define the sign to highlight a covered line
function M.define_sign()
  local opt = vim.empty_dict()
  --- Use nvim diff highlight
  opt["linehl"] = "DiffAdd"

  vim.fn.sign_define("rustCoverage", opt)
end

--- Set the signs for the covered lines of the current buffer
--- @param self any
function M.set_signs(self)
  local sign_list = self.SIGN_MAP[vim.fn.expand("%:p")]

  if sign_list == nil then
    return
  end

  vim.fn.sign_placelist(sign_list)
end

--- Runs the code coverage in a floating terminal
function M.generate_coverage(self)
  local out_dir = OUTPUT_PATH .. vim.fn.getcwd()
  local cmd = string.format("%s %s %s", COVERAGE_COMMAND, OUTPUT_OPTIONS, out_dir)
  local out_file = out_dir .. "/" .. "tarpaulin-report.json"

  utils.float_term_cmd(cmd, false, function() self.SIGN_MAP = load_coverage(out_file) end)
end

--- Defines the sign and the autocmd to set them
function M.setup()
  M.define_sign()

  vim.cmd([[
    augroup RustCodeCoverage
      autocmd!
      autocmd BufEnter *.rs lua require('rust-coverage'):set_signs()
    augroup END
    command RustCoverage lua require('rust-coverage'):generate_coverage()
  ]])
end

return M
