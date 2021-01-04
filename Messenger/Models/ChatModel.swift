//
//  UserChatRefModel.swift
//  Messenger
//
//  Created by Ahmed on 1/4/21.
//  Copyright © 2021 Ahmed. All rights reserved.
//

import Foundation

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let userChatRef = try? newJSONDecoder().decode(UserChatRef.self, from: jsonData)

import Foundation

// MARK: - Chat
struct Chat: Codable {
    let id: String
    let reciverUser: UserRef
    let senderUser: UserRef
    let latestMessage: LatestMessage

    enum CodingKeys: String, CodingKey {
        case id
        case reciverUser = "reciver_user"
        case senderUser = "sender_user"
        case latestMessage = "latest_message"
    }
}

// MARK: - LatestMessage
struct LatestMessage: Codable {
    let message, date: String
    let timeStamp: Double
    let isRead: Bool

    enum CodingKeys: String, CodingKey {
        case message, date
        case timeStamp = "time_stamp"
        case isRead = "is_read"
    }
}

// MARK: - UserRef
struct UserRef: Codable {
    let userID, name: String
    
    var imageURL: String {
        get { return "images/\(self.userID)_profile_image.png" }
    }

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case name
    }
}


//struct Chat {
//    let id: String
//    let otherUser: Reciver
//    let latestMessage: LatestMessage
//}
//
//struct LatestMessage {
//    let date: String
//    let message: String
//    let isRead: Bool
//}
