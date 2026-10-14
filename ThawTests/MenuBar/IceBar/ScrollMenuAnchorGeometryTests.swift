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
