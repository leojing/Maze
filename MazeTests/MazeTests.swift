//
//  MazeTests.swift
//  MazeTests
//
//  Created by JINGLUO on 26/5/17.
//  Copyright © 2017 JINGLUO. All rights reserved.
//

import XCTest
@testable import Pods_Maze

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
    
    let mockUIUpdateManager = MockUIUpdateManager()
    let mockLogicManager = MockLogicManager()
    mockLogicManager.uiUpdateProtocol = mockUIUpdateManager
    vc.mazeLogicManager = mockLogicManager
    XCTAssertNotNil(vc.mazeLogicManager)
    
    for i in 0 ..< 10 {
      let ex = self.expectation(description: String(i))
      
      self.vc.mazeLogicManager.startFetchRoom(at: (x: 0, y: 0))
      
      sleep(10)
      ex.fulfill()
      
      //Async function when finished call [expectation fullfill]
      self.waitForExpectations(timeout: 0) { (error) in
        XCTAssertNotNil(self.vc.mazeLogicManager.visitedRooms, "rooms are not empty")
        XCTAssertFalse(mockLogicManager.roomVisitedTwice())
      }
    }
  }
  
  func testParseRoom() {
    let json = ["id":"R4b7f8b8bd464e959","tileUrl":"https://example.com/sometile.jpg","rooms": ["east": ["room":"R4b7f8c8cd464ee5e"], "west":["lock":"onF1pXP9jUimx0v9+5oBcccqid=="]], "type":"EMPTY"] as [String : Any]
    
    let room = Room(json)
    
    XCTAssertNil(room?.rooms)
    
    if case let .unlock(east) = room!.rooms["east"]! {
      XCTAssertEqual(east, "R4b7f8c8cd464ee5e")
    } else {
      XCTFail("it's not the right room")
    }
  }
  
  func testPerformanceExample() {
    // This is an example of a performance test case.
    self.measure {
      // Put the code you want to measure the time of here.
    }
  }
  
}

// MARK: - Mock MazeUIUpdateManager

class MockUIUpdateManager: MazeUIUpdateProtocol {
  
  func updateMazeViewWithError(_ error: Error?) {
    print("error")
  }
  
  func updateMazeViewWith(_ imageUrl: String?, start: (x: Float, y: Float)) {
    print(imageUrl ?? "no url")
  }
}

// MARK: - Mock MazeLogicManager

class MockLogicManager: MazeLogicManager {
  
  // MARK: check if each room is only visited once
  fileprivate func roomVisitedTwice() -> Bool {
    if let rooms = self.visitedRooms {
      let sortedRooms = rooms.sorted()
      for i in 0 ..< sortedRooms.count-1 {
        let a = sortedRooms[i]
        let b = sortedRooms[i+1]
        if a == b {
          return true
        }
      }
    } else {
      return true
    }
    
    return false
  }
}
