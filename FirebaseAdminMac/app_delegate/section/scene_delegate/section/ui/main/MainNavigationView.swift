//
//  MainNavigationView.swift
//  FirebaseAdminMac
//
//  Created by Kumar Shivang on 13/04/20.
//  Copyright © 2020 Kumar Shivang. All rights reserved.
//

import SwiftUI

struct MainNavigationView: View {
    
    let viewModel: ViewModel
    
    var body: some View {
        NavigationView {
            MenuView()
            ProjectSelectionView(viewModel: viewModel.projectSelectionDataModel)
        }
    }
}

struct MainNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        MainNavigationView(viewModel: .init())
    }
}

extension MainNavigationView {
    struct ViewModel {
        var projectSelectionDataModel: ProjectSelectionView.ViewModel {
            .init()
        }
    }
}
