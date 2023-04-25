import Vapor
import Fluent

class SocketController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        // builder
        let builder = routes.grouped("io")
        /*
         builder.webSocket("link") { req, so in
             printlog("Socket link success.")
             // deal socket receive
             so.onText { ws, text in
                 printlog("Socket receive: \(text)")
                 so.send("echo: " + text)
             }
             
             so.onPing { ws in
                 printlog("Socket ping")
             }
             
             so.onPong { ws in
                 printlog("Socket pong")
             }
         }
         */

        builder.webSocket("chat") { [self] req, so in
            printlog("Socket chat success.")
            // 为当前 WebSocket 连接生成一个唯一的标识符
            let user = ChatUser(id: UUID().uuidString, name: .random(6))
            // 将当前 WebSocket 连接及其标识符添加到聊天室中
            self.item.connections.append((so, user))
            // 返回用户id
            so.send(user.id)
            // 接收来自 WebSocket 连接的消息
            so.onText { webSocket, text in
                webSocket.send("收到用户信息: \(text)")
                // 通过对文本消息进行自定义处理, 直接将text转换成data, 进而转换成json对象
                /*
                 guard let d = text.data(using: .utf8) else {
                     printlog("Can't dela with this text: \(text)")
                     return
                 }
                 */
            }
            // 自定义消息
            so.onBinary { so, data in
                do {
                    try self.item.broadcast(data)
                } catch {
                    print(error.localizedDescription)
                }
            }
            
            // 当 WebSocket 连接关闭时，将其从聊天室中移除
            so.onClose.whenComplete { _ in
                self.item.connections.removeAll(where: { $0.0 === so })
            }
            
        }
        
        builder.group("user") { b in
            /// 聊天室所有在线用户
            b.post("onlines", use: onlines)
            /// 聊天室所有用户
            b.post("total", use: totals)
        }
        
    }
    
    func onlines(req: Request) async throws -> [ChatUser] {
        let item = try req.content.decode(ChatUser.self)
        return self.item.connections
            .filter { $0.0.isClosed == false && $0.1.id != item.id }
            .map { $0.1 }
    }
    
    func totals(req: Request) async throws -> [ChatUser] {
        let item = try req.content.decode(ChatUser.self)
        return self.item.connections
            .filter { $0.1.id != item.id }
            .map { $0.1 }
    }
    
    fileprivate let item = ChatRoom()
        
}
