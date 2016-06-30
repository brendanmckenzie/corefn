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

function split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
   table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end

function split_path(str)
 return split(str,'[\\/]+')
end

-- 1. map request to function
local path = split_path(ngx.var.uri)
fnmod = path[1]
fnfunc = path[2]
fnmod = string.lower(fnmod, '')
fnmod = string.gsub(fnmod, '%A', '')

local docker_image = 'corefn/' .. fnmod
-- TODO: map function to integral representation
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
