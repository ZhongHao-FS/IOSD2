//
//  ViewController.swift
//  ZhongHao_4.1
//
//  Created by Hao Zhong on 8/10/21.
//

import UIKit
import CoreData

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return playingDeck.numOfCards
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Image_cell", for: indexPath) as! ImageCollectionViewCell
        
        cell.imageView.image = UIImage(imageLiteralResourceName: "\(playingDeck.cards[indexPath.item].imageName)")
        
        cell.backgroundColor = .white
        cell.layer.cornerRadius = 10
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = view.frame.width
        let height = view.frame.height
        var length = width * 0.2
        
        if self.traitCollection.userInterfaceIdiom == .pad {
            if height > width {
                length = width * 0.14
            } else {
                length = height * 0.14
            }
        } else if self.traitCollection.verticalSizeClass == .compact {
            length = height * 0.2
        }
        
        return CGSize(width: length, height: length)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Get the user selected cell
        let cell = collectionView.cellForItem(at: indexPath) as! ImageCollectionViewCell
        
        // Flip the card if it is not flipped
        if playingDeck.cards[indexPath.item].isFlipped == false {
            cell.flip()
            playingDeck.cards[indexPath.item].isFlipped = true
            
            if openCard == nil {
                openCard = indexPath
            } else {
                compareCards(indexPath)
                openCard = nil
            }
        }
        
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var gameOverLabel: UILabel!
    @IBOutlet weak var playButton: UIBarButtonItem!
    @IBOutlet weak var timerDisplay: UIBarButtonItem!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var movesItem: UIBarButtonItem!
    @IBOutlet weak var movesLabel: UILabel!
    @IBOutlet weak var sureButton: UIButton!
    
    var playingDeck = Deck(24)
    var remainingCards = 24
    var timer: Timer?
    var countDownFive: Float = 500 // Five seconds
    var gameTime: Float = 0
    var moves = 0
    var openCard: IndexPath? = nil
    let screen: CGRect = UIScreen.main.bounds
    
    private var appDelegate: AppDelegate!
    private var managedContext: NSManagedObjectContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let bound = screen.height + screen.width
        if self.traitCollection.userInterfaceIdiom == .pad {
            playingDeck = Deck(40)
            remainingCards = 40
        } else if bound < 1151 {
            playingDeck = Deck(20)
            remainingCards = 20
        }
        if self.traitCollection.verticalSizeClass == .compact {
            timerDisplay.isEnabled = false
        }
        collectionView.isUserInteractionEnabled = false
        
        appDelegate = UIApplication.shared.delegate as? AppDelegate
        managedContext = appDelegate.persistentContainer.viewContext
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if self.traitCollection.verticalSizeClass == .compact {
            timerDisplay.isEnabled = false
        } else {
            timerDisplay.isEnabled = true
        }
    }
    
    @IBAction func startOrNewGame(_ sender: UIBarButtonItem) {
        if playButton.title == "Start" {
            playButton.title = "New Game"
            for eachCell in collectionView.visibleCells {
                let cell = eachCell as? ImageCollectionViewCell
                cell?.flip()
            }
            
            timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(countingDown), userInfo: nil, repeats: true)
            
        } else {
            playButton.title = "Start"
            
            playingDeck = Deck(playingDeck.numOfCards)
            remainingCards = playingDeck.numOfCards
            collectionView.reloadData()
            collectionView.isUserInteractionEnabled = false
            openCard = nil
            
            timer?.invalidate()
            countDownFive = 500
            gameTime = 0
            moves = 0
            gameOverLabel.isHidden = true
            sureButton.isEnabled = false
            sureButton.isHidden = true
        }
    }
    
    @objc func countingDown() {
        countDownFive -= 1
        let seconds = String(format: "%.2f", countDownFive/100)
        timerDisplay?.title = "Starts in: \(seconds)"
        timerLabel?.text = "Starts in: \n\(seconds)"
        
        if countDownFive <= 0 {
            timer?.invalidate()
            
            for eachCell in collectionView.visibleCells {
                let cell = eachCell as? ImageCollectionViewCell
                cell?.flipBack(0)
            }
            
            timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(timeElapsed), userInfo: nil, repeats: true)
        }
    }
    
    @objc func timeElapsed() {
        collectionView.isUserInteractionEnabled = true
        gameTime += 1
        let seconds = String(format: "%.2f", gameTime/100)
        timerDisplay?.title = "Time: \(seconds)"
        timerLabel?.text = "Time Elapsed: \n\(seconds)\nseconds"
    }
    
    func compareCards(_ secondSelectedCard: IndexPath) {
        moves += 1
        movesItem?.title = "\(moves) moves"
        movesLabel?.text = "\(moves) moves"
        let cellOne = collectionView.cellForItem(at: openCard!) as? ImageCollectionViewCell
        let cellTwo = collectionView.cellForItem(at: secondSelectedCard) as? ImageCollectionViewCell
        
        if playingDeck.cards[openCard!.item].imageName == playingDeck.cards[secondSelectedCard.item].imageName {
            cellOne?.remove()
            remainingCards -= 1
            
            cellTwo?.remove()
            remainingCards -= 1
            
            checkGameOver()
        } else {
            cellOne?.flipBack(0.7)
            playingDeck.cards[openCard!.item].isFlipped = false
            
            cellTwo?.flipBack(0.7)
            playingDeck.cards[secondSelectedCard.item].isFlipped = false
        }
    }
    
    func checkGameOver() {
        if remainingCards <= 0 {
            timer?.invalidate()
            gameOverLabel.text = "Congrats, you won!\n\nTime Used:\n\(String(format: "%.2f", gameTime/100)) seconds\n\(moves) moves\n\nPlease leave your name on Leader Board."
            gameOverLabel.isHidden = false
            sureButton.isHidden = false
            sureButton.isEnabled = true
        }
    }
    
    @IBAction func sureTapped(_ sender: UIButton) {
        var username: String? = nil
        let alert = UIAlertController(title: "Great Memory", message: "Please enter your username or initials", preferredStyle: .alert)
        alert.addTextField(configurationHandler: nil)
        alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: {_ in
            username = alert.textFields![0].text
            
            if let userName = username {
                self.save(username: userName)
                self.performSegue(withIdentifier: "ToLeaderBoard", sender: sender)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func save(username: String) {
        if username != "" {
            let entityHighScore = NSEntityDescription.entity(forEntityName: "HighScores", in: managedContext)
            let newHighScore = NSManagedObject(entity: entityHighScore!, insertInto: managedContext)
            newHighScore.setValue(Date(timeIntervalSinceNow: 0), forKey: "date")
            newHighScore.setValue(moves, forKey: "moves")
            newHighScore.setValue(username, forKey: "name")
            newHighScore.setValue(gameTime/100, forKey: "time")
            
            appDelegate.saveContext()
        }
        
    }
    
    @IBAction func titleTapped(_ sender: UIButton) {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Leader Board", style: .default, handler: {_ in
            self.performSegue(withIdentifier: "ToLeaderBoard", sender: sender)
        }))
        self.present(sheet, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination = segue.destination as! LeaderBoardViewController
        destination.managedContext = self.managedContext
    }
    
    @IBAction func unwindToRoot(_ unwindSegue: UIStoryboardSegue) {}
}

