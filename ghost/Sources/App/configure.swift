import Fluent
import FluentSQLiteDriver
import Leaf
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
    /// 此处Debug环境下, 并不能直接migrate成功, 需要主动进行autoMigrate并wait
    /// 再terminal中, 也需要执行 vapor run migrate
    app.migrations.add([CreateTodo(), CreateUser(), CreateNotes(), AddNotesTable(), CreateProfiles()])
    
#if DEBUG
    try app.autoMigrate().wait()
#endif
    
    /*
     /// 这个代码在debug环境下依旧无法指定资源的真是位置, 因此还是要修改当前workingDirectory
     /// https://github.com/vapor/leaf/issues/175
     app.leaf.sources = .singleSource(NIOLeafFiles(fileio: app.fileio,
         limits: .default,
         sandboxDirectory: app.directory.workingDirectory,
         viewDirectory: app.directory.workingDirectory + "Views/"))
     */
    app.views.use(.leaf)
    
    // register routes
    try routes(app)
}
