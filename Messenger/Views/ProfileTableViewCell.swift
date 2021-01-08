//
//  ProfileTableViewCell.swift
//  Messenger
//
//  Created by Ahmed on 1/7/21.
//  Copyright © 2021 Ahmed. All rights reserved.
//

import UIKit

final class ProfileTableViewCell: UITableViewCell {
    public static var identifier = "ProfileTableViewCell"
    
    private let leadingImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    private let title: UILabel = {
        let label = UILabel()
        label.textColor = .systemGray2
        label.font = .systemFont(ofSize: 15)
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(leadingImageView)
        contentView.addSubview(title)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let imageLength: CGFloat = 30
        leadingImageView.frame = CGRect(
            x: 10,
            y: 6,
            width: imageLength,
            height: imageLength
        )
        leadingImageView.makeCirculer()
        
        title.frame = CGRect(
            x: leadingImageView.width + 20,
            y: 6,
            width: 10,
            height: 9
        )
    }
    
    public func configure(with model: ProfileViewModel) -> Void {
        self.textLabel?.text = model.title
        switch model.viewModelType {
        case .info:
            if let icon = model.icon {
                leadingImageView.image = icon.icon
                leadingImageView.backgroundColor = icon.backgroundColor
                leadingImageView.tintColor = icon.iconTint
            }
            title.textAlignment = .left
            selectionStyle = .none
        case .logout:
            title.textColor = .red
            title.textAlignment = .center
        }
    }
}
