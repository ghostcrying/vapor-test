import Vapor
import Fluent

final class NotesController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let notes = routes.grouped("notes")
        notes.get() { req -> EventLoopFuture<[Notes]> in try self.index(req: req) }
        notes.post(use: create)
        notes.group(":noteID") { note in
            note.delete(use: delete)
            note.get(use: show)
            note.patch(use: update)
            note.get("user", use: getUser)
        }
    }

    func index(req: Request) throws -> EventLoopFuture<[Notes]> {
        return Notes.query(on: req.db).all()
    }

    func create(req: Request) throws -> EventLoopFuture<Notes> {
        let item = try req.content.decode(NotesItem.self)
        let notes = Notes(title: item.title, body: item.body ?? "", userID: item.userID)
        return notes.save(on: req.db).map { notes }
    }

    func delete(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return Notes.find(req.parameters.get("noteID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: req.db) }
            .transform(to: .ok)
    }

    func show(req: Request) throws -> EventLoopFuture<Notes> {
        return Notes.find(req.parameters.get("noteID"), on: req.db)
            .unwrap(or: Abort(.notFound)) // 可以直接进行错误的抛出
    }

    func update(req: Request) throws -> EventLoopFuture<Notes> {
        let updateData = try req.content.decode(Notes.self)
        return Notes.find(req.parameters.get("noteID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { notes in
                notes.title = updateData.title
                return notes.save(on: req.db).map { notes }
            }
    }

    func getUser(req: Request) throws -> EventLoopFuture<User> {
        return Notes.find(req.parameters.get("noteID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { notes in
                notes.$user.get(on: req.db)
            }
    }
}
