//
//  test_gameApp.swift
//  test_game
//
//  Created by Michael Miroshnikov on 27/08/2025.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn
import AVFoundation

@main
struct test_gameApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var audioManager = AudioManager.shared
    
    init() {
        FirebaseApp.configure()
        
        // Configure Google Sign-In
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            print("Error: Could not load GoogleService-Info.plist")
            return
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
        
        // Handle Google Sign-In URL
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if let error = error {
                print("Error restoring Google Sign-In: \(error)")
            }
        }
        
        // Настройка аудио сессии
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                MainTabView()
                    .environmentObject(authViewModel)
                    .onAppear {
                        audioManager.playMusic()
                    }
            } else {
                AuthView(authViewModel: authViewModel)
                    .onAppear {
                        audioManager.playMusic()
                    }
            }
        }
    }
}
