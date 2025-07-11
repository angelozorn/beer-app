import SwiftUI

// MARK: – Color Palette

extension Color {
    /// App background behind all content
    static var background: Color { Color.black }

    /// Card and form backgrounds
    static var cardBackground: Color { Color(white: 0.12) }

    /// Primary “action” accent (buttons, highlights)
    static var primaryAccent: Color { Color.blue }

    /// Secondary accent (links, secondary buttons)
    static var secondaryAccent: Color { Color.orange }

    /// Main text color on dark background
    static var textPrimary: Color { Color.white }

    /// Subtle text color for captions, labels
    static var textSecondary: Color { Color.gray }
}

// MARK: – Typography

extension Font {
    /// Large title
    static var heading1: Font { .system(size: 32, weight: .bold) }

    /// Section titles
    static var heading2: Font { .system(size: 22, weight: .semibold) }

    /// Body text
    static var bodyText: Font { .system(size: 17, weight: .regular) }

    /// Small captions
    static var caption: Font { .system(size: 13, weight: .regular) }
}
