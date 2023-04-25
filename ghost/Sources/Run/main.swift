import App
import Vapor

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
let app = Application(env)

app.http.server.configuration.hostname = "10.109.62.86"
app.http.server.configuration.port = 2048

// 降低数据包延迟。
app.http.server.configuration.tcpNoDelay = true
app.http.server.configuration.responseCompression = .enabled(initialByteBufferCapacity: 10_000_000) // 10M

defer { app.shutdown() }
try configure(app)
try app.run()

