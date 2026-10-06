import Foundation
import IOKit.pwr_mgt

/// Wraps IOPMAssertionCreateWithName / IOPMAssertionRelease.
///
/// Holds at most one assertion at a time. Switching modes releases the
/// old assertion before taking the new one.
final class PowerAssertionManager {
    private var assertionID: IOPMAssertionID = 0
    private var hasAssertion = false

    var isHeld: Bool { hasAssertion }

    /// Apply the given mode. Returns true on success.
    @discardableResult
    func apply(_ mode: AwakeMode) -> Bool {
        release()

        switch mode {
        case .off:
            return true
        case .system:
            return take(
                type: kIOPMAssertionTypeNoIdleSleep as CFString,
                reason: "Wired: keeping the system awake (display may sleep)" as CFString
            )
        case .display:
            return take(
                type: kIOPMAssertionTypeNoDisplaySleep as CFString,
                reason: "Wired: keeping the display on" as CFString
            )
        }
    }

    func release() {
        if hasAssertion {
            IOPMAssertionRelease(assertionID)
            hasAssertion = false
            assertionID = 0
        }
    }

    deinit {
        release()
    }

    // MARK: - Private

    private func take(type: CFString, reason: CFString) -> Bool {
        var id = IOPMAssertionID(0)
        let result = IOPMAssertionCreateWithName(
            type,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &id
        )
        guard result == kIOReturnSuccess else {
            NSLog("Wired: IOPMAssertionCreateWithName failed: \(result)")
            return false
        }
        assertionID = id
        hasAssertion = true
        return true
    }
}
