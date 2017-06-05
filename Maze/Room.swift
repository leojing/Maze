//
//  Room.swift
//  Maze
//
//  Created by JINGLUO on 29/5/17.
//  Copyright © 2017 JINGLUO. All rights reserved.
//

import Foundation

struct Room {
  let id: String
  let tileUrl: String
  let rooms: [String: Any]
  let type: String
}

extension Room {
  
  init?(json: [String: Any]) {
    guard let id = json["id"] as? String,
      let tileUrl = json["tileUrl"] as? String,
      let roomsJSON = json["rooms"] as? [String: Any],
      let type = json["type"] as? String
      else {
        return nil
    }
    
    self.id = id
    self.tileUrl = tileUrl
    self.rooms = roomsJSON
    self.type = type
  }
  
}
