//
//  Room.swift
//  Maze
//
//  Created by JINGLUO on 29/5/17.
//  Copyright © 2017 JINGLUO. All rights reserved.
//

import Foundation

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
  let rooms: [String: Any]
  let type: String
  
  var location: (x: Float, y: Float)?
}

extension Room {
  
  init?(json: [String: Any]) {
    guard let roomId = json["id"] as? String,
      let tileUrl = json["tileUrl"] as? String,
      let roomsJSON = json["rooms"] as? [String: Any],
      let type = json["type"] as? String
      else {
        return nil
    }
    
    self.roomId = roomId
    self.tileUrl = tileUrl
    self.rooms = roomsJSON
    self.type = type
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
