--- Function utilities to work with nvim api
local M = {}

--- Open a floating a new floating window
-- @param options The command to execute
function M.new_float_window(margin, style)
  margin = margin or 20
  style = style or "minimal"
  -- Get the current UI to center the float
  local ui = vim.api.nvim_list_uis()[1]
  local height = ui.height - margin
  local width = ui.width - margin
  -- Create a new scratch buffer
  local buf = vim.api.nvim_create_buf(false, true)
  local config = {
    relative = "editor",
    width = width,
    height = height,
    row = margin / 2,
    col = margin / 2,
    style = style,
  }
  local win = vim.api.nvim_open_win(buf, true, config)
  vim.api.nvim_input('i')
  return buf, win
end

--- Open a floating terminal with the command
--- @param cmd string The command to execute
--- @param close_win boolean Boolean to close the window if the cmd returned 0
--- @param callback function?
--- @return number job-id
function M.float_term_cmd(cmd, close_win, callback)
  -- Create a new scratch buffer
  local _, win = M.new_float_window()
  local options = vim.empty_dict()

  options.on_exit = function(_, exit_code, _)
    if close_win then
      if exit_code == 0 then
        vim.api.nvim_win_close(win, false)
      end
    end

    if callback ~= nil then
      callback()
    end
  end

  return vim.fn.termopen(cmd, options)
end

return M
