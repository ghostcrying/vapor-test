import Vapor
import Fluent

public extension RouteCollection {
    
    /// Thsi method takes a generic type parameter T, which must conform to the Model protocol.
    /// This method queries the database associated with the given Request object for all instances of the T model and returns them as an array wrapped in an EventLoopFuture.
    func index<T: Model>(req: Request) throws -> EventLoopFuture<[T]> {
        return T.query(on: req.db).all()
    }
    
    /// This method takes a generic type parameter T that must conform to the Model protocol.
    /// This method decodes a T object from the Request object's content, saves it to the database associated with the request using the save(on:) method, and returns the saved object wrapped in an EventLoopFuture.
    func create<T: Model>(req: Request) throws -> EventLoopFuture<T> {
        let item = try req.content.decode(T.self)
        return item.save(on: req.db).map { item }
    }
}

extension RoutesBuilder {
    /// Registers all of the routes in every group to this router.
    ///
    /// - parameters:
    ///     - collections: `RouteCollection` to register.
    public func register(collections: [RouteCollection]) throws {
        try collections.forEach {
            try $0.boot(routes: self)
        }
    }
}
