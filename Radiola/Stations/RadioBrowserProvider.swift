//
//  RadioBrowserProvider.swift
//  Radiola
//
//  Created by Aleksandr Sokolov on 01.12.2023.
//

import Foundation

// MARK: - RadioBrowserProvider
class RadioBrowserProvider: InternetStationProvider {
    /* ****************************************
     *
     * ****************************************/
    @MainActor  override func fetch() async {
        print("FETCH START 1")
        if searchText.isEmpty  { return }

        print("FETCH 2")
//        state = .loading
        let type = requestType()

            do {
                let server = try await RadioBrowser.getFastestServer()

                var reverse = false
                let order = requestOrderType()
                switch order {
                    case .bitrate: reverse = true
                    case .votes: reverse = true
                    default: reverse = false
                }

                let resp = try await server.listStations(by: type, searchTerm: searchText, order: order, reverse: reverse, limit: 1000)
                var res = [InternetStation]()
                
                for r in resp {
                    var s = InternetStation(title: r.name, url: r.url)
                    s.codec = r.codec
                    s.bitrate = r.bitrate * 1024
                    s.votes = r.votes
                    s.countryCode = r.countryCode
                    res.append(s)
                }
                print("FETCH res: \(res.count)")
                    self.stations = res
                print("FETCH res: \(self.stations .count)")
                print("FETCH END")
            } catch {
                await MainActor.run {
                    print(error)
                    Alarm.show(title: "Couldn't download the stations from radio-browser.info", message: "\(error.localizedDescription)")
                }
            }
    }
    
    /* ****************************************
     *
     * ****************************************/
    private func requestType() -> RadioBrowser.Stations.RequestType {
        return isExactMatch ? .byTagExact : .byTag
//        switch searchType() {
//            case .byUUID: return .byUUID
//            case .byName, .byNameExact: return searchOptions.isExactMatch ? .byNameExact : .byName
//            case .byCodec, .byCodecExact: return searchOptions.isExactMatch ? .byCodecExact : .byCodec
//            case .byCountry, .byCountryExact: return searchOptions.isExactMatch ? .byCountryExact : .byCountry
//            case .byCountryCodeExact: return .byCountryCodeExact
//            case .byState, .byStateExact: return searchOptions.isExactMatch ? .byStateExact : .byState
//            case .byLanguage, .byLanguageExact: return searchOptions.isExactMatch ? .byLanguageExact : .byLanguage
//            case .byTag, .byTagExact: return searchOptions.isExactMatch ? .byTagExact : .byTag
//        }
    }
    
    /* ****************************************
     *
     * ****************************************/
    private func requestOrderType() -> RadioBrowser.Stations.Order {
        switch order {
            case .byName: return .name
            case .byVotes: return .votes
            case .byCountry: return .country
            case .byBitrate: return .bitrate
        }
    }
    
    
//    override func fetch() async -> [InternetStation] {
//        return [
//            InternetStation(title: "Super station", url: "https://www.station.com"),
//            InternetStation(title: "Radio Caroline", url: "http://sc3.radiocaroline.net:8030"),
//            InternetStation(title: "Radio Caroline 319 Gold [ Hits from '60-'70 ]", url: "http://www.rcgoldserver.eu:8192"),
//            InternetStation(title: "Radio Caroline 259 Gold [ Happy Rock &amp; Album Station ]", url: "http://www.rcgoldserver.eu:8253"),
//            InternetStation(title: "Super station", url: "https://www.station.com"),
//            InternetStation(title: "Radio Caroline", url: "http://sc3.radiocaroline.net:8030"),
//            InternetStation(title: "Radio Caroline 319 Gold [ Hits from '60-'70 ]", url: "http://www.rcgoldserver.eu:8192"),
//            InternetStation(title: "Radio Caroline 259 Gold [ Happy Rock &amp; Album Station ]", url: "http://www.rcgoldserver.eu:8253"),
//            InternetStation(title: "Super station", url: "https://www.station.com"),
//            InternetStation(title: "Radio Caroline", url: "http://sc3.radiocaroline.net:8030"),
//            InternetStation(title: "Radio Caroline 319 Gold [ Hits from '60-'70 ]", url: "http://www.rcgoldserver.eu:8192"),
//            InternetStation(title: "Radio Caroline 259 Gold [ Happy Rock &amp; Album Station ]", url: "http://www.rcgoldserver.eu:8253"),
//            InternetStation(title: "Super station", url: "https://www.station.com"),
//            InternetStation(title: "Radio Caroline", url: "http://sc3.radiocaroline.net:8030"),
//            InternetStation(title: "Radio Caroline 319 Gold [ Hits from '60-'70 ]", url: "http://www.rcgoldserver.eu:8192"),
//            InternetStation(title: "Radio Caroline 259 Gold [ Happy Rock &amp; Album Station ]", url: "http://www.rcgoldserver.eu:8253"),
//            InternetStation(title: "Super station", url: "https://www.station.com"),
//            InternetStation(title: "Radio Caroline", url: "http://sc3.radiocaroline.net:8030"),
//            InternetStation(title: "Radio Caroline 319 Gold [ Hits from '60-'70 ]", url: "http://www.rcgoldserver.eu:8192"),
//            InternetStation(title: "Radio Caroline 259 Gold [ Happy Rock &amp; Album Station ]", url: "http://www.rcgoldserver.eu:8253"),
//            InternetStation(title: "Super station", url: "https://www.station.com"),
//            InternetStation(title: "Radio Caroline", url: "http://sc3.radiocaroline.net:8030"),
//            InternetStation(title: "Radio Caroline 319 Gold [ Hits from '60-'70 ]", url: "http://www.rcgoldserver.eu:8192"),
//            InternetStation(title: "Radio Caroline 259 Gold [ Happy Rock &amp; Album Station ]", url: "http://www.rcgoldserver.eu:8253"),
//            InternetStation(title: "Super station", url: "https://www.station.com"),
//            InternetStation(title: "Radio Caroline", url: "http://sc3.radiocaroline.net:8030"),
//            InternetStation(title: "Radio Caroline 319 Gold [ Hits from '60-'70 ]", url: "http://www.rcgoldserver.eu:8192"),
//            InternetStation(title: "Radio Caroline 259 Gold [ Happy Rock &amp; Album Station ]", url: "http://www.rcgoldserver.eu:8253"),
//            InternetStation(title: "Super station", url: "https://www.station.com"),
//            InternetStation(title: "Radio Caroline", url: "http://sc3.radiocaroline.net:8030"),
//            InternetStation(title: "Radio Caroline 319 Gold [ Hits from '60-'70 ]", url: "http://www.rcgoldserver.eu:8192"),
//            InternetStation(title: "Radio Caroline 259 Gold [ Happy Rock &amp; Album Station ]", url: "http://www.rcgoldserver.eu:8253"),
//            InternetStation(title: "Super station", url: "https://www.station.com"),
//            InternetStation(title: "Radio Caroline", url: "http://sc3.radiocaroline.net:8030"),
//            InternetStation(title: "Radio Caroline 319 Gold [ Hits from '60-'70 ]", url: "http://www.rcgoldserver.eu:8192"),
//            InternetStation(title: "Radio Caroline 259 Gold [ Happy Rock &amp; Album Station ]", url: "http://www.rcgoldserver.eu:8253"),
//        ]
//        do {
//            print("task 1", stations.count)
//            stations = try await provider.fetch()
//            print("task 2", stations.count)
//        } catch {
//            Alarm.show(title: "Couldn't download the stations from radio-browser.info", message: "\(error.localizedDescription)")
//        }
//    }
}
