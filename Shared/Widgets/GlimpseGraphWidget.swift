//
//  GlimpseGraphWidget.swift
//  Glimpse
//
//  Created by Kyle Bashour on 5/1/24.
//

import WidgetKit
import SwiftUI
import Dexcom

struct GlimpseGraphWidget: Widget {
    let kind: String = "GlimpseChartWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: GraphWidgetConfiguration.self,
            provider: GraphTimelineProvider()
        ) { entry in
            GraphWidgetView(entry: entry)
        }
        .supportedFamilies(families)
        .configurationDisplayName("Reading Graph")
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

#Preview(as: .accessoryRectangular) {
    GlimpseGraphWidget()
} timeline: {
    GlucoseEntry<GlucoseGraphEntryData>(
        date: .now,
        state: .reading(
            .init(
                configuration: GraphWidgetConfiguration(),
                current: .placeholder,
                history: .placeholder
            )
        )
    )
    GlucoseEntry<GlucoseGraphEntryData>(
        date: .now.addingTimeInterval(80),
        state: .reading(
            .init(
                configuration: GraphWidgetConfiguration(),
                current: .placeholder,
                history: .placeholder
            )
        )
    )
    GlucoseEntry<GlucoseGraphEntryData>(
        date: .now.addingTimeInterval(300),
        state: .reading(
            .init(
                configuration: GraphWidgetConfiguration(),
                current: .placeholder,
                history: .placeholder
            )
        )
    )
    GlucoseEntry<GlucoseGraphEntryData>(
        date: .now.addingTimeInterval(60 * 30),
        state: .reading(
            .init(
                configuration: GraphWidgetConfiguration(),
                current: .placeholder,
                history: .placeholder
            )
        )
    )
    GlucoseEntry<GlucoseGraphEntryData>(date: .now, state: .error(.failedToLoad))
    GlucoseEntry<GlucoseGraphEntryData>(date: .now, state: .error(.noRecentReadings))
    GlucoseEntry<GlucoseGraphEntryData>(date: .now, state: .error(.loggedOut))
}