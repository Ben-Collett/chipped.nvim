local M = {}

local sockets = {}
local failed_connections = {}
local autoretry_enabled = false

local function my_log(msg)
	print(msg)
end
function M.set_autoretry(enabled)
	autoretry_enabled = enabled
end

function M.connect(port)
	local socket = vim.loop.new_tcp()
	socket:connect("127.0.0.1", port, function(err)
		if err then
			my_log("Failed to connect to port " .. port .. ": " .. err)
			socket:close()
			failed_connections[port] = true
		else
			my_log("connected to port " .. port)
			sockets[port] = socket
			failed_connections[port] = nil
		end
	end)
end

function M.reconnect(port)
	local socket = vim.loop.new_tcp()
	socket:connect("127.0.0.1", port, function(err)
		if err then
			socket:close()
			failed_connections[port] = true
		else
			sockets[port] = socket
			failed_connections[port] = nil
			my_log("reconnected to port " .. port)
		end
	end)
end

function M.disconnect(port)
	local socket = sockets[port]

	sockets[port] = nil
	failed_connections[port] = nil

	if socket then
		my_log("disconnecting" .. port)
		socket:close()
	end
end
local function _retry_failed_connections()
	for port, _ in pairs(failed_connections) do
		M.reconnect(port)
	end
end
function M.send_msg(msg)
	local formatted_msg = msg:len() .. "\n" .. msg
	if autoretry_enabled then
		_retry_failed_connections()
	end

	for port, socket in pairs(sockets) do
		socket:write(formatted_msg, function(err)
			if err then
				my_log("lost connection to port " .. port .. ": " .. err)
				sockets[port] = nil
				socket:close()
				failed_connections[port] = true
			end
		end)
	end
end

function M.send_clear_buffer()
	M.send_msg("cb")
end
function M.send_set_main_buffer(content)
	M.send_msg("sm " .. content)
end
function M.send_set_right_buffer(content)
	M.send_msg("sr " .. content)
end
function M.connected_ports() end

function M.normal_casing()
	M.send_message("mc")
end

function M.snake_casing()
	M.send_message("sc")
end
function M.proper_casing()
	M.send_message("pm")
end
function M.camel_casing()
	M.send_message("cm")
end
function M.upper_snake_casing()
	M.send("us")
end

function M.reload_config()
	M.send("rl")
end
function M.restart()
	M.send("rs")
end

function M.set_main_buffer(text)
	M.send_message("sm " .. text)
end
function M.set_right_buffer(text)
	M.send_message("sr " .. text)
end
return M
