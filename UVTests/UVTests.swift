//===--- UVTests.swift -------------------------------------------------------===//
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
//===-------------------------------------------------------------------------===//

import XCTest
@testable import UV
import CUV

class UVTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testTimer() {
        var counter = 0
        
        let loop = try! Loop()
        let timer = try! Timer(loop: loop) { timer in
            counter += 1
            print("timer:", counter)
            if counter == 10 {
                try! timer.stop()
                try! timer.start(0, repeatTimeout: 100)
            }
            if counter > 20 {
                timer.close()
            }
        }
        
        try! timer.start(0, repeatTimeout: 50)
        
        try! loop.run()
        
        print(timer.repeatTimeout)
    }
    
    func testExample() {
        let loop = try? Loop()
        
        try! loop?.run()
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
