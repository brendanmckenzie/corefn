const async = require('async')
const redis = require('redis')
const network = require('network')
const spawn = require('child_process').spawn

const redisHost = 'redis'
let dockerHost = null // 'tcp://172.17.0.1:2375'

const exec = (exe, args, callback) => {
  const cmd = spawn(exe, args)
  let output = ''
  cmd.stdout.on('data', (data) => {
    output += data
  })

  cmd.stderr.on('data', (data) => {
    console.error('error', exe, data.toString())
  })

  cmd.on('close', (code) => {
    callback(null, output)
  })
}

const listFromRedis = (callback) => {
  const client = redis.createClient(6379, redisHost)
  client.keys('*', function (err, res) {
    if (err) {
      client.quit()
      return console.error('redis', err)
    }

    const ret = res
      .filter(ent => ent.length == 64)
      .map(ent => ent.substr(0, 12))

    callback(null, ret)

    client.quit()
  })
}

const listFromDocker = (callback) => {
  const cmd = exec('docker', ['-H', dockerHost, 'ps', '-f', 'label=corefn=true', '--format', '{{.ID}}'], (err, res) => {
    const ret = res
      .split('\n')
      .filter((ent) => ent && ent.length > 0)

    callback(null, ret)
  })
}

const run = () => {
  console.log('cleaning')
  async.parallel([
    listFromRedis,
    listFromDocker
  ], (err, results) => {
    if (err) {
      return console.error(err);
    }
    const redis = results[0]
    const docker = results[1]

    const kill = docker.filter(ent => redis.indexOf(ent) === -1)

    async.each(kill, (ent, callback) => {
      console.log(`killing ${ent}`)
      async.eachSeries(['kill', 'rm'], (cmd, innerCallback) => {
        exec('docker', ['-H', dockerHost, cmd, ent], innerCallback)
      }, (err, res) => {
        callback()
      })
    }, (err, res) => {
      if (err) {
        return console.error(err)
      }
    })
  })
}
network.get_gateway_ip((err, ip) => {
  console.log(`gateway (docker host): ${ip}`)
  dockerHost = `tcp://${ip}:2375`

  setInterval(run, 10000)
})

