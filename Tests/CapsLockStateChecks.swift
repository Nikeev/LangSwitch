import IOKit.hid

private final class DisconnectedAppDelegate: AppDelegate {
    override func withHIDSystemConnection(_ body: (io_connect_t) -> Void) {
    }
}

private final class InvalidConnectionAppDelegate: AppDelegate {
    override func withHIDSystemConnection(_ body: (io_connect_t) -> Void) {
        body(0)
    }
}

@main
private enum CapsLockStateChecks {
    static func main() {
        let disconnectedDelegate = DisconnectedAppDelegate()
        assert(
            disconnectedDelegate.getCapsLockState() == nil,
            "An unavailable HID connection must not be reported as Caps Lock being off."
        )

        let invalidConnectionDelegate = InvalidConnectionAppDelegate()
        assert(
            invalidConnectionDelegate.getCapsLockState() == nil,
            "A failed HID read must not be reported as Caps Lock being off."
        )

        print("Caps Lock failure checks passed.")
    }
}
