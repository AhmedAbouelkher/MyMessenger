//
//  UserModel.swift
//  Messenger
//
//  Created by Ahmed on 1/5/21.
//  Copyright © 2021 Ahmed. All rights reserved.
//

import Foundation

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let user = try? newJSONDecoder().decode(User.self, from: jsonData)


// MARK: - User
struct User: Codable {
    let email, firstName, id, lastName: String
    let name, uid: String
    
    var imageURL: String {
        get { return "images/\(id)_profile_image.png" }
    }

    enum CodingKeys: String, CodingKey {
        case email
        case firstName = "first_name"
        case id
        case lastName = "last_name"
        case name, uid
    }
}
