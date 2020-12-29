//
//  RegisterViewController.swift
//  Messenger
//
//  Created by Ahmed on 12/27/20.
//  Copyright © 2020 Ahmed. All rights reserved.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

class RegisterViewController: UIViewController {
    
    private let progressHud = JGProgressHUD(style: .dark)
    
    let scrollView: UIScrollView =  {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        scrollView.isUserInteractionEnabled = true
        return scrollView
    }()
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person")
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.tintColor = .gray
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        imageView.layer.borderWidth = 3
        imageView.clipsToBounds = true
        return imageView
    }()
    
    
    let firstNameTxtField: UITextField = {
        let textField = UITextField()
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.returnKeyType = .continue
        textField.clearButtonMode = .whileEditing
        textField.backgroundColor = .white
        textField.layer.borderColor = UIColor.gray.cgColor
        textField.layer.borderWidth = 0.5
        textField.layer.cornerRadius = 15
        textField.placeholder = "First Name..."
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        textField.leftViewMode = .always
        return textField
    }()
    
    let lastNameTextField: UITextField = {
        let textField = UITextField()
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.returnKeyType = .continue
        textField.clearButtonMode = .whileEditing
        textField.backgroundColor = .white
        textField.layer.borderColor = UIColor.gray.cgColor
        textField.layer.borderWidth = 0.5
        textField.layer.cornerRadius = 15
        textField.placeholder = "Last Name..."
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        textField.leftViewMode = .always
        return textField
    }()
    
    let emailTextField: UITextField = {
        let textField = UITextField()
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.returnKeyType = .continue
        textField.keyboardType = .emailAddress
        textField.clearButtonMode = .whileEditing
        textField.backgroundColor = .white
        textField.layer.borderColor = UIColor.gray.cgColor
        textField.layer.borderWidth = 0.5
        textField.layer.cornerRadius = 15
        textField.placeholder = "Email Address..."
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        textField.leftViewMode = .always
        return textField
    }()
    
    let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.returnKeyType = .done
        textField.clearButtonMode = .whileEditing
        textField.backgroundColor = .white
        textField.isSecureTextEntry = true
        textField.layer.borderColor = UIColor.gray.cgColor
        textField.layer.borderWidth = 0.5
        textField.layer.cornerRadius = 15
        textField.placeholder = "Password..."
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        textField.leftViewMode = .always
        return textField
    }()
    
    let registerButton: UIButton = {
        let button = UIButton()
        button.setTitle("Register", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        button.layer.cornerRadius = 15
        button.clipsToBounds = true
        return button
    }()
    
    let databaseManager = DatabaseManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Delegates
        emailTextField.delegate = self
        passwordTextField.delegate = self
        firstNameTxtField.delegate = self
        lastNameTextField.delegate = self
        
        //Current View
        title = "Register"
        view.backgroundColor = .white
        
        //Callbacks
        registerButton.addTarget(self,
                                 action: #selector(didPressedRegisterButton),
                                 for: .touchUpInside)
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didPressedProfilePic))
        imageView.addGestureRecognizer(gesture)
        
        //Add Sub Views
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailTextField)
        scrollView.addSubview(passwordTextField)
        scrollView.addSubview(registerButton)
        scrollView.addSubview(firstNameTxtField)
        scrollView.addSubview(lastNameTextField)
    }
    
    override func viewDidLayoutSubviews() {
        scrollView.frame = view.bounds
        let size = scrollView.width / 3
        imageView.frame = CGRect(x: (scrollView.width - size) / 2,
                                 y: scrollView.top + 20,
                                 width: size,
                                 height: size)
        
        imageView.layer.cornerRadius = size / 2
        
        firstNameTxtField.frame = CGRect(x: 30,
                                         y: imageView.bottom + 30,
                                         width: scrollView.width - 60,
                                         height: 48)
        
        lastNameTextField.frame = CGRect(x: 30,
                                         y: firstNameTxtField.bottom + 20,
                                         width: scrollView.width - 60,
                                         height: 48)
        
        emailTextField.frame = CGRect(x: 30,
                                      y: lastNameTextField.bottom + 20,
                                      width: scrollView.width - 60,
                                      height: 48)
        
        passwordTextField.frame = CGRect(x: 30,
                                         y: emailTextField.bottom + 20,
                                         width: scrollView.width - 60,
                                         height: 48)
        
        registerButton.frame = CGRect(x: 30,
                                      y: passwordTextField.bottom + 30,
                                      width: scrollView.width - 60,
                                      height: 48)
        
    }
    
    @objc private func didPressedProfilePic() -> Void {
        presentImagePickerSheet()
    }
    
    //MARK: - User Registration Login
    @objc private func didPressedRegisterButton() -> Void {
        guard let email = emailTextField.text, let password = passwordTextField.text,
            let firstName = firstNameTxtField.text, let lastName = lastNameTextField.text,
            !email.isEmpty, !password.isEmpty, password.count >= 6,
            !firstName.isEmpty, !lastName.isEmpty else {
                showErrorAlert()
                return
        }
        progressHud.show(in: view)
        UserDefaults.standard.set(email, forKey: "email")
        //Firebase Register
        databaseManager.userExists(withEmail: email) { [weak self] exists in
            guard let strongSelf = self else { return }
            
            DispatchQueue.main.async {
                strongSelf.progressHud.dismiss()
            }
            guard !exists else {
                //User already exists
                strongSelf.showErrorAlert(with: "It looks like you have already created an account.")
                return
            }
            Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
                guard authResult != nil, error == nil else {
                    strongSelf.showErrorAlert(with: "Error while creating new user: \(error!.localizedDescription)")
                    return
                }
                let chatUser =  ChatAppUser(uid: authResult!.user.uid,
                                            firstName: firstName,
                                            lastName: lastName,
                                            email: email)
                
                strongSelf.databaseManager.createNewUser(with: chatUser)
                
                //Uploading User Image
                if let image = strongSelf.imageView.image, let data = image.pngData() {
                    StorageManager.shared.uploadProfilePicture(with: data, fileName: chatUser.imageUrl) { result in
                        switch result {
                        case .success(let url):
                            UserDefaults.standard.set(url, forKey: "profile_image")
                        case .failure(let e ):
                            print("Error While uploading to storage: \(e.localizedDescription)")
                        }
                    }
                }
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
        
    }
    
    
    
    private func showErrorAlert(with message: String = "You should type your information to create a new account."){
        let alert = UIAlertController(title: "Woops",
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    
}

extension RegisterViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            didPressedRegisterButton()
        }
        return true
    }
}

extension RegisterViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private func presentImagePickerSheet() -> Void {
        let imagePickerActionSheet = UIAlertController(title: "Pick Image",
                                                       message: "Select you profile image source.",
                                                       preferredStyle: .actionSheet)
        
        imagePickerActionSheet.addAction(UIAlertAction(title: "Camera Roll", style: .default, handler: { [weak self] _ in
            self?.presentCamera()
        }))
        imagePickerActionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in
            self?.presentPhotoLibrary()
        }))
        imagePickerActionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(imagePickerActionSheet, animated: true)
    }
    
    private func presentCamera() -> Void {
        let vc = UIImagePickerController()
        vc.delegate = self
        vc.sourceType = .camera
        vc.allowsEditing = true
        self.present(vc, animated: true)
    }
    
    private func presentPhotoLibrary() -> Void {
        let vc = UIImagePickerController()
        vc.delegate = self
        vc.sourceType = .photoLibrary
        vc.allowsEditing = true
        self.present(vc, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let pickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            imageView.image = pickedImage
        }
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
