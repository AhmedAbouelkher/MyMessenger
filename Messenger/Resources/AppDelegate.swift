//
//  AppDelegate.swift
//  Messenger
//
//  Created by Ahmed on 12/27/20.
//  Copyright © 2020 Ahmed. All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        FirebaseApp.configure()
        
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )

        GIDSignIn.sharedInstance()?.clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance()?.delegate = self

        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {

        ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )

        return GIDSignIn.sharedInstance().handle(url)
    }
}

extension AppDelegate : GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        guard error == nil else {
            if let error = error {
                print("Failed to sign in with Google: \(error.localizedDescription)")
            }
            return
        }

        guard let user = user else {
            return
        }

        print("Did sign in with Google: \(user)")

        guard let email = user.profile.email,
            let firstName = user.profile.givenName,
            let lastName = user.profile.familyName else {
                return
        }
        UserDefaults.standard.set(email, forKey: "email")
        
        DatabaseManager.shared.userExists(with: email) { (exists) in
            if !exists {
                // insert to database
                let chatUser = ChatAppUser(uid: user.userID,
                                           firstName: firstName,
                                           lastName: lastName,
                                           email: email)
                
                DatabaseManager.shared.createNewUser(user: chatUser) { success in
                    print("Creating new user resaults: \(success)")
                    if success {
                        //Uploading User Image
                        if !user.profile.hasImage { return }
                        let imageUrl = user.profile.imageURL(withDimension: 200)
                        URLSession.shared.dataTask(with: imageUrl!) { (data, _, error) in
                            guard error == nil , let data = data else {
                                print("Error while downloading Google image: \(error?.localizedDescription ?? "nil error")")
                                return
                            }
                            StorageManager.shared.uploadProfilePicture(with: data, fileName: chatUser.imageUrl) { result in
                                switch result {
                                case .success(let url):
                                    UserDefaults.standard.set(url, forKey: "profile_image")
                                case .failure(let e ):
                                    print("Error While uploading to storage: \(e.localizedDescription)")
                                }
                            }
                        }.resume()
                    } else {
                        
                    }
                    
                }
            }
        }
        

        
        guard let authentication = user.authentication else {
            print("Missing auth object off of google user")
            return
        }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)

        FirebaseAuth.Auth.auth().signIn(with: credential, completion: { authResult, error in
            guard authResult != nil, error == nil else {
                print("failed to log in with google credential")
                return
            }
            print("Successfully signed in with Google credential.")
            NotificationCenter.default.post(name: .didLogInNotification, object: nil)
        })
    }

    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        print("Google user was disconnected")
        
    }
}
