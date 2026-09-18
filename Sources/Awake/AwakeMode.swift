import Foundation

/// The three power states of the eyeball.
///
/// - off:     sleepy eye, no assertion held, Mac may sleep normally.
/// - system:  drowsy half-open eye, system stays awake but display may sleep.
/// - display: wide-awake eye, display stays on (implies system awake).
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
        case .off: return "Sleepy (Allow Sleep)"
        case .system: return "Drowsy (System Awake)"
        case .display: return "Wide Awake (Display On)"
        }
    }

    var tooltip: String {
        switch self {
        case .off: return "Awake: Off — click to keep system awake"
        case .system: return "Awake: System — click for display-on mode"
        case .display: return "Awake: Display On — click to allow sleep"
        }
    }

    var isActive: Bool { self != .off }
}
