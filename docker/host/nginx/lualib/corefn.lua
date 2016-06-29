local redis = require 'resty.redis'

local docker_host_ip = '172.17.0.1'
local docker_host = 'tcp://' .. docker_host_ip .. ':2375'

function exec(cmd)
    local fd = assert(io.popen(cmd, 'r'))
    local ret = assert(fd:read('*a'))
    fd:close()

    return ret:gsub('^%s*(.-)%s*$', '%1')
end

function run_docker_image(image)
  -- spin up docker image
  local container = exec('docker -H ' .. docker_host .. ' run -d -p 6543 '.. image)

  -- 4. wait for it to be ready
  local fd = assert(io.popen('docker -H ' .. docker_host .. ' logs -f ' .. container))
  while true do
      s = fd:read('*l'):gsub('^%s*(.-)%s*$', '%1')
      if s == 'Listening on port 6543' then break end
  end

  return container
end

function get_docker_port(container)
  local port = exec('docker -H ' .. docker_host .. ' inspect --format=\'{{(index (index .NetworkSettings.Ports "6543/tcp") 0).HostPort}}\' ' .. container)

  return tonumber(port)
end

function image_port(image)
  local container = nil

  local red = redis:new()
  local ok, err = red:connect('172.17.0.3', 6379)
  if not ok then
    ngx.log(ngx.ERR, 'failed to connect to redis')
  else
    container, err = red:get(image)
    if container then
      if container == ngx.null then
        ngx.log(ngx.NOTICE, 'container not found.')
        container = nil
      else
        red:set(container .. ':last_hit', os.time())
      end
    end
  end

  if not container then
    container = run_docker_image(image)

    red:set(image, container)
  end

  return get_docker_port(container)
end

-- TODO:
-- 1. map request to function
local docker_image = 'testing'
local func = [[\xFF\xFF\xFF\x7F]]

ngx.req.read_body()

local data = ngx.req.get_body_data()

if data == nil then
    data = ''
end

port = image_port(docker_image)

local sock = ngx.socket.tcp()
local ok, err = sock:connect(docker_host_ip, port)

local packet = [[\x0F\x0A]] .. func .. [[\xFF\xAA]] .. data .. [[\x00\x00\x00\x00]]
packet_bin = packet:gsub('\\x(%x%x)',function (x) return string.char(tonumber(x,16)) end)

local bytes, err = sock:send(packet_bin)

ret = sock:receive('*a')

sock:close()

ngx.say(ret)
ngx.eof()
