# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0-beta.1] - 2026-08-21

First public beta of Arc.

### Added
- Custom bottom navigation bar with three modes: standard, compact, and hidden.
- Horizontal swipe navigation between library tabs; pages stay alive so scroll
  position is preserved when switching tabs or opening a detail.
- Spotify Canvas background in the full-screen player, with safe audio focus
  (it no longer steals playback) and on-disk URL caching, so a known no-canvas
  track no longer hits the API on restart.
- "Cached canvas" indicator on the player, alongside the existing "Sin Canvas"
  marker.
- Reorderable and hideable library tabs (settings dialog).
- "Locate" FAB on the Songs tab that scrolls the list to the currently playing
  (or next) track; configurable via a new setting.
- Tapping artists/albums on the Home page opens their detail page.
- Redesigned persistent miniplayer bar with shared-element artwork flight.
- App renamed to "Arc" and a new app icon.

### Changed
- Persistent bottom chrome (miniplayer + navbar) driven by a route observer, so
  it hides/shows in sync with detail and player routes.
- Settings: added navbar mode and "skip to next on locate" options.

### Fixed
- Canvas video stealing audio focus (music stopped when a canvas loaded).
- Unnecessary Spotify API calls for tracks already known to have no canvas.
