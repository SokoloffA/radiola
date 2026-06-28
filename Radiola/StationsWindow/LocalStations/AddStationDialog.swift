//
//  AddStationDialog.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 06.07.2022.
//

import Cocoa

// MARK: - AddStationDialog

class AddStationDialog: OkCancelDialog, NSTextFieldDelegate {
    private let titleLabel = NSLocalizedString("Title:", comment: "Add station dialog label for Tile edit")
    private let urlLabel = NSLocalizedString("URL:", comment: "Add station dialog label for URL edit")
    private let titleEdit = NSTextField()
    private let urlEdit = NSTextField()
    private let downloadTitleButton = SpinnerImageButton(systemSymbolName: "icloud.and.arrow.down", accessibilityDescription: "Download stations title from the internet")

    var title: String { return titleEdit.stringValue }
    var url: String { return urlEdit.stringValue }

    /* ****************************************
     *
     * ****************************************/
    override init(size: NSSize? = nil) {
        super.init(size: size)
        messageLabel.stringValue = NSLocalizedString("To add a station, fill out the following information:", comment: "Add station dialog message")
        okButton.title = NSLocalizedString("Add station", comment: "Add station dialog button")

        gridView.addRow(title: titleLabel, rightViews: [titleEdit, downloadTitleButton])
        gridView.addRow(title: urlLabel, rightView: urlEdit)

        titleEdit.delegate = self

        downloadTitleButton.toolTip = NSLocalizedString("Fetch the name from the website", comment: "Button tooltip ")
        downloadTitleButton.target = self
        downloadTitleButton.action = #selector(downloadTitle)
        downloadTitleButton.title = ""

        urlEdit.delegate = self
        urlEdit.stringValue = getUrlFromPasteboard() ?? ""

        updateButtons()
    }

    /* ****************************************
     *
     * ****************************************/
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /* ****************************************
     *
     * ****************************************/
    func controlTextDidChange(_ obj: Notification) {
        updateButtons()
    }

    /* ****************************************
     *
     * ****************************************/
    private func updateButtons() {
        okButton.isEnabled =
            !urlEdit.stringValue.isEmpty &&
            !titleEdit.stringValue.isEmpty

        downloadTitleButton.isEnabled = !urlEdit.stringValue.isEmpty
    }

    /* ****************************************
     *
     * ****************************************/
    private func getUrlFromPasteboard() -> String? {
        guard
            let res = NSPasteboard.general.string(forType: .string),
            let url = URL(string: res),
            url.scheme == "http" || url.scheme == "https"
        else {
            return nil
        }
        return res
    }

    /* ****************************************
     *
     * ****************************************/
    @objc private func downloadTitle() {
        guard
            !self.url.isEmpty,
            let url = URL(string: url)
        else {
            return
        }

        downloadTitleButton.setAsLoading(true)

        Task {
            do {
                var title: String?
                if PlayList.isPlayListURL(url) {
                    let list = PlayList()
                    try list.download(url: url)
                    title = list.links.first?.title
                } else {
                    if #available(macOS 12.0, *) {
                        var request = URLRequest(url: url)
                        request.httpMethod = "GET"
                        request.setValue("1", forHTTPHeaderField: "Icy-MetaData")
                        let headers = try await fetchHTTPHeaders(request: request)
                        title = headers["icy-name"]
                    }
                }

                await MainActor.run {
                    downloadTitleButton.setAsLoading(false)
                    if let title = title {
                        titleEdit.stringValue = title
                    }
                }

            } catch {
            }
        }
    }
}
