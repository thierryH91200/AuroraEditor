//
//  RepositoriesTableViewController.swift
//  AuroraEditor
//
//  Created by TAY KAI QUAN on 17/8/22.
//  Copyright © 2022 Aurora Company. All rights reserved.
//

import SwiftUI

/// A `NSTableCellView` showing an ``icon`` and a ``label``
final class RepositoriesTableViewCell: StandardTableViewCell {
    // swiftlint:disable:next function_body_length
    init(frame frameRect: NSRect,
         repository: RepositoryModel,
         represents cellType: CellType = .repo,
         item: RepoItem? = nil
    ) {
        super.init(frame: frameRect)

        // Add text and image
        var image = NSImage()
        switch cellType {
        case .repo:
            label.stringValue = "\(repository.repoName ?? "Unknown Repo")"
            if let branches = repository.branches,
               branches.contents.count  > branches.current {
                let currentBranch = (branches.contents[branches.current] as? RepoBranch)?
                    .name ?? "Unknown Main Branch"
                secondaryLabel.stringValue = "\(currentBranch)"
            } else {
                secondaryLabel.stringValue = "Unknown Main Branch"
            }
            image = NSImage(systemSymbolName: "clock", accessibilityDescription: nil)!

        case .branches:
            label.stringValue = "Branches"
            image = NSImage(named: "git.branch")!

        case .recentLocations:
            label.stringValue = "Recent Locations"
            image = NSImage(named: "git.branch")!

        case .tags:
            label.stringValue = "Tags"
            image = NSImage(systemSymbolName: "tag", accessibilityDescription: nil)!

        case .stashedChanges:
            label.stringValue = "Stashed Changes"
            image = NSImage(systemSymbolName: "tray", accessibilityDescription: nil)!

        case .remotes:
            label.stringValue = "Remotes"
            image = NSImage(named: "vault")!

        case .remote:
            label.stringValue = "origin" // TODO: Modifiable remote name
            image = NSImage(named: "vault")!

        case .branch:
            var currentBranch = "Unknown Main Branch"
            if let branches = repository.branches,
               let unsafeCurrentBranch = branches.contents[branches.current] as? RepoBranch {
                currentBranch = unsafeCurrentBranch.name
            }

            label.stringValue = item?.name ?? "Unknown Branch"
            if label.stringValue == currentBranch {
                secondaryLabel.stringValue = "*"
            }
            image = NSImage(named: "git.branch")!

        case .tag:
            label.stringValue = item?.name ?? "Unknown Tag"
            image = NSImage(systemSymbolName: "tag", accessibilityDescription: nil)!

        case .change:
            label.stringValue = item?.name ?? "Unknown Change"
            image = NSImage(systemSymbolName: "tray", accessibilityDescription: nil)!
        }
        icon.image = image
        icon.contentTintColor = .gray

        if cellType == .repo {
            self.secondaryLabelRightAlignmed = false
        }
        resizeSubviews(withOldSize: .zero)
    }

    enum CellType {
        // groups
        case repo
        case branches
        case recentLocations
        case tags
        case stashedChanges
        case remotes
        case remote

        // items
        case branch
        case tag
        case change
    }

    required init?(coder: NSCoder) {
        fatalError("""
            init?(coder: NSCoder) isn't implemented on `RepositoriesTableViewCell`.
            Please use `.init(frame: NSRect)
            """)
    }
}
