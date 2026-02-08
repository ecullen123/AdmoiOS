//
//  AdModels.swift
//  AdmoiOS
//
//  Created by Eugene Cullen on 29/01/2026.
//
import Foundation
import FirebaseFirestore

struct AdMetadata: Identifiable, Codable {
    @DocumentID var id: String?

    // Ownership
    var businessId: String

    // Display
    var brandName: String
    var title: String
    var description: String?
    var category: String?
    var tags: [String]

    // Rewards & budget
    /// Example: 0.50 means £0.50 per 1,000 views
    var rewardPer1K: Double
    /// Total budget allocated to campaign in GBP
    var budgetGBP: Double

    // Video storage info
    var storagePath: String
    var videoDownloadURL: String?

    // Status
    var isActive: Bool
    var createdAt: Timestamp
    var updatedAt: Timestamp
}
