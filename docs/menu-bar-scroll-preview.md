# Menu Bar Scroll preview

This local prototype is based on Thaw 2.0.1 (`d5eab80b`). Select
**Displays → Use Thaw Bar → Arrangement → Menu Bar Scroll** on each display.
Hidden items appear in a horizontal viewport at menu-bar height. Items in
Thaw's visible section remain native and occupy their original positions.
The viewport uses the available space between application menus (or the notch)
and visible status items, up to 480 points. If there is less than 44 points of
free space, the current prototype falls back to a separate bar.

Trackpad horizontal gestures use AppKit precision scrolling and momentum.
Vertical wheel input is mapped to horizontal movement; ordinary wheels animate
over 160 ms. The viewport opens at the trailing end and preserves its offset
as icon content refreshes. Thaw's global scroll-to-hide handler ignores wheel
events inside the open viewport.
Mouse-down events inside it also bypass the global empty-menu-bar toggle so
the panel stays alive until the item's mouse-up handler forwards the click.
The nested hosting view accepts the first mouse event on the nonactivating panel.
While open, the viewport checks live native item bounds every 250 ms and adjusts
its origin and width only when those bounds change. This timer stops on close.
Hover and unchanged image refresh no longer reset the scrolling offset or
interrupt momentum. Tooltips in this mode use at most a 120 ms delay and track
only the visible portion of each clipped item.
The scroll viewport does not draw hover highlights, avoiding retained hover
state after clipping or scrolling. WeChat uses artwork from its locally installed
application instead of its unreliable offscreen capture. This entry remains
clickable but does not display the native unread badge.

## Scope and limitations

Icon previews still use Thaw's existing capture implementation. Left clicks in
the scroll viewport use direct Accessibility activation only for WeChat, which
was verified on the target Mac. Other items use Thaw's existing temporary reveal
and click forwarding; that path
can still reposition the pointer briefly. Synthetic clicks hide the pointer
before warping and install restoration before the asynchronous settle delay.
Screen Recording and Accessibility permissions are therefore required for the
complete experience. This is not yet a capture-free implementation. App menus
may open at the original native item's position; menu anchoring is a later phase.
Real gesture feel, click behavior, multi-display switching and CPU/memory use
must be validated on the target Mac before treating this as a daily-use release.

## Isolated application

The preview uses bundle ID `com.yqc.ThawScrollPreview`, a separate XPC service,
preferences domain and `Application Support/ThawScrollPreview/Profiles` folder.
The staged app is `~/Applications/ThawScrollPreview.app`. It is locally ad-hoc
signed. Original Thaw is retained at `/Applications/Thaw.app`; do not run both
menu-bar managers at once. Automatic updates and launch at login are disabled
for the preview.

Local originals are backed up under `.local-install/backups`. To return to the
original experience, quit the preview and launch `/Applications/Thaw.app`.

## Validation status

- Debug build succeeds.
- 35 focused Swift Testing cases across four suites pass: viewport boundaries,
  layout compatibility, AX candidate selection, click reaction verification,
  and preservation of visible captures across transparent refreshes.
- The final arm64 Release build and deep strict signature verification succeed.
- Both macOS permissions granted through System Settings on the test Mac.
- The user confirmed that icons appear in the menu-bar row and horizontal
  scrolling works on the built-in display.
- Initial click validation failed; the mouse-down routing correction restored
  clicks according to the user's retest. Menus still open at native positions.
- The user reported pointer jumps after clicking. Logs showed a WeChat temporary
  move and activation taking 1.648 seconds. Direct AX activation is being tested
  to avoid that move where supported. Logs confirmed two direct WeChat
  activations at approximately 160–170 ms without a move.
- Further user feedback identified tooltip lag, geometry changes interrupting
  scrolling, and transparent WeChat captures replacing its icon. The continuity
  corrections and their regression tests are under validation. Resource
  measurements remain pending.
- The transparent-capture guard did not restore WeChat in the user's retest.
  A local application-icon rendering path now bypasses that capture entirely.
  Retained hover highlights are removed for the scroll layout. These UI changes
  require another physical retest after the new build is installed.
- The user subsequently reported that ThermalForge and other menus did not open.
  The generic offscreen AX path accepted actions without proving the menu was
  visible. Direct activation is now limited to the verified WeChat owner; other
  owners return to the temporary reveal path. The user then confirmed that both
  ThermalForge and WeChat open normally. Logs show ThermalForge taking 697 ms
  through the temporary reveal path and WeChat taking 122 ms via direct AX.

The source remains GPLv3, following Thaw's license.
