import AppKit

/// Custom-drawn eyeball icons, one per AwakeMode.
///
/// Geometry-only difference (same palette) so the icon reads in both
/// light and dark menu bars:
/// - off:     sleepy closed slit + rising z, no pupil, no lashes.
/// - system:  drowsy heavy-lidded eye, low half-mast pupil, under-eye bag.
/// - display: wide-open almond, large pupil + catchlight.
enum EyeIcon {
    static func image(for mode: AwakeMode) -> NSImage {
        let size = NSSize(width: 22, height: 22)
        // NOTE: keep flipped:false. The handler context is standard y-up;
        // an earlier flipped:true experiment mirrored every icon on screen.
        // Drawing coordinates below assume y grows upward.
        let image = NSImage(size: size, flipped: false) { rect in
            drawEye(for: mode, in: rect)
            return true
        }
        image.isTemplate = false
        image.accessibilityDescription = mode.tooltip
        return image
    }

    // MARK: - Private

    private static func drawEye(for mode: AwakeMode, in rect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.saveGState()
        defer { ctx.restoreGState() }

        let cx: CGFloat = rect.midX
        let cy: CGFloat = rect.midY + 1.0 // optical centering
        let leftX: CGFloat = 2.0
        let rightX: CGFloat = 20.0

        // Asymmetric lids: the drowsy eye gets a heavy upper lid that
        // sags low over the pupil, with a normal lower lid.
        let topHeight: CGFloat
        let bottomHeight: CGFloat
        switch mode {
        case .off:
            topHeight = 2.2
            bottomHeight = 2.2
        case .system:
            topHeight = 1.0
            bottomHeight = 5.5
        case .display:
            topHeight = 7.5
            bottomHeight = 7.5
        }

        let almond = NSBezierPath()
        almond.move(to: NSPoint(x: leftX, y: cy))
        almond.curve(
            to: NSPoint(x: rightX, y: cy),
            controlPoint1: NSPoint(x: cx - 4.5, y: cy + topHeight),
            controlPoint2: NSPoint(x: cx + 4.5, y: cy + topHeight)
        )
        almond.curve(
            to: NSPoint(x: leftX, y: cy),
            controlPoint1: NSPoint(x: cx + 4.5, y: cy - bottomHeight),
            controlPoint2: NSPoint(x: cx - 4.5, y: cy - bottomHeight)
        )
        almond.close()

        // Sclera fill
        switch mode {
        case .off:
            NSColor.systemGray.withAlphaComponent(0.55).setFill()
        case .system, .display:
            NSColor.white.setFill()
        }
        almond.fill()

        // Outline (adapts to light/dark)
        NSColor.labelColor.setStroke()
        almond.lineWidth = 1.6
        almond.lineJoinStyle = .round
        almond.stroke()

        if mode == .off {
            // Plain closed lid + z. Deliberately no lashes: at 22pt any
            // lash ticks risk reading as flipped, and a bare slit with a
            // rising z is unambiguous in both light and dark mode.
            // Tiny "z" for sleepiness, top-right
            let z = NSBezierPath()
            z.lineWidth = 1.2
            z.lineCapStyle = .round
            z.move(to: NSPoint(x: 16.4, y: 18.2))
            z.line(to: NSPoint(x: 19.6, y: 18.2))
            z.line(to: NSPoint(x: 16.6, y: 15.0))
            z.line(to: NSPoint(x: 19.8, y: 15.0))
            NSColor.secondaryLabelColor.setStroke()
            z.stroke()
            return
        }

        // Pupil, clipped to the almond so the lid covers it.
        // Drowsy pupil sits low and half-mast under the heavy lid.
        ctx.saveGState()
        almond.addClip()

        let pupilDiameter: CGFloat
        let pupilCenterY: CGFloat
        switch mode {
        case .off:
            pupilDiameter = 0
            pupilCenterY = cy
        case .system:
            pupilDiameter = 4.2
            pupilCenterY = cy - 2.2
        case .display:
            pupilDiameter = 8.0
            pupilCenterY = cy
        }
        let pupilRect = NSRect(
            x: cx - pupilDiameter / 2,
            y: pupilCenterY - pupilDiameter / 2,
            width: pupilDiameter,
            height: pupilDiameter
        )
        let pupil = NSBezierPath(ovalIn: pupilRect)
        NSColor.black.setFill()
        pupil.fill()

        // Catchlight: bright and crisp when wide awake; none when
        // drowsy — a dull eye reads sleepier.
        if mode == .display {
            let glint = NSBezierPath(ovalIn: NSRect(
                x: cx - 2.4,
                y: cy + 1.4,
                width: 2.4,
                height: 2.4
            ))
            NSColor.white.setFill()
            glint.fill()
        }

        ctx.restoreGState()

        if mode == .system {
            // Upper-lid lashes sprouting outward from the flat lid edge.
            // They sit on the background (not the sclera) so they read in
            // both light mode (dark lashes) and dark mode (light lashes).
            NSColor.labelColor.setStroke()
            let lashes = NSBezierPath()
            lashes.lineWidth = 1.2
            lashes.lineCapStyle = .round
            // (dx from center, edge y offset, tip splay) along the flat lid edge.
            let ticks: [(CGFloat, CGFloat, CGFloat)] = [
                (-3.5, 0.3, -0.9),
                (0.0, 0.8, 0.0),
                (3.5, 0.3, 0.9),
            ]
            for (dx, edgeDy, splay) in ticks {
                lashes.move(to: NSPoint(x: cx + dx, y: cy + edgeDy))
                lashes.line(to: NSPoint(x: cx + dx + splay, y: cy + edgeDy + 2.4))
            }
            lashes.stroke()

            // Tired under-eye bag, hugging the lower lid.
            let bag = NSBezierPath()
            bag.move(to: NSPoint(x: cx - 5.0, y: cy - bottomHeight - 1.0))
            bag.curve(
                to: NSPoint(x: cx + 5.0, y: cy - bottomHeight - 1.0),
                controlPoint1: NSPoint(x: cx - 2.0, y: cy - bottomHeight - 2.0),
                controlPoint2: NSPoint(x: cx + 2.0, y: cy - bottomHeight - 2.0)
            )
            bag.lineWidth = 0.9
            NSColor.secondaryLabelColor.setStroke()
            bag.stroke()
        }
    }
}
