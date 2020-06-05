//
//  ProjectSelectionView.swift
//  FirebaseAdminMac
//
//  Created by Kumar Shivang on 13/04/20.
//  Copyright © 2020 Kumar Shivang. All rights reserved.
//

import SwiftUI
import Combine

struct ProjectSelectionView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        Group {
            if viewModel.projects.count == 0 {
                Text("Loading projects..")
            } else {
                List {
                    ForEach(self.viewModel.projects, id: \.projectId) { project in
                        Text("\(project.name)")
                            .onAppear {
                                self.viewModel
                                    .onItemVisible(project: project)
                            }
                    }
                }
            }
        }
        .navigationBarTitle("Projects")
    }
}

struct ProjectSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectSelectionView(viewModel: .init())
    }
}

extension ProjectSelectionView {
    class ViewModel: ObservableObject {
        @Published var projects: [FirebaseProject] = []
        
        private var cancelBag = Set<AnyCancellable>()
        private var nextPageToken: String? = nil
        
        init() {
            loadMore()
        }
        
        func onItemVisible(project: FirebaseProject) {
            if project.projectId == projects.last?.projectId && nextPageToken != nil {
                loadMore()
            }
        }
        
        func loadMore() {
            projectsPagePublisher(nextPageToken: nextPageToken)
                .receive(on: RunLoop.main)
                .sink { (result) in
                    self.projects.append(contentsOf: result.0)
                    self.nextPageToken = result.1
                }.store(in: &cancelBag)
        }
    }
}
