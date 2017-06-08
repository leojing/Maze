//
//  MazeUIUpdateManager.swift
//  Maze
//
//  Created by JINGLUO on 29/5/17.
//  Copyright © 2017 JINGLUO. All rights reserved.
//

import Foundation


protocol MazeUIUpdateProtocol {
  
  func updateMazeViewWith(_ imageUrl: String?, x: Float, y: Float)
  func updateMazeViewWithError(_ error: Error?)
  
}
