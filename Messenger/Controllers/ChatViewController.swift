//
//  ChatViewController.swift
//  Messenger
//
//  Created by Ahmed on 12/28/20.
//  Copyright © 2020 Ahmed. All rights reserved.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import JGProgressHUD
import FirebaseAuth

class ChatViewController: MessagesViewController {
    
    private let prgressIndicator = JGProgressHUD(style: .dark)
    
    private let noMessagesLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.textAlignment = .center
        label.textColor = .gray
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 19, weight: .medium)
        return label
    }()
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    
    private var messages = [Message]()
    private let otherUser: Reciver
    private let chat: Chat?
    
    private var sender: Sender? {
        guard  let email = UserDefaults.standard.value(forKey: "email") as? String,
        let currentUser =  Auth.auth().currentUser,
        let userName = currentUser.displayName else {
            print("FAILED TO GET CURRENT USER")
            return nil
        }
        let senderId = DatabaseManager.createDataBaseEmail(with: email)
        return Sender(senderId: senderId, displayName: userName)
    }
    
    init(with reciver: Reciver, in chat: Chat?) {
        self.otherUser = reciver
        self.chat = chat
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        
        view.addSubview(noMessagesLabel)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        loadMessages()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        noMessagesLabel.text = "Start Chating with \(otherUser.displayName)"
        
        noMessagesLabel.frame = CGRect(x: (view.width - 200) / 2,
                                           y: (view.height - 50) / 2,
                                           width: 200,
                                           height: 50)
    }
    
    private func loadMessages() {
        DatabaseManager.shared.loadChat(with: self.otherUser, in: self.chat) { [weak self] result in
            print(result)
            switch result {
            case .success(let messages):
                guard !messages.isEmpty else {
                    self?.messagesCollectionView.isHidden = true
                    self?.noMessagesLabel.isHidden = false
                    return
                }
                self?.messages = messages
                DispatchQueue.main.async {
                    self?.messagesCollectionView.isHidden = false
                    self?.noMessagesLabel.isHidden = true
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
//                    self?.messagesCollectionView.scrollToBottom()
                }
            case .failure(let error):
                print(error)
            }
        }
    }
}


extension ChatViewController : InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let messageId = createMessageId(),
              let currentSender = self.sender else {
            //Invalid Data to be sent
            print("Invalid Data to be sent")
            return
        }
        let date = Date()
        
        /*
         Reciver Data
         */
        
        let reviver = Reciver(
            senderId: self.otherUser.senderId,
            displayName: self.otherUser.displayName
        )
        
        /*
         Sending Message
         */
        
        let message = Message(
            sender: currentSender,
            messageId: messageId,
            sentDate: date,
            kind: .text(text),
            timeStamp: date.timeIntervalSince1970
        )
        
        DatabaseManager.shared.startChat(with: reviver, send: message, in: self.chat) { [weak self] success in
            if success {
                print("Message Sent Successfuly")
                self?.messageInputBar.inputTextView.text = ""
            } else {
                print("Message Sending Failed")
            }
        }
        
    }
    
    private func createMessageId() -> String? {
        // date, otherUesrEmail, senderEmail, randomInt
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            print("Created Message ID Failed")
            return nil
        }
        let safeCurrentEmail = DatabaseManager.createDataBaseEmail(with: currentUserEmail)
        let dateString = Self.dateFormatter.string(from: Date())
        let newIdentifier = "\(self.otherUser.senderId)_\(safeCurrentEmail)_\(dateString)"
        return newIdentifier
    }
}

extension ChatViewController : MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    func currentSender() -> SenderType {
        if let sender = self.sender {
            return sender
        }
        fatalError("##Self Sender is nil, email should be cached")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
}
