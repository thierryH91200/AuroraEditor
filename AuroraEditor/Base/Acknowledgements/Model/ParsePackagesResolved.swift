//
//  ParsePackagesResolved.swift
//  AuroraEditorModules/Acknowledgements
//
//  Created by Shivesh M M on 4/4/22.
//

import Foundation

struct Dependency: Decodable {
    var name: String
    var repositoryLink: String
    var version: String
    var repositoryURL: URL {
        URL(string: repositoryLink)!
    }
}

struct RootObject: Codable {
    let object: Object
}

// MARK: - Object
struct Object: Codable {
    let pins: [Pin]
}

// MARK: - Pin
struct Pin: Codable {
    let package: String
    let repositoryURL: String
    let state: AcknowledgementsState
}

// MARK: - State
struct AcknowledgementsState: Codable {
    let revision: String
    let version: String?
}
