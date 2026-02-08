//
//  AdVideo.swift
//  AdmoiOS
//
//  Created by Eugene Cullen on 29/01/2026.
//
import Foundation

struct AdVideo: Identifiable, Hashable {
    let id: String                 // use fullPath
    let name: String               // filename
    let fullPath: String           // advertisements/...
    let downloadURL: URL
}
