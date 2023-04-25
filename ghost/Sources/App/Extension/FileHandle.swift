//
//  File.swift
//  
//
//  Created by 陈卓 on 2023/4/24.
//

import Vapor
import NIO
import NIOHTTP1

func fileHandle(_ path: String, req: Request) throws -> EventLoopFuture<Response> {
    let loop = req.eventLoop
    let filePath = "/path/to/your/file.txt"
    let fileIO = req.application.fileio
    let fileHandle = fileIO.openFile(path: filePath, eventLoop: req.eventLoop)
    return fileHandle.flatMap { (handle, region) in
        let data = fileIO.read(fileHandle: handle, byteCount: 1024, allocator: ByteBufferAllocator(), eventLoop: loop)
        return data.map { buffer in
            let response = Response(status: .ok, headers: HTTPHeaders())
            response.headers.contentType = .plainText
            response.body = .init(buffer: buffer)
            return response
        }
    }
}
