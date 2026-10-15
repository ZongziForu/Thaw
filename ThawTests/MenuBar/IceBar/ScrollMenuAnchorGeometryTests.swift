import CoreGraphics
import Testing
@testable import Thaw

@Suite("Click-position menu anchor")
struct ScrollMenuAnchorGeometryTests {
    let anchor = CGRect(x: 1100, y: 0, width: 28, height: 30)

    @Test("Expanding the anchor leaves native icons to its right stationary")
    func rightEdgeStaysFixed() throws {
        let plan = try #require(ScrollMenuAnchorGeometry.plan(anchor: anchor, itemWidth: 44,
            requestedX: 800, minimumX: 400))
        #expect(plan.centerX == 800)
        #expect(plan.length == 306)
        #expect(anchor.maxX - plan.length - 44 / 2 == 800)
    }

    @Test("An out-of-range click cannot push the item into application menus")
    func leftEdgeClamped() throws {
        let plan = try #require(ScrollMenuAnchorGeometry.plan(anchor: anchor, itemWidth: 44,
            requestedX: 100, minimumX: 400))
        #expect(plan.centerX == 422)
        #expect(plan.length == plan.maximumLength)
    }

    @Test("A click to the right cannot shrink the original status item")
    func rightEdgeClamped() throws {
        let plan = try #require(ScrollMenuAnchorGeometry.plan(anchor: anchor, itemWidth: 44,
            requestedX: 1400, minimumX: 400))
        #expect(plan.centerX == 1078)
        #expect(plan.length == 28)
    }

    @Test("Negative coordinates on secondary displays remain valid")
    func secondaryDisplay() throws {
        let plan = try #require(ScrollMenuAnchorGeometry.plan(anchor: CGRect(x: -500, y: 0, width: 28, height: 30),
            itemWidth: 28, requestedX: -900, minimumX: -1500))
        #expect(plan.centerX == -900)
        #expect(plan.length == 414)
    }

    @Test("No room and invalid measurements fall back without changing the anchor")
    func unavailable() {
        #expect(ScrollMenuAnchorGeometry.plan(anchor: anchor, itemWidth: 44, requestedX: 800, minimumX: 1090) == nil)
        #expect(ScrollMenuAnchorGeometry.plan(anchor: anchor, itemWidth: 0, requestedX: 800, minimumX: 400) == nil)
        #expect(ScrollMenuAnchorGeometry.plan(anchor: anchor, itemWidth: 44, requestedX: .nan, minimumX: 400) == nil)
    }
}

@Suite("Click-position asynchronous layout acknowledgement")
struct ScrollMenuAnchorStabilityTests {
    let anchor = CGRect(x: 750, y: 0, width: 300, height: 30)
    let item = CGRect(x: 688, y: 0, width: 62, height: 30)

    @Test("Repeated stale widths do not acknowledge a resize")
    func staleWidth() {
        var stability = ScrollMenuAnchorStability()
        for _ in 0 ..< 20 {
            let ready1 = stability.observe(anchor: anchor, item: item, previousWidth: 300, expectedWidthChange: 40); #expect(!ready1)
        }
    }

    @Test("Both windows must remain unchanged for four observations")
    func itemStillMoving() {
        var stability = ScrollMenuAnchorStability()
        for offset in 0 ..< 10 {
            let ready2 = stability.observe(anchor: anchor, item: item.offsetBy(dx: CGFloat(offset), dy: 0), previousWidth: 270, expectedWidthChange: 30); #expect(!ready2)
        }
    }

    @Test("A settled acknowledged layout becomes eligible")
    func acknowledged() {
        var stability = ScrollMenuAnchorStability()
        for _ in 0 ..< 3 { let ready3 = stability.observe(anchor: anchor, item: item, previousWidth: 270, expectedWidthChange: 30); #expect(!ready3) }
        let ready4 = stability.observe(anchor: anchor, item: item, previousWidth: 270, expectedWidthChange: 30); #expect(ready4)
    }

    @Test("Changing the requested width invalidates earlier stability")
    func newAssignment() {
        var stability = ScrollMenuAnchorStability()
        for _ in 0 ..< 4 { _ = stability.observe(anchor: anchor, item: item, previousWidth: 270, expectedWidthChange: 30) }
        let ready5 = stability.observe(anchor: anchor, item: item, previousWidth: 300, expectedWidthChange: 30); #expect(!ready5)
        let ready6 = stability.observe(anchor: anchor, item: item, previousWidth: 270, expectedWidthChange: 30); #expect(!ready6)
    }
}
