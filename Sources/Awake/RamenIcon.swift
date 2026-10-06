import AppKit

/// Ramen-bowl icons, one per AwakeMode.
///
/// Mapping:
/// - off:     empty bowl — bare rim, hollow interior, no steam.
/// - system:  full bowl — noodle surface, egg + toppings, chopsticks, no steam.
/// - display: steaming bowl — full bowl plus three rising steam wisps.
///
/// Coordinates assume a 22x22 canvas with y growing upward
/// (image created with flipped:false), matching ``EyeIcon``.
enum RamenIcon {
    static func image(for mode: AwakeMode) -> NSImage {
        let size = NSSize(width: 22, height: 22)
        let image = NSImage(size: size, flipped: false) { rect in
            drawBowl(for: mode, in: rect)
            return true
        }
        image.isTemplate = false
        image.accessibilityDescription = mode.tooltip
        return image
    }

    // MARK: - Private

    private static func drawBowl(for mode: AwakeMode, in rect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.saveGState()
        defer { ctx.restoreGState() }

        let cx: CGFloat = rect.midX
        let rimY: CGFloat = 9.5
        let leftRimX: CGFloat = 2.5
        let rightRimX: CGFloat = 19.5

        // Steam sits behind everything else (drawn first, above the bowl).
        if mode == .display {
            drawSteam(centerX: cx)
        }

        // Bowl body: rim left -> rim right -> tapered bottom.
        let bowl = NSBezierPath()
        bowl.move(to: NSPoint(x: leftRimX, y: rimY))
        bowl.line(to: NSPoint(x: rightRimX, y: rimY))
        bowl.line(to: NSPoint(x: 16.5, y: 4.0))
        bowl.curve(
            to: NSPoint(x: 5.5, y: 4.0),
            controlPoint1: NSPoint(x: 13.5, y: 2.2),
            controlPoint2: NSPoint(x: 8.5, y: 2.2)
        )
        bowl.close()

        NSColor.white.setFill()
        bowl.fill()
        NSColor.labelColor.setStroke()
        bowl.lineWidth = 1.5
        bowl.lineJoinStyle = .round
        bowl.stroke()

        // Decorative stripe near the base so the bowl reads as a bowl even
        // when empty.
        let stripe = NSBezierPath()
        stripe.move(to: NSPoint(x: 5.0, y: 5.6))
        stripe.curve(
            to: NSPoint(x: 17.0, y: 5.6),
            controlPoint1: NSPoint(x: 8.5, y: 4.4),
            controlPoint2: NSPoint(x: 13.5, y: 4.4)
        )
        stripe.lineWidth = 1.1
        NSColor.systemBlue.setStroke()
        stripe.stroke()

        // Foot.
        let foot = NSBezierPath()
        foot.move(to: NSPoint(x: cx - 3.0, y: 3.1))
        foot.line(to: NSPoint(x: cx + 3.0, y: 3.1))
        foot.line(to: NSPoint(x: cx + 2.4, y: 1.4))
        foot.line(to: NSPoint(x: cx - 2.4, y: 1.4))
        foot.close()
        NSColor.controlColor.setFill()
        foot.fill()
        NSColor.labelColor.setStroke()
        foot.lineWidth = 1.1
        foot.stroke()

        switch mode {
        case .off:
            // Empty: hollow interior — a shallow inner ellipse suggesting
            // the inside of an empty bowl.
            let inner = NSBezierPath(ovalIn: NSRect(x: 4.5, y: 7.6, width: 13.0, height: 3.4))
            NSColor.systemGray.withAlphaComponent(0.35).setFill()
            inner.fill()
            NSColor.secondaryLabelColor.setStroke()
            inner.lineWidth = 1.0
            inner.stroke()
        case .system, .display:
            drawNoodles(centerX: cx, rimY: rimY)
            // Chopsticks resting across the rim.
            let sticks = NSBezierPath()
            sticks.lineWidth = 1.3
            sticks.lineCapStyle = .round
            NSColor.systemBrown.setStroke()
            sticks.move(to: NSPoint(x: 3.5, y: 12.2))
            sticks.line(to: NSPoint(x: 18.5, y: 13.6))
            sticks.move(to: NSPoint(x: 3.5, y: 11.0))
            sticks.line(to: NSPoint(x: 18.5, y: 12.4))
            sticks.stroke()
        }
    }

