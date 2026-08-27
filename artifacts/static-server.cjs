const http = require('node:http')
const fs = require('node:fs')
const path = require('node:path')

const root = path.resolve(__dirname, '..', 'build', 'web')
const mime = {
  '.css': 'text/css; charset=utf-8',
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.otf': 'font/otf',
  '.woff2': 'font/woff2',
}

http.createServer((request, response) => {
  const requested = decodeURIComponent((request.url || '/').split('?')[0])
  const relative = requested === '/' ? '/index.html' : requested
  const filePath = path.resolve(root, `.${relative}`)
  const safePath = filePath.startsWith(root) ? filePath : path.join(root, 'index.html')

  fs.readFile(safePath, (error, data) => {
    if (error) {
      fs.readFile(path.join(root, 'index.html'), (fallbackError, fallback) => {
        if (fallbackError) {
          response.writeHead(500)
          response.end('Flutter build unavailable')
          return
        }
        response.writeHead(200, { 'Content-Type': mime['.html'] })
        response.end(fallback)
      })
      return
    }
    response.writeHead(200, { 'Content-Type': mime[path.extname(safePath)] || 'application/octet-stream' })
    response.end(data)
  })
}).listen(4174, '127.0.0.1', () => console.log('Flutter static build: http://127.0.0.1:4174/'))
