//
//  NewConversationViewController.swift
//  Messenger
//
//  Created by Ahmed on 12/27/20.
//  Copyright © 2020 Ahmed. All rights reserved.
//

import UIKit
import JGProgressHUD

class NewConversationViewController: UIViewController {
    
    private let progressIndicator = JGProgressHUD(style: .dark)
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.register(NewConversationTableViewCell.self, forCellReuseIdentifier: NewConversationTableViewCell.identifier)
        return table
    }()
    
    private let searchBar: UISearchBar = {
       let search = UISearchBar()
        search.placeholder = "Search for Users..."
        search.autocorrectionType = .no
        search.autocapitalizationType = .none
        return search
    }()
    
    private let noResultsLabel: UILabel = {
       let label = UILabel()
        label.text = "No Results"
        label.textColor = .gray
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.isHidden = true
        return label
    }()
    
    
    ///Returns `target user data` as a dictionary
    public var completion: ((Reciver) -> (Void))?
    
    private var results = [User]()
    private var fetchedUsers = [User]()
    private var hasFetched = false
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        
        //Adding search
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(didTapDone))
        //Delegates
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        
        //Adding subViews
        view.addSubview(tableView)
        view.addSubview(noResultsLabel)
        
        tableView.separatorStyle = .none
    }
    
    override func viewDidLayoutSubviews() {
        searchBar.becomeFirstResponder()
        tableView.frame = view.bounds
        noResultsLabel.frame = CGRect(x: view.width/4,
                                      y: (view.height-200)/2,
                                      width: view.width/2,
                                      height: 200)
    }
    
    @objc private func didTapDone(){
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
}

extension NewConversationViewController : UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let result = results[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: NewConversationTableViewCell.identifier, for: indexPath) as! NewConversationTableViewCell
        cell.configure(with: result)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        //Start new convirsation
        let targetUser = results[indexPath.row]
        self.navigationController?.dismiss(animated: true, completion: { [weak self] in
            let reciver = Reciver(senderId: targetUser.id, displayName: targetUser.name)
            self?.completion?(reciver)
        })
    }

//    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 30
//    }
}

extension NewConversationViewController : UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchTerm = searchBar.text, !searchTerm.replacingOccurrences(of: " ", with: "").isEmpty else {
            print("Invalid Search term")
            return
        }
        searchBar.resignFirstResponder()
        progressIndicator.show(in: view)
        self.startSearching(with: searchTerm)
    }
    
    private func startSearching(with query: String) {
        
        guard !hasFetched else {
            filterSearchResults(with: query)
            return
        }
        
        DatabaseManager.shared.fetchAllUsers { [weak self] result in
            guard let self = self else {return}
            switch  result {
            case .success(let users):
                self.hasFetched = true
                self.fetchedUsers = users
                self.filterSearchResults(with: query)
            case .failure(let error):
                print(error)
                self.progressIndicator.dismiss()
                self.noResultsLabel.isHidden = false
                self.tableView.isHidden = true
                self.searchBar.resignFirstResponder()
            }
        }
    }
    
    private func filterSearchResults(with query: String) {
        let results: [User] = self.fetchedUsers.filter { user -> Bool in
            guard let currentEmailId = DatabaseManager.getCurrentUserID else {  return false  }
            let name = user.name.lowercased()
            if currentEmailId == user.id { return false }
            else { return name.hasPrefix(query.lowercased()) }
        }
        self.results = results
        self.progressIndicator.dismiss()
        updateUIWithSearchData()
    }
    
    
    private func updateUIWithSearchData() {
        if self.results.isEmpty {
            noResultsLabel.isHidden = false
            tableView.isHidden = true
        } else {
            noResultsLabel.isHidden = true
            tableView.isHidden = false
            tableView.reloadData()
        }
    }
}
