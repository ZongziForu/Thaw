// Local Thaw preview experiment. Licensed under the GNU GPLv3.
import AppKit

nonisolated enum ScrollMenuAnchorGeometry {
    struct Plan: Equatable {
        let centerX: CGFloat
        let length: CGFloat
        let maximumLength: CGFloat
    }

    static func plan(anchor: CGRect, itemWidth: CGFloat, requestedX: CGFloat,
                     minimumX: CGFloat) -> Plan? {
        guard !anchor.isNull, !anchor.isInfinite, anchor.width.isFinite, anchor.width > 0,
              anchor.minX.isFinite, anchor.maxX.isFinite,
              itemWidth.isFinite, itemWidth > 0, requestedX.isFinite, minimumX.isFinite else { return nil }
        let lower = minimumX + itemWidth / 2
        let upper = anchor.minX - itemWidth / 2
        guard lower <= upper else { return nil }
        let center = min(upper, max(lower, requestedX))
        return Plan(centerX: center, length: anchor.maxX - center - itemWidth / 2,
                    maximumLength: anchor.maxX - minimumX - itemWidth)
    }
}

/// A width assignment is asynchronous. Stable stale frames must not count as
/// acknowledgement of a new assignment, or successive corrections overshoot.
nonisolated struct ScrollMenuAnchorStability {
    private var previous: (anchor: CGRect, item: CGRect?)?
    private var matches = 0

    mutating func observe(anchor: CGRect, item: CGRect?, previousWidth: CGFloat, expectedWidthChange: CGFloat) -> Bool {
        // AppKit's outer window includes padding beyond NSStatusItem.length.
        // Acknowledge a change in the requested direction, not equality to length.
        let change = anchor.width - previousWidth
        guard anchor.width.isFinite, previousWidth.isFinite, expectedWidthChange.isFinite,
              abs(expectedWidthChange) < 0.5 ||
                (abs(change) >= 0.5 && change * expectedWidthChange > 0) else {
            previous = nil
            matches = 0
            return false
        }
        if let previous, previous.anchor == anchor, previous.item == item {
            matches += 1
        } else { matches = 1 }
        previous = (anchor, item)
        return matches >= 4
    }
}

/// Held until the real menu closes and its item is rehidden. Ownership prevents
/// stale cleanup from undoing a newer anchor operation.
@MainActor
final class ScrollMenuAnchorLease {
    private weak var control: ControlItem?
    private weak var panel: IceBarPanel?
    private var panelToken: UUID?

    func retainPanel(_ panel: IceBarPanel, token: UUID) {
        self.panel = panel
        panelToken = token
    }
    private let token: UUID
    private var isActive = true
    private var length: CGFloat
    private let minimumLength: CGFloat
    private var previousAnchorWidth: CGFloat
    private var expectedWidthChange: CGFloat
    private let plan: ScrollMenuAnchorGeometry.Plan

    init(control: ControlItem, token: UUID, minimumLength: CGFloat,
         plan: ScrollMenuAnchorGeometry.Plan) {
        self.control = control
        self.token = token
        self.minimumLength = minimumLength
        self.plan = plan
        self.length = plan.length
        previousAnchorWidth = minimumLength
        expectedWidthChange = plan.length - minimumLength
    }

    isolated deinit {
        control?.endScrollMenuAnchor(token: token)
        if let panelToken { panel?.endAnchoredMenu(token: panelToken) }
    }

    func release() {
        guard isActive else { return }
        isActive = false
        control?.endScrollMenuAnchor(token: token)
        if let panelToken { panel?.endAnchoredMenu(token: panelToken) }
    }

    /// Observe the same acknowledged geometry four times (80 ms apart) before
    /// moving or correcting again. Both the anchor and real item must settle.
    func waitForStableGeometry(itemWindowID: CGWindowID? = nil) async -> CGRect? {
        var stability = ScrollMenuAnchorStability()
        for _ in 0 ..< 15 {
            guard !Task.isCancelled, isActive, let window = control?.window,
                  let anchor = Bridging.getWindowBounds(for: CGWindowID(window.windowNumber)) else { return nil }
            let item = itemWindowID.flatMap { Bridging.getWindowBounds(for: $0) }
            if itemWindowID != nil, item == nil { return nil }
            if stability.observe(anchor: anchor, item: item, previousWidth: previousAnchorWidth,
                                 expectedWidthChange: expectedWidthChange) {
                return item ?? anchor
            }
            try? await Task.sleep(for: .milliseconds(80))
        }
        return nil
    }

    func settle(itemWindowID: CGWindowID) async -> Bool {
        for attempt in 0 ..< 4 {
            guard let bounds = await waitForStableGeometry(itemWindowID: itemWindowID) else { return false }
            let error = bounds.midX - plan.centerX
            if abs(error) <= 2 { return true }
            let revised = min(plan.maximumLength, max(minimumLength, length + error))
            MenuBarItemManager.diagLog.notice("Scroll menu calibration: attempt=\(attempt) item=\(bounds.debugDescription) requestedLength=\(length) error=\(error) nextLength=\(revised)")
            guard attempt < 3, abs(revised - length) >= 0.5 else { return false }
            guard let window = control?.window,
                  let anchor = Bridging.getWindowBounds(for: CGWindowID(window.windowNumber)) else { return false }
            previousAnchorWidth = anchor.width
            expectedWidthChange = revised - length
            length = revised
            control?.adjustScrollMenuAnchor(token: token, length: length)
        }
        return false
    }
}
