import Vapor
import Fluent
import Leaf

enum ContentType {
    case text
    case image  // image与File是否可以统一处理
    case file   // 文件类型
    case video  // 视频
    case audio  // 音频
}

struct ChatUser: Content {
    // 用户的唯一标识符
    let id: String
    
    // 用户的昵称或用户名
    let name: String?
}

struct ChatMessageReceive: Content {
    
    /// 用户
    var from: ChatUser
    /// 用户
    var sender: ChatUser
    /// 内容
    let content: String
    /// 时间戳
    let timestamp: Int
}

struct ChatMessageSend: Content {
    /// 用户
    var from: ChatUser
    /// 内容
    let content: String
    /// 时间戳
    let timestamp: Int
}


// 定义一个名为 ChatRoom 的类，表示聊天室
class ChatRoom {
    // 存储聊天室中所有连接的 WebSocket 连接和用户
    var connections: [(WebSocket, ChatUser)] = []
    
    func broadcast(_ buffer: ByteBuffer) throws {
        
        // let data = buffer.withUnsafeReadableBytes({ Data($0) })
        let message = try JSONDecoder().decode(ChatMessageReceive.self, from: buffer)
        // 发送的消息
        let msg = ChatMessageSend(from: message.from, content: message.content, timestamp: message.timestamp)
        let data = try JSONEncoder().encode(msg)
        // 发送信息
        connections
            .filter { $0.1.id == message.sender.id }
            .first?
            .0
            .send(ByteBuffer(data: data))
    }
}
