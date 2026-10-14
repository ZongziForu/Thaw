// Copyright (Thaw) © 2026 Toni Förster
// Licensed under the GNU GPLv3
import AppKit
import SwiftUI

nonisolated enum MenuBarScrollGeometry {
    static func viewport(screen: CGRect, menuHeight: CGFloat,
                         leftBoundary: CGFloat, pinnedBoundary: CGFloat) -> CGRect? {
        let left = max(screen.minX, leftBoundary)
        let right = min(screen.maxX, pinnedBoundary - 4)
        guard right - left >= 44, menuHeight > 0 else { return nil }
        let width = min(480, right - left)
        return CGRect(x: right - width, y: screen.maxY - menuHeight, width: width, height: menuHeight)
    }
}

/// AppKit supplies native precision scrolling and momentum; vertical wheels are
/// translated horizontally without registering a global input monitor.
struct SmoothMenuBarScrollView<Content: View>: NSViewRepresentable {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    func makeNSView(context: Context) -> MenuBarScrollView<Content> {
        MenuBarScrollView(content: content)
    }
    func updateNSView(_ view: MenuBarScrollView<Content>, context: Context) {
        view.host.rootView = content
        view.needsLayout = true
    }
}

final class MenuBarScrollView<Content: View>: NSScrollView {
    private final class HostingView: NSHostingView<Content> {
        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    }
    let host: NSHostingView<Content>
    private var initializedPosition = false
    private var lastViewportSize = NSSize.zero
    private var lastDocumentSize = NSSize.zero
    init(content: Content) {
        host = HostingView(rootView: content)
        super.init(frame: .zero)
        drawsBackground = false
        hasHorizontalScroller = false
        hasVerticalScroller = false
        horizontalScrollElasticity = .allowed
        verticalScrollElasticity = .none
        usesPredominantAxisScrolling = false
        documentView = host
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layout() {
        super.layout()
        let width = max(host.fittingSize.width, contentSize.width)
        let documentSize = NSSize(width: width, height: contentSize.height)
        // Hover and image refresh update SwiftUI without changing geometry.
        // Re-scrolling the clip view on those updates interrupts momentum.
        guard lastViewportSize != contentSize || lastDocumentSize != documentSize else { return }
        lastViewportSize = contentSize
        lastDocumentSize = documentSize
        let oldOffset = contentView.bounds.minX
        host.setFrameSize(documentSize)
        let maximum = max(0, width - contentSize.width)
        if !initializedPosition && maximum > 0 {
            contentView.scroll(to: NSPoint(x: maximum, y: 0))
            initializedPosition = true
        } else {
            contentView.scroll(to: NSPoint(x: min(maximum, max(0, oldOffset)), y: 0))
        }
        reflectScrolledClipView(contentView)
    }

    override func scrollWheel(with event: NSEvent) {
        if abs(event.scrollingDeltaX) >= abs(event.scrollingDeltaY) {
            super.scrollWheel(with: event)
            return
        }
        let delta = event.scrollingDeltaY * (event.hasPreciseScrollingDeltas ? 1 : 12)
        let maximum = max(0, host.frame.width - contentSize.width)
        let target = NSPoint(x: min(maximum, max(0, contentView.bounds.minX - delta)), y: 0)
        if event.hasPreciseScrollingDeltas {
            contentView.scroll(to: target)
        } else {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.16
                contentView.animator().setBoundsOrigin(target)
            }
        }
        reflectScrolledClipView(contentView)
    }
}
