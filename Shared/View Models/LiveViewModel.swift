//
//  LiveViewModel.swift
//  Glimpse
//
//  Created by Kyle Bashour on 5/2/24.
//

import Foundation
import KeychainAccess
import Dexcom

@MainActor @Observable class LiveViewModel {
    enum State {
        case initial
        case loaded(GlucoseChartData)
        case noRecentReading
        case error(Error)
    }

    var isLoggedIn: Bool {
        username != nil && password != nil
    }

    var outsideUS: Bool = UserDefaults.standard.bool(forKey: .outsideUSKey) {
        didSet {
            if outsideUS != oldValue {
                setUpClientAndBeginRefreshing()
            }
        }
    }

    private(set) var reading: State = .initial
    private(set) var message: String?

    private(set) var username: String? = Keychain.shared[.usernameKey]
    private(set) var password: String? = Keychain.shared[.passwordKey]

    private var client: DexcomClient?
    private let decoder = JSONDecoder()

    private var shouldRefreshReading: Bool {
        switch reading {
        case .initial, .error, .noRecentReading:
            return true
        case .loaded(let reading):
            return reading.current.date.timeIntervalSinceNow < -60 * 5
        }
    }

    init() {
        decoder.dateDecodingStrategy = .iso8601
        setUpClientAndBeginRefreshing()
    }

    func logIn(username: String, password: String) {
        self.username = username
        self.password = password

        setUpClientAndBeginRefreshing()
    }

    private func setUpClientAndBeginRefreshing() {
        if let username, let password {
            reading = .initial

            client = DexcomClient(
                username: username,
                password: password,
                outsideUS: outsideUS
            )

            beginRefreshing()
        }
    }

    func beginRefreshing() {
        guard let client else { return }

        Task<Void, Never> {
            if shouldRefreshReading {
                print("Refreshing reading")

                do {
                    if let current = try await client.getChartReadings() {
                        reading = .loaded(current)
                    } else {
                        reading = .noRecentReading
                    }
                } catch let error as DexcomError {
                    // Could be too many attempts; stop auto refreshing.
                    reading = .error(error)
                } catch {
                    reading = .error(error)
                }
            }

            updateMessage()

            let refreshTime: TimeInterval? = {
                switch reading {
                case .initial:
                    return nil
                case .loaded(let reading):
                    // 5:10 after the last reading.
                    let fiveMinuteRefresh = 60 * 5 + reading.current.date.timeIntervalSinceNow + 10
                    // Refresh 5:10 after reading, then every 10s.
                    return max(10, fiveMinuteRefresh)
                case .noRecentReading:
                    return 10
                case .error(let error):
                    if error is DexcomError {
                        return nil
                    } else {
                        return 10
                    }
                }
            }()

            if let refreshTime {
                // Refresh at least every 60s for the time stamp.
                let refreshTime = min(60, refreshTime)

                print("Scheduling refresh in \(refreshTime / 60) minutes")

                Timer.scheduledTimer(withTimeInterval: refreshTime, repeats: false) { [weak self] _ in
                    DispatchQueue.main.async { [weak self] in
                        self?.beginRefreshing()
                    }
                }
            }
        }
    }

    private func updateMessage() {
        switch reading {
        case .initial:
            message = "Loading..."
        case .loaded(let reading):
            if reading.current.date.timeIntervalSinceNow > -60 {
                message = "Just now"
            } else {
                message = reading.current.date.formatted(.relative(presentation: .numeric))
            }
        case .noRecentReading:
            message = "No recent glucose readings"
        case .error(let error):
            if error is DexcomError {
                message = "Try refreshing in 10 minutes"
            } else {
                message = "Unknown error"
            }
        }
    }
}
