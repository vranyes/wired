import AppKit

/// Coffee-cup icons, one per AwakeMode.
///
/// Mapping:
/// - off:     empty cup — hollow interior, no steam.
/// - system:  half-full cup — coffee to ~45%, one central steam wisp.
/// - display: full cup — coffee to ~85%, three steam wisps.
///
/// Coordinates assume a 22x22 canvas with y growing upward
/// (image created with flipped:false), matching ``EyeIcon``.
enum CoffeeIcon {
    static func image(for mode: AwakeMode) -> NSImage {
        let size = NSSize(width: 22, height: 22)
        let image = NSImage(size: size, flipped: false) { rect in
            drawCup(for: mode, in: rect)
            return true
        }
        image.isTemplate = false
        image.accessibilityDescription = mode.tooltip
        return image
    }

    // MARK: - Private

    private static func drawCup(for mode: AwakeMode, in rect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.saveGState()
        defer { ctx.restoreGState() }

        let cx: CGFloat = rect.midX - 2.0
        let cupLeft: CGFloat = cx - 4.5
        let cupRight: CGFloat = cx + 4.5
        let cupBottom: CGFloat = 2.5
        let cupTop: CGFloat = 12.5

        // Steam first (behind the cup rim).
        switch mode {
        case .off:
            break
        case .system:
            drawWisps(xs: [cx], baseY: cupTop + 1.5)
        case .display:
            drawWisps(xs: [cx - 3.0, cx, cx + 3.0], baseY: cupTop + 1.5)
        }

        // Mug body.
        let body = NSBezierPath(
            roundedRect: NSRect(
                x: cupLeft, y: cupBottom,
                width: cupRight - cupLeft, height: cupTop - cupBottom
            ),
            xRadius: 1.5, yRadius: 1.5
        )
        NSColor.white.setFill()
        body.fill()

        // Coffee fill, clipped to the mug so levels stay inside.
        ctx.saveGState()
        body.addClip()
        let fillTop: CGFloat?
        switch mode {
        case .off:
            fillTop = nil
        case .system:
            // Part full (~45%).
            fillTop = cupBottom + (cupTop - cupBottom) * 0.45
        case .display:
            // Full (~85%).
            fillTop = cupBottom + (cupTop - cupBottom) * 0.85
        }
        if let fillTop {
            NSColor.systemBrown.withAlphaComponent(0.9).setFill()
            NSRect(x: cupLeft, y: cupBottom, width: cupRight - cupLeft, height: fillTop - cupBottom).fill()
            // Highlight line at the liquid surface.
            NSColor.systemBrown.setStroke()
            let surface = NSBezierPath()
            surface.move(to: NSPoint(x: cupLeft, y: fillTop))
            surface.line(to: NSPoint(x: cupRight, y: fillTop))
            surface.lineWidth = 1.0
            surface.stroke()
        } else {
            // Empty: faint inner floor so the hollow cup reads as hollow.
            NSColor.systemGray.withAlphaComponent(0.3).setFill()
            NSRect(x: cupLeft + 1.0, y: cupBottom, width: cupRight - cupLeft - 2.0, height: 1.4).fill()
        }
        ctx.restoreGState()

        NSColor.labelColor.setStroke()
        body.lineWidth = 1.5
        body.lineJoinStyle = .round
        body.stroke()

        // Handle on the right.
        let handle = NSBezierPath()
        handle.move(to: NSPoint(x: cupRight - 0.5, y: 10.0))
        handle.curve(
            to: NSPoint(x: cupRight - 0.5, y: 5.5),
            controlPoint1: NSPoint(x: cupRight + 4.0, y: 10.0),
            controlPoint2: NSPoint(x: cupRight + 4.0, y: 5.5)
        )
        handle.lineWidth = 1.5
        handle.lineCapStyle = .round
        NSColor.labelColor.setStroke()
        handle.stroke()

        // Saucer.
        let saucer = NSBezierPath()
        saucer.move(to: NSPoint(x: cupLeft - 2.0, y: cupBottom - 0.6))
        saucer.line(to: NSPoint(x: cupRight + 2.6, y: cupBottom - 0.6))
        saucer.lineWidth = 1.3
        saucer.lineCapStyle = .round
        NSColor.labelColor.setStroke()
        saucer.stroke()
    }

    /// S-curved steam wisps. Count varies by mode (1 vs 3).
    private static func drawWisps(xs: [CGFloat], baseY: CGFloat) {
        NSColor.secondaryLabelColor.setStroke()
        let steam = NSBezierPath()
        steam.lineWidth = 1.1
        steam.lineCapStyle = .round
        for x in xs {
            steam.move(to: NSPoint(x: x, y: baseY))
            steam.curve(
                to: NSPoint(x: x, y: baseY + 5.4),
                controlPoint1: NSPoint(x: x - 1.5, y: baseY + 1.8),
                controlPoint2: NSPoint(x: x + 1.5, y: baseY + 3.6)
            )
        }
        steam.stroke()
    }
}
