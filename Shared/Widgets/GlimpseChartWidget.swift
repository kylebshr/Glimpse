//
//  GlimpseChartWidget.swift
//  Glimpse
//
//  Created by Kyle Bashour on 5/1/24.
//

import WidgetKit
import SwiftUI
import Dexcom

struct GlimpseChartWidget: Widget {
    let kind: String = "GlimpseChartWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ChartWidgetConfiguration.self,
            provider: ChartTimelineProvider()
        ) { entry in
            ChartWidgetView(entry: entry)
        }
        .supportedFamilies(families)
        .configurationDisplayName("Reading Chart")
    }

    private var families: [WidgetFamily] {
        #if os(watchOS)
        [
            .accessoryRectangular,
        ]
        #else
        [
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryRectangular,
        ]
        #endif
    }
}

#if os(iOS)
#Preview(as: .systemSmall) {
    GlimpseChartWidget()
} timeline: {
    GlucoseEntry<ChartGlucoseData>(
        date: .now,
        state: .reading(
            .init(
                configuration: ChartWidgetConfiguration(),
                current: .placeholder,
                history: .placeholder
            )
        )
    )
    GlucoseEntry<ChartGlucoseData>(date: .now, state: .error(.failedToLoad))
    GlucoseEntry<ChartGlucoseData>(date: .now, state: .error(.noRecentReadings))
    GlucoseEntry<ChartGlucoseData>(date: .now, state: .error(.loggedOut))
}
#endif
