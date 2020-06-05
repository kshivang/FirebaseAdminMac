//
//  MenuView.swift
//  FirebaseAdminMac
//
//  Created by Kumar Shivang on 13/04/20.
//  Copyright © 2020 Kumar Shivang. All rights reserved.
//

import SwiftUI
import Firebase

struct MenuView: View {
    var body: some View {
        List {
            HStack {
                Text("Logout")
                    .onTapGesture {
                        self.onLogout()
                    }
            }
        }
        .navigationBarTitle("")
        .navigationBarHidden(true)
    }
    
    func onLogout() {
        try? Auth.auth().signOut()
    }
}

struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        MenuView()
    }
}
