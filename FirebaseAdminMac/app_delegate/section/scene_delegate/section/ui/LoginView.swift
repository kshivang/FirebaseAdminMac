//
//  LoginView.swift
//  FirebaseAdminMac
//
//  Created by Kumar Shivang on 13/04/20.
//  Copyright © 2020 Kumar Shivang. All rights reserved.
//

import SwiftUI
import AppAuth
import Firebase
import CombineFirebase
import Combine

struct LoginView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        Group {
            if viewModel.loggedIn {
                MainNavigationView(viewModel: viewModel.mainNavigationViewModel)
            } else {
                VStack {
                    Spacer()
                    Text("Firebase Admin").font(Font.system(size: 40, weight: .semibold)).padding(.top, 40)
                    Spacer()
                    Button(action: {
                        self.viewModel.attemptToSignIn()
                    }) {
                        Text("Login with Google")
                            .font(Font.system(size: 23, weight: .bold))
                            .foregroundColor(Color.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical)
                            .background(RoundedRectangle(cornerRadius: 10))
                    }.padding(.bottom, 60)
                }
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(viewModel: .init())
    }
}

extension LoginView {
    class ViewModel: ObservableObject {
        @Published var loggedIn: Bool = false
        
        var mainNavigationViewModel: MainNavigationView.ViewModel {
            .init()
        }
        
        private var cancelBag = Set<AnyCancellable>()
        
        init() {
            Auth.auth().stateDidChangePublisher
                .receive(on: RunLoop.main).sink {
                    if $0 == nil {
                        self.loggedIn = false
                    } else {
                        self.loggedIn = true
                    }
            }.store(in: &cancelBag)
        }
        
        deinit {
            cancelBag.removeAll()
        }
        
        private var vc: UIViewController {
            UIApplication.shared.rootViewController!
        }
        
        func attemptToSignIn() {
            do {
                GAppAuth.shared.appendAuthorizationRealm("https://www.googleapis.com/auth/cloud-platform")
                GAppAuth.shared.appendAuthorizationRealm("https://www.googleapis.com/auth/cloud-platform.read-only")
                GAppAuth.shared.appendAuthorizationRealm("https://www.googleapis.com/auth/firebase")
                GAppAuth.shared.appendAuthorizationRealm("https://www.googleapis.com/auth/firebase.readonly")
                GAppAuth.shared.appendAuthorizationRealm("https://www.googleapis.com/auth/datastore")

                try GAppAuth.shared.authorize(in: self.vc) { [weak self] (completed) in
                    guard completed, let authorization = GAppAuth.shared.authorization, let lastTokenResponse = authorization.authState.lastTokenResponse, let idToken = lastTokenResponse.idToken, let accessToken = lastTokenResponse.accessToken else {
                        
                        DispatchQueue.main.async {
                            self?.loggedIn = false
                        }
                        return
                    }
                    let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
                    self?.linkFirebase(credential)
                }
            } catch {
                print("error: \(error)")
            }
        }
        
        func linkFirebase(_ credential: AuthCredential) {
            Auth.auth().signIn(with: credential) { [weak self] (authResult, error) in
                if let error = error {
                    print("error: \(error)")
                    DispatchQueue.main.async {
                        self?.loggedIn = false
                    }
                    return
                }
            }
        }
    }
}
