//
//  ContentView.swift
//  AdmoiOS
//
//  Created by Eugene Cullen on 27/01/2026.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedRole: UserRole? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                // Always paint the background to prevent any white flash during transitions
                AppBackground()

                Group {
                    if let role = selectedRole {
                        AuthGateView(role: role) {
                            selectedRole = nil
                        }
                    } else {
                        RolePickerView { role in
                            selectedRole = role
                        }
                    }
                }
            }
            // Global accent color (black & neon green theme)
            .tint(Theme.neon)

            // Helps keep nav bar consistent dark during transitions
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Theme.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}
