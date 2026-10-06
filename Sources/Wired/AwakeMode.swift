import Foundation

/// The three power states.
///
/// - off:     no assertion held, Mac may sleep normally.
/// - system:  system stays awake but display may sleep.
/// - display: display stays on (implies system awake).
enum AwakeMode: String, CaseIterable {
    case off
    case system
    case display

    /// Left-click order: off -> system -> display -> off
    func next() -> AwakeMode {
        switch self {
        case .off: return .system
        case .system: return .display
        case .display: return .off
        }
    }

    var menuTitle: String {
        switch self {
        case .off: return "Off (Allow Sleep)"
        case .system: return "System Awake (Display May Sleep)"
        case .display: return "Display On (System Awake)"
        }
    }

    var tooltip: String {
        switch self {
        case .off: return "Wired: Off — click to keep system awake"
        case .system: return "Wired: System Awake — click for display-on mode"
        case .display: return "Wired: Display On — click to allow sleep"
        }
    }

    var isActive: Bool { self != .off }
}