    /// Noodle surface + toppings clipped to the rim ellipse.
    private static func drawNoodles(centerX cx: CGFloat, rimY: CGFloat) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.saveGState()

        let surface = NSBezierPath(ovalIn: NSRect(x: 3.0, y: rimY - 1.7, width: 16.0, height: 3.8))
        surface.addClip()

        // Broth / noodle base.
        NSColor.systemYellow.withAlphaComponent(0.9).setFill()
        NSRect(x: 2.0, y: rimY - 2.0, width: 18.0, height: 4.5).fill()

        // Wavy noodle strands.
        NSColor.systemBrown.setStroke()
        let strands = NSBezierPath()
        strands.lineWidth = 0.9
        strands.lineCapStyle = .round
        for (i, dy) in [-0.8, 0.0, 0.8].enumerated() {
            let y = rimY + dy
            strands.move(to: NSPoint(x: 4.0, y: y))
            strands.curve(
                to: NSPoint(x: 18.0, y: y),
                controlPoint1: NSPoint(x: 8.0 + CGFloat(i) * 0.6, y: y + 1.0),
                controlPoint2: NSPoint(x: 14.0 - CGFloat(i) * 0.6, y: y - 1.0)
            )
        }
        strands.stroke()

        // Half egg (white + yolk) on the left.
        let eggWhite = NSBezierPath(ovalIn: NSRect(x: 4.6, y: rimY - 1.4, width: 4.4, height: 3.0))
        NSColor.white.setFill()
        eggWhite.fill()
        NSColor.labelColor.setStroke()
        eggWhite.lineWidth = 0.7
        eggWhite.stroke()
        let yolk = NSBezierPath(ovalIn: NSRect(x: 6.0, y: rimY - 0.9, width: 1.8, height: 1.8))
        NSColor.systemOrange.setFill()
        yolk.fill()

        // Nori sheet on the right.
        let nori = NSBezierPath(rect: NSRect(x: 14.6, y: rimY - 1.2, width: 2.6, height: 2.6))
        NSColor.systemGreen.withAlphaComponent(0.9).setFill()
        nori.fill()

        // Scallion dots.
        NSColor.systemGreen.setFill()
        for p in [NSPoint(x: 11.2, y: rimY - 0.2), NSPoint(x: 12.8, y: rimY + 0.3)] {
            NSBezierPath(ovalIn: NSRect(x: p.x, y: p.y, width: 1.2, height: 1.2)).fill()
        }

        ctx.restoreGState()

        // Re-stroke the rim so toppings never spill over the edge.
        let rim = NSBezierPath(ovalIn: NSRect(x: 3.0, y: rimY - 1.7, width: 16.0, height: 3.8))
        NSColor.labelColor.setStroke()
        rim.lineWidth = 1.3
        rim.stroke()
    }

    /// Three S-curved steam wisps rising above the bowl.
    private static func drawSteam(centerX cx: CGFloat) {
        NSColor.secondaryLabelColor.setStroke()
        let steam = NSBezierPath()
        steam.lineWidth = 1.1
        steam.lineCapStyle = .round
        for dx in [-4.0, 0.0, 4.0] {
            let x = cx + dx
            steam.move(to: NSPoint(x: x, y: 14.2))
            steam.curve(
                to: NSPoint(x: x, y: 20.0),
                controlPoint1: NSPoint(x: x - 1.6, y: 16.0),
                controlPoint2: NSPoint(x: x + 1.6, y: 18.0)
            )
        }
        steam.stroke()
    }
}
