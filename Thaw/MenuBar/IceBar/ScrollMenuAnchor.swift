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

/// Held until the real menu closes and its item is rehidden. Ownership prevents
/// stale cleanup from undoing a newer anchor operation.
@MainActor
final class ScrollMenuAnchorLease {
    private weak var control: ControlItem?
    private let token: UUID
    private var isActive = true
    private var length: CGFloat
    private let minimumLength: CGFloat
    private let plan: ScrollMenuAnchorGeometry.Plan

    init(control: ControlItem, token: UUID, minimumLength: CGFloat,
         plan: ScrollMenuAnchorGeometry.Plan) {
        self.control = control
        self.token = token
        self.minimumLength = minimumLength
        self.plan = plan
        self.length = plan.length
    }

    isolated deinit { control?.endScrollMenuAnchor(token: token) }

    func release() {
        guard isActive else { return }
        isActive = false
        control?.endScrollMenuAnchor(token: token)
    }

    /// AppKit adds spacing around status items. Correct the measured result,
    /// rather than assuming a length assignment gives an exact pixel position.
    func settle(itemWindowID: CGWindowID) async -> Bool {
        for _ in 0 ..< 3 {
            guard !Task.isCancelled, isActive else { return false }
            try? await Task.sleep(for: .milliseconds(50))
            guard !Task.isCancelled, isActive else { return false }
            guard let bounds = Bridging.getWindowBounds(for: itemWindowID) else { return false }
            let error = bounds.midX - plan.centerX
            if abs(error) <= 2 { return true }
            let revised = min(plan.maximumLength, max(minimumLength, length + error))
            if abs(revised - length) < 0.5 { return false }
            length = revised
            control?.adjustScrollMenuAnchor(token: token, length: length)
        }
        try? await Task.sleep(for: .milliseconds(50))
        guard !Task.isCancelled, isActive,
              let bounds = Bridging.getWindowBounds(for: itemWindowID) else { return false }
        return abs(bounds.midX - plan.centerX) <= 4
    }
}
