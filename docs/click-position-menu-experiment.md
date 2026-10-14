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
