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
  fileprivate var group = DispatchGroup()
  
  private var _visitedRooms: [String]?
  var visitedRooms: [String]? {
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

  public var uiUpdateProtocol: MazeUIUpdateProtocol?
  
  // MARK: fetch start room, and set it's location as (x,y)
  public func startFetchRoom(x: Float, y: Float) {
    visitedRooms = []
    
    mazeManager.fetchStartRoom { (data, error) in
      guard let data = data else {
        print("Empty data! Can't build Maze")
        return
      }
      
      let json = try? JSONSerialization.jsonObject(with: data, options: [])
      if let dictionary = json as? [String: Any] {
        if let roomId = dictionary["id"] as? String {
          self.traversalRooms(roomId, start: (x, y))
        }
      }
      
      if error != nil {
        print("Error! Can't build Maze")
      }
    }
    
    group.notify(queue: .main) { 
      print("finshed")
    }
  }
  
  // MARK: This method is the main logic one, its core is BFS Algorithm, this method is recursion to make sure each room can be visited.
  fileprivate func traversalRooms(_ id: String?, start: (x: Float, y: Float)) {
    guard let id = id, id.characters.count > 0 else {
      return
    }

    // if this room is visited, return
    guard let visited = self.visitedRooms else {
      return
    }
    if visited.contains(id) {
      return
    }

    self.concurrentQueue.async {

      self.mazeManager.fetchRoom(withIdentifier: id) { (data, error) in
        guard let data = data else {
          return
        }
        let json = try? JSONSerialization.jsonObject(with: data, options: [])
        guard let dictionary = json as? [String: Any] else  {
          return
        }
        
        let roomInfo = Room(json: dictionary)

        // Parse tile url, update maze view in main queue if it's not nil
        if let tileUrl = roomInfo?.tileUrl {
          
          // Parse room id and add it to visitedRooms Set to make sure it never been visited again. This is must happens when the tile image exsit, if not, refetch this room again
          if let roomId = roomInfo?.id {
            if var visited = self.visitedRooms {
              visited.append(roomId)
              self.visitedRooms = visited
            }
          }

          // draw tile if UIUpdate protocol isn't nil
          if let uiProtocol = self.uiUpdateProtocol {
            DispatchQueue.main.async {
              uiProtocol.updateMazeViewWith(tileUrl, x: start.x, y: start.y)
            }
          }
        }
        
        // Parse connected rooms
        self.concurrentQueue.async {
          if let connectedRooms = roomInfo?.rooms {
            for (k, v) in connectedRooms {
              if let nestedDictionary = v as? [String: Any] {
                
                var newRoomId = String()
                if let roomId = nestedDictionary["room"] as? String {
                  newRoomId = roomId
                }
                if let lock = nestedDictionary["lock"] as? String {
                  newRoomId = self.mazeManager.unlockRoom(withLock: lock)
                }
                
                // fetch new room with roomId and start location by recursion
                self.traversalRooms(newRoomId, start: self.configDimension(k, start: start))
              }
            }
          }
        }
      }
    }
  }
  
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


}
