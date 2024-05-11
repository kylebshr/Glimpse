//
//  LiveViewModel.swift
//  Glimpse
//
//  Created by Kyle Bashour on 5/2/24.
//

import Foundation
import KeychainAccess
import Dexcom
import Defaults

@MainActor @Observable class LiveViewModel {
    enum State {
        case initial
        case loaded([GlucoseReading], latest: GlucoseReading)
        case noRecentReading
        case error(Error)
    }

    private(set) var state: State = .initial
    private(set) var message: String = LiveViewModel.message(for: .initial)

    private(set) var username: String? = Keychain.shared.username
    private(set) var password: String? = Keychain.shared.password
    private(set) var accountLocation: AccountLocation? = Defaults[.accountLocation]

    private var timestampTimer: Timer?
    private var timer: Timer?
    private var client: DexcomClient?
    private let decoder = JSONDecoder()

    var messageValue: TimeInterval {
        switch state {
        case .initial, .noRecentReading, .error: 0
        case .loaded(_, let latest): latest.date.timeIntervalSince1970
        }
    }

    private var shouldRefreshReading: Bool {
        switch state {
        case .initial, .error, .noRecentReading:
            return true
        case .loaded(_, let latest):
            return latest.date.timeIntervalSinceNow < -60 * 5
        }
    }
    init() {
        decoder.dateDecodingStrategy = .iso8601
        setUpClientAndBeginRefreshing()

        timestampTimer = .scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.message = LiveViewModel.message(for: self.state)
            }
        }
    }

    private func setUpClientAndBeginRefreshing() {
        if let username, let password, let accountLocation {
            state = .initial

            client = DexcomClient(
                username: username,
                password: password,
                existingAccountID: Keychain.shared.accountID,
                existingSessionID: Keychain.shared.sessionID,
                accountLocation: accountLocation
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
                    let readings = try await client.getGraphReadings(duration: .init(value: 24, unit: .hours))
                    if let latest = readings.last {
                        state = .loaded(readings, latest: latest)
                    } else {
                        state = .noRecentReading
                    }
                } catch {
                    state = .error(error)
                }
            }

            message = LiveViewModel.message(for: state)

            let refreshTime: TimeInterval? = {
                switch state {
                case .initial:
                    return nil
                case .loaded(_, let latest):
                    // 5:10 after the last reading.
                    let fiveMinuteRefresh = 60 * 5 + latest.date.timeIntervalSinceNow + 10
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

                timer?.invalidate()
                timer = Timer.scheduledTimer(withTimeInterval: refreshTime, repeats: false) { [weak self] _ in
                    DispatchQueue.main.async { [weak self] in
                        self?.beginRefreshing()
                    }
                }
            }
        }
    }

    private static func message(for state: State) -> String {
        switch state {
        case .initial:
            return "Updating"
        case .loaded(_, let latest):
            return latest.timestamp(for: .now)
        case .noRecentReading:
            return "No recent readings"
        case .error:
            return "Error loading readings"
        }
    }
}
