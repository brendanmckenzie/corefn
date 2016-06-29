local socket = require 'socket'

function exec(cmd)
    -- ngx.log(ngx.ERR, 'executing: ' .. cmd)

    local fd = assert(io.popen(cmd, 'r'))
    local ret = assert(fd:read('*a'))
    fd:close()

    return ret:gsub("^%s*(.-)%s*$", "%1")
end

-- TODO:
-- 1. map request to function
local docker_image = 'testing'
local func = [[\xFF\xFF\xFF\x7F]]

-- 2. spin up docker image
local docker_container = exec('docker run -d -p 6543 '.. docker_image)

-- 3. get port for docker container
local docker_container_port = exec('docker inspect --format=\'{{(index (index .NetworkSettings.Ports "6543/tcp") 0).HostPort}}\' ' .. docker_container)

-- 4. wait for it to be ready
local fd = assert(io.popen('docker logs -f ' .. docker_container))
while true do
    s = fd:read('*l'):gsub("^%s*(.-)%s*$", "%1")
    if s == 'Listening on port 6543' then break end
end

-- extract host/port info
local host = '127.0.0.1'
local port = tonumber(string.sub(docker_container_port_info, port_delim + 1))

ngx.req.read_body()

local data = ngx.req.get_body_data()

-- sleep(1)

c = assert(socket.connect(host, port))

if data == nil then
    data = ''
end

local packet = [[\x0F\x0A]] .. func .. [[\xFF\xAA]] .. data .. [[\x00\x00\x00\x00]]
packet_bin = packet:gsub("\\x(%x%x)",function (x) return string.char(tonumber(x,16)) end)
c:send(packet_bin)

ret = c:receive('*a')

c:close()

ngx.say(ret)
ngx.eof()

os.execute('docker kill ' .. docker_container)
os.execute('docker rm ' .. docker_container)
