local mod = {}
local redis = require 'resty.redis'

redis.add_commands('expire')

local redis_host_ip = nil
local docker_host_ip = nil -- '172.17.0.1'
local docker_host = nil

function mod.split(str, pat)
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

-- TODO: deprecate. use env var
function mod.lookup_host(host)
  return mod.exec("getent hosts " .. host .. " | awk '{ print $1 }'")
end

function mod.exec(cmd)
  local fd = assert(io.popen(cmd, 'r'))
  local ret = assert(fd:read('*a'))
  fd:close()

  return ret:gsub('^%s*(.-)%s*$', '%1')
end

function mod.run_docker_image(image)
  -- spin up docker image
  local container = mod.exec('docker -H ' .. docker_host .. ' run -d -p 6543 --label=corefn=true '.. image)

  -- 4. wait for it to be ready
  -- TODO: add a timeout to this so it doesn't wait forever
  local fd = assert(io.popen('docker -H ' .. docker_host .. ' logs -f ' .. container))
  while true do
      s = fd:read('*l'):gsub('^%s*(.-)%s*$', '%1')
      if s == 'Listening on port 6543' then break end
  end

  return container
end

function mod.get_docker_port(container)
  local port = mod.exec('docker -H ' .. docker_host .. ' inspect --format=\'{{(index (index .NetworkSettings.Ports "6543/tcp") 0).HostPort}}\' ' .. container)

  return tonumber(port)
end

function mod.image_port(image)
  if redis_host_ip == nil then
    redis_host_ip = mod.lookup_host('redis')
  end

  local red = redis:new()
  local red_ok, err = red:connect(redis_host_ip, 6379)
  if not red_ok then
    ngx.log(ngx.ERR, 'failed to connect to redis')
  end

  -- avoid race condition
  lock_key = 'lock:' .. image
  lock, err = red:get(lock_key)
  while lock == '1' do
    lock, err = red:get(lock_key)
  end
  red:set(lock_key, '1')

  local container = nil

  if red_ok then
    container, err = red:get(image)
    if container then
      if container == ngx.null then
        ngx.log(ngx.NOTICE, 'container not found.')
        container = nil
      else
        red:expire(container, 60)
        red:expire(image, 60)
      end
    end
  end

  if not container then
    container = mod.run_docker_image(image)

    red:set(image, container)
    red:set(container, image)
    red:expire(container, 60)
    red:expire(image, 60)
  end

  red:del(lock_key)

  return mod.get_docker_port(container)
end

function mod.split_path(str)
 return mod.split(str,'[\\/]+')
end

function mod.file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

function mod.int_to_bytes(n)
  if n > 2147483647 then error(n.." is too large",2) end
  if n < -2147483648 then error(n.." is too small",2) end
  -- adjust for 2's complement
  n = (n < 0) and (4294967296 + n) or n
  return (math.modf(n / 16777216)) % 256,
         (math.modf(n / 65536)) % 256,
         (math.modf(n / 256)) % 256,
         n % 256
end

docker_host_ip = mod.exec("ip route list | head -n 1 | awk '{ print $3 }'")
docker_host = 'tcp://' .. docker_host_ip .. ':2375'

mod.docker_host_ip = docker_host_ip

return mod
