@testable import App
import XCTVapor

final class AppTests: XCTestCase {
    func testHelloWorld() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)

        try app.test(.GET, "hello", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "Hello, world!")
        })
    }
    
    // Define a test route for the TodoController
    func testTodoControllerRoute() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        
        try configure(app)
        
        try app.test(.GET, "/todos", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            // Add more assertions here for expected response data
        })
    }
}
