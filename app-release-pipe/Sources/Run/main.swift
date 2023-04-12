import App
import Vapor
import AppStoreConnect

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)

AppManager.shared.run(isTest: env.name != Environment.production.name)

let app = Application(env)
defer { app.shutdown() }
try configure(app)
try app.run()
