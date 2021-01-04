//
//  ViewController.swift
//  Messenger
//
//  Created by Ahmed on 12/27/20.
//  Copyright © 2020 Ahmed. All rights reserved.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

class ConversationViewController: UIViewController {
    
    private let progressHud = JGProgressHUD(style: .dark)
    
    private var chats = [Chat]()
    
    private let conversationsTableView: UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.register(ChatTableViewCell.self, forCellReuseIdentifier: ChatTableViewCell.identifier)
        return table
    }()
    
    private let noConversationLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.text = "Start Chating Now"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 19, weight: .medium)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //TableView Delegates
        conversationsTableView.dataSource = self
        conversationsTableView.delegate = self
        
        view.addSubview(conversationsTableView)
        view.addSubview(noConversationLabel)
        conversationsTableView.separatorStyle = .none
        
//        progressHud.show(in: self.view)
    }
    
    override func viewDidLayoutSubviews() {
        conversationsTableView.frame = view.bounds
        noConversationLabel.frame = CGRect(x: (view.width - 200) / 2,
                                           y: (view.height - 50) / 2,
                                           width: 200,
                                           height: 50)
        fetchChats()
//        progressHud.dismiss()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentLogin()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose,
                                                            target: self,
                                                            action: #selector(startNewConversationPressed))
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action,
                                                            target: self,
                                                            action: #selector(getFirebaseData))
    }
    
    @objc private func getFirebaseData() {
        guard let currentUser = Auth.auth().currentUser else {
            print("CAN'T GET CURRENT USER")
            return
        }
        print(currentUser.displayName)
        print(currentUser.email)
    }
    
    @objc private func startNewConversationPressed() {
        let vc = NewConversationViewController()
        vc.completion = { [weak self] reciver in
            self?.createNewConversation(with: reciver)
        }
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }

    private func createNewConversation(with reciver: Reciver) {
        let vc = ChatViewController(with: reciver, in: nil)
        vc.title = reciver.displayName
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }

    
    private func presentLogin() {
        let isLoggedIn = FirebaseAuth.Auth.auth().currentUser != nil
        if !isLoggedIn {
            let vc = LoginViewController()
            let navController = UINavigationController(rootViewController: vc)
            navController.modalPresentationStyle = .fullScreen
            present(navController, animated: false, completion: nil)
        }
    }
    
    private func fetchChats() {
        DatabaseManager.shared.loadChatsSnippet { [weak self] result in
            switch result {
            case .success(let chatsConv):
                self?.chats = chatsConv
                if chatsConv.isEmpty {
                    self?.conversationsTableView.isHidden = true
                    self?.noConversationLabel.isHidden = false
                } else {
                    self?.conversationsTableView.isHidden = false
                    self?.noConversationLabel.isHidden = true
                    DispatchQueue.main.async {
                        self?.conversationsTableView.reloadData()
                    }
                }
            case .failure(let error):
                print(error)
                self?.conversationsTableView.isHidden = true
                self?.noConversationLabel.isHidden = false
            }
        }
    }
}

extension ConversationViewController : UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.chats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let chat = self.chats[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatTableViewCell.identifier, for: indexPath) as! ChatTableViewCell
        cell.configure(with: chat)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let chat = self.chats[indexPath.row]
        let reciver = Reciver(senderId: chat.reciverUser.userID, displayName: chat.reciverUser.name)
        let vc = ChatViewController(with: reciver, in: chat)
        vc.title = chat.reciverUser.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 70
//    }
    
}
