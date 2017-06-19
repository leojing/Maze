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
    if var roomInfo = Room(json: json) {
      // set default location for room
      roomInfo.setupLocation(start)
      
      // Parse room id
      logicManager.parseRoomId(roomInfo.id, logicManager: logicManager)
      
      // Parse tile image url
      logicManager.parseTileURL(roomInfo.tileUrl, start: start, logicManager: logicManager)
      
      // Parse connected rooms
      logicManager.parseConeectedRooms(roomInfo.rooms, room: roomInfo, logicManager: logicManager)
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
  private func parseConeectedRooms(_ connectedRooms: [String: Any], room: Room, logicManager: MazeLogicManager) {
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
          logicManager.traversalRooms(newRoomId, start: room.locationForDirection(Direction(direction: k)))
        }
      }
    }
  }
}
