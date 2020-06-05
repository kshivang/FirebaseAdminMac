//
//  MainObject.swift
//  FirebaseAdminMac
//
//  Created by Kumar Shivang on 13/04/20.
//  Copyright © 2020 Kumar Shivang. All rights reserved.
//

import SwiftUI

class MainObject: ObservableObject {
    
    private static var singletonInstance: MainObject?
    public static var shared: MainObject {
        if singletonInstance == nil {
            singletonInstance = MainObject()
        }
        return singletonInstance!
    }
    
    // No instances allowed
    private init() {}
    
    var accessToken: String? {
        GAppAuth.shared.authorization?.authState.lastTokenResponse?.accessToken
    }
}
