//
//  LoginView.swift
//  AdmoiOS
//
//  Created by Eugene Cullen on 27/01/2026.
//
import SwiftUI

struct LoginView: View {
    let role: UserRole
    @EnvironmentObject private var auth: AuthManager

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isCreatingAccount: Bool = false

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(spacing: 18) {
                    VStack(spacing: 10) {
                        Image(systemName: role.systemImage)
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(Theme.neon)

                        Text("\(role.displayName) Account")
                            .font(.title2.bold())
                            .foregroundStyle(Theme.textPrimary)

                        Text(isCreatingAccount ? "Create your account to get started" : "Sign in to continue")
                            .foregroundStyle(Theme.textSecondary)
                            .font(.subheadline)
                    }
                    .padding(.top, 20)

                    GlowCard {
                        VStack(spacing: 12) {
                            TextField("Email", text: $email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .neonField()

                            SecureField("Password", text: $password)
                                .neonField()

                            if auth.isLoading {
                                ProgressView()
                                    .tint(Theme.neon)
                                    .padding(.top, 6)
                            }

                            Button {
                                let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
                                if isCreatingAccount {
                                    auth.signUp(email: trimmed, password: password, role: role)
                                } else {
                                    auth.signIn(email: trimmed, password: password)
                                }
                            } label: {
                                Text(isCreatingAccount ? "Create Account" : "Sign In")
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(email.isEmpty || password.isEmpty)

                            Button {
                                isCreatingAccount.toggle()
                            } label: {
                                Text(isCreatingAccount ? "Already have an account? Sign in" : "New here? Create an account")
                                    .foregroundStyle(Theme.neon)
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.top, 4)
                            }
                        }
                    }

                    Spacer(minLength: 10)
                }
                .padding()
            }
        }
    }
}
