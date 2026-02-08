//
//  UserRole.swift
//  AdmoiOS
//
//  Created by Eugene Cullen on 27/01/2026.
//
import Foundation

enum UserRole: String, CaseIterable, Identifiable {
    case user
    case business

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .user: return "User"
        case .business: return "Business"
        }
    }

    var systemImage: String {
        switch self {
        case .user: return "person.fill"
        case .business: return "building.2.fill"
        }
    }

    var firestoreValue: String { rawValue }
}
