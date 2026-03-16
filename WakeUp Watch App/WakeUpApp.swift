//
//  WakeUpApp.swift
//  WakeUp Watch App
//
//  Created by Henry Stephen on 2026/3/16.
//

import SwiftUI

@main
struct WakeUp_Watch_AppApp: App {
    @StateObject private var sleepVM = SleepViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sleepVM)
                .onAppear {
                    NotificationService.shared.requestAuthorization { granted in
                        print("Notification granted: \(granted)")
                    }
                }
        }
    }
}
