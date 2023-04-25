import Fluent
import Vapor

struct TodoController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let todos = routes.grouped("todos")
        todos.get(use: index)
        todos.post(use: create)
        todos.group(":todoID") { todo in
            todo.delete(use: delete)
        }
    }

    /*
     curl --header "Content-Type: application/json" \
            --request GET \
            http://localhost:8080/todos
     */
    func index(req: Request) async throws -> [Todo] {
        try await Todo.query(on: req.db).all()
    }

    /*
     curl --header "Content-Type: application/json" \
            --request POST \
            --data '{"title": "Buy groceries"}' \
            http://localhost:8080/todos
     */
    func create(req: Request) async throws -> Todo {
        let todo = try req.content.decode(Todo.self)
        try await todo.save(on: req.db)
        return todo
    }
    /*
     func create(req: Request) throws -> EventLoopFuture<Todo> {
         let item = try req.content.decode(Todo.self)
         return item.save(on: req.db).map { item }
     }
     */

    func delete(req: Request) async throws -> HTTPStatus {
        guard let todo = try await Todo.find(req.parameters.get("todoID"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await todo.delete(on: req.db)
        return .noContent
    }
    
}
