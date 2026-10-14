//
//  IceBarLayout.swift
//  Project: Thaw
//
//  Copyright (Ice) © 2023–2025 Jordan Baird
//  Copyright (Thaw) © 2026 Toni Förster
//  Licensed under the GNU GPLv3

import SwiftUI

/// Layout modes for the Thaw Bar.
nonisolated enum IceBarLayout: Int, CaseIterable, Codable, Identifiable {
    /// Items are arranged in a single horizontal row.
    case horizontal = 0

    /// Items are stacked vertically in a single column.
    case vertical = 1

    /// Items are arranged in a grid with a configurable number of columns.
    case grid = 2

    /// Hidden icons scroll in the menu bar, beside the native visible section.
    case menuBarScroll = 3

    var id: Int {
        rawValue
    }

    /// Localized string key representation.
    var localized: LocalizedStringKey {
        switch self {
        case .horizontal: "Horizontal"
        case .vertical: "Vertical"
        case .grid: "Grid"
        case .menuBarScroll: "Menu Bar Scroll"
        }
    }

    /// Parses an IceBarLayout from a string value.
    /// Supports exact case names: "horizontal", "vertical", "grid"
    /// Or raw integer values: "0", "1", "2"
    static func fromString(_ value: String) -> IceBarLayout? {
        switch value {
        case "horizontal", "0":
            return .horizontal
        case "vertical", "1":
            return .vertical
        case "grid", "2":
            return .grid
        case "menuBarScroll", "3":
            return .menuBarScroll
        default:
            return nil
        }
    }
}
