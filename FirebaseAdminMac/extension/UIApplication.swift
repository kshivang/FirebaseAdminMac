//
//  UIApplication.swift
//  FirebaseAdminMac
//
//  Created by Kumar Shivang on 13/04/20.
//  Copyright © 2020 Kumar Shivang. All rights reserved.
//

import SwiftUI

extension UIApplication {
    
    var keyedWindow: UIWindow? {
        windows
            .filter{$0.isKeyWindow}
            .first
    }
    
    var rootViewController: UIViewController? {
        keyedWindow?
            .rootViewController
    }
}

