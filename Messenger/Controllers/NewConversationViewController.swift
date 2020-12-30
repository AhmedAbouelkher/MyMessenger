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
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
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
    
    
    private var results = [[String: String]]()
    private var fetchedUsers = [[String: String]]()
    private var hasFetched = false
    

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = results[indexPath.row]["name"]
        return cell
    }
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
        
        DatabaseManager.shared.getAllUsers { [weak self] result in
            switch  result {
            case .success(let users):
                self?.hasFetched = true
                self?.fetchedUsers = users
                self?.filterSearchResults(with: query)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    private func filterSearchResults(with query: String) {
        let results: [[String:String]] = self.fetchedUsers.filter { dic -> Bool in
            guard let name = dic["name"]?.lowercased() else {
                return false
            }
            return name.hasPrefix(query.lowercased())
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
