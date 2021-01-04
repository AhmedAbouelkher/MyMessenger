//
//  MessagingModels.swift
//  Messenger
//
//  Created by Ahmed on 1/4/21.
//  Copyright © 2021 Ahmed. All rights reserved.
//

import Foundation
import MessageKit

struct Message: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    var timeStamp: Double
    
}

extension MessageKind {
    var messageKindString: String {
        switch self {
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .custom(_):
            return "customc"
        case .linkPreview(_):
            return "linkPreview"
        }
    }
}

struct Sender: SenderType {
    var imageURL: String {
        get { return "images/\(self.senderId)_profile_image.png" }
    }
    var senderId: String
    var displayName: String
}

struct Reciver: SenderType {
    var imageURL: String {
        get { return "images/\(self.senderId)_profile_image.png" }
    }
    var senderId: String
    var displayName: String
}
