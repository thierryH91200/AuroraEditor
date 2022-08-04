//
//  WorkspaceCodeFileEditor.swift
//  AuroraEditor
//
//  Created by Pavel Kasila on 20.03.22.
//

import SwiftUI
import UniformTypeIdentifiers

private let log = Logger()

struct WorkspaceCodeFileView: View {
    var windowController: NSWindowController

    @ObservedObject
    var workspace: WorkspaceDocument

    @StateObject
    private var prefs: AppPreferencesModel = .shared

    @ViewBuilder
    var codeView: some View {
        ZStack {
            if let item = workspace.selectionState.openFileItems.first(where: { file in
                if file.tabID == workspace.selectionState.selectedId {
                    log.info("Item loaded is: \(file.url)")
                }
                return file.tabID == workspace.selectionState.selectedId
            }) {
                if let fileItem = workspace.selectionState.openedCodeFiles[item] {
                    if fileItem.typeOfFile == .image {
                        imageFileView(fileItem, for: item)
                    } else {
                        codeFileView(fileItem, for: item)
                    }
                }
            } else {
                Text("No Editor")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                    .frame(minHeight: 0)
                    .clipped()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func codeFileView(
        _ codeFile: CodeFileDocument,
        for item: WorkspaceClient.FileItem
    ) -> some View {
        CodeFileView(codeFile: codeFile)
            .safeAreaInset(edge: .top, spacing: 0) {
                VStack(spacing: 0) {
                    BreadcrumbsView(file: item, tappedOpenFile: workspace.openTab(item:))
                    Divider()
                }
            }
    }

    @ViewBuilder
    private func imageFileView(
        _ otherFile: CodeFileDocument,
        for item: WorkspaceClient.FileItem
    ) -> some View {
        ZStack {
            if let url = otherFile.previewItemURL,
               let image = NSImage(contentsOf: url),
               otherFile.typeOfFile == .image {
                GeometryReader { proxy in
                    if image.size.width > proxy.size.width || image.size.height > proxy.size.height {
                        OtherFileView(otherFile)
                    } else {
                        OtherFileView(otherFile)
                            .frame(width: image.size.width, height: image.size.height)
                            .position(x: proxy.frame(in: .local).midX, y: proxy.frame(in: .local).midY)
                    }
                }
            } else {
                OtherFileView(otherFile)
            }
        }.safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 0) {
                BreadcrumbsView(file: item, tappedOpenFile: workspace.openTab(item:))
                Divider()
            }
        }
    }

    var body: some View {
        codeView
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
