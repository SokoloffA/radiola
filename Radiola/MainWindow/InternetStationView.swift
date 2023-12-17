//
//  InternetStationView.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 30.11.2023.
//

import Foundation
import SwiftUI

struct InternetStationsView: View {
    @ObservedObject var list: InternetStationList
    @State private var selectedStationId: UUID?
    @EnvironmentObject var appState: AppState

    /* ****************************************
     *
     * ****************************************/
    var body: some View {
        VStack(spacing: 0) {
            InternetStationsSearchView(provider: list.provider, action: fetch)
            Divider()

            List(selection: $selectedStationId) {
                ForEach(list.stations) { station in
                    InternetStationRow(station: station)
                }
            }
            .listStyle(.plain)
            .modifier(PlayOnDoubleClick(handler: doubleClicked))
            .overlay { LoadingIndicator(list.isLoading) }

            Text("")
                .frame(height: 36)
        }
    } // body

    /* ****************************************
     *
     * ****************************************/
    private func fetch() {
        Task {
            await list.fetch()
        }
    }

    /* ****************************************
     *
     * ****************************************/
    private func doubleClicked() {
        guard
            let selectedStationId = selectedStationId,
            let station = list.first(byID: selectedStationId)
        else { return }

        Player.shared.switchStation(station: station)
    }
}

// MARK: - InternetStationsSearchView

struct InternetStationsSearchView: View {
    @ObservedObject var provider: RadioBrowserProvider
    var action: () -> Void

    /* ****************************************
     *
     * ****************************************/
    var body: some View {
        HStack {
//            Text("Search on radio-browser.info by tags that")
//                .foregroundStyle(.secondary)
//                .lineLimit(1)

            Spacer()

            Menu(exactMatchToString(provider.isExactMatch)) {
                Button(exactMatchToString(true)) { provider.isExactMatch = true }
                Button(exactMatchToString(false)) { provider.isExactMatch = false }
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            SearchView(placeholder: "Search", text: $provider.searchText, action: action)
                .frame(width: 400)
                .fixedSize()
                .padding(.trailing, 20)

            Menu(orderToString(provider.order)) {
                Button(orderToString(.byVotes)) { provider.order = .byVotes; action() }
                Button(orderToString(.byName)) { provider.order = .byName; action() }
                Button(orderToString(.byCountry)) { provider.order = .byCountry; action() }
                Button(orderToString(.byBitrate)) { provider.order = .byBitrate; action() }
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    } // body

    /* ****************************************
     *
     * ****************************************/
    private func exactMatchToString(_ value: Bool) -> String {
        return value ? "matches with" : "contains"
    }

    /* ****************************************
     *
     * ****************************************/
    private func orderToString(_ order: RadioBrowserProvider.Order) -> String {
        switch order {
            case .byName: return "sort by name"
            case .byVotes: return "sort by votes"
            case .byCountry: return "sort by country"
            case .byBitrate: return "sort by bitrate"
        }
    }
}

// MARK: - LoadingIndicator

struct LoadingIndicator: View {
    var isLoading: Bool

    /* ****************************************
     *
     * ****************************************/
    init(_ isLoading: Bool) {
        self.isLoading = isLoading
    }

    /* ****************************************
     *
     * ****************************************/
    var body: some View {
        if isLoading {
            ProgressView("Loading…")
                .scaleEffect(0.85)
                .progressViewStyle(.circular)
        }
    } // body
}

// MARK: - InternetStationRow

struct InternetStationRow: View {
    var station: InternetStation
    let normalFont = Font.system(size: 11)
    let smallFont = Font.system(size: 10)
    @ObservedObject private var player = Player.shared

    /* ****************************************
     *
     * ****************************************/
    var body: some View {
        VStack {
            HStack {
                Text(station.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.headline)

                ImageButton(iconOff: "music.house", iconOn: "music.house.fill", isSet: .constant(true))
            }
            .padding(EdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 8))

            HStack {
                Text(station.url)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(votesInfo()).foregroundColor(.secondary)

                Text(qualityInfo()).foregroundColor(.secondary)

            }.padding(EdgeInsets(top: 0, leading: 2, bottom: 1, trailing: 8))
        }
        .padding(EdgeInsets(top: 0, leading: 24, bottom: 1, trailing: 8))
        .overlay(alignment: .leading) {
            if player.station?.id == station.id {
                Image(systemName: "waveform.path")
                    .resizable()
                    .frame(width: 18, height: 18)
                    .foregroundColor(.accentColor)
            }
        }
    } // body

    /* ****************************************
     *
     * ****************************************/
    private func votesInfo() -> AttributedString {
        guard let votes = station.votes else { return AttributedString("") }

        var res = AttributedString()

        switch votes {
            case 0:
                res.append(format("no votes", normalFont))

            case 0 ..< 1000:
                res.append(format("votes:", smallFont))
                res.append(format(" \(votes)", normalFont))

            case 1000 ..< 1_000_000:
                res.append(format("votes:", smallFont))
                res.append(format(" \(votes / 1000)", normalFont))
                res.append(format("k", smallFont))
            default:
                res.append(format("votes: ", smallFont))
                res.append(format("\(votes / 10_000_000)", normalFont))
                res.append(format("M", smallFont))
        }
        return res
    }

    /* ****************************************
     *
     * ****************************************/
    private func qualityInfo() -> AttributedString {
        var res = AttributedString()

        if let codec = station.codec {
            res.append(format("codec: ", smallFont))
            res.append(format(codec.lowercased(), normalFont))
        }

        if let bitrate = station.bitrate {
            switch bitrate {
                case 0: break

                case 1 ..< 1024:
                    res.append(format(" \(bitrate)b", normalFont))

                default:
                    res.append(format(" \(bitrate / 1024)k", normalFont))
            }
        }
        return res
    }

    /* ****************************************
     *
     * ****************************************/
    private func format(_ str: String, _ font: Font) -> AttributedString {
        var res = AttributedString(str)
        res.font = font
        return res
    }
}
