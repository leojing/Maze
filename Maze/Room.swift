//
//  Room.swift
//  Maze
//
//  Created by JINGLUO on 29/5/17.
//  Copyright © 2017 JINGLUO. All rights reserved.
//

import Foundation

enum LockType {
  case unlock(String)
  case lock(String)
}

public enum Direction {
  case west
  case east
  case north
  case south
  
  init?(direction: String) {
    switch direction {
    case "west":
      self = .west
      
    case "east":
    self = .east
      
    case "north":
      self = .north
      
    case "south":
      self = .south
      
    default:
      return nil
    }
  }

}

struct Room {
  let roomId: String
  let tileUrl: String
  var rooms: [String: LockType]
  let type: String
  
  var location: (x: Float, y: Float)?
}

extension Room {
  
  init?(_ json: [String: Any]) {
    guard let roomId = json["id"] as? String,
      let tileUrl = json["tileUrl"] as? String,
      let roomsJSON = json["rooms"] as? [String: Any],
      let type = json["type"] as? String
      else {
        return nil
    }
    
    self.roomId = roomId
    self.tileUrl = tileUrl
    self.rooms = Room.parseRooms(roomsJSON)
    self.type = type
  }
  
  static func parseRooms(_ json: [String: Any]) -> [String: LockType] {
    var result = [String: LockType]()
    for (k, v) in json {
      var lockType: LockType? = nil
      if let nestedDictionary = v as? [String: Any] {
        if let roomId = nestedDictionary["room"] as? String {
          lockType = LockType.unlock(roomId)
        }
        if let lock = nestedDictionary["lock"] as? String {
          lockType = LockType.lock(lock)
        }
      }
      
      result[k] = lockType
    }
    
    return result
  }
  
  mutating func setupLocation(_ location: (x: Float, y: Float)) {
    self.location = location
  }
  
  // MARK: define nearby room's location by it's direction to current room, for example, if current room is (0,0), the it's east room should be (1,0), west=(-1,0), north=(0,1), south=(0,-1)
  public func locationForDirection(_ direction: Direction?) -> (Float, Float) {
    guard let direction = direction else { return (0, 0) }
  
    guard var x = self.location?.x, var y = self.location?.y else { return (0, 0) }
    
    switch direction {
    case .west:
      x += -1
      
    case .east:
      x += 1
      
    case .north:
      y += 1
      
    case .south:
      y += -1
    }
    
    return (x, y)
  }
}
