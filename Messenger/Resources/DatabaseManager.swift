//
//  DatabaseManager.swift
//  Messenger
//
//  Created by Ahmed on 12/28/20.
//  Copyright © 2020 Ahmed. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseFirestore
import FirebaseAuth
import FirebaseFirestoreSwift

typealias ChatsListenerBlock = (Result<[Chat], Error>) -> Void
typealias MessagesListenerBlock = (Result<[Message], Error>) -> Void
typealias GettingAllUsersCompletion = (Result<[[String:String]], Error>) -> Void


struct ChatAppUser {
    let uid: String?
    let firstName: String
    let lastName: String
    let email: String
    
    var databaseEmail: String {
        return DatabaseManager.createDataBaseEmail(with: self.email)
    }
    
    var imageUrl: String {
        return "\(self.databaseEmail)_profile_image.png"
    }
    
}

final class DatabaseManager {
    static var shared = DatabaseManager()
    
    private var database = Database.database().reference()
    private let fireDB = Firestore.firestore()
    
    
    public static func createDataBaseEmail(with email: String) -> String {
        let notAllowedChars: [String] = [ ".",  "#", "@", "[", "]" ]
        var safeEmail = email
        for char in notAllowedChars {
            safeEmail = safeEmail.replacingOccurrences(of: char, with: "-")
        }
        return safeEmail
    }
    
    public static func getCurrentUserID() -> String? {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let notAllowedChars: [String] = [ ".",  "#", "@", "[", "]" ]
        var safeEmail = currentEmail
        for char in notAllowedChars {
            safeEmail = safeEmail.replacingOccurrences(of: char, with: "-")
        }
        return safeEmail
    }
    
    public enum DatabaseError: Error {
        case failedToFetch
    }
}
//MARK: - Conversations Manager 'Real-time Database'
extension DatabaseManager {
    
    ///Load current user conversation in real-time
    public func loadChatsSnippet(listener: @escaping ChatsListenerBlock) -> Void {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let currentEmail = DatabaseManager.createDataBaseEmail(with: email)
        let currentUserChatsRef = fireDB.collection("users")
            .document(currentEmail)
            .collection("chats")
        currentUserChatsRef.addSnapshotListener { (snapshot, error) in
            guard error == nil, let docs = snapshot?.documents else {
                print("Loading error: \(error?.localizedDescription ?? "nil error")")
                listener(.failure(DatabaseError.failedToFetch))
                return
            }
            let chats: [Chat] = docs.compactMap { (doc) -> Chat? in
                guard let chat = try? doc.data(as: Chat.self) else {
                    print("Invaild Chat Model decoding")
                    return nil
                }
                return chat
            }
            listener(.success(chats))
        }
    }
    
