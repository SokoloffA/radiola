//
//  RowViews.swift
//  Radiola
//
//  Created by Alex Sokolov on 02.12.2023.
//

import SwiftUI

struct InternetStationRow: View {
    var station: InternetStation
    let normalFont = Font.system(size: 11)
    let smallFont = Font.system(size: 10)

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

