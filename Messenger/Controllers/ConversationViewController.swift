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
    private var notificationObserver: NSObjectProtocol?
    
    private let chatsTableView: UITableView = {
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
        chatsTableView.dataSource = self
        chatsTableView.delegate = self
        
        view.addSubview(chatsTableView)
        view.addSubview(noConversationLabel)
        chatsTableView.separatorStyle = .none
                
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .compose,
            target: self,
            action: #selector(startNewConversationPressed)
        )
        
        notificationObserver =  NotificationCenter
            .default
            .addObserver(forName: .didLogInNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            self.listenToChats()
        }

    }
    
    override func viewDidLayoutSubviews() {
        chatsTableView.frame = view.bounds
        noConversationLabel.frame = CGRect(x: (view.width - 200) / 2,
                                           y: (view.height - 50) / 2,
                                           width: 200,
                                           height: 50)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        goToLoginPageIfNotLoggedIn()
        listenToChats()
    }

    
    deinit {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
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

    
    private func goToLoginPageIfNotLoggedIn() {
        let isLoggedIn = FirebaseAuth.Auth.auth().currentUser != nil
        if !isLoggedIn {
            let vc = LoginViewController()
            let navController = UINavigationController(rootViewController: vc)
            navController.modalPresentationStyle = .fullScreen
            present(navController, animated: false, completion: nil)
        }
    }
    
    
    private func listenToChats() {
        DatabaseManager.shared.loadChatsSnippet { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let chatsConv):
                guard !chatsConv.isEmpty  else {
                    self.chatsTableView.isHidden = true
                    self.noConversationLabel.isHidden = false
                    return
                }
                self.chats = chatsConv
                self.chatsTableView.isHidden = false
                self.noConversationLabel.isHidden = true
                DispatchQueue.main.async {
                    self.chatsTableView.reloadData()
                }
            case .failure(let error):
                print(error)
                self.chatsTableView.isHidden = true
                self.noConversationLabel.isHidden = false
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        //Begin Deleting
        let chat = chats[indexPath.row]
        tableView.beginUpdates()
        self.chats.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .left)
        
        DatabaseManager.shared.deleteChat(with: chat) { success in
            guard success else {
                print("Couldn't delete the chat")
                return
            }
            print("Conversation Deleted")
        }
        
        tableView.endUpdates()
    }
}
