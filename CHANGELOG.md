# Changelog

## v0.3.0 (2026-11-24)

### Added

* `EQRCode.render/2` takes options. `compact: true` draws the QR code with
  Unicode half-block characters at about a quarter of the size, and
  `inverse: true` swaps the dark and light colors. `EQRCode.Render.render2/2`
  takes the same options. (#34)

### Fixed

* Removed the compile warnings Elixir 1.20 gives about variables used inside
  `size(...)` of a binary match. (#38)

### Changed

* The minimum supported Elixir version is now 1.13. Earlier releases already
  used functions that need 1.12 or later, so `~> 1.6` was never accurate.
