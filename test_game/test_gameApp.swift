//
//  test_gameApp.swift
//  test_game
//
//  Created by Michael Miroshnikov on 27/08/2025.
//

import SwiftUI
import FirebaseCore

@main
struct test_gameApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var isLoading = true
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if isLoading {
                    LoadingView()
                        .onAppear {
                            // Симуляция загрузки
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                isLoading = false
                            }
                        }
                } else if authViewModel.isAuthenticated {
                    MainTabView()
                        .environmentObject(authViewModel)
                } else {
                    AuthView(authViewModel: authViewModel)
                }
            }
        }
    }
}
