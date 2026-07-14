const http = require("http");
const PORT = process.env.PORT || 8080;

const server = http.createServer((req, res) => {
  res.writeHead(200, { "Content-Type": "text/plain" });
  res.end("Hello from Docker + Node.js!\n");
});

server.listen(PORT, () => {
  console.log(`Server running at http://0.0.0.0:${PORT}/`);
});
