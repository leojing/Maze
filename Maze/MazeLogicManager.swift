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
    
  fileprivate let mazeManager = MazeManager()
  fileprivate let concurrentQueue = DispatchQueue(label: "jing.luo.concurrent", attributes: .concurrent)
  fileprivate let safeQueue = DispatchQueue(label: "SafeQueue")

  public var uiUpdateProtocol: MazeUIUpdateProtocol?
  
  private var _visitedRooms: [String]?
  public var visitedRooms: [String]? {
    set {
        safeQueue.async() {
            self._visitedRooms = newValue
      }
    }

    get {
        return safeQueue.sync {
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
  public func traversalRooms(_ roomId: String, start: (x: Float, y: Float)) {
    if roomId.characters.count <= 0 {
      return
    }
    
    // if this room is visited, return
    if let visited = self.visitedRooms  {
      if visited.contains(roomId) {
        return
      }
    }
    
    concurrentQueue.async { [weak self] in
      self?.mazeManager.fetchRoom(withIdentifier: roomId) { (data, error) in
        if let error = error {
          self?.errorOfRoom(error)
        }
        
        guard let data = data else {
          return
        }
        let json = try? JSONSerialization.jsonObject(with: data, options: [])
        guard let dictionary = json as? [String: Any] else  {
          return
        }
        
        // Parse Room Details
        self?.parseRoomWithJson(dictionary, start: start)
      }
    }
  }
}

// MARK: - Parse Room Details

extension MazeLogicManager {
  
  // MARK: Error Handling
  fileprivate func errorOfRoom(_ error: Error) {
    DispatchQueue.main.async {
      if let uiProtocol = self.uiUpdateProtocol{
        uiProtocol.updateMazeViewWithError(error)
      }
    }
  }
  
  // MARK: Parse Room Details
  fileprivate func parseRoomWithJson(_ json: [String: Any], start: (Float, Float)) {
    if var roomInfo = Room(json) {
      // set default location for room
      roomInfo.setupLocation(start)
      
      // Parse room id
      self.parseRoomId(roomInfo)
      
      // Parse tile image url
      self.parseTileURL(roomInfo)
      
      // Parse connected rooms
      self.parseConeectedRooms(roomInfo)
    }
  }
  
  // MARK: Parse Room ID
  private func parseRoomId(_ room: Room) {
    // if this room is visited, return
    if var visited = self.visitedRooms {
      if visited.contains(room.roomId) {
        return
      }
      
      // add it to visitedRooms Set to make sure it never been visited again
      visited.append(room.roomId)
      self.visitedRooms = visited
    }
  }
  
  // MARK: - Parse Tile Image URL
  private func parseTileURL(_ room: Room) {
    DispatchQueue.main.async {
      // draw tile if UIUpdate protocol isn't nil
      if let uiProtocol = self.uiUpdateProtocol, let start = room.location {
        uiProtocol.updateMazeViewWith(room.tileUrl, start: start)
      }
    }
  }
  
  // MARK: - Parse Connected Rooms
  private func parseConeectedRooms(_ room: Room) {
    let connectedRooms = room.rooms
    for (k, v) in connectedRooms {
      switch v {
      case .unlock(let roomId):
        concurrentQueue.async {
          // fetch new room with roomId and start location by recursion
          self.traversalRooms(roomId, start: room.locationForDirection(Direction(direction: k)))
        }
        
      case .lock(let lockId):
        concurrentQueue.async {
          let newRoomId = self.mazeManager.unlockRoom(withLock: lockId)
          self.traversalRooms(newRoomId, start: room.locationForDirection(Direction(direction: k)))
        }
      }
    }
  }
}
