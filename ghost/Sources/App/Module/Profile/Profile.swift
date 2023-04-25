import Fluent
import Vapor

/// Content可以通过自定义CodingKey来进行自定义变量映射
/// 此外还可以通过beforeEncode和afterEncode进行自定义处理
/// https://docs.vapor.codes/basics/content/
struct ProfileData: Content {
    
    /// Custom Codingkey
    enum CodingKeys: String, CodingKey {
        case bio
        case userID = "user_id"
    }
    
    var bio: String
    let userID: UUID
    
    // Runs after this Content is decoded. `mutating` is only required for structs, not classes.
    mutating func afterDecode() throws {
        // Name may not be passed in, but if it is, then it can't be an empty string.
        self.bio = self.bio.trimmingCharacters(in: .whitespacesAndNewlines)
        if self.bio.isEmpty {
            throw Abort(.badRequest, reason: "Bio must not be empty.")
        }
    }
    
    // Runs before this Content is encoded. `mutating` is only required for structs, not classes.
    mutating func beforeEncode() throws {
        // Have to *always* pass a name back, and it can't be an empty string.
        let bio = self.bio.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !bio.isEmpty else {
            throw Abort(.badRequest, reason: "Bio must not be empty.")
        }
        self.bio = bio
    }
}

/// @Parent 无法直接参与Decode映射, 正常Json请求数据: {"bio": "Hello, world!", "user_id": "30871B91-BB8B-4571-9F7E-C05394F7DFB8"}, 因为use_rid无法直接映射, 因此需构建一层Content充当Decode的处理
/// ProfileData可以充当这个中介
final class Profile: Model, Content {
    static let schema = "profiles"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "bio")
    var bio: String

    @Parent(key: "user_id")
    var user: User

    init() { }

    init(id: UUID? = nil, bio: String, userID: User.IDValue) {
        self.id = id
        self.bio = bio
        self.$user.id = userID
    }
    
}

// MARK: - AsyncMigration
/// 可以理解为每一个标都有独立的管理
struct CreateProfiles: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Profile.schema)
            .id()
            .field("bio", .string, .required)
            .field("user_id", .uuid, .required, .references(User.schema, "id"))
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(User.schema).delete()
    }
}
