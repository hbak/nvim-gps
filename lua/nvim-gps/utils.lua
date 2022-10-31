local ts_utils = require("nvim-treesitter.ts_utils")
local ts_parsers = require "nvim-treesitter.parsers"

local M = {}

function M.get_node_text(node)
	local bufnr = vim.api.nvim_get_current_buf()

	-- We have to remember that end_col is end-exclusive
	local start_row, start_col, end_row, end_col = ts_utils.get_node_range(node)

	if start_row ~= end_row then
		local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
		lines[1] = string.sub(lines[1], start_col + 1)
		-- end_row might be just after the last line. In this case the last line is not truncated.
		if #lines == end_row - start_row + 1 then
			lines[#lines] = string.sub(lines[#lines], 1, end_col)
		end
		return lines
	else
		local line = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1]
		-- If line is nil then the line is empty
		return line and { string.sub(line, start_col + 1, end_col) } or {}
	end
end

function M.get_node_at_coords(bufnr, coords, ignore_injected_langs)
  local root_lang_tree = ts_parsers.get_parser(bufnr)
  if not root_lang_tree then
    return
  end

  local root
  if ignore_injected_langs then
    for _, tree in ipairs(root_lang_tree:trees()) do
      local tree_root = tree:root()
      if tree_root and ts_utils.is_in_node_range(tree_root, coords[1], coords[2]) then
        root = tree_root
        break
      end
    end
  else
    root = ts_utils.get_root_for_position(coords[1], coords[2], root_lang_tree)
  end

  if not root then
    return
  end

  return root:named_descendant_for_range(coords[1], coords[2], coords[1], coords[2])
end

return M
