//===--- Stream.swift -------------------------------------------------------===//
//Copyright (c) 2016 Daniel Leping (dileping)
//
//Licensed under the Apache License, Version 2.0 (the "License");
//you may not use this file except in compliance with the License.
//You may obtain a copy of the License at
//
//http://www.apache.org/licenses/LICENSE-2.0
//
//Unless required by applicable law or agreed to in writing, software
//distributed under the License is distributed on an "AS IS" BASIS,
//WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//See the License for the specific language governing permissions and
//limitations under the License.
//===-----------------------------------------------------------------------===//

import Foundation
import Boilerplate

import CUV

public protocol uv_stream_type : uv_handle_type {
}

extension UnsafeMutablePointer : uv_stream_type {
}

public typealias uv_stream_p = UnsafeMutablePointer<uv_stream_t>

extension uv_shutdown_t : uv_request_type {
}

public protocol SimpleCallbackCaller {
    associatedtype SimpleCallback = (Self)->Void
}

public class ShutdownRequest : Request<uv_shutdown_t> {
}

public class Stream<Type : uv_stream_type> : Handle<Type>, SimpleCallbackCaller {
    private lazy var streamHandle:UnsafeMutablePointer<uv_stream_t> = self.getStreamHandle()
    
    private let connectionCallback:Stream.SimpleCallback
    
    private func getStreamHandle() -> UnsafeMutablePointer<uv_stream_t> {
        return handle.cast()
    }
    
    init(connectionCallback:Stream.SimpleCallback, _ initializer:(Type)->Int32) throws {
        self.connectionCallback = connectionCallback
        try super.init(initializer)
    }
    
    public func shutdown(callback:ShutdownRequest.RequestCallback = {_,_ in}) throws {
        let req = Request<uv_shutdown_t>(callback)
        
        try ccall(Error.self) {
            uv_shutdown(req.pointer, streamHandle, shutdown_cb)
        }
        
        req.alive()
    }
    
    public func listen(backlog:Int32) throws {
        try ccall(Error.self) {
            uv_listen(streamHandle, backlog, connection_cb)
        }
    }
}

func shutdown_cb(req:UnsafeMutablePointer<uv_shutdown_t>, status:Int32) {
    req_cb(req, status: status)
}

func connection_cb(server:uv_stream_p, status:Int32) {
    let handle:uv_handle_p = server.cast()
    let stream = Stream<uv_stream_p>.fromHandle(handle)
    stream.connectionCallback(stream)
}