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

function serveStaticFile(req, res) {
  const localPath = path.join(process.env.SWIFT_PROJECT_DIRECTORY, 'public', req.url)
  const data = fs.readFileSync(localPath)
  res.writeHead(200, {
    'cache-control': 'public, max-age=0, must-revalidate',
    'content-length': Buffer.byteLength(data),
    'content-type': getContentType(localPath)
  })
  res.write(data)
  res.end()
}

const server = http.createServer(async (req, res) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`)
  try {
    serveStaticFile(req, res)
    return
  } catch (err) {
    // ignore
  }
  try {
    const method = req.method
    const path = req.url
    const headers = req.headers
    const body = await readBody(req)
    const _res = await invoke({ method, path, headers, body })
    const _body = JSON.parse(await readBody(_res))
    res.writeHead(_body.statusCode, _body.headers)
    res.end(Buffer.from(_body.body || '', _body.encoding || 'utf8'))
  } catch (err) {
    console.error(err)
    console.log('')
    res.writeHead(500, {})
    res.end('Internal server error')
  }
})

server.listen(port, () => {})

function getContentType(path) {
  const ext = path.split('.').pop()
  switch (ext) {
    case 'html':
      return 'text/html'
    case 'css':
      return 'text/css'
    case 'txt':
      return 'text/plain'
    case 'js':
      return 'text/javascript'
    case 'json':
      return 'application/json'
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg'
    case 'png':
      return 'image/png'
    case 'gif':
      return 'image/gif'
    default:
      return 'application/octet-stream' // fallback for unknown file types
  }
}
