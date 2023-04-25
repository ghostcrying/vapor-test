
import Vapor
import NIO
import Swim
import Foundation
import LeafKit

class FileController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let builder = routes.grouped("files")
        
        // stream downlaod
        builder.get("download", ":name", use: downlaod)
        
        // upload: 不支持直接builder.post("/upload/single")这一类路径, 必须经由group重新构造
        builder.group("upload") { b in
            b.post("single", use: singleUpload)
            b.post("stream", use: streamUpload)
            b.post("images", use: imageUpload)
        }
        
        /*
         多文件上传
         curl -X POST \
              http://10.109.62.86:2048/files/uploads \
              -H 'Content-Type: multipart/form-data' \
              -F 'files[]=@/xxx/xxx.xxx' \
              -F 'files[]=@/xxx/xxx.xxx'
         */
        builder.post("uploads") { req -> EventLoopFuture<[String]> in
            struct Input: Content {
                var files: [File]
            }
            let input = try req.content.decode(Input.self)
            
            let formatter = DateFormatter()
            formatter.dateFormat = "y-m-d-HH-MM-SS-"
            let prefix = formatter.string(from: .init())
                    
            let uploadFutures = input.files
                .filter { $0.data.readableBytes > 0 }
                .map { file -> EventLoopFuture<String> in
                    let fileName = prefix + file.filename
                    let filePath = req.application.directory.workingDirectory + "Resources/Uploads/Images/\(fileName)"
                    return req.application.fileio.openFile(path: filePath,
                                                           mode: .write,
                                                           flags: .allowFileCreation(posixMode: 0x744),
                                                           eventLoop: req.eventLoop)
                    .flatMap { handle in
                        req.application.fileio.write(fileHandle: handle,
                                                     buffer: file.data,
                                                     eventLoop: req.eventLoop)
                        .flatMapThrowing { _ in
                            try handle.close()
                            return fileName
                        }
                    }
                }
            return req.eventLoop.flatten(uploadFutures)
        }
        
        /*
         struct UploadedFile: LeafDataRepresentable {
             let url: String
             let isImage: Bool
             
             var leafData: LeafData { .dictionary([ "url": url, "isImage": isImage]) }
         }
         let uploadFutures = input.files
             .filter { $0.data.readableBytes > 0 }
             .map { file -> EventLoopFuture<UploadedFile> in
                 let fileName = prefix + file.filename
                 let path = req.application.directory.publicDirectory + fileName
                 let isImage = ["png", "jpeg", "jpg", "gif"].contains(file.extension?.lowercased())
                 
                 return req.application.fileio.openFile(path: path,
                                                        mode: .write,
                                                        flags: .allowFileCreation(posixMode: 0x744),
                                                        eventLoop: req.eventLoop)
                 .flatMap { handle in
                     req.application.fileio.write(fileHandle: handle,
                                                  buffer: file.data,
                                                  eventLoop: req.eventLoop)
                     .flatMapThrowing { _ in
                         try handle.close()
                         return UploadedFile(url: fileName, isImage: isImage)
                     }
                     
                 }
             }
         return req.eventLoop.flatten(uploadFutures).flatMap { files in
             req.leaf.render(template: "result", context: [
                 "files": .array(files.map(\.leafData))
             ])
         }
         */
    }
    
    // 下载文件
    func downlaod(req: Request) throws -> Response {
        guard let filename = req.parameters.get("name") else {
            throw Abort(.badRequest, reason: "name must not be empty!")
        }
        let filePath = req.application.directory.workingDirectory + "Resources/Files/\(filename)"
        return req.fileio.streamFile(at: filePath)
    }
    
    func singleUpload(req: Request) throws -> EventLoopFuture<String> {
        let file = try req.content.decode(File.self)
        let path = req.application.directory.workingDirectory + "Resources/Uploads/" + file.filename
        
        return req.application.fileio.openFile(path: path, mode: .write, eventLoop: req.eventLoop)
            .flatMap { handle in
                req.application.fileio.write(fileHandle: handle, buffer: file.data, eventLoop: req.eventLoop)
                    .flatMapError { error in
                        req.logger.error("Failed to upload file: \(error)")
                        return req.eventLoop.makeFailedFuture(error)
                    }
                    .flatMap {
                        return req.eventLoop.makeSucceededFuture("File uploaded successfully")
                    }
            }
    }
    
    // 用这种方式吧
    func streamUpload(req: Request) throws -> EventLoopFuture<String> {
        let file = try req.content.decode(File.self)
        let path = req.application.directory.workingDirectory + "Resources/Uploads/" + file.filename
        return req.fileio.writeFile(file.data, at: path)
            .flatMapError { error in
                req.logger.error("Failed to upload file: \(error)")
                return req.eventLoop.makeFailedFuture(error)
            }
            .flatMap {
                return req.eventLoop.makeSucceededFuture("File uploaded successfully")
            }
    }
    
    // 单图片处理
    func imageUpload(req: Request) throws -> EventLoopFuture<String> {
        req.id.multipart
        let file = try req.content.decode(File.self)
        guard file.data.readableBytes <= 10000000 else {
            return req.eventLoop.makeFailedFuture(
                Abort(.badRequest, reason: "Image size should not exceed 1mb.")
            )
        }
        guard let type = file.extension?.lowercased(), !type.isEmpty else {
            return req.eventLoop.makeFailedFuture(
                Abort(.badRequest, reason: "Image name should not empty.")
            )
        }
        guard ["png", "jpeg", "jpg"].contains(type) else {
            return req.eventLoop.makeFailedFuture(
                Abort(.badRequest, reason: "Image extension is not acceptable.")
            )
        }
        let path = req.application.directory.workingDirectory + "Resources/Uploads/Images/" + file.filename
        let url = URL(fileURLWithPath: path)
        return req.fileio.writeFile(file.data, at: path)
            .flatMapError { error in
                req.logger.error("Failed to upload file: \(error)")
                return req.eventLoop.makeFailedFuture(error)
            }
            .flatMap {
                if let io = try? Swim.Image<RGB, UInt8>(contentsOf: url) {
                    try? io.resize(width: 200, height: 200).write(to: url)
                }
                return req.eventLoop.makeSucceededFuture("File uploaded successfully")
            }

    }
    
    // 批量图片处理
    func imagesUpload(req: Request) throws -> EventLoopFuture<String> {
        

        //
        return req.eventLoop.makeSucceededFuture("")
    }
}

/*
 您可以使用 Vapor 中的 `MultiPartFormData` 类来实现批量文件上传。`MultiPartFormData` 类允许您将多个文件打包到单个请求中，并可以通过 `req.body.collect()` 方法来访问上传的所有文件。以下是一个示例代码片段，演示如何使用 `MultiPartFormData` 类来实现批量文件上传：

 ```swift
 import Vapor

 func uploadFiles(_ req: Request) throws -> EventLoopFuture<String> {
     return req.body.collect()
         .flatMap { parts -> EventLoopFuture<String> in
             for part in parts {
                 guard let filename = part.filename else { continue }
                 let path = req.application.directory.workingDirectory + "uploads/" + filename
                 try part.data.write(to: URL(fileURLWithPath: path))
             }
             return req.eventLoop.makeSucceededFuture("Files uploaded successfully")
         }
 }
 ```

 在此示例中，我们首先调用 `req.body.collect()` 方法来收集所有上传的文件。然后，我们遍历所有部分，并将每个文件保存到 `uploads` 目录下。我们使用 `part.filename`
 */
