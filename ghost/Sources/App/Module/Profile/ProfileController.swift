import Vapor
import Fluent

final class ProfileController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped("profile")
        routes.group(":userID") { r in
            r.post(use: create)
        }
    }
    
    func create(req: Request) throws -> EventLoopFuture<Profile> {
        let item = try req.content.decode(ProfileData.self)
        let profile = Profile(bio: item.bio, userID: item.userID)
        return profile.save(on: req.db).map { profile }
    }
}

/*
 如果您想继续使用类似这种类型的形式`users.get(use: index)`，您可以为`RoutesBuilder`添加一个扩展方法，该方法接受一个泛型类型参数，表示要查询的模型类型。然后，您可以在该方法中使用泛型类型参数来调用`index`方法，并将结果作为路由处理程序返回。

 以下是一个示例代码，用于将`users.get(use: index)`封装在一个扩展方法中：

 ```swift
 extension RoutesBuilder {
     func get<T: Model>(_ path: PathComponent..., use handler: @escaping (Request) throws -> EventLoopFuture<[T]>) -> Route {
         return self.grouped(path).get(use: { req in
             return try handler(req)
         })
     }
 }
 ```

 在这个示例代码中，我们为`RoutesBuilder`添加了一个名为`get`的扩展方法，该方法接受一个泛型类型参数`T: Model`，表示要查询的模型类型。然后，我们使用该参数来调用`index`方法，并将结果作为路由处理程序返回。

 例如，如果您要查询`Note`模型，您可以使用以下代码：

 ```swift
 users.get("notes", use: index)
 ```

 在这个示例代码中，我们使用`get`方法定义了一个名为`notes`的子路由，并将`Note`类型作为泛型类型参数传递给`get`方法。然后，我们将`index`方法作为处理程序传递给`get`方法。这将查询`notes`表中的所有记录，并返回一个包含`Note`对象的数组。

 请注意，您需要根据您的实际情况修改这个示例代码，并确保您的模型正确地实现了`Model`协议。
 */
