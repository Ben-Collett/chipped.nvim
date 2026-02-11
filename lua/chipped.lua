local DEFAULT_PORT = 8765
local DEFAULT_HOST = "127.0.0.1"
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
local function host_port_id(port, host)
	return host .. " " .. tostring(port)
end
local function split_host_port_id(id)
	local host, port = id:match("^(.-)%s+(%d+)$")
	return host, tonumber(port)
end
function M.connect(port, host)
	port = port or DEFAULT_PORT
	host = host or DEFAULT_HOST
	local id = host_port_id(port, host)
	local socket = vim.loop.new_tcp()
	socket:connect(host, port, function(err)
		if err then
			my_log("Failed to connect to port " .. port .. ": " .. err)
			socket:close()
			failed_connections[id] = true
		else
			my_log("connected to port " .. port)
			sockets[id] = socket
			failed_connections[id] = nil
		end
	end)
end

function M.reconnect(port, host)
	port = port or DEFAULT_PORT
	host = host or DEFAULT_HOST
	local id = host_port_id(port, host)
	local socket = vim.loop.new_tcp()
	socket:connect(host, port, function(err)
		if err then
			socket:close()
			failed_connections[id] = true
		else
			sockets[id] = socket
			failed_connections[id] = nil
			my_log("reconnected to port " .. port)
		end
	end)
end

function M.disconnect(port, host)
	port = port or DEFAULT_PORT
	host = host or DEFAULT_HOST
	local id = host_port_id(port, host)
	local socket = sockets[id]

	sockets[id] = nil
	failed_connections[id] = nil

	if socket then
		my_log("disconnecting" .. host .. " " .. port)
		socket:close()
	end
end
local function _retry_failed_connections()
	for id, _ in pairs(failed_connections) do
		local host, port = split_host_port_id(id)
		M.reconnect(port, host)
	end
end
function M.send_message(msg)
	local formatted_msg = msg:len() .. "\n" .. msg
	if autoretry_enabled then
		_retry_failed_connections()
	end

	for id, socket in pairs(sockets) do
		socket:write(formatted_msg, function(err)
			if err then
				my_log("lost connection to " .. id .. ": " .. err)
				sockets[id] = nil
				socket:close()
				failed_connections[id] = true
			end
		end)
	end
end

function M.send_clear_buffer()
	M.send_message("cb")
end
function M.send_set_main_buffer(content)
	M.send_message("sm " .. content)
end
function M.send_set_right_buffer(content)
	M.send_message("sr " .. content)
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
function M.kebab_casing()
	M.send_message("kb")
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
