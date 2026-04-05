local ipc = require("chipped")
ipc.set_autoretry(true)
ipc.connect()

local last_insert_line = nil

local function get_left_right_buffers()
	local _, col = unpack(vim.api.nvim_win_get_cursor(0))
	local line = vim.api.nvim_get_current_line()

	local left = line:sub(1, col)
	local right = line:sub(col + 1)

	return left, right
end

local function update_buffers()
	local left, right = get_left_right_buffers()
	ipc.send_set_main_buffer(left)
	ipc.send_set_right_buffer(right)
end

local group = vim.api.nvim_create_augroup("IPCInsertTracking", { clear = true })

vim.api.nvim_create_autocmd("InsertEnter", {
	group = group,
	callback = function()
		last_insert_line = vim.api.nvim_win_get_cursor(0)[1]
		update_buffers()
	end,
})

vim.api.nvim_create_autocmd("CursorMovedI", {
	group = group,
	callback = function()
		local current_line = vim.api.nvim_win_get_cursor(0)[1]
		if current_line ~= last_insert_line then
			last_insert_line = current_line
			update_buffers()
		end
	end,
})

vim.on_key(function(key)
	local mode = vim.api.nvim_get_mode().mode
	local m = mode:sub(1, 1)

	if m == "i" then
		if key == "<Del>" or key:match("^<[CMDA]%-") then
			update_buffers()
		end
		return
	end

	if m == "c" or m == "t" then
		return
	end

	ipc.send_clear_buffer()
end, vim.api.nvim_create_namespace("ipc_cb"))
