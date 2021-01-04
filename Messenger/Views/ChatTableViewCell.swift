//
//  ChatTableViewCell.swift
//  Messenger
//
//  Created by Ahmed on 1/3/21.
//  Copyright © 2021 Ahmed. All rights reserved.
//

import UIKit
import SDWebImage

extension UIView {
    public func makeCirculer() -> Void {
        let width = self.frame.width
        self.layer.cornerRadius = width / 2
    }
}

class ChatTableViewCell: UITableViewCell {
    
    static let identifier = "ChatTableViewCell"
    
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    private let userNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 21, weight: .semibold)
        return label
    }()
    
    private let userMessageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 19, weight: .regular)
        label.numberOfLines = 0
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLabel)
        contentView.addSubview(userMessageLabel)
        
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        userImageView.frame = CGRect(x: 10,
                                     y: 10,
                                     width: 50,
                                     height: 50)
        userImageView.layer.cornerRadius = userImageView.frame.width / 2
        
        userNameLabel.frame = CGRect(x: userImageView.right + 10,
                                     y: 10,
                                     width: contentView.width - 20 - userImageView.width,
                                     height: (contentView.height-20)/2)
        
        userMessageLabel.frame = CGRect(x: userImageView.right + 10,
                                        y: userNameLabel.bottom + 10,
                                        width: contentView.width - 20 - userImageView.width,
                                        height: (contentView.height-20)/2)
        
    }
    
    public func configure(with model: Chat) {
        configureLatestMessage(model)
        self.userNameLabel.text = model.reciverUser.name
        print("CHAT MODEL \(model)")
        StorageManager.shared.downloadURL(for: model.reciverUser.imageURL, completion: { [weak self] result in
            switch result {
            case .success(let url):
                guard let path = URL(string: url) else {
                    return
                }
                DispatchQueue.main.async {
                    self?.userImageView.sd_setImage(with: path, completed: nil)
                }
                
            case .failure(let error):
                print("failed to get image url: \(error)")
            }
        })
    }
    
    fileprivate func configureLatestMessage(_ model: Chat) {
        if let emailID = DatabaseManager.getCurrentUserID() {
            print("## Is me" , emailID == model.senderUser.userID, "currentEmail: \(emailID), sender: \(model.senderUser.userID)")
            self.userMessageLabel.text = "You: \(model.latestMessage.message)"
        } else {
            self.userMessageLabel.text = model.latestMessage.message
        }
    }
}
