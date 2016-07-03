local cjson = require 'cjson'
local fn = require 'lualib/functions'

print ('######## --------')

local manifest_root = '/var/func/manifest'

-- 1. map request to function
local path = fn.split_path(ngx.var.uri)
local account = path[1]
local fnmod = path[2]
local fnfunc = path[3]
if (account == nil) then
  ngx.status = 404
  ngx.say('no account specified')
  ngx.exit(ngx.HTTP_NOT_FOUND)
  return
end
if (fnmod == nil or fnfunc == nil) then
  ngx.status = 404
  ngx.say('no function specified')
  ngx.exit(ngx.HTTP_NOT_FOUND)
  return
end

local manifest_fd = io.open(manifest_root .. '/' .. account .. '/' .. fnmod .. '.json', 'r')
if manifest_fd == nil then
  ngx.status = 404
  ngx.say('function manifest not found')
  ngx.exit(ngx.HTTP_NOT_FOUND)
  return
end
local manifest_raw = manifest_fd:read('*a')
local manifest = cjson.decode(manifest_raw)

local func_id = nil
for i, fn in ipairs(manifest['Functions']) do
  if fn['Name'] == fnfunc then
    func_id = fn['Index']
    break
  end
end

if func_id == nil then
  ngx.status = 404
  ngx.say('function method not found')
  ngx.exit(ngx.HTTP_NOT_FOUND)
  return
end

fnmod = string.lower(fnmod, '')
fnmod = string.gsub(fnmod, '%A', '')

local docker_image = 'corefn/' .. fnmod
local func1, func2, func3, func4 = fn.int_to_bytes(tonumber(func_id))
local func = string.format('\\x%02X\\x%02X\\x%02X\\x%02X', func4, func3, func2, func1)

ngx.req.read_body()

local data = ngx.req.get_body_data()

if data == nil then
    data = ''
end

port = fn.image_port(docker_image)

local sock = ngx.socket.tcp()
local ok, err = sock:connect(fn.docker_host_ip, port)

-- TODO: fix this... use proper bytestreams
local packet = [[\x0F\x0A]] .. func .. [[\xFF\xAA]] .. data .. [[\x00\x00\x00\x00]]
packet_bin = packet:gsub('\\x(%x%x)', function (x) return string.char(tonumber(x,16)) end)

local bytes, err = sock:send(packet_bin)

ret = sock:receive('*a')

sock:close()

ngx.say(ret)
ngx.eof()
