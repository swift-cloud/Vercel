const http = require('http')
const port = Number(process.argv[2] || 8000)

async function invoke(payload) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: '127.0.0.1',
      port: 7000,
      path: '/invoke',
      method: 'POST'
    }
    const req = http.request(options, resolve)
    req.write(JSON.stringify({ body: JSON.stringify(payload) }))
    req.end()
    req.on('error', reject)
  })
}

async function readBody(stream) {
  return new Promise((resolve, reject) => {
    let body = ''
    stream.setEncoding('utf8')
    stream.on('data', (chunk) => (body += chunk))
    stream.on('end', () => resolve(body))
    stream.on('error', reject)
  })
}

const server = http.createServer(async (req, res) => {
  try {
    const method = req.method
    const path = req.url
    const headers = req.headers
    const body = await readBody(req)
    const _res = await invoke({ method, path, headers, body })
    const _body = JSON.parse(await readBody(_res))
    res.writeHead(_body.statusCode, _body.headers)
    res.end(_body.body)
  } catch (err) {
    console.error(err)
    res.writeHead(500, {})
    res.end('Internal server error')
  }
})

server.listen(port)