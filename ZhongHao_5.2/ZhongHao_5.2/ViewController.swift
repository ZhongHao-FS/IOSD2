//
//  ViewController.swift
//  ZhongHao_5.2
//
//  Created by Hao Zhong on 8/17/21.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController, MCBrowserViewControllerDelegate, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        let alert = UIAlertController(title: "Incoming connection from \(peerID.displayName)", message: "Do you want to accept this connection?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Accept", style: .default, handler: { (action) in
            invitationHandler(true, self.session)
        }))
        
        alert.addAction(UIAlertAction(title: "Decline", style: .destructive, handler: { (action) in
            invitationHandler(false, self.session)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case MCSessionState.connecting:
                self.configNavTitle("Connecting...")
            case MCSessionState.connected:
                if session.connectedPeers.count > 1 {
                    self.configNavTitle("Connected to \(session.connectedPeers.count) peers")
                } else {
                    self.configNavTitle("Connected to \(peerID.displayName)")
                    if self.opponentName.text != peerID.displayName {
                        self.winCount = 0
                        self.loseCount = 0
                        self.tieCount = 0
                        self.opponentName.text = peerID.displayName
                    }
                }
                self.waitingPlayers = 0
                self.connectButton.title = "Disconnect"
                self.updateScore("Tap \"Play\" for a new round:")
            default:
                self.configNavTitle("Not Connected")
                self.connectButton.title = "Connect"
                self.messageLabel.text = "Welcome!\nPlease connect to play"
                self.playButton.isHidden = true
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let message: String = String(data: data, encoding: String.Encoding.utf8) {
            DispatchQueue.main.async {
                switch message {
                case "Play Intention":
                    self.waitingPlayers += 1
                    if self.waitingPlayers == 2 {
                        self.gameStart()
                    }
                case "":
                    print("Wrong Message")
                default:
                    self.opponentChoice = message
                    self.checkWinner()
                }
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        browserViewController.dismiss(animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        browserViewController.dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var connectButton: UIBarButtonItem!
    @IBOutlet weak var winLabel: UILabel!
    @IBOutlet weak var loseLabel: UILabel!
    @IBOutlet weak var tieLabel: UILabel!
    @IBOutlet weak var opponentName: UILabel!
    @IBOutlet weak var theirMove: UIImageView!
    @IBOutlet weak var yourMove: UIImageView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var chooseRPS: UISegmentedControl!
    
    var peerID: MCPeerID!
    var session: MCSession!
    var browser: MCBrowserViewController!
    var advertiser: MCNearbyServiceAdvertiser!
    let serviceID = "RPS"
    var winCount = 0
    var loseCount = 0
    var tieCount = 0
    var myChoice = ""
    var opponentChoice = ""
    var waitingPlayers = 0
    var timer: Timer?
    var countDownThree = 3
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        peerID = MCPeerID(displayName: UIDevice.current.name)
        session = MCSession(peer: peerID)
        session.delegate = self
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceID)
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
        
        messageLabel.text = "Welcome!\nPlease connect to play"
        playButton.layer.cornerRadius = 10
        playButton.isHidden = true
        chooseRPS.isHidden = true
        // Now I use auto-font sizing instead of a hard coded size.
        // self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: UIFont(name: "Helvetica", size: 10)!]
    }

    func configNavTitle(_ title: String) {
        let tempLabel = UILabel()
            tempLabel.font = UIFont(name: "Helvetica", size: 24)
            tempLabel.text = title

        if tempLabel.intrinsicContentSize.width > UIScreen.main.bounds.width - 30 {
            var bestFontSize: CGFloat = 24
            for _ in 10 ... 24 {
                bestFontSize -= 1
                tempLabel.font = UIFont(name: "Helvetica", size: bestFontSize)
                if tempLabel.intrinsicContentSize.width < UIScreen.main.bounds.width - 30 {
                    break
                }
            }
            self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.font : UIFont(name: "Helvetica", size: bestFontSize)!]
        }
        self.navItem.title = title
    }
    
    @IBAction func connectTapped(_ sender: UIBarButtonItem) {
        if connectButton.title == "Connect" {
            browser = MCBrowserViewController(serviceType: serviceID, session: session)
            browser.delegate = self
            
            self.present(browser, animated: true, completion: nil)
        } else {
            session.disconnect()
            connectButton.title = "Connect"
        }
    }
    
    @IBAction func playTapped(_ sender: UIButton) {
        playButton.isEnabled = false
        waitingPlayers += 1
        
        if let playRequest = "Play Intention".data(using: String.Encoding.utf8) {
            do {
                try session.send(playRequest, toPeers: session.connectedPeers, with: MCSessionSendDataMode.reliable)
            } catch {
                print("Error starting games")
            }
        }
        
        if waitingPlayers == 2 {
            gameStart()
        }
    }
    
    @IBAction func choiceChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 1:
            myChoice = "paper"
        case 2:
            myChoice = "scissors"
        default:
            myChoice = "rock"
        }
    }
    
    func updateScore(_ message: String) {
        winLabel.text = "Win:\n\(winCount)"
        loseLabel.text = "Lose:\n\(loseCount)"
        tieLabel.text = "Tie:\n\(tieCount)"
        messageLabel.text = message
        chooseRPS.isHidden = true
        playButton.isHidden = false
        playButton.isEnabled = true
    }
    
    func gameStart() {
        chooseRPS.isHidden = false
        countDownThree = 3
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(shoot), userInfo: nil, repeats: true)
    }
    
    @objc func shoot() {
        messageLabel.text = "\(countDownThree)"
        countDownThree -= 1
        
        if countDownThree == 0 {
            timer?.invalidate()
            messageLabel.text = "SHOOT!"
            if myChoice == "" {
                switch chooseRPS.selectedSegmentIndex {
                case 1:
                    myChoice = "paper"
                case 2:
                    myChoice = "scissors"
                default:
                    myChoice = "rock"
                }
            }
            
            if let myShoot = myChoice.data(using: String.Encoding.utf8) {
                do {
                    try session.send(myShoot, toPeers: session.connectedPeers, with: MCSessionSendDataMode.reliable)
                } catch {
                    print("Error Shooting")
                }
            }
            
            checkWinner()
        }
    }
    
    func checkWinner() {
        if myChoice != "" && opponentChoice != "" {
            switch myChoice {
            case "paper":
                switch opponentChoice {
                case "paper":
                    theirMove.image = UIImage(imageLiteralResourceName: "Paper")
                    yourMove.image = UIImage(imageLiteralResourceName: "Paper")
                    tieCount += 1
                    updateScore("Tie!")
                case "scissors":
                    theirMove.image = UIImage(imageLiteralResourceName: "Scissors")
                    yourMove.image = UIImage(imageLiteralResourceName: "Paper")
                    loseCount += 1
                    updateScore("You lost!")
                default:
                    theirMove.image = UIImage(imageLiteralResourceName: "Rock")
                    yourMove.image = UIImage(imageLiteralResourceName: "Paper")
                    winCount += 1
                    updateScore("You win!")
                }
            case "scissors":
                switch opponentChoice {
                case "paper":
                    theirMove.image = UIImage(imageLiteralResourceName: "Paper")
                    yourMove.image = UIImage(imageLiteralResourceName: "Scissors")
                    winCount += 1
                    updateScore("You win!")
                case "scissors":
                    theirMove.image = UIImage(imageLiteralResourceName: "Scissors")
                    yourMove.image = UIImage(imageLiteralResourceName: "Scissors")
                    tieCount += 1
                    updateScore("Tie!")
                default:
                    theirMove.image = UIImage(imageLiteralResourceName: "Rock")
                    yourMove.image = UIImage(imageLiteralResourceName: "Scissors")
                    loseCount += 1
                    updateScore("You lost!")
                }
            default:
                switch opponentChoice {
                case "paper":
                    theirMove.image = UIImage(imageLiteralResourceName: "Paper")
                    yourMove.image = UIImage(imageLiteralResourceName: "Rock")
                    loseCount += 1
                    updateScore("You lost!")
                case "scissors":
                    theirMove.image = UIImage(imageLiteralResourceName: "Scissors")
                    yourMove.image = UIImage(imageLiteralResourceName: "Rock")
                    winCount += 1
                    updateScore("You win!")
                default:
                    theirMove.image = UIImage(imageLiteralResourceName: "Rock")
                    yourMove.image = UIImage(imageLiteralResourceName: "Rock")
                    tieCount += 1
                    updateScore("Tie!")
                }
            }
            myChoice = ""
            opponentChoice = ""
            waitingPlayers = 0
        }
    }
}

