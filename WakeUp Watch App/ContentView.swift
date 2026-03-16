//
//  ContentView.swift
//  WakeUp Watch App
//
//  Created by Henry Stephen on 2026/3/16.
//

import SwiftUI
import Combine

struct ContentView: View {
    @EnvironmentObject var sleepVM: SleepViewModel

    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack(spacing: 8) {
                    Text("睡眠目标")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    let goal = sleepVM.currentGoalMinutes()

                    // Prefer HealthKit-detected session if available
                    let detected = sleepVM.currentDetectedSession
                    let session = detected ?? sleepVM.ongoingSession
                    let elapsed = session?.durationMinutes ?? 0
                    let sourceLabel = session?.source ?? "无"
                    let notified = session?.notificationSent ?? false

                    // Use a conservative ring size so it fits on most watch screens
                    let ringSize: CGFloat = 100

                    ZStack {
                        Circle()
                            .stroke(lineWidth: max(4, ringSize * 0.06))
                            .opacity(0.2)
                            .foregroundColor(.accentColor)
                        Circle()
                            .trim(from: 0, to: min(Double(elapsed) / Double(max(1, goal)), 1.0))
                            .stroke(style: StrokeStyle(lineWidth: max(4, ringSize * 0.06), lineCap: .round))
                            .foregroundColor(.accentColor)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut, value: elapsed)
                        VStack {
                            Text("\(elapsed) 分")
                                .font(.headline)
                            Text("目标 \(goal / 60) 小时")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: ringSize, height: ringSize)

                    // source and notification status
                    HStack(spacing: 6) {
                        Text("来源: \(sourceLabel)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        if notified {
                            Text("已提醒")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }

                    HStack(spacing: 12) {
                        // Manual override: create a manual session or end manual session
                        if session == nil || session?.source == "healthkit" {
                            Button(action: {
                                sleepVM.startManualSession()
                            }) {
                                Text("手动补录")
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            Button(action: {
                                sleepVM.endManualSession()
                            }) {
                                Text("结束补录")
                            }
                            .buttonStyle(.bordered)
                        }

                        NavigationLink(destination: MonthlyGridView()) {
                            Text("统计")
                        }
                    }
                    .padding(.top, 6)

                    HStack(spacing: 12) {
                        NavigationLink(destination: WeeklyGoalsView()) { Text("每周目标") }
                        NavigationLink(destination: SettingsView()) { Text("设置") }
                    }
                    .padding(.top, 6)
                    .padding(.bottom, 20) // Ensure content isn't hidden under system UI; use bottom padding instead of Spacer inside ScrollView
                }
                .padding()
                // Ensure VStack takes full width so centering works
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("WakeUp")
            .onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) { _ in
                // periodically update and check
                sleepVM.objectWillChange.send()
                sleepVM.checkAndNotifyIfNeeded()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SleepViewModel.previewInstance())
}
