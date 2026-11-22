import CoreGraphics
import Testing

@testable import computer_use_mcp

@Suite struct GlobalCursorInputTests {
    private let targetPID = pid_t(42)
    private let targetWindowID = CGWindowID(7)
    private let point = CGPoint(x: 20, y: 30)
    private let bounds = CGRect(x: 0, y: 0, width: 100, height: 100)

    @Test func acceptsTargetWindowAtPointerAndIgnoresItsClickThroughOverlay() {
        let windows = [
            GlobalClickWindow(
                pid: 99, windowID: 99, layer: 0, alpha: 1,
                bounds: CGRect(x: 0, y: 0, width: 100, height: 100),
                ownerName: nil, isComputerUseOverlay: true, isDockBackdrop: false),
            GlobalClickWindow(
                pid: targetPID, windowID: targetWindowID, layer: 0, alpha: 1,
                bounds: bounds, ownerName: nil, isComputerUseOverlay: false, isDockBackdrop: false),
        ]

        #expect(globalClickTargetIsUnoccluded(
            point: point, targetPID: targetPID, targetWindowID: targetWindowID,
            windows: windows))
    }

    @Test func rejectsUnrelatedOrDifferentTargetWindowAbovePointer() {
        let target = GlobalClickWindow(
            pid: targetPID, windowID: targetWindowID, layer: 0, alpha: 1,
            bounds: bounds, ownerName: nil, isComputerUseOverlay: false, isDockBackdrop: false)
        let unrelated = GlobalClickWindow(
            pid: 99, windowID: 99, layer: 25, alpha: 1,
            bounds: bounds, ownerName: nil, isComputerUseOverlay: false, isDockBackdrop: false)
        let siblingWindow = GlobalClickWindow(
            pid: targetPID, windowID: 8, layer: 0, alpha: 1,
            bounds: bounds, ownerName: nil, isComputerUseOverlay: false, isDockBackdrop: false)

        #expect(!globalClickTargetIsUnoccluded(
            point: point, targetPID: targetPID, targetWindowID: targetWindowID,
            windows: [unrelated, target]))
        #expect(!globalClickTargetIsUnoccluded(
            point: point, targetPID: targetPID, targetWindowID: targetWindowID,
            windows: [siblingWindow, target]))
        #expect(!globalClickTargetIsUnoccluded(
            point: point, targetPID: targetPID, targetWindowID: nil,
            windows: [target]))
    }

    @Test func ignoresSystemDockBackdropButNotItsOtherWindows() {
        let target = GlobalClickWindow(
            pid: targetPID, windowID: targetWindowID, layer: 0, alpha: 1,
            bounds: bounds, ownerName: nil, isComputerUseOverlay: false, isDockBackdrop: false)
        let dockBackdrop = GlobalClickWindow(
            pid: 99, windowID: 99, layer: 20, alpha: 1,
            bounds: bounds, ownerName: "Dock", isComputerUseOverlay: false, isDockBackdrop: true)
        let dockPanel = GlobalClickWindow(
            pid: 99, windowID: 100, layer: 20, alpha: 1,
            bounds: bounds, ownerName: "Dock", isComputerUseOverlay: false, isDockBackdrop: false)

        #expect(globalClickTargetIsUnoccluded(
            point: point, targetPID: targetPID, targetWindowID: targetWindowID,
            windows: [dockBackdrop, target]))
        #expect(!globalClickTargetIsUnoccluded(
            point: point, targetPID: targetPID, targetWindowID: targetWindowID,
            windows: [dockPanel, target]))
    }
}
