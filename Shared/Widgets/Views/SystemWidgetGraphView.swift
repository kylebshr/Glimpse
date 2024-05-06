//
//  SystemWidgetReadingView.swift
//  Glimpse
//
//  Created by Kyle Bashour on 4/25/24.
//

import SwiftUI
import WidgetKit
import Dexcom

#if os(iOS)
struct SystemWidgetGraphView: View {
    let entry: GraphTimelineProvider.Entry
    let data: GlucoseGraphEntryData

    @Environment(\.redactionReasons) private var redactionReasons
    @Environment(\.widgetContentMargins) private var widgetContentMargins

    var body: some View {
        VStack(alignment: .leading) {
            Button(intent: ReloadWidgetIntent()) {
                VStack(alignment: .leading) {
                    HStack(alignment: .firstTextBaseline) {
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text(data.current.value.formatted())
                                .contentTransition(.numericText(value: Double(data.current.value)))
                                .invalidatableContent()

                            if redactionReasons.isEmpty {
                                data.current.image
                                    .imageScale(.small)
                                    .contentTransition(.symbolEffect(.replace))
                            }
                        }

                        timeLabels
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                }
            }
            .buttonStyle(.plain)

            GraphView(
                range: data.configuration.graphRange,
                readings: data.history,
                highlight: data.current,
                graphUpperBound: data.graphUpperBound,
                targetRange: data.targetLowerBound...data.targetUpperBound,
                roundBottomCorners: true
            )
        }
        .standByMargins()
        .containerBackground(.background, for: .widget)
    }

    private var timeLabels: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            ViewThatFits {
                Text(data.current.timestamp(for: entry.date))
                Text(data.current.timestamp(for: entry.date, style: .abbreviated, appendRelativeText: false))
            }
            .contentTransition(.numericText())

//            if entry.date.timeIntervalSince(data.current.date) > 5 * 60 {
//                Image(systemName: "arrow.circlepath").imageScale(.small)
//                    .transition(.blurReplace(.downUp))
//            }

            Spacer()

            Text(data.graphRangeTitle)
        }
        .foregroundStyle(.secondary)
        .font(.footnote.weight(.medium))
    }
}
#endif
