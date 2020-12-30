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
    typealias GettingAllUsersCompletion = (Result<[[String:String]], DatabaseError>) -> Void
    
    /// Get all users in the database and show them to the user, using `(Result<[String:String], DatabaseError>) -> Void` compelition clouser
    public func getAllUsers(completion: @escaping GettingAllUsersCompletion) {
        database.child("users").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
    
    
    public enum DatabaseError: Error {
        case failedToFetch
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
