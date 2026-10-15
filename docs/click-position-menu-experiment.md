# Click-position menu experiment

Recovery baseline: Git tag `scroll-preview-v0.1.0` at `db0fa157`, published with
an arm64 application archive and checksums in the personal GitHub fork:
https://github.com/ZongziForu/Thaw/releases/tag/scroll-preview-v0.1.0

Work proceeds on `experiment/click-position-menu`. The stable source branch
`customization/smooth-menu-scroll` remains at the baseline.

## First prototype

Displays → Menu Bar Scroll adds the disabled-by-default **Menus near click
position (experimental)** option. It currently affects only ThermalForge left
clicks. WeChat and other applications retain their verified baseline behavior.

The prototype records the pointer's horizontal position before closing the
scroll viewport. It temporarily expands the existing visible control item's
width, keeping its right edge and the native items to its right fixed. The
ThermalForge item is revealed immediately to its left. Live geometry is then
measured and corrected up to three times before the menu is activated.

During this operation the Thaw entry's artwork is temporarily hidden, leaving
an invisible positioning region. The width and artwork are restored after the
original item is rehidden. The existing rehide timer may take several seconds
after the menu closes. Ownership tokens and scoped cleanup prevent an obsolete
operation from undoing a later one. Lack of usable space or failed alignment
falls back to the baseline position.

No third-party menu content is copied, and no foreign menu window is dragged.
The real application draws its own menu from the relocated native item.

## Validation

40 tests across five suites passed, including geometry boundaries, negative
display coordinates, screenshot continuity, AX selection, and click reactions.
Physical menu placement, cleanup after dismissal, and preservation of visible
native item positions still require real-device testing. The checkbox is a
single preview-wide preference even though it appears in display controls.

To stop the experiment, turn its checkbox off. For exact baseline recovery,
quit the preview and restore the application archive from the baseline release.

## Device feedback: first prototype failed (2026-10-14)

The user observed the scroll strip and its blur disappear, a native fan icon
jump between positions, and the other preview icons vanish. Logs show that the
first attempt fell back after alignment failure; on the second attempt only the
native icon's center aligned (about 0.25 pt error). AX activation failed frame
verification and synthetic event acknowledgement did not prove a menu opened.
The first prototype is not a working click-position menu implementation.

## Second prototype (2026-10-15, awaiting device validation)

Keep the existing panel and hosting view while relocating ThermalForge. Freeze
its item list, cached artwork, and viewport until rehide completes; leave the
material background in place. The panel passes mouse events through during the
native interaction. An ownership token restores live geometry and input when
the native anchor lease ends; closing the panel also clears the visual freeze.
WeChat continues to use its app artwork, including while the strip is frozen.

Wait for the anchor's measured width and origin to stabilize before dragging.
Resolve AX delivery through the target application's extras menu bar rather
than hit-testing the preview, while retaining the existing frame check.
Log the tracked interface window separately: successful event delivery alone
still does not establish that the menu appeared or appeared at the desired
position. Other applications keep the baseline path. The experimental switch
was turned off after the failed first prototype.

Validation for the second prototype: all 40 focused tests across the same five
suites passed on 2026-10-15. These tests do not simulate a foreign application's
native menu or establish visual success. Device acceptance remains pending.

## Second prototype device outcome and third iteration (2026-10-15)

Three device attempts: the first two failed alignment and visibly fell back to
the baseline position; the third succeeded according to the user. Its measured
icon center was 745.5 pt versus a requested 746.277 pt (about 0.78 pt difference),
and the application interface was tracked. This establishes an occasionally
working path, not reliable behavior. The switch was turned off and the preview
restarted after the test, retaining the normal scrolling/clicking behavior.

The third iteration replaces 50 ms incremental correction with a bounded wait
for four unchanged samples 80 ms apart. Resize acknowledgement checks movement
in the requested direction against the prior measured width: AppKit's outer
window includes padding, so equality with NSStatusItem.length is inappropriate.
The real item's bounds must also remain unchanged before each correction.
Failed initial acknowledgement cancels before moving; failed final alignment
rehides the item without opening a menu in the wrong place. This avoids treating
an acknowledged event or an automatic baseline fallback as positioning success.
Device validation of this iteration is still required.

All 44 focused tests across six suites passed for the geometry, capture, AX,
click reaction, and asynchronous acknowledgement helpers. Failed calibration
also preserves the scroll panel after cleanup. These checks do not replace a
fresh first-click device test. Release validation and installation follow.
