//
//  PhotoViewerViewController.swift
//  Messenger
//
//  Created by Ahmed on 12/27/20.
//  Copyright © 2020 Ahmed. All rights reserved.
//

import UIKit
import SDWebImage
class PhotoViewerViewController: UIViewController {
    
    private let imageURL: URL?
    
    private let imageView: UIImageView = {
       let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    init(with url: URL) {
        imageURL = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Photo"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .black
        let subViews = [imageView]
        subViews.forEach { view.addSubview($0) }
        imageView.sd_setImage(with: imageURL, completed: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageView.frame = view.bounds
    }
}
