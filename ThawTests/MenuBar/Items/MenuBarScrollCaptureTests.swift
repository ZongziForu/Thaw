import CoreGraphics
import Testing
@testable import Thaw

@Suite("Scroll preview capture continuity")
struct MenuBarScrollCaptureTests {
    private func image(alpha: CGFloat) throws -> CGImage {
        let context = try #require(CGContext(data: nil, width: 8, height: 8,
            bitsPerComponent: 8, bytesPerRow: 32, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.setFillColor(red: 1, green: 1, blue: 1, alpha: alpha)
        context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        return try #require(context.makeImage())
    }

    @Test("A cleared backing surface cannot erase a previously visible icon")
    func retainVisibleIcon() throws {
        #expect(!MenuBarItemImageCache.shouldReplaceCapture(previous: try image(alpha: 1),
            incoming: try image(alpha: 0)))
    }

    @Test("Intentional empty spacer captures remain accepted")
    func allowSpacers() throws {
        #expect(MenuBarItemImageCache.shouldReplaceCapture(previous: nil, incoming: try image(alpha: 0)))
        #expect(MenuBarItemImageCache.shouldReplaceCapture(previous: try image(alpha: 0),
            incoming: try image(alpha: 0)))
    }

    @Test("A later visible capture replaces a placeholder or previous image")
    func acceptVisibleRefresh() throws {
        #expect(MenuBarItemImageCache.shouldReplaceCapture(previous: try image(alpha: 0),
            incoming: try image(alpha: 1)))
        #expect(MenuBarItemImageCache.shouldReplaceCapture(previous: try image(alpha: 1),
            incoming: try image(alpha: 0.5)))
    }
}
