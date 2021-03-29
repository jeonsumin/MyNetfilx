//
//  PlayerViewController.swift
//  MyNetflix
//
//  Created by joonwon lee on 2020/04/01.
//  Copyright © 2020 com.joonwon. All rights reserved.
//

import UIKit
import AVFoundation

class PlayerViewController: UIViewController {
    
    @IBOutlet weak var playerView: PlayerView!
    @IBOutlet weak var controlView: UIView!
    @IBOutlet weak var playButton: UIButton!
    
    let player = AVPlayer()
    
    //로딩시 가로모드로 고정
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask{
        return .landscapeRight
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        playerView.player = player
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        play()
    }
    
    @IBAction func tappedPlayButton(_ sender: Any) {
        playButton.isSelected = !playButton.isSelected
        if player.isPlaying {
            pause()
        }else{
            play()
        }
        
        
    }
    
    func play(){
        player.play()
        playButton.isSelected = true
    }
    
    func pause(){
        player.pause()
        playButton.isSelected = false
    }
    
    func reset(){
        pause()
        player.replaceCurrentItem(with: nil)
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        reset()
        dismiss(animated: false, completion: nil)
    }
}

// 플레이어가 진행중인지 아닌지 체크
extension AVPlayer {
    var isPlaying: Bool {
        guard self.currentItem != nil else { return false }
        return self.rate != 0
    }
}
