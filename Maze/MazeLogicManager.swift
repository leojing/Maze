//
//  MazeLogicManager.swift
//  Maze
//
//  Created by JINGLUO on 29/5/17.
//  Copyright © 2017 JINGLUO. All rights reserved.
//

import Foundation
import TakeHomeTask

class MazeLogicManager: NSObject {
  
  fileprivate enum Direction: String {
    case west
    case east
    case north
    case south
  }
  
  fileprivate let mazeManager = MazeManager()
  fileprivate let concurrentQueue = DispatchQueue(label: "jing.luo.concurrent", attributes: .concurrent)
  
  public var uiUpdateProtocol: MazeUIUpdateProtocol?
  
  private var _visitedRooms: [String]?
  public var visitedRooms: [String]? {
    set {
      concurrentQueue.sync {
        _visitedRooms = newValue
      }
    }
    
    get {
      return concurrentQueue.sync {
        _visitedRooms
      }
    }
  }
  
  // MARK: fetch start room, and set it's location as (x,y)
  public func startFetchRoom(at start:(x: Float, y: Float)) {
    if visitedRooms == nil {
      visitedRooms = [String]()
    }
    else{
      visitedRooms?.removeAll()
    }
    
    mazeManager.fetchStartRoom { (data, error) in
      if let error = error {
        print(error.localizedDescription)
        return
      }
      
      guard let data = data else {
        print("Empty data! Can't build Maze")
        return
      }
      
      let json = try? JSONSerialization.jsonObject(with: data, options: [])
      if let dictionary = json as? [String: Any] {
        if let roomId = dictionary["id"] as? String {
          self.traversalRooms(roomId, start: start)
        }
      }
    }
  }
  
  // MARK: This method is the main logic one, its core is BFS Algorithm, this method is recursion to make sure each room can be visited.
  public func traversalRooms(_ roomId: String?, start: (x: Float, y: Float)) {
    guard let roomId = roomId, roomId.characters.count > 0 else {
      return
    }
    
    // if this room is visited, return
    if let visited = self.visitedRooms  {
      if visited.contains(roomId) {
        return
      }
    }
    
    concurrentQueue.async { [weak self] in
      guard let strongSelf = self else {
        return
      }
      
      strongSelf.mazeManager.fetchRoom(withIdentifier: roomId) { (data, error) in
        if let error = error {
          strongSelf.errorOfRoom(error, logicManager: strongSelf)
        }
        
        guard let data = data else {
          return
        }
        let json = try? JSONSerialization.jsonObject(with: data, options: [])
        guard let dictionary = json as? [String: Any] else  {
          return
        }
        
        // Parse Room Details
        strongSelf.parseRoomWithJson(dictionary, start: start, logicManager: strongSelf)
      }
    }
  }
}

// MARK: - Parse Room Details

extension MazeLogicManager {
  
  // MARK: Error Handling
  fileprivate func errorOfRoom(_ error: Error, logicManager: MazeLogicManager) {
    DispatchQueue.main.async {
      if let uiProtocol = logicManager.uiUpdateProtocol{
        uiProtocol.updateMazeViewWithError(error)
      }
    }
  }
  
  // MARK: Parse Room Details
  fileprivate func parseRoomWithJson(_ json: [String: Any], start: (Float, Float), logicManager: MazeLogicManager) {
    if let roomInfo = Room(json: json) {
      // Parse room id
      logicManager.parseRoomId(roomInfo.id, logicManager: logicManager)
      
      // Parse tile image url
      logicManager.parseTileURL(roomInfo.tileUrl, start: start, logicManager: logicManager)
      
      // Parse connected rooms
      logicManager.parseConeectedRooms(roomInfo.rooms, start: start, logicManager: logicManager)
    }
  }
  
  // MARK: Parse Room ID
  private func parseRoomId(_ roomId: String, logicManager: MazeLogicManager) {
    // if this room is visited, return
    if var visited = logicManager.visitedRooms {
      if visited.contains(roomId) {
        return
      }
      
      // add it to visitedRooms Set to make sure it never been visited again
      visited.append(roomId)
      logicManager.visitedRooms = visited
    }
  }
  
  // MARK: - Parse Tile Image URL
  private func parseTileURL(_ imageURL: String, start: (Float, Float), logicManager: MazeLogicManager) {
    DispatchQueue.main.async {
      // draw tile if UIUpdate protocol isn't nil
      if let uiProtocol = logicManager.uiUpdateProtocol {
        uiProtocol.updateMazeViewWith(imageURL, start: start)
      }
    }
  }
  
  // MARK: - Parse Connected Rooms
  private func parseConeectedRooms(_ connectedRooms: [String: Any], start: (Float, Float), logicManager: MazeLogicManager) {
    for (k, v) in connectedRooms {
      if let nestedDictionary = v as? [String: Any] {
        
        var newRoomId = String()
        if let roomId = nestedDictionary["room"] as? String {
          newRoomId = roomId
        }
        if let lock = nestedDictionary["lock"] as? String {
          newRoomId = logicManager.mazeManager.unlockRoom(withLock: lock)
        }
        
        logicManager.concurrentQueue.async {
          // fetch new room with roomId and start location by recursion
          logicManager.traversalRooms(newRoomId, start: logicManager.configDimension(k, start: start))
        }
      }
    }
  }
}

// MARK: - Utilities

extension MazeLogicManager {
  
  // MARK: define nearby room's location by it's direction to current room, for example, if current room is (0,0), the it's east room should be (1,0), west=(-1,0), north=(0,1), south=(0,-1)
  fileprivate func configDimension(_ direction: String?, start: (x: Float, y: Float)) -> (Float, Float) {
    var x = start.x, y = start.y
    
    guard let dir = direction else {
      return (0, 0)
    }
    
    switch dir {
    case Direction.west.rawValue:
      x += -1
      
    case Direction.east.rawValue:
      x += 1
      
    case Direction.north.rawValue:
      y += 1
      
    case Direction.south.rawValue:
      y += -1
      
    default:
      return (0, 0)
    }
    
    return (x, y)
  }
  
  // MARK: check if each room is only visited once
  func roomVisitedTwice() -> Bool {
    if let rooms = visitedRooms {
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
