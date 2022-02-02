//
//  HistoryViewController.swift
//  MyNetflix
//
//  Created by Terry on 2020/11/18.
//  Copyright © 2020 com.joonwon. All rights reserved.
//

import UIKit
import FirebaseDatabase


class HistoryViewController: UIViewController {

    @IBOutlet weak var historyTable: UITableView!
    
    let db = Database.database().reference().child("searchHistory")
    
    var searchTerms: [SearchTerms] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        historyTable.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        db.observeSingleEvent(of: .value) { (snapshot) in
            
            guard let searchHistory = snapshot.value as? [String:Any] else { return }
            
            let JsonData = try! JSONSerialization.data(withJSONObject: Array(searchHistory.values), options: [])
            
            let decoder = JSONDecoder()
            let searchTerms = try! decoder.decode([SearchTerms].self, from: JsonData)
            self.searchTerms = searchTerms.sorted{ $0.timestamp > $1.timestamp}
            /*
            (by: { (term1, term2) in
                return term1.timestamp > term2.timestamp
            })*/
            self.historyTable.reloadData()
        }
    }
}
extension HistoryViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchTerms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryListCell", for: indexPath) as? HistoryListCell else { return UITableViewCell() }
        cell.lbHistory.text = searchTerms[indexPath.row].term
        
        return cell
    }
    
    
}

class HistoryListCell : UITableViewCell {
    
    @IBOutlet weak var lbHistory: UILabel!
}


struct SearchTerms :Codable {
    let term: String
    let timestamp: TimeInterval
}
