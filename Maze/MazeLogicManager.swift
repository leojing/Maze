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
  
  private var _visitedRooms: Set<String>?
  public var visitedRooms: Set<String>? {
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
  public func startFetchRoom(x: Float, y: Float) {
    if visitedRooms == nil {
      visitedRooms = Set<String>()
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
          self.traversalRooms(roomId, start: (x, y))
        }
      }
    }
  }
  
  // MARK: This method is the main logic one, its core is BFS Algorithm, this method is recursion to make sure each room can be visited.
  public func traversalRooms(_ id: String?, start: (x: Float, y: Float)) {
    guard let id = id, id.characters.count > 0 else {
      return
    }

    // if this room is visited, return
    if let visited = self.visitedRooms  {
      if visited.contains(id) {
        return
      }
    }

    concurrentQueue.async { [weak self] in
      guard let strongSelf = self else {
        return
      }

      strongSelf.mazeManager.fetchRoom(withIdentifier: id) { (data, error) in
        if let error = error {
          DispatchQueue.main.async {
            if let uiProtocol = strongSelf.uiUpdateProtocol{
              uiProtocol.updateMazeViewWithError(error)
            }
          }
        }

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
            if var visited = strongSelf.visitedRooms {
              visited.insert(roomId)
              strongSelf.visitedRooms = visited
            }
          }

          // draw tile if UIUpdate protocol isn't nil
          DispatchQueue.main.async {
            if let uiProtocol = strongSelf.uiUpdateProtocol {
              uiProtocol.updateMazeViewWith(tileUrl, x: start.x, y: start.y)
            }
          }
        }
        
        // Parse connected rooms
       if let connectedRooms = roomInfo?.rooms {
          for (k, v) in connectedRooms {
            if let nestedDictionary = v as? [String: Any] {
              
              var newRoomId = String()
              if let roomId = nestedDictionary["room"] as? String {
                newRoomId = roomId
              }
              if let lock = nestedDictionary["lock"] as? String {
                newRoomId = strongSelf.mazeManager.unlockRoom(withLock: lock)
              }
              
              strongSelf.concurrentQueue.async {
                // fetch new room with roomId and start location by recursion
                strongSelf.traversalRooms(newRoomId, start: strongSelf.configDimension(k, start: start))
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
