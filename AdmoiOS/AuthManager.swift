//
//  AuthManager.swift
//  AdmoiOS
//
//  Created by Eugene Cullen on 27/01/2026.
//
import Foundation
import FirebaseAuth
import FirebaseFirestore

final class AuthManager: ObservableObject {
    @Published var user: FirebaseAuth.User? = nil
    @Published var role: UserRole? = nil
    @Published var isLoading: Bool = true
    @Published var errorMessage: String? = nil

    private let db = Firestore.firestore()
    private var authHandle: AuthStateDidChangeListenerHandle?

    private let expectedRole: UserRole

    init(expectedRole: UserRole) {
        self.expectedRole = expectedRole
        listenAuthState()
    }

    deinit {
        if let authHandle {
            Auth.auth().removeStateDidChangeListener(authHandle)
        }
    }

    private func listenAuthState() {
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            self.user = user

            guard let user else {
                self.role = nil
                self.isLoading = false
                return
            }

            self.isLoading = true
            self.loadRole(forUID: user.uid) { loadedRole in
                self.role = loadedRole
                self.isLoading = false

                // If role mismatch, sign out and show clear message
                if let loadedRole, loadedRole != self.expectedRole {
                    self.errorMessage = "This account is registered as a \(loadedRole.displayName) account. Please choose the correct login type."
                    try? Auth.auth().signOut()
                    self.user = nil
                    self.role = nil
                }
            }
        }
    }

    func signIn(email: String, password: String) {
        errorMessage = nil
        isLoading = true

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
            guard let self else { return }
            self.isLoading = false
            if let error { self.errorMessage = error.localizedDescription }
        }
    }

    func signUp(email: String, password: String, role: UserRole) {
        errorMessage = nil
        isLoading = true

        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self else { return }

            if let error {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                return
            }

            guard let uid = result?.user.uid else {
                self.isLoading = false
                self.errorMessage = "Could not create user."
                return
            }

            self.saveRole(uid: uid, role: role) { ok in
                self.isLoading = false
                if !ok {
                    self.errorMessage = "Account created, but failed to save role. Please try again."
                }
            }
        }
    }

    func signOut() {
        errorMessage = nil
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // Firestore: users/{uid} { role: "user"|"business", createdAt: serverTimestamp }
    private func saveRole(uid: String, role: UserRole, completion: @escaping (Bool) -> Void) {
        db.collection("users").document(uid).setData([
            "role": role.firestoreValue,
            "createdAt": FieldValue.serverTimestamp()
        ], merge: true) { error in
            completion(error == nil)
        }
    }

    private func loadRole(forUID uid: String, completion: @escaping (UserRole?) -> Void) {
        db.collection("users").document(uid).getDocument { snapshot, _ in
            guard
                let data = snapshot?.data(),
                let roleString = data["role"] as? String,
                let role = UserRole(rawValue: roleString)
            else {
                completion(nil)
                return
            }
            completion(role)
        }
    }
}
