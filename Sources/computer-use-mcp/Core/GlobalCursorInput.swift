import AppKit
import CoreGraphics
import Foundation

struct GlobalClickWindow: Equatable {
    let pid: pid_t
    let windowID: CGWindowID
    let layer: Int
    let alpha: Double
    let bounds: CGRect
    let ownerName: String?
    let isComputerUseOverlay: Bool
    let isDockBackdrop: Bool
}

func globalClickTargetIsUnoccluded(
    point: CGPoint, targetPID: pid_t, targetWindowID: CGWindowID?,
    windows: [GlobalClickWindow]
) -> Bool {
    guard let targetWindowID,
        let frontWindow = windows.first(where: {
            $0.alpha > 0 && !$0.isComputerUseOverlay && !$0.isDockBackdrop
                && $0.bounds.contains(point)
        })
    else { return false }
    return frontWindow.pid == targetPID && frontWindow.windowID == targetWindowID
}

func requireGlobalClickTarget(
    point: CGPoint, targetPID: pid_t, targetWindowID: CGWindowID?
) throws {
    let currentExecutable = Bundle.main.executableURL?.resolvingSymlinksInPath().path
    let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
    let clickWindows = windows.compactMap { window -> GlobalClickWindow? in
        guard let pid = window[kCGWindowOwnerPID as String] as? pid_t,
            let windowID = window[kCGWindowNumber as String] as? CGWindowID,
            let layer = window[kCGWindowLayer as String] as? Int,
            let rawBounds = window[kCGWindowBounds as String] as? NSDictionary,
            let bounds = CGRect(dictionaryRepresentation: rawBounds)
        else { return nil }
        let alpha = window[kCGWindowAlpha as String] as? Double ?? 1
        let ownerApplication = NSRunningApplication(processIdentifier: pid)
        let ownerExecutable = ownerApplication?
            .executableURL?.resolvingSymlinksInPath().path
        let ownerName = window[kCGWindowOwnerName as String] as? String
        let isComputerUseOverlay = pid != getpid()
            && ownerExecutable != nil && ownerExecutable == currentExecutable
            && ownerName == "Computer Use MCP"
            && ownerApplication?.bundleIdentifier == "dev.computer-use-mcp.app"
        let displayBounds = CGDisplayBounds(CGMainDisplayID())
        let isDockBackdrop = ownerName == "Dock"
            && ownerApplication?.bundleIdentifier == "com.apple.dock"
            && ownerExecutable == "/System/Library/CoreServices/Dock.app/Contents/MacOS/Dock"
            && layer == 20
            && bounds.origin == displayBounds.origin && bounds.size == displayBounds.size
        return GlobalClickWindow(
            pid: pid, windowID: windowID, layer: layer, alpha: alpha, bounds: bounds,
            ownerName: ownerName, isComputerUseOverlay: isComputerUseOverlay,
            isDockBackdrop: isDockBackdrop)
    }
    guard globalClickTargetIsUnoccluded(
        point: point, targetPID: targetPID, targetWindowID: targetWindowID,
        windows: clickWindows)
    else {
        throw ToolError.failed(
            "Global click blocked because the target window is not the topmost visible window at that point. "
                + "Bring the target window forward or choose a point that is not covered, then retry."
        )
    }
}

/// Tier 4: guarded global cursor. Moves the real cursor and posts input through
/// the HID event tap so foreground apps receive normal mouse events. Only
/// reached on explicit opt-in; the cursor remains at the target.
func deliverClickGlobal(
    at point: CGPoint, button: MouseButtonKind, clickCount: Int
) throws -> InputTier {
    guard CGWarpMouseCursorPosition(point) == .success else {
        throw ToolError.failed("Could not move the system cursor to the click target.")
    }
    let source = CGEventSource(stateID: .combinedSessionState)
    guard let moved = CGEvent(
        mouseEventSource: source, mouseType: .mouseMoved,
        mouseCursorPosition: point, mouseButton: .left
    ) else {
        throw ToolError.failed("Could not create a mouse-move event.")
    }
    moved.post(tap: .cghidEventTap)
    for clickState in 1...clickCount {
        guard let down = CGEvent(
            mouseEventSource: source, mouseType: button.downType,
            mouseCursorPosition: point, mouseButton: button.cgButton
        ), let up = CGEvent(
            mouseEventSource: source, mouseType: button.upType,
            mouseCursorPosition: point, mouseButton: button.cgButton
        ) else {
            throw ToolError.failed("Could not create a click event.")
        }
        down.setIntegerValueField(.mouseEventClickState, value: Int64(clickState))
        down.post(tap: .cghidEventTap)
        up.setIntegerValueField(.mouseEventClickState, value: Int64(clickState))
        up.post(tap: .cghidEventTap)
    }
    return .globalCursor
}
