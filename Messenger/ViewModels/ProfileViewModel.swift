//
//  ProfileViewModel.swift
//  Messenger
//
//  Created by Ahmed on 1/7/21.
//  Copyright © 2021 Ahmed. All rights reserved.
//

import UIKit

enum ProfileViewModelType {
    case logout, info
}

struct ProfileViewModel {
    let viewModelType: ProfileViewModelType
    let title: String
    let icon: Icon?
    let handler: (() -> Void)?
}

struct Icon {
    let icon: UIImage
    let iconTint: UIColor
    let backgroundColor: UIColor
}
