import Vapor
import Fluent

final class UserController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let builder = routes.grouped("users")
        builder.get { req -> EventLoopFuture<[User]> in try self.index(req: req) }
        builder.post { req -> EventLoopFuture<User> in try self.create(req: req) }
        builder.group(":userID") { build in
            build.delete(use: delete)
            build.get(use: show)
            build.patch(use: update)
            build.get("notes", use: getNotes)
            build.get("profiles", use: getPofiles)
        }
    }

    func delete(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: req.db) }
            .transform(to: .ok)
    }

    func show(req: Request) throws -> EventLoopFuture<User> {
        return User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
    }

    func update(req: Request) throws -> EventLoopFuture<User> {
        let updateData = try req.content.decode(User.self)
        return User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                user.name = updateData.name
                return user.save(on: req.db).map { user }
            }
    }

    func getNotes(req: Request) throws -> EventLoopFuture<[Notes]> {
        /*
         let user = try self.show(req: req).wait()
         return user.$notes.query(on: req.db).all()
         */
        return User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                user.$notes.query(on: req.db).all()
            }
    }
    
    func getPofiles(req: Request) throws -> EventLoopFuture<[Profile]> {
        return User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                user.$profiles.query(on: req.db).all()
            }
    }
    
}

/**
// Test Cases
import XCTest
@testable import Vapor
@testable import Fluent

final class UserControllerTests: XCTestCase {

    var app: Application!
    var controller: UserController!

    override func setUpWithError() throws {
        try super.setUpWithError()

        app = Application(.testing)
        try configure(app)
        controller = UserController()
    }

    override func tearDownWithError() throws {
        app.shutdown()
        try super.tearDownWithError()
    }

    func testIndex() throws {
        let req = try Request(application: app, on: app.eventLoopGroup.next())
        let users = try controller.index(req: req).wait()

        XCTAssertGreaterThan(users.count, 0)
    }

    func testCreate() throws {
        let req = try Request(application: app, on: app.eventLoopGroup.next())
        let user = User(name: "Test")
        let result = try controller.create(req: req).wait()

        XCTAssertEqual(result, user)
    }

    func testDelete() throws {
        let req = try Request(application: app, on: app.eventLoopGroup.next())
        let userID = UUID().uuidString
        let user = User(name: "Test", id: UUID(uuidString: userID))

        try user.save(on: req.db).wait()

        req.parameters.set("userID", to: userID)
        let status = try controller.delete(req: req).wait()

        XCTAssertEqual(status, .ok)
    }

    func testShow() throws {
        let req = try Request(application: app, on: app.eventLoopGroup.next())
        let userID = UUID().uuidString
        let user = User(name: "Test", id: UUID(uuidString: userID))

        try user.save(on: req.db).wait()

        req.parameters.set("userID", to: userID)
        let result = try controller.show(req: req).wait()

        XCTAssertEqual(result, user)
    }

    func testUpdate() throws {
        let req = try Request(application: app, on: app.eventLoopGroup.next())
        let userID = UUID().uuidString
        let user = User(name: "Test", id: UUID(uuidString: userID))

        try user.save(on: req.db).wait()

        req.parameters.set("userID", to: userID)
        let updatedUser = User(name: "Updated Test", id: UUID(uuidString: userID))
        let result = try controller.update(req: req).wait()

        XCTAssertEqual(result, updatedUser)
    }

    func testGetNotes() throws {
        let req = try Request(application: app, on: app.eventLoopGroup.next())
        let userID = UUID().uuidString
        let user = User(name: "Test", id: UUID(uuidString: userID))
        var notes = [Note]()

        for i in 1...3 {
            let note = Note(userID: user.id!, text: "Note #\(i)")
            notes.append(note)
        }

        try user.save(on: req.db).wait()
        try notes.create(on: req.db).wait()

        req.parameters.set("userID", to: userID)
        let result = try controller.getNotes(req: req).wait()

        XCTAssertEqual(result, notes)
    }
}
*/
