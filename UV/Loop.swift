//===--- Loop.swift -------------------------------------------------------===//
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
//===----------------------------------------------------------------------===//

import CUV
import Boilerplate

public typealias uv_loop_p = UnsafeMutablePointer<uv_loop_t>

open class Loop {
    fileprivate let exclusive:Bool
    open let loop:uv_loop_p
    
    public init(loop:uv_loop_p) {
        self.loop = loop
        exclusive = false
    }
    
    public init() throws {
        loop = uv_loop_p.allocate(capacity: 1)
        exclusive = true
        try ccall(Error.self) {
            uv_loop_init(loop)
        }
    }
    
    deinit {
        if exclusive {
            defer {
                loop.deinitialize(count: 1)
                loop.deallocate(capacity: 1)
            }
            do {
                try close()
            } catch let e as Error {
                print(e.description)
            } catch {
                print("Unknown error occured while destroying the loop")
            }
        }
    }
    
    open static var defaultLoop: Loop {
        get {
            return Loop(loop: uv_default_loop())
        }
    }
    
    /*public func configure(option:uv_loop_option, _ args: CVarArgType...) {
        try Error.handle {
            uv_loop_configure(loop, option, getVaList(args))
        }
    }*/
    
    fileprivate func close() throws {
        try ccall(Error.self) {
            uv_loop_close(loop)
        }
    }
    
    /// returns true if no more handles are there
#if swift(>=3.0)
    @discardableResult
    public func run(inMode mode:uv_run_mode = UV_RUN_DEFAULT) -> Bool {
        return uv_run(loop, mode) == 0
    }
#else
    open func run(inMode mode:uv_run_mode = UV_RUN_DEFAULT) -> Bool {
        return uv_run(loop, mode) == 0
    }
#endif
    
    open var alive:Bool {
        get {
            return uv_loop_alive(loop) != 0
        }
    }
    
    open func stop() {
        uv_stop(loop)
    }
    
    fileprivate static var size:UInt64 {
        return UInt64(uv_loop_size())
    }
    
    open var backendFd:Int32 {
        get {
            return uv_backend_fd(loop)
        }
    }
    
    //in millisec
    //wierd thing, doc says it should return -1 on no timeout, in fact - 0. Leaving as is for now. Subject to investigate
    open var backendTimeout:Int32? {
        get {
            let timeout = uv_backend_timeout(loop)
            return timeout == -1 ? nil : timeout
        }
    }
    
    open var now:UInt64 {
        get {
            return uv_now(loop)
        }
    }
    
    open func updateTime() {
        uv_update_time(loop)
    }
    
    open func walk(_ f:LoopWalkCallback) {
        let container = AnyContainer(f)
        let arg = UnsafeMutableRawPointer(Unmanaged.passUnretained(container).toOpaque())
        uv_walk(loop, loop_walker, arg)
    }
    
    open var handles:Array<HandleType> {
        get {
            return Array(enumerator: walk)
        }
    }
}

public typealias LoopWalkCallback = (HandleType)->Void

private func _loop_walker(_ handle:uv_handle_p?, arg:UnsafeMutableRawPointer?) {
    guard let arg = arg , arg != .null else {
        return
    }
    
    guard let handle = handle , handle != .null else {
        return
    }
    let container = Unmanaged<AnyContainer<LoopWalkCallback>>.fromOpaque(arg).takeUnretainedValue()
    let callback = container.content
    let handleObject:Handle<uv_handle_p> = Handle.from(handle: handle)
    callback(handleObject)
}

private func loop_walker(handle:uv_handle_p?, arg:UnsafeMutableRawPointer?) {
    _loop_walker(handle, arg: arg)
}


extension Loop : Equatable {
}

public func ==(lhs: Loop, rhs: Loop) -> Bool {
    return lhs.loop == rhs.loop
}
