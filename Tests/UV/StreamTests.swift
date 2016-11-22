//
//  StreamTests.swift
//  UV
//
//  Created by Daniel Leping on 21/04/2016.
//  Copyright © 2016 Crossroad Labs s.r.o. All rights reserved.
//

import Foundation

import XCTest
@testable import UV
import CUV

class StreamTests: XCTestCase {
    func testConnectability() {
        let string = "Hello TCP"
        let array:[UInt8] = Array(string.utf8)
        
        let acceptedExpectation = self.expectation(description: "ACCEPTED")
        let connectedExpectation = self.expectation(description: "CONNECTED")
        
        let loop = try! Loop()
        let server = try! TCP(loop: loop) { (server:UV.Stream) -> Void in
            let accepted = try! server.accept { stream, result in
                guard let data = result.value else {
                    XCTFail(result.error!.description)
                    return
                }
                
                XCTAssertEqual(data.array, array)
                
                let writeBackExpectation = self.expectation(description: "WRITE BACK")
                
                stream.write(data: data) { req, e in
                    XCTAssertNil(e)
                    writeBackExpectation.fulfill()
                }
                stream.close()
            }
            server.close()
            
            try! accepted.startReading()
            acceptedExpectation.fulfill()
        }
        var addr = sockaddr_in()
        
        XCTAssertGreaterThanOrEqual(uv_ip4_addr("127.0.0.1", 45678, &addr), 0)
        
        try! withUnsafePointer(to: &addr) { pointer in
            
            let addr = pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { pointer in
                pointer
            }
            try server.bind(to: addr)
        }
        
        try! server.listen(backlog: 125)
        
        let client = try! TCP(loop: loop) { stream, result in
            guard let data = result.value else {
                XCTFail(result.error!.description)
                return
            }
            
            XCTAssertEqual(data.array, array)
            
            stream.close()
        }
        
        withUnsafePointer(to: &addr) { pointer in
            
            let sock = pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { ptr in
                return UnsafePointer(ptr)
            }
            client.connect(to: sock) { req, e in
                XCTAssertNil(e)
                connectedExpectation.fulfill()
                
                let data = Data(data: array)
                
                client.write(data: data) { req, e in
                    XCTAssertNil(e)
                    data.destroy()
                }
                try! client.startReading()
            }
        }
        
        loop.run(inMode: UV_RUN_DEFAULT)
        
        self.waitForExpectations(timeout: 0)
    }
}