    ///Loads the messages in real-time
    public func loadChat(with reciver: Reciver, in chat: Chat?, listener: @escaping MessagesListenerBlock) -> Void {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String  else {
            return
        }
        let currentEmail = DatabaseManager.createDataBaseEmail(with: email)
        ///Conversation ID `Auto-Generated if the conversation is new`
        var conversationId = "conversation@\(reciver.senderId)@\(currentEmail)"
        if let chat = chat { conversationId = chat.id }
        
        let chatRef = fireDB
            .collection("chats")
            .document(conversationId)
            .collection("messages")
            .order(by: "time_stamp", descending: false)
        chatRef.addSnapshotListener { (snapshot, error) in
            guard error == nil, let docs = snapshot?.documents else {
                if let e = error {
                    print("Loading error: \(e.localizedDescription)")
                } else {
                    print("Snapshot has \(snapshot?.count ?? -1) docs")
                }
                listener(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let messages: [Message] = docs.compactMap { (doc) -> Message? in
                print(doc.data())
                guard let firebaseChat = try? doc.data(as: FirebaseChat.self) else {
                    print("Invaild FirebaseChat Model decoding")
                    return nil
                }
                
                let senderUser = Sender(senderId: firebaseChat.sender.id, displayName: firebaseChat.sender.name)
                // TODO: Change date to be the message sending date
                let message = Message(
                    sender: senderUser,
                    messageId: firebaseChat.id,
                    sentDate: Date(),
                    kind: .text(firebaseChat.content),
                    timeStamp: firebaseChat.timeStamp
                )
                return message
                
            }
            listener(.success(messages))
            
        }
    }
    
    // TODO: [FIX] reciver and sender don't switch when the last one send new message
    //you should switch users when sending new message
    
    /// - Send First message that creates the chat between two users
    /// - Send the messages between theme after creating the first message
    public func startChat(with reciver: Reciver, send message: Message, in chat: Chat?, completion:  @escaping (Bool) -> Void ) {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String,
              let firebaseUser = Auth.auth().currentUser,
              /// Current Sender `username`
              let currentUserName = firebaseUser.displayName else {
            completion(false)
            return
        }
        
        ///The message content `text`, `photo`, `video`, etc..
        var messageContent = ""
        
        getMessagetype(message, &messageContent)
        
        ///Current User E-mail ID `Document ID`
        let currentEmail = DatabaseManager.createDataBaseEmail(with: email)
        
        ///Conversation ID `Auto-Generated if the conversation is new`
        var conversationId = "conversation@\(reciver.senderId)@\(currentEmail)"
        if let chat = chat { conversationId = chat.id }
        
        let messageDate = ChatViewController.dateFormatter.string(from: message.sentDate)
        
        /*
         Sending Messages
         */
        let batch = fireDB.batch()
        
        //Add new chat to chats
        let chatsRef = fireDB.collection("chats")
            .document(conversationId)
            .collection("messages")
            .document(message.messageId)
        
        let chat = FirebaseChat(
            id: message.messageId,
            type: message.kind.messageKindString,
            content: messageContent,
            date: messageDate,
            timeStamp: message.timeStamp,
            sender: ChatUser(
                id: currentEmail,
                email: email,
                name: currentUserName,
                imagePath: nil
            ),
            reciver: ChatUser(
                id: reciver.senderId,
                email: nil,
                name: reciver.displayName,
                imagePath: reciver.imageURL
            ),
            isRead: false
        )
        
        guard let _ = try? batch.setData(from: chat.self, forDocument: chatsRef) else {
            print("ERROR WHILE WRITING THE FIREBAE MESSAGE")
            completion(false)
            return
        }
        /*
         Adding chats to users
         */

        
        //Add new chat to current user
        let currentSenderFirebaseRef = fireDB.collection("users")
            .document(currentEmail)
            .collection("chats")
            .document(conversationId)
        
        let currentSenderFirebaseChatRef = Chat(
            id: conversationId,
            reciverUser: UserRef(
                userID: reciver.senderId,
                name: reciver.displayName
            ),
            senderUser: UserRef(
                userID: currentEmail,
                name: currentUserName
            ),
            latestMessage: LatestMessage(
                message: messageContent,
                date: messageDate,
                timeStamp: message.timeStamp,
                isRead: false
            )
        )
        
        guard let _ = try? batch.setData(from: currentSenderFirebaseChatRef.self, forDocument: currentSenderFirebaseRef) else {
            print("ERROR WHILE WRITING THE FIREBAE MESSAGE")
            completion(false)
            return
        }
        
        //Add new chat to other user
        
        let otherUserRef = fireDB.collection("users")
            .document(reciver.senderId)
            .collection("chats")
            .document(conversationId)
        
        let otherUserChatRef = Chat(
            id: conversationId,
            reciverUser: UserRef(
                userID: currentEmail,
                name: currentUserName
            ),
            senderUser: UserRef(
                userID: reciver.senderId,
                name: reciver.displayName
            ),
            latestMessage: LatestMessage(
                message: messageContent,
                date: messageDate,
                timeStamp: message.timeStamp,
                isRead: false
            )
        )
        
        guard let _ = try? batch.setData(from: otherUserChatRef.self, forDocument: otherUserRef) else {
            print("ERROR WHILE WRITING THE FIREBAE MESSAGE")
            completion(false)
            return
        }
        
        batch.commit { error in
            guard error == nil else {
                print("ERROR SENDING MESSAGES: \(error?.localizedDescription ?? "nil error")")
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    fileprivate func getMessagetype(_ message: Message, _ messageContent: inout String) {
        switch message.kind {
        case .text(let messageText):
            messageContent = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .custom(_):
            break
        case .linkPreview(_):
            break
        }
    }
   
}

//MARK: - Firestore
extension DatabaseManager {
    
    /// Checks weather the register user has already created a profile or not.
    public func userExists(with email: String, complition: @escaping ((Bool) -> Void)) {
        let safeEmail = DatabaseManager.createDataBaseEmail(with: email)
        fireDB.collection("users").document(safeEmail).getDocument { (document, error) in
            guard error != nil, let doc = document, doc.exists else {
                //User doesn't exist
                complition(false)
                return
            }
            //User exist
            complition(true)
        }
    }
    
    /// Creates a new user database profile.
    public func createNewUser(user: ChatAppUser, completion: @escaping (Bool) -> Void ) -> Void {
        let data: [String: Any] = [
            "id": DatabaseManager.createDataBaseEmail(with: user.email),
            "name": "\(user.firstName) \(user.lastName)",
            "first_name":user.firstName,
            "last_name": user.lastName,
            "email": user.email,
            "uid": user.uid ?? "null"
        ]
        fireDB.collection("users").document(user.databaseEmail).setData(data) { error in
            guard error == nil else {
                print("failed ot write to database")
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    /// Get all users in the database and show them to the user, using `(Result<[[String: String]], DatabaseError>) -> Void` compelition clouser
    public func fetchAllUsers(completion: @escaping GettingAllUsersCompletion) {
        fireDB.collection("users").getDocuments { (snapshot, error) in
            guard error == nil , let docs = snapshot?.documents else {
                print("Error while fetching all users: \(error?.localizedDescription ?? "nil error")")
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            var users: [[String: String]] = []
            for doc in docs {
                let data = doc.data() as! [String: String]
                users.append(data)
            }
            completion(.success(users))
        }
    }
    
    ///Updates user data `displayName` and `photoUrl`
    public func updateUserData(_ user: ChatAppUser, imageUrl: URL?, completion: @escaping (Bool) -> Void) -> Void {
        guard let currenUser = Auth.auth().currentUser else {
            completion(false)
            return
        }
        let userChange  = currenUser.createProfileChangeRequest()
        userChange.displayName = "\(user.firstName) \(user.lastName)"
        if imageUrl == imageUrl {
            userChange.photoURL = imageUrl
        }
        
        userChange.commitChanges { error in
            guard error == nil else {
                print("ERORR WHILE UPDATING USER \(error?.localizedDescription ?? "")")
                completion(false)
                return
            }
            completion(true)
        }
    }
    
}

//MARK: - DEPRECATED SECTION

//MARK: - Account Managment
extension DatabaseManager{
    
    /// Checks weather the register user has already created a profile or not.
    public func userExists(withEmail email: String, complition: @escaping ((Bool) -> Void)) {
        
        let safeEmail = DatabaseManager.createDataBaseEmail(with: email)
        
        database.child(safeEmail).observeSingleEvent(of: .value) { (snapshot) in
            guard snapshot.value as? String != nil else {
                complition(false)
                return
            }
            complition(true)
        }
    }
    
    /// Creates a new user database profile.
    public func createNewUser(with user: ChatAppUser, completion: @escaping (Bool) -> Void ) -> Void {
        database.child(user.databaseEmail).setValue([
            "first_name":user.firstName,
            "last_name": user.lastName,
            "email": user.email,
            "uid": user.uid
        ]) { error, _ in
            guard error == nil else {
                print("failed ot write to database")
                completion(false)
                return
            }
            
            self.database.child("users").observeSingleEvent(of: .value, with: { snapshot in
                if var usersCollection = snapshot.value as? [[String: String]] {
                    // append to user dictionary
                    let newElement = [
                        "name": user.firstName + " " + user.lastName,
                        "email": user.databaseEmail
                    ]
                    usersCollection.append(newElement)
                    
                    self.database.child("users").setValue(usersCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        completion(true)
                    })
                }
                else {
                    // create that array
                    let newCollection: [[String: String]] = [
                        [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.databaseEmail
                        ]
                    ]
                    self.database.child("users").setValue(newCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        completion(true)
                    })
                }
            })
        }
    }
    
    /// Get all users in the database and show them to the user, using `(Result<[String:String], DatabaseError>) -> Void` compelition clouser
    public func getAllUsers(completion: @escaping GettingAllUsersCompletion) {
        database.child("users").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
    
    

}

extension DatabaseManager {
    
    /*
     "dfsdfdsfds" {
     "messages": [
     {
     "id": String,
     "type": text, photo, video,
     "content": String,
     "date": Date(),
     "sender_email": String,
     "isRead": true/false,
     }
     ]
     }
     
     conversaiton => [
     [
     "conversation_id": "dfsdfdsfds"
     "other_user_email":
     "latest_message": => {
     "date": Date()
     "latest_message": "message"
     "is_read": true/false
     }
     ],
     ]
     */
    
    /// Creates a new conversation with target user emamil and first message sent
    public func createNewConversation(with otherUserEmail: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.createDataBaseEmail(with: currentEmail)
        
        let ref = database.child("\(safeEmail)")
        
        ref.observeSingleEvent(of: .value, with: { snapshot in
            guard var userNode = snapshot.value as? [String: Any] else {
                completion(false)
                print("user not found")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch firstMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .custom(_):
                break
            case .linkPreview(_):
                break
            }
            
            let conversationId = "conversation_\(firstMessage.messageId)"
            
            let newConversationData: [String: Any] = [
                "id": conversationId,
                "other_user_email": otherUserEmail,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                // conversation array exists for current user
                // you should append
                
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                ref.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(conversationID: conversationId,
                                                     firstMessage: firstMessage,
                                                     completion: completion)
                })
            }
            else {
                // conversation array does NOT exist
                // create it
                userNode["conversations"] = [
                    newConversationData
                ]
                
                ref.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    
                    self?.finishCreatingConversation(conversationID: conversationId,
                                                     firstMessage: firstMessage,
                                                     completion: completion)
                })
            }
        })
    }
    
    private func finishCreatingConversation(conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        //        {
        //            "id": String,
        //            "type": text, photo, video,
        //            "content": String,
        //            "date": Date(),
        //            "sender_email": String,
        //            "isRead": true/false,
        //        }
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        var message = ""
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .custom(_):
            break
        case .linkPreview(_):
            break
        }
        
        guard let myEmmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let currentUserEmail = DatabaseManager.createDataBaseEmail(with: myEmmail)
        
        let collectionMessage: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "sender_email": currentUserEmail,
            "is_read": false
        ]
        
        let value: [String: Any] = [
            "messages": [
                collectionMessage
            ]
        ]
        
        print("adding conversation: \(conversationID)")
        
        database.child("\(conversationID)").setValue(value, withCompletionBlock: { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
}
