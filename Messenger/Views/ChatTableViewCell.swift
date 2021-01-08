//
//  ChatTableViewCell.swift
//  Messenger
//
//  Created by Ahmed on 1/3/21.
//  Copyright © 2021 Ahmed. All rights reserved.
//

import UIKit
import SDWebImage

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
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        return label
    }()
    
    private let userMessageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
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
        
        userImageView.makeCirculer()
        
        userNameLabel.frame = CGRect(x: userImageView.right + 10,
                                     y: 10,
                                     width: contentView.width - 20 - userImageView.width,
                                     height: (contentView.height-20)/2)
        
        userMessageLabel.frame = CGRect(x: userImageView.right + 10,
                                        y: userNameLabel.bottom,
                                        width: contentView.width - 20 - userImageView.width,
                                        height: (contentView.height-20)/2)
        
    }
    
    public func configure(with model: Chat) {
        configureLatestMessage(model)
        self.userNameLabel.text = model.reciverUser.name
        StorageManager.shared.downloadURL(for: model.reciverUser.imageURL, completion: { [weak self] result in
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
                    self?.userImageView.sd_setImage(with: url, completed: nil)
                }                
            case .failure(let error):
                print("failed to get image url: \(error)")
            }
        })
    }
    
    fileprivate func configureLatestMessage(_ model: Chat) {
        
        userMessageLabel.text = model.latestMessage.message
        
        if model.latestMessage.type != "text" {
            userMessageLabel.text = "sent an attachment"
            userMessageLabel.font = .italicSystemFont(ofSize: 15)
        }
        
        if let emailId = DatabaseManager.getCurrentUserID, emailId == model.latestMessage.sentBy.userID {
            userMessageLabel.text = "You: " + userMessageLabel.text!
        }
    }
}

