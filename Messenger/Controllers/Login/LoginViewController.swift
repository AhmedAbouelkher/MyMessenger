//
//  LoginViewController.swift
//  Messenger
//
//  Created by Ahmed on 12/27/20.
//  Copyright © 2020 Ahmed. All rights reserved.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import JGProgressHUD

class LoginViewController: UIViewController {
    
    private let progressHud = JGProgressHUD(style: .dark)
    
    private let scrollView: UIScrollView =  {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let logoImage: UIImageView = {
        let logoImage = UIImageView()
        logoImage.image = UIImage(named: "logo")
        logoImage.contentMode = .scaleAspectFit
        return logoImage
    }()
    
    private let emailTextField: UITextField = {
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
    
    private let passwordTextField: UITextField = {
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
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log in", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        button.layer.cornerRadius = 15
        button.clipsToBounds = true
        return button
    }()
    
    private let fbLoginButton: FBLoginButton = {
       let button = FBLoginButton()
        button.permissions = ["email,public_profile"]
        button.layer.cornerRadius = 15
        button.clipsToBounds = true
        return button
    }()
    
    private let gidSigingButton: GIDSignInButton = {
       let button = GIDSignInButton()
        button.layer.cornerRadius = 15
        button.clipsToBounds = true
        return button
    }()
    
    private let gidSignIn = GIDSignIn.sharedInstance()
    private var notificationObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        notificationObserver =  NotificationCenter.default.addObserver(forName: .didLogInNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else {return}
            self.navigationController?.dismiss(animated: true, completion: nil)
        }
        
        //Delegates
        emailTextField.delegate = self
        passwordTextField.delegate = self
        fbLoginButton.delegate = self
        gidSignIn?.presentingViewController = self
        
        title = "Login"
        view.backgroundColor = .white
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(didPressedRegister))
        loginButton.addTarget(self,
                              action: #selector(didPressedLoginButton),
                              for: .touchUpInside)
        
        //Add Sub Views
        view.addSubview(scrollView)
        scrollView.addSubview(logoImage)
        scrollView.addSubview(emailTextField)
        scrollView.addSubview(passwordTextField)
        scrollView.addSubview(loginButton)
        // TODO: reactivate Facebook sign in
        scrollView.addSubview(fbLoginButton)
        scrollView.addSubview(gidSigingButton)
    }
    
    deinit {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    override func viewDidLayoutSubviews() {
        scrollView.frame = view.bounds
        let size = scrollView.width / 4
        
        logoImage.frame = CGRect(x: (scrollView.width - size) / 2,
                                 y: scrollView.top + 20,
                                 width: size,
                                 height: size)
        
        emailTextField.frame = CGRect(x: 30,
                                      y: logoImage.bottom + 30,
                                      width: scrollView.width - 60,
                                      height: 48)
        
        passwordTextField.frame = CGRect(x: 30,
                                         y: emailTextField.bottom + 20,
                                         width: scrollView.width - 60,
                                         height: 48)
        
        loginButton.frame = CGRect(x: 30,
                                   y: passwordTextField.bottom + 30,
                                   width: scrollView.width - 60,
                                   height: 48)
        
        fbLoginButton.frame = CGRect(x: 30,
                                     y: loginButton.bottom + 40,
                                     width: scrollView.width - 60,
                                     height: 48)
        
        gidSigingButton.frame = CGRect(x: 30,
                                     y: fbLoginButton.bottom + 20,
                                     width: scrollView.width - 60,
                                     height: 48)
    }
    
    @objc private func didPressedLoginButton() -> Void {
        guard let email = emailTextField.text, let password = passwordTextField.text,
            !email.isEmpty, !password.isEmpty, password.count >= 6  else {
                showErrorAlert()
            return
        }
        //Firebase Login
        progressHud.show(in: view)
        loginUser(email: email, password: password)
    }
    
    private func loginUser(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] (authResult, error) in
            guard let strongSelf = self else {return}
            UserDefaults.standard.setValue(email, forKey: "email")
            DispatchQueue.main.async {
                strongSelf.progressHud.dismiss()
            }
            
            guard authResult != nil, error == nil else {
                print("Error while singing in: \(error!.localizedDescription)")
                return
            }
            print("User signed In Successfuly")
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        }
    }
    
    private func showErrorAlert() -> Void {
        let alert = UIAlertController(title: "Woops", message: "You should type your information to login.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    @objc private func didPressedRegister() {
        let vc = RegisterViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
}

//MARK: - UITextFieldDelegate

extension LoginViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            textField.resignFirstResponder()
            didPressedLoginButton()
        }
        return true
    }
}

//MARK: - Facebook Login Button Delegate

extension LoginViewController : LoginButtonDelegate {
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        //Do Nothing
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        
        guard error != nil, let token = result?.token?.tokenString else {
            print("Firebase login did fail with error: \(error!)")
            return
        }
        
        let credential = FacebookAuthProvider.credential(withAccessToken: token)
        
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                         parameters: ["fields": "email,name"],
                                                         tokenString: token,
                                                         version: nil,
                                                         httpMethod: .get)
        
        facebookRequest.start { (_, result, error) in
            guard let result = result, error != nil else {
                print("Failed to start facbook graph request")
                return
            }
            
            print(result)
        }
        
        Auth.auth().signIn(with: credential) { [weak self] (authResult, error) in
            guard let self = self else {return}
            guard error != nil, authResult != nil else {
                print("Firbase sining with Facebook did fail: \(error!)")
                return
            }
            
            print("Sign in was successful")
            self.navigationController?.dismiss(animated: true, completion: nil)
            
        }
        
    }
    
    
}
