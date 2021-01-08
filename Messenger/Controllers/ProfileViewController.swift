//
//  ProfileViewController.swift
//  Messenger
//
//  Created by Ahmed on 12/27/20.
//  Copyright © 2020 Ahmed. All rights reserved.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import SDWebImage


class ProfileViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private let headerView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let profileImage: UIImageView = {
        let circulerImage = UIImageView()
        circulerImage.contentMode = .scaleAspectFill
        circulerImage.layer.cornerRadius = circulerImage.width / 2.0
        circulerImage.backgroundColor = .white
        circulerImage.layer.borderColor = UIColor.gray.cgColor
        circulerImage.layer.borderWidth = 4
        circulerImage.clipsToBounds = true
        return circulerImage
    }()
    
    private let userNameLabel: UILabel = {
       let label = UILabel()
        label.font = .boldSystemFont(ofSize: 20)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    
    private var data = [ProfileViewModel]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Delegates
        tableView.delegate = self
        tableView.dataSource = self
        
        //Registering new UITableViewCell
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: ProfileTableViewCell.identifier)
        
        //Adding Rows
        let userEmail = ProfileViewModel(
            viewModelType: .info,
            title: "E-mail: am303737@gmail.com",
            icon: nil,
            handler: nil
        )
        let name = ProfileViewModel(
            viewModelType: .info,
            title: "Name: Ahmed Mahmoud",
            icon: Icon(
                icon: UIImage(systemName: "person")!,
                iconTint: .white,
                backgroundColor: .link
            ),
            handler: nil
        )
        let logout = ProfileViewModel(
            viewModelType: .logout,
            title: "Sign out",
            icon: nil) { [weak self] in
            guard let self = self else { return }
            self.logout()
        }
        data.append(userEmail)
        data.append(name)
        data.append(logout)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        //Add Profile Image
        tableView.tableHeaderView = createProfileImage()
    }
    
    func createProfileImage() -> UIView? {
        guard let safeEmail = DatabaseManager.getCurrentUserID,
              let currentUser = Auth.auth().currentUser,
              let name = currentUser.displayName,
              let _ = currentUser.email else {
            print("Couldn't find the Current user email address")
            return nil
        }
        
        let subViews: [UIView] = [
            profileImage,
            userNameLabel,
        ]
        
        subViews.forEach { headerView.addSubview($0) }
        userNameLabel.text = name

        headerView.frame = CGRect(
            x: 0,
            y: 0,
            width: view.width,
            height: 220
        )
        let imageWidth: CGFloat = 120.0
        profileImage.frame = CGRect(
            x: (headerView.width - imageWidth) / 2.0,
            y: (headerView.height - imageWidth) / 2.0,
            width: imageWidth,
            height: imageWidth
        )
        profileImage.makeCirculer()

        let labelWidth: CGFloat = 200.0
        let labelhieght: CGFloat = 30.0
        userNameLabel.frame = CGRect(
            x: (headerView.width - labelWidth) / 2.0,
            y: profileImage.height + labelhieght + 30,
            width: labelWidth ,
            height: labelhieght
        )
        
        
        let path = "images/\(safeEmail)_profile_image.png"
        StorageManager.shared.downloadURL(for: path) {  [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
                    self.profileImage.sd_setImage(with: url, completed: nil)
                }
            case .failure(let error):
                print("Failed to get download url: \(error)")
            }
        }
        return headerView
    }
}

extension ProfileViewController : UITableViewDelegate, UITableViewDataSource {

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = data[indexPath.row]
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ProfileTableViewCell.identifier,
            for: indexPath
        ) as! ProfileTableViewCell
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = data[indexPath.row]
        model.handler?()
    }
    
    private func logout() {
        let logoutSheet = UIAlertController(
            title: "Loging Out",
            message: "Are you sure you want to log out?",
            preferredStyle: .actionSheet
        )
        
        logoutSheet.addAction(UIAlertAction(title: "Log out", style: .destructive, handler: { [weak self] _ in
            guard let strongSelf = self else { return }
            
            //Singing out of Google
            GIDSignIn.sharedInstance()?.signOut()
            
            do {
                try Auth.auth().signOut()
                let vc = LoginViewController()
                let navController = UINavigationController(rootViewController: vc)
                navController.modalPresentationStyle = .fullScreen
                strongSelf.present(navController, animated: true, completion: nil)
            } catch {
                print("Error: \(error)")
            }
        }))
        
        logoutSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(logoutSheet, animated: true, completion: nil)
    }
}
