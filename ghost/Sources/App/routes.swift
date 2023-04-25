import Fluent
import Vapor
import Leaf
import NIO

/// Debug模式下,
/// 报错: No custom working directory set for this scheme
/// 此时需要主动为项目指定Scheme路径: Edit Scheme -> Options -> Working Directory, 指定Resource的资源路径

func routes(_ app: Application) throws {
    
    app.routes.defaultMaxBodySize = 10_100_1000 // 10M大小限制
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    app.get { req async throws in
        try await req.view.render("index", ["title": "Hello!"])
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }
    
    app.get("leaf") { req -> EventLoopFuture<View> in
        return req.view.render("Leaf/index", ["title": "Mine Leaf"])
    }

    /// register group
    try app.register(collection: TodoController())
    try app.register(collection: UserController())
    try app.register(collection: NotesController())
    try app.register(collection: ProfileController())
    try app.register(collection: SocketController())
    try app.register(collection: FileController())
}

/*
 curl -X GET http://localhost:8080/user
        
 curl --header "Content-Type: application/json" \
      -X POST \
      --data '{"title": "Windy", "body": "It is so hot", "userID": "30871B91-BB8B-4571-9F7E-C05394F7DFB8"}' \
      http://localhost:8080/notes
      
 curl --header "Content-Type: application/json" \
      -X GET \
      --data '{"id": "8B020FCB-567B-4456-91FD-EBC8532B0D43"}' \
      http://127.0.0.1:8080/io/user/onlines

 curl --header "Content-Type: application/json" \
      -X POST \
      --data '{"name": "JOYE"}' \
      http://172.17.26.183:2048/users

 # 文件下载, output是写入本地的路径
 curl http://10.109.50.116:2048/files/download/Music_Gucunxinsi_fengzihauzhuan
      --output /xxx/xxx/xxx/music_0.mp3
      
 # 文件上传: 目前文件的上传有限制大小, 可以主动修改大小
 app.routes.defaultMaxBodySize = 10_100_1000 // 10M大小限制, 也可以更改
 # filename: 文件名
 # data: 表示文件的二进制数据, `@` 符号后面的路径应该是实际文件路径
 curl -X POST \
      -H "Content-Type: multipart/form-data" \
      -F "filename=Music_Gucunxinsi_fengzihauzhuan.mp3"  \
      -F "data=@/xxx/xxx/xxx/music_0.mp3" \
      http://10.109.50.116:2048/files/upload/stream
  */
