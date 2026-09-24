#if os(macOS)
import SwiftUI

@available(macOS 12, *)
extension View {
	/**
	Register a listener for keyboard shortcut events with the given name.

	You can safely call this even if the user has not yet set a keyboard shortcut. It will just be inactive until they do.

	The listener will stop automatically when the view disappears.

	- Note: This method is not affected by `.removeAllHandlers()`.
	*/
	@MainActor
	public func onKeyboardShortcut(
		_ shortcut: KeyboardShortcutsLegacy.Name,
		perform: @escaping (KeyboardShortcutsLegacy.EventType) -> Void
	) -> some View {
		task {
			for await eventType in KeyboardShortcutsLegacy.events(for: shortcut) {
				perform(eventType)
			}
		}
	}

	/**
	Register a listener for keyboard shortcut events with the given name and type.

	You can safely call this even if the user has not yet set a keyboard shortcut. It will just be inactive until they do.

	The listener will stop automatically when the view disappears.

	- Note: This method is not affected by `.removeAllHandlers()`.
	*/
	@MainActor
	public func onKeyboardShortcut(
		_ shortcut: KeyboardShortcutsLegacy.Name,
		type: KeyboardShortcutsLegacy.EventType,
		perform: @escaping () -> Void
	) -> some View {
		task {
			for await _ in KeyboardShortcutsLegacy.events(type, for: shortcut) {
				perform()
			}
		}
	}
}
#endif
