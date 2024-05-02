//
//  SystemWidgetReadingView.swift
//  Glimpse
//
//  Created by Kyle Bashour on 4/25/24.
//

import SwiftUI
import WidgetKit
import Dexcom

struct SystemWidgetChartView: View {
    let entry: ChartTimelineProvider.Entry
    let data: ChartGlucoseData

    @Environment(\.redactionReasons) private var redactionReasons
    @Environment(\.widgetContentMargins) private var widgetContentMargins

    var body: some View {
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
                .font(.system(.headline, design: .rounded, weight: .semibold))

                Spacer()

                Text(data.chartRangeTitle)
                    .foregroundStyle(.secondary)
                    .font(.caption2)
            }

            ChartView(
                range: data.configuration.chartRange,
                readings: data.history,
                highlight: data.current,
                chartUpperBound: data.chartUpperBound,
                targetRange: data.targetLowerBound...data.targetUpperBound,
                roundBottomCorners: false
            )
            .padding(.leading, -widgetContentMargins.leading)
            .padding(.trailing, -widgetContentMargins.trailing)

            Spacer(minLength: 12)

            Button(intent: ReloadWidgetIntent()) {
                HStack {
                    Text(data.current.timestamp(for: entry.date))
                        .contentTransition(.numericText(value: data.current.date.timeIntervalSinceNow))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Image(systemName: "arrow.circlepath")
                        .foregroundStyle(.secondary)
                        .unredacted()
                }
                .font(.caption2)
            }
            .buttonStyle(.plain)
            .tint(.primary)
        }
        .fontWeight(.semibold)
        .standByMargins()
        .containerBackground(.background, for: .widget)
    }
}