//
//  ViewController.swift
//  Maze
//
//  Created by JINGLUO on 26/5/17.
//  Copyright © 2017 JINGLUO. All rights reserved.
//

import UIKit
import SDWebImage

class ViewController: UIViewController {

  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var generateButton: UIButton!
  @IBOutlet weak var loremButton: UIButton!
  @IBOutlet weak var ipsumButton: UIButton!
  @IBOutlet weak var mazeView: UIView!
  @IBOutlet weak var widthOfMazeView: NSLayoutConstraint!
  @IBOutlet weak var heightOfMazeView: NSLayoutConstraint!
  @IBOutlet weak var topOfMazeView: NSLayoutConstraint!
  @IBOutlet weak var leadingOfMazeView: NSLayoutConstraint!

  fileprivate static let tileWidth: Float = 5.0
  fileprivate var miniX: Float = 0.0, miniY: Float = 0.0, maxX: Float = 0.0, maxY: Float = 0.0
  fileprivate var startTime: Date?, endTime: Date?
  
  public var mazeLogicManager = MazeLogicManager()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    if let backgroungImg = UIImage(named: "Background") {
      self.view.backgroundColor = UIColor(patternImage: backgroungImg)
    }
  }
 
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
}

// MARK: - set up

extension ViewController {
  
  fileprivate func setup() {
    setupUI()
    setupLogicManager()
  }
  
  private func setupLogicManager() {
    miniX = 0
    miniY = 0
    maxX = miniX
    maxY = miniY
    
    startTime = Date()
    endTime = nil
    
    mazeLogicManager.uiUpdateProtocol = self
    mazeLogicManager.startFetchRoom(x: miniX, y: miniY)
  }
  
  private func setupUI() {
    for view in mazeView.subviews {
      view.removeFromSuperview()
    }
  }
}

// MARK: - Button Actions

extension ViewController {
  
  @IBAction func generateAction(_ sender: Any) {
    print("generate")
    
    setup()
  }
  
  @IBAction func loremAction(_ sender: Any) {
    print("lorem")
  }
  
  @IBAction func ipsumAction(_ sender: Any) {
    print("ipsum")
  }

}

// MARK: - UI Updates

extension ViewController {
  
  // MARK: update MazeView's frame, location and draw tile into maze
  fileprivate func redrawMazeViewWith(_ imageUrl: String?, x: Float, y: Float) {
    // draw each room with it's relatively location (x, y) and tile image's url
    let tileWidth = CGFloat(ViewController.tileWidth)
    let _x = CGFloat(x) * tileWidth
    let _y = CGFloat(y) * tileWidth
    
    guard let url = imageUrl else {
      return
    }
    let tileImageView = UIImageView(frame: CGRect(x: _x, y: _y, width: tileWidth, height: tileWidth))
    tileImageView.sd_setImage(with: URL(string: url))
    self.mazeView.addSubview(tileImageView)
    
    
    // adjust MazeView's frame and location by every time a new room is fetched to make sure Maze can cover correctly on Border background ImageView
    miniX = miniX < x ? miniX : x
    miniY = miniY < y ? miniY : y
    
    maxX = maxX > x ? maxX : x
    maxY = maxY > y ? maxY : y
    
    self.widthOfMazeView.constant =  tileWidth * CGFloat(self.maxX-self.miniX)
    self.heightOfMazeView.constant = tileWidth * CGFloat(self.maxY-self.miniY)
    
    self.topOfMazeView.constant = tileWidth * CGFloat(self.miniY) - 10
    self.leadingOfMazeView.constant = tileWidth * CGFloat(self.miniX) - 10
    
    self.view.updateConstraintsIfNeeded()
    self.view.layoutIfNeeded()
  }
  
  // MARK: count how many time had been spent to creat the Maze
  fileprivate func updateTimer() {
    endTime = Date()
    if let startTime = startTime, let endTime = endTime {
      let interval = endTime.timeIntervalSince(startTime)
      timeLabel.text = "Spent time: \(String(format: "%.2f", interval)) seconds"
    }
  }

}

// MARK: - Conform to MazeUIUpdateProtocol

extension ViewController: MazeUIUpdateProtocol {
  
  // MARK: Error handling
  func updateMazeViewWithError(_ error: Error?) {
    let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
    alert.addAction(UIAlertAction(title: "oOh...", style: UIAlertActionStyle.cancel, handler:nil))
//    self.present(alert, animated: true, completion: nil)
    if let errorMsg = error?.localizedDescription {
      print("Error! \(errorMsg)")
    }
  }

  // MARK: update maze view
  func updateMazeViewWith(_ imageUrl: String?, x: Float, y: Float) {
    redrawMazeViewWith(imageUrl, x: x, y: y)
    updateTimer()
  }
  
}

