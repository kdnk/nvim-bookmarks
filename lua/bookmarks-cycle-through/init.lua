local M = {}

local list_map = function(list, map)
	local new_list = {}
	for index, value in ipairs(list) do
		table.insert(new_list, map(value, index))
	end
	return new_list
end

local list_find_index = function(list, target)
	for index, value in ipairs(list) do
		if target == value then
			return index
		end
	end
	return nil
end

local goto_file_line = function(file_index, line_index)
	local file = vim.fn["bm#all_files"]()[file_index]
	local bufnr = vim.fn.bufnr(file, true)
	vim.api.nvim_set_current_buf(bufnr)

	local win_id = vim.api.nvim_get_current_win()

	local lines = list_map(vim.fn["bm#all_lines"](file), function(line)
		return tonumber(line)
	end)
	table.sort(lines)

	local line = lines[line_index]
	vim.api.nvim_win_set_cursor(win_id, { line, 0 })
end

function M.bookmark_toggle()
	if not M.latest_file_index then
		M.latest_file_index = list_find_index(vim.fn["bm#all_files"](), vim.api.nvim_buf_get_name(0))
		M.latest_line_index = vim.api.nvim_win_get_cursor(0)[1]
	end
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Plug>BookmarkToggle", true, true, true), "n", true)
end

function M.cycle_through(reverse)
	local max_file_count = #vim.fn["bm#all_files"]()

	if max_file_count == 0 then
		print("No bookmark")
		return
	end

	local file = vim.fn["bm#all_files"]()[M.latest_file_index or 1]
	local max_line_count = #vim.fn["bm#all_lines"](file)

	if M.latest_file_index == nil then
		M.latest_file_index = 1
	end

	if M.latest_line_index == nil then
		M.latest_line_index = 1
	end

	if not reverse then
		if max_file_count <= M.latest_file_index then
			if max_line_count <= M.latest_line_index then
				M.latest_file_index = 1
				M.latest_line_index = 1
			else
				M.latest_line_index = M.latest_line_index + 1
			end
		else
			if max_line_count <= M.latest_line_index then
				M.latest_file_index = M.latest_file_index + 1
				M.latest_line_index = 1
			else
				M.latest_line_index = M.latest_line_index + 1
			end
		end
	else
		if M.latest_file_index == 1 then
			if M.latest_line_index == 1 then
				M.latest_file_index = max_file_count
				M.latest_line_index = #vim.fn["bm#all_lines"](vim.fn["bm#all_files"]()[M.latest_file_index])
			else
				M.latest_line_index = M.latest_line_index - 1
			end
		else
			if M.latest_line_index == 1 then
				M.latest_file_index = M.latest_file_index - 1
				M.latest_line_index = #vim.fn["bm#all_lines"](vim.fn["bm#all_files"]()[M.latest_file_index])
			else
				M.latest_line_index = M.latest_line_index - 1
			end
		end
	end

	goto_file_line(M.latest_file_index, M.latest_line_index)
end

return M
