#if os(macOS)
extension KeyboardShortcutsLegacy {
	/**
	The strongly-typed name of the keyboard shortcut.

	After registering it, you can use it in, for example, `KeyboardShortcut.Recorder` and `KeyboardShortcut.onKeyUp()`.

	```swift
	import KeyboardShortcutsLegacy

	extension KeyboardShortcutsLegacy.Name {
		static let toggleUnicornMode = Self("toggleUnicornMode")
	}
	```
	*/
	public struct Name: Hashable, Sendable {
		// This makes it possible to use `Shortcut` without the namespace.
		/// :nodoc:
		public typealias Shortcut = KeyboardShortcutsLegacy.Shortcut

		public let rawValue: String
		public let defaultShortcut: Shortcut?

		/**
		The keyboard shortcut assigned to the name.
		*/
		public var shortcut: Shortcut? {
			get { KeyboardShortcutsLegacy.getShortcut(for: self) }
			nonmutating set {
				KeyboardShortcutsLegacy.setShortcut(newValue, for: self)
			}
		}

		/**
		- Parameter name: Name of the shortcut.
		- Parameter default: Optional default key combination. Do not set this unless it's essential. Users find it annoying when random apps steal their existing keyboard shortcuts. It's generally better to show a welcome screen on the first app launch that lets the user set the shortcut.
		*/
		public init(_ name: String, default initialShortcut: Shortcut? = nil) {
			self.rawValue = name
			self.defaultShortcut = initialShortcut

			if
				let initialShortcut,
				!userDefaultsContains(name: self)
			{
				setShortcut(initialShortcut, for: self)
			}

			KeyboardShortcutsLegacy.initialize()
		}
	}
}

extension KeyboardShortcutsLegacy.Name: RawRepresentable {
	/// :nodoc:
	public init?(rawValue: String) {
		self.init(rawValue)
	}
}
#endif
