const http = require('http')
const path = require('path')
const fs = require('fs')
const port = Number(process.argv[2] || 7676)

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

function serveStaticFile(method, pathname) {
  if (method.toUpperCase() !== 'GET') {
    return false
  }
  try {
    const localPath = path.join(process.env.SWIFT_PROJECT_DIRECTORY, 'public', pathname)
    console.log({ localPath })
    const data = fs.readFileSync(localPath)
    res.writeHead(200, {})
    res.end(data)
    return true
  } catch (err) {
    return false
  }
}

const server = http.createServer(async (req, res) => {
  try {
    const method = req.method
    const headers = req.headers
    const path = req.url
    if (serveStaticFile(method, path)) {
      return
    }
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

server.listen(port, () => {
    console.log('')
    console.log('Http Server running:', `http://localhost:${port}`)
    console.log('')
})
