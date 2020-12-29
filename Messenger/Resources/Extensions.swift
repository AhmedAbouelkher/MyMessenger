//
//  Extension.swift
//  Messenger
//
//  Created by Ahmed on 12/27/20.
//  Copyright © 2020 Ahmed. All rights reserved.
//

import UIKit

extension UIView {
    
    public var width: CGFloat {
        return self.frame.size.width
    }
    
    public var height: CGFloat {
        return self.frame.size.height
    }
    
    public var top: CGFloat {
        return self.frame.origin.y
    }
    
    public var bottom: CGFloat {
        let frame = self.frame
        return frame.size.height + frame.origin.y
    }
    
    public var left: CGFloat {
        return self.frame.origin.x
    }
    
    
    public var right: CGFloat {
        let frame = self.frame
        return frame.origin.x + frame.size.width
    }
}

extension Notification.Name {
    static let didLogInNotification = Notification.Name("didLogInNotification")
}
