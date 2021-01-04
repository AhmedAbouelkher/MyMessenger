//
//  ChatFirebaseModel.swift
//  Messenger
//
//  Created by Ahmed on 1/4/21.
//  Copyright © 2021 Ahmed. All rights reserved.
//

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let firebaseChat = try? newJSONDecoder().decode(FirebaseChat.self, from: jsonData)

import Foundation
import FirebaseFirestoreSwift

// MARK: - FirebaseChat
struct FirebaseChat: Codable {
    let id: String
    let type, content, date: String
    let timeStamp: Double
    let sender, reciver: ChatUser
    let isRead: Bool

    enum CodingKeys: String, CodingKey {
        case id, type, content, date
        case timeStamp = "time_stamp"
        case sender, reciver
        case isRead = "is_read"
    }
}

// MARK: - Reciver
struct ChatUser: Codable {
    let id: String
    let email: String?
    let name: String
    let imagePath: String?

    enum CodingKeys: String, CodingKey {
        case id, email, name
        case imagePath = "image_path"
    }
}
