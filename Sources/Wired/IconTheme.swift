import AppKit

/// Selectable menu-bar icon theme.
///
/// Each theme maps the three ``AwakeMode`` levels onto a distinct visual:
/// - eye:    sleepy slit / drowsy half-mast / wide open (see ``EyeIcon``).
/// - ramen:  empty bowl / full bowl / full bowl with steam.
/// - coffee: empty cup / half-full cup with a wisp / full cup with full steam.
enum IconTheme: String, CaseIterable {
    case eye
    case ramen
    case coffee

    var menuTitle: String {
        switch self {
        case .eye: return "Eyes"
        case .ramen: return "Ramen"
        case .coffee: return "Coffee"
        }
    }

    func image(for mode: AwakeMode) -> NSImage {
        switch self {
        case .eye: return EyeIcon.image(for: mode)
        case .ramen: return RamenIcon.image(for: mode)
        case .coffee: return CoffeeIcon.image(for: mode)
        }
    }
}
