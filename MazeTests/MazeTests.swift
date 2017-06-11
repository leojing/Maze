//
//  MazeTests.swift
//  MazeTests
//
//  Created by JINGLUO on 26/5/17.
//  Copyright © 2017 JINGLUO. All rights reserved.
//

import XCTest
@testable import Maze

class MazeTests: XCTestCase {
  
  var vc = ViewController()

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
      
      let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
      vc = storyboard.instantiateInitialViewController() as! ViewController
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testIfRevisitRoom() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
      
      XCTAssertNotNil(vc.mazeLogicManager)
      
      let startRooms = [(10, "R40912fa5dc6cdd6d"), (10, "R469737bdda6ac575"), (10, "R4b9a35bfd767c777"), (10, "R76a73fb5ea5acd7d"), (10, "R5b8a2fa5c777dd6d"), (10, "R419036bcdd6dc474"), (10, "R5a8b21abc676d363")]
      for (t, roomId) in startRooms {
        let ex = self.expectation(description: roomId)
        
        self.vc.mazeLogicManager.visitedRooms = []
        self.vc.mazeLogicManager.traversalRooms(roomId, start: (0,0))
        
        print(roomId)
        sleep(UInt32(t))
        ex.fulfill()
        
        //Async function when finished call [expectation fullfill]
        self.waitForExpectations(timeout: 0) { (error) in
          XCTAssertNotNil(self.vc.mazeLogicManager.visitedRooms, "rooms are not empty")
          XCTAssertFalse(self.vc.mazeLogicManager.roomVisitedTwice())
        }
      }
    }
  
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
