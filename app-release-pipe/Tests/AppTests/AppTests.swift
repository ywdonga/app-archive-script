@testable import App
@testable import AppStoreConnect
import XCTVapor

final class AppTests: XCTestCase {
    // func testHelloWorld() throws {
    //     let app = Application(.testing)
    //     defer { app.shutdown() }
    //     try configure(app)

    //     try app.test(.GET, "hello", afterResponse: { res in
    //         XCTAssertEqual(res.status, .ok)
    //         XCTAssertEqual(res.body.string, "Hello, world!")
    //     })
    // }

    func testDing() async {
        let d = DingDingBot(name: "拓客本test", version: "1.0.4", state: "创建新版本")
        await d.send(false)
    }

    func testFeishu() async {
        let d = FeishuBot(name: "拓客本test", version: "1.0.4", state: "创建新版本")
        await d.send(false)
    }
}
