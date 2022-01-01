//
//  LeaderBoardViewController.swift
//  ZhongHao_4.1
//
//  Created by Hao Zhong on 8/27/21.
//

import UIKit
import CoreData

class LeaderBoardViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return leadersArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "highscore_Cell_1", for: indexPath)
        let leader = leadersArray[indexPath.row]
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        
        cell.textLabel?.text = leader.name
        cell.detailTextLabel?.text = "\(leader.time) secs, \(leader.moves) moves \(dateFormatter.string(from: leader.date!))"
        
        return cell
    }
    
    @IBOutlet weak var leaderBoard: UITableView!
    
    var managedContext: NSManagedObjectContext!
    var leadersArray = [HighScores]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        load()
        while leadersArray.count > 5 {
            leadersArray.removeLast()
        }
        leaderBoard.reloadData()
    }
    
    func load() {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "HighScores")
        do {
            let results: [NSManagedObject] = try managedContext.fetch(fetchRequest)
            for obj in results {
                let hS = obj as! HighScores
                leadersArray.append(hS)
            }
        } catch {
            assertionFailure()
        }
        
        leadersArray.sort(by: {$0.time < $1.time})
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
