local chipped = require("chipped")

local cases = {
	snake = function()
		chipped.snake_casing()
	end,
	normal = function()
		chipped.normal_casing()
	end,
	UPPER_SNAKE = function()
		chipped.upper_snake_casing()
	end,
	camel = function()
		chipped.camel_casing()
	end,
	proper = function()
		chipped.proper_casing()
	end,
	kebab = function()
		chipped.kebab_casing()
	end,
}

local subcommands = {

	-- connect <port?> <host?>
	connect = function(args)
		local port = args[1] and tonumber(args[1]) or nil
		local host = args[2]
		chipped.connect(port, host)
	end,

	-- disconnect <port?> <host?>
	disconnect = function(args)
		local port = args[1] and tonumber(args[1]) or nil
		local host = args[2]
		chipped.disconnect(port, host)
	end,

	enable_autoretry = function()
		chipped.set_autoretry(true)
	end,

	disable_autoretry = function()
		chipped.set_autoretry(false)
	end,

	-- send_msg <msg>
	send_msg = function(args)
		local msg = table.concat(args, " ")
		if msg == "" then
			vim.notify("Chipped: send_msg requires <msg>", vim.log.levels.ERROR)
			return
		end
		chipped.send_message(msg)
	end,

	clear_buffer = function()
		chipped.send_clear_buffer()
	end,

	-- set_main_buffer <text>
	set_main_buffer = function(args)
		local text = table.concat(args, " ")
		if text == "" then
			vim.notify("Chipped: set_main_buffer requires <text>", vim.log.levels.ERROR)
			return
		end
		chipped.send_set_main_buffer(text)
	end,

	-- set_right_buffer <text>
	set_right_buffer = function(args)
		local text = table.concat(args, " ")
		if text == "" then
			vim.notify("Chipped: set_right_buffer requires <text>", vim.log.levels.ERROR)
			return
		end
		chipped.send_set_right_buffer(text)
	end,

	-- set_case ["snake","normal","UPPER_SNAKE","camel","proper","kebab"]
	set_case = function(args)
		local case = args[1]
		if not case or not cases[case] then
			vim.notify(
				"Chipped: set_case must be one of snake, normal, UPPER_SNAKE, camel, proper, kebab",
				vim.log.levels.ERROR
			)
			return
		end
		cases[case]()
	end,

	reload_fuzzy_chips = function()
		chipped.reload_config()
	end,

	restart_fuzzy_chips = function()
		chipped.restart()
	end,
}

vim.api.nvim_create_user_command("Chipped", function(opts)
	local sub = opts.fargs[1]

	if not sub then
		vim.notify("Chipped: missing subcommand", vim.log.levels.ERROR)
		return
	end

	local fn = subcommands[sub]
	if not fn then
		vim.notify("Chipped: unknown subcommand '" .. sub .. "'", vim.log.levels.ERROR)
		return
	end

	fn(vim.list_slice(opts.fargs, 2))
end, {
	nargs = "*",
	complete = function(_, line)
		local words = vim.split(line, "%s+")
		if #words == 2 then
			return vim.tbl_keys(subcommands)
		end

		if #words == 3 and words[2] == "set_case" then
			return vim.tbl_keys(cases)
		end
	end,
})
