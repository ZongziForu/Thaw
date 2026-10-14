import CoreGraphics
import Foundation
import Testing
@testable import Thaw

@Suite("Menu bar scroll viewport")
struct MenuBarScrollGeometryTests {
    @Test("Viewport sits inside the actual top bar and leaves pinned icons untouched")
    func pinnedRegion() {
        let frame = MenuBarScrollGeometry.viewport(screen: CGRect(x: 0,y: 0,width: 1440,height: 900),
            menuHeight: 24, leftBoundary: 300, pinnedBoundary: 1100)
        #expect(frame == CGRect(x: 616,y: 876,width: 480,height: 24))
        #expect((frame?.maxX ?? 0) < 1100)
    }
    @Test("Narrow free space is respected instead of covering the application menu")
    func narrowSpace() {
        let frame = MenuBarScrollGeometry.viewport(screen: CGRect(x: 0,y: 0,width: 1440,height: 900),
            menuHeight: 24, leftBoundary: 600, pinnedBoundary: 740)
        #expect(frame == CGRect(x: 600,y: 876,width: 136,height: 24))
    }
    @Test("Secondary displays can have negative coordinates")
    func secondaryDisplay() {
        let frame = MenuBarScrollGeometry.viewport(screen: CGRect(x: -1920,y: 100,width: 1920,height: 1080),
            menuHeight: 28, leftBoundary: -1500, pinnedBoundary: -500)
        #expect(frame == CGRect(x: -984,y: 1152,width: 480,height: 28))
    }
    @Test("No usable free space falls back instead of drawing over pinned controls")
    func noSpace() {
        #expect(MenuBarScrollGeometry.viewport(screen: CGRect(x: 0,y: 0,width: 1440,height: 900),
            menuHeight: 24, leftBoundary: 1000, pinnedBoundary: 1040) == nil)
        #expect(MenuBarScrollGeometry.viewport(screen: CGRect(x: 0,y: 0,width: 1440,height: 900),
            menuHeight: 0, leftBoundary: 300, pinnedBoundary: 1100) == nil)
    }
    @Test("The new layout preserves existing raw values and round-trips in configuration")
    func configuration() throws {
        #expect(IceBarLayout.horizontal.rawValue == 0)
        #expect(IceBarLayout.vertical.rawValue == 1)
        #expect(IceBarLayout.grid.rawValue == 2)
        #expect(IceBarLayout.fromString("menuBarScroll") == .menuBarScroll)
        #expect(IceBarLayout.fromString("3") == .menuBarScroll)
        #expect(try JSONDecoder().decode(IceBarLayout.self,
            from: JSONEncoder().encode(IceBarLayout.menuBarScroll)) == .menuBarScroll)
    }
}
