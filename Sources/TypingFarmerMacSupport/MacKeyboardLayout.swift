import TypingFarmerCore

public enum MacKeyboardLayout {
    public static let rows = KeyboardLayout.rows
    public static let allKeys = KeyboardLayout.allKeys
    public static let keysByCode = KeyboardLayout.keysByCode

    public static func key(forKeyCode keyCode: Int) -> KeyboardKeyDefinition? {
        KeyboardLayout.key(forKeyCode: keyCode)
    }

    public static func label(forKeyCode keyCode: Int) -> String? {
        KeyboardLayout.label(forKeyCode: keyCode)
    }

    public static func defaultKeyPlots(cropID: String = "wheat") -> [KeyPlotState] {
        KeyboardLayout.defaultKeyPlots(cropID: cropID)
    }
}
