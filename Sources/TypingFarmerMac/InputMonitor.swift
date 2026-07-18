import ApplicationServices
import Foundation
import TypingFarmerCore
import TypingFarmerMacSupport

final class InputMonitor {
    enum PermissionStatus: Equatable {
        case authorized
        case notAuthorized

        var title: String {
            switch self {
            case .authorized:
                return "已授权"
            case .notAuthorized:
                return "未授权"
            }
        }
    }

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let onEvent: (InputEvent) -> Void

    init(onEvent: @escaping (InputEvent) -> Void) {
        self.onEvent = onEvent
    }

    deinit {
        stop()
    }

    func refreshPermissionStatus() -> PermissionStatus {
        AXIsProcessTrusted() ? .authorized : .notAuthorized
    }

    static func requestAccessibilityPermissionPrompt() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }

    @discardableResult
    func start() -> Bool {
        guard refreshPermissionStatus() == .authorized else {
            return false
        }
        if eventTap != nil {
            return true
        }

        // Use a listen-only session event tap so farming reacts to input without
        // delaying, changing, or consuming the user's real keyboard/mouse events.
        let eventMask =
            (1 << UInt64(CGEventType.keyDown.rawValue)) |
            (1 << UInt64(CGEventType.leftMouseDown.rawValue)) |
            (1 << UInt64(CGEventType.rightMouseDown.rawValue)) |
            (1 << UInt64(CGEventType.otherMouseDown.rawValue))

        let callback: CGEventTapCallBack = { _, type, event, userInfo in
            guard let userInfo else {
                return Unmanaged.passUnretained(event)
            }

            let monitor = Unmanaged<InputMonitor>.fromOpaque(userInfo).takeUnretainedValue()
            let kind: InputEventKind?
            let keyCode: Int?
            switch type {
            case .keyDown:
                kind = .keyboard
                keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
            case .leftMouseDown, .rightMouseDown, .otherMouseDown:
                kind = .mouse
                keyCode = nil
            default:
                kind = nil
                keyCode = nil
            }

            if let kind {
                monitor.onEvent(
                    InputEvent(
                        kind: kind,
                        timestamp: Date(),
                        count: 1,
                        keyCode: keyCode,
                        keyLabel: keyCode.flatMap { MacKeyboardLayout.label(forKeyCode: $0) }
                    )
                )
            }
            return Unmanaged.passUnretained(event)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(eventMask),
            callback: callback,
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            return false
        }

        eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }
}
