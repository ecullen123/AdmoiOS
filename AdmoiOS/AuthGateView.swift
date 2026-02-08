import SwiftUI

struct AuthGateView: View {
    let role: UserRole
    var onBack: () -> Void

    @StateObject private var auth: AuthManager

    init(role: UserRole, onBack: @escaping () -> Void) {
        self.role = role
        self.onBack = onBack
        _auth = StateObject(wrappedValue: AuthManager(expectedRole: role))
    }

    var body: some View {
        ZStack {
            AppBackground()

            Group {
                if auth.isLoading {
                    ProgressView()
                        .tint(Theme.neon)

                } else if auth.user == nil {
                    LoginView(role: role)
                        .environmentObject(auth)

                } else {
                    if role == .business {
                        BusinessDashboardView()
                            .environmentObject(auth)
                    } else {
                        UserDashboardView()
                            .environmentObject(auth)
                    }
                }
            }
        }
        .navigationTitle("\(role.displayName) Login")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") { onBack() }
            }
        }
        .alert("Sign-in issue", isPresented: Binding(
            get: { auth.errorMessage != nil },
            set: { if !$0 { auth.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { auth.errorMessage = nil }
        } message: {
            Text(auth.errorMessage ?? "")
        }
    }
}
