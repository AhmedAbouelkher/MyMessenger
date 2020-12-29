//
//  DatabaseManager.swift
//  Messenger
//
//  Created by Ahmed on 12/28/20.
//  Copyright © 2020 Ahmed. All rights reserved.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    static var shared = DatabaseManager()
    
    private var database = Database.database().reference()
    
    public static func createDataBaseEmail(with email: String) -> String {
        let notAllowedChars: [String] = [ ".",  "#", "@", "[", "]" ]
        var safeEmail = email
        for char in notAllowedChars {
            safeEmail = safeEmail.replacingOccurrences(of: char, with: "-")
        }
        return safeEmail
    }

}

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
    public func createNewUser(with user: ChatAppUser) -> Void {
        database.child(user.databaseEmail).setValue([
            "first_name":user.firstName,
            "last_name": user.lastName,
            "email": user.email,
            "uid": user.uid
        ])
    }
    

}

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
