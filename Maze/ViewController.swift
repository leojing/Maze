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

extension ViewController: MazeUIUpdateProtocol {
  
  //MARK: update MazeView's frame, location and draw tile into maze
  func updateMazeViewWith(_ imageUrl: String?, x: Float, y: Float) {
    
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
  
}

