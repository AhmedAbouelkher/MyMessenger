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
    private let activityIndicatorView = UIActivityIndicatorView(style: .medium)
    
    private let list = ["Log out"]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Delegates
        tableView.delegate = self
        tableView.dataSource = self
        
        //Add profile image
        tableView.tableHeaderView = createProfileImage()
        
        //Registering new UITableViewCell
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    func createProfileImage() -> UIView? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            print("Couldn't find the Current user email address")
            return nil
        }
        let safeEmail = DatabaseManager.createDataBaseEmail(with: email)
        let path = "images/\(safeEmail)_profile_image.png"
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.width, height: 200))
        
        headerView.backgroundColor = .link
        let width: CGFloat = 150.0
        let circulerImage = UIImageView(frame: CGRect(x: (headerView.width - width) / 2.0,
                                                      y: (headerView.height - width) / 2.0,
                                                      width: width,
                                                      height: width))
        
        circulerImage.contentMode = .scaleAspectFill
        circulerImage.layer.cornerRadius = circulerImage.width / 2.0
        circulerImage.backgroundColor = .white
        circulerImage.layer.borderColor = UIColor.gray.cgColor
        circulerImage.layer.borderWidth = 4
        circulerImage.clipsToBounds = true
        circulerImage.addSubview(activityIndicatorView)
        headerView.addSubview(circulerImage)
        
        activityIndicatorView.startAnimating()
        
        StorageManager.shared.downloadURL(for: path) {
            [weak self] result in
            switch result {
            case .success(let url):
                let urlObj = URL(string: url)
                print("urlObj: \(urlObj!)")
                self?.downloadImage(to: circulerImage, with: urlObj!)
            case .failure(let error):
                print("Failed to get download url: \(error)")
            }
        }
        
        return headerView
    }
    
    private func downloadImage(to imageView: UIImageView, with url: URL) {
        URLSession.shared.dataTask(with: url) { (data, _, error) in
            guard error == nil , let data = data else {
                print("Couldn't download the required image: \(error?.localizedDescription  ?? "nil error")")
                return
            }
            DispatchQueue.main.async {
                print(data)
                imageView.image = UIImage(data: data)
            }
        }.resume()
    }
}

extension ProfileViewController : UITableViewDelegate, UITableViewDataSource {

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = list[indexPath.row]
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = .red
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let logoutSheet = UIAlertController(title: "Loging Out",
                                            message: "Are you sure you want to log out?",
                                            preferredStyle: .actionSheet)
        
        logoutSheet.addAction(UIAlertAction(title: "Log out", style: .destructive, handler: { [weak self] _ in
            guard let strongSelf = self else { return }
            //Singing out of Google
            GIDSignIn.sharedInstance()?.signOut()
            // TODO: signing out of Facebook
            
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
