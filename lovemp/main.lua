local socket = require "socket"

-- the address and port of the server
local address, port = "localhost", 12345

local entity -- entity is what we'll be controlling
local updaterate = 0.1 -- how long to wait, in seconds, before requesting an update

local world = {} -- the empty world-state
local t


function love.load()
    udp = socket.udp()
	udp:settimeout(0)
	udp:setpeername(address, port)
	math.randomseed(os.time())
    entity = tostring(math.random(99999))
	local dg = string.format("%s %s %d %d", entity, 'at', 320, 240)
    udp:send(dg) -- the magic line in question.
   
    -- t is just a variable we use to help us with the update rate in love.update.
    t = 0 -- (re)set t to 0
	
	player = {
        grid_x = 256,
        grid_y = 256,
        act_x = 200,
        act_y = 200,
        speed = 10
    }
end

function love.update(deltatime)
    t = t + deltatime -- increase t by the deltatime
   
    --if t > updaterate then
		local dg = string.format("%s %s %f %f", entity, 'move', player.act_x, player.act_y)  -- Skicka move
		udp:send(dg)
		t=t-updaterate -- set t for the next round
	--end
	
	repeat  -- Här tar vi emot skit
        data, msg = udp:receive()

        if data then -- you remember, right? that all values in lua evaluate as true, save nil and false?
		ent, cmd, parms = data:match("^(%S*) (%S*) (.*)")
        if cmd == 'at' then
            local x, y = parms:match("^(%-?[%d.e]*) (%-?[%d.e]*)$")
			assert(x and y)
            x, y = tonumber(x), tonumber(y)
            world[ent] = {x=x, y=y}
			else
                print("unrecognised command:", cmd)
            end
			elseif msg ~= 'timeout' then
            error("Network error: "..tostring(msg))
        end
    until not data
	
	player.act_y = player.act_y - ((player.act_y - player.grid_y) * player.speed * deltatime)
    player.act_x = player.act_x - ((player.act_x - player.grid_x) * player.speed * deltatime)
end

function love.keypressed(key)
    if key == "up" then
        player.grid_y = player.grid_y - 32
    elseif key == "down" then
        player.grid_y = player.grid_y + 32
    elseif key == "left" then
        player.grid_x = player.grid_x - 32
    elseif key == "right" then
        player.grid_x = player.grid_x + 32
    end
end

function table.tostring( tbl )
	local result, done = {}, {}
	for k, v in ipairs( tbl ) do
		table.insert( result, table.val_to_str( v ) )
		done[ k ] = true
	end
	for k, v in pairs( tbl ) do
    if not done[ k ] then
		table.insert( result,
		table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
	end
	end
	return "{" .. table.concat( result, "," ) .. "}"
end

function love.draw()
love.graphics.print(table.tostring(world), 10, 10)
love.graphics.rectangle("fill", player.act_x, player.act_y, 32, 32)
    -- pretty simple, we
    for k, v in pairs(world) do
	    love.graphics.rectangle("fill", v.x, v.y, 32, 32)
        love.graphics.print(k, v.x, v.y)
    end
end

