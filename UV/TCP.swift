//===--- TCP.swift -------------------------------------------------------===//
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

public typealias uv_tcp_p = UnsafeMutablePointer<uv_tcp_t>

extension uv_connect_t : uv_request_type {
}

public class ConnectRequest : Request<uv_connect_t> {
}

public class TCP : Stream<uv_tcp_p> {
    public init(loop:Loop, connectionCallback:TCP.SimpleCallback) throws {
        try super.init(connectionCallback: connectionCallback) { handle in
            uv_tcp_init(loop.loop, handle)
        }
    }
    
    public func bind(addr:UnsafePointer<sockaddr>, ipV6only:Bool = false) throws {
        let flags:UInt32 = ipV6only ? UV_TCP_IPV6ONLY.rawValue : 0
        try ccall(Error.self) {
            uv_tcp_bind(handle, addr, flags)
        }
    }
    
    public func connect(addr:UnsafePointer<sockaddr>, callback:ConnectRequest.RequestCallback = {_,_ in}) {
        ConnectRequest.perform(callback) { req in
            uv_tcp_connect(req, self.handle, addr, connect_cb)
        }
    }
}

func connect_cb(req:UnsafeMutablePointer<uv_connect_t>, status:Int32) {
    req_cb(req, status: status)
}