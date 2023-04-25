import Vapor
import Fluent

struct NotesItem: Content {

    let title: String
    
    let body: String?
    
    let userID: UUID
}

final class Notes: Model, Content {
    static let schema = "notes"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "title")
    var title: String
    
    @Field(key: "body")
    var body: String

    @Parent(key: "user_id")
    var user: User
    
    init() { }

    init(id: UUID? = nil, title: String, body: String, userID: User.IDValue) {
        self.id = id
        self.title = title
        self.body = body
        self.$user.id = userID
    }
}

// MARK: - AsyncMigration
/// 可以理解为每一个标都有独立的管理
struct CreateNotes: AsyncMigration {
    
    func prepare(on database: Database) async throws {
        try await database.schema(Notes.schema)
            .id()
            .field("title", .string, .required)
            .field("user_id", .uuid, .required, .references(User.schema, "id", onDelete: .cascade)) // cascade 表示在删除用户是相关的笔记也删除
            .create()
        
        try await database
            .schema(Notes.schema)
            .field("body", .string)
            .update()
        
    }

    func revert(on database: Database) async throws {
        try await database.schema(Notes.schema).delete()
    }
}

/// 增加表结构
struct AddNotesTable: AsyncMigration {
    
    func prepare(on database: Database) async throws {
        database
            .schema(Notes.schema)
            .field("body", .string)
            .update()
            .whenComplete({ result in
                switch result {
                case .success:
                    print("添加Body列表成功")
                case .failure(let error):
                    print("添加Body列表: \(error)")
                }
            })
    }

    func revert(on database: Database) async throws {
        try await database.schema(Notes.schema).delete()
    }
}
