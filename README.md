## [2.0.1-CanguroMIO修改版] - 2026-01-01

### Added
- **Hybrid Map Mode**: Introduced a dual-layer map system using **AutoNavi (HighDe/Amap) Satellite** imagery as the base and a transparent **Road Network** overlay for better visibility of new compounds/streets.
- **Coordinate Rectification**: Implemented **GCJ-02 (Mars Coordinate System)** conversion algorithm (`CoordConv`).
    - Automatically corrects GPS (WGS-84) offsets for Tracks, Markers, and Current Position to perfectly align with Chinese map data.
- **Local Customization**:
    - **Local Nickname**: Users can now set a custom nickname stored locally, overriding the cloud username in the UI.
    - **Local Avatar**: Added support for setting a local profile picture via Camera or Gallery.
- **Image Editor**: Integrated `image_cropper` to allow 1:1 cropping, zooming, and rotating when uploading avatars.
- **Camera Support**: Added direct photo taking capability for avatar updates.
- **Permissions**: Added missing iOS permission descriptions (`NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`) to `Info.plist`.
- **Localization**: Added translation keys for avatar and nickname actions (`pick_from_gallery`, `take_photo`, `edit_avatar`, `set_nickname`, etc.).
- **Credits**: Added "Modified by CanguroMIO" footer in Settings.

### Changed
- **Map Provider**: Switched tile provider source to `wprd0{s}.is.autonavi.com` for better stability and anti-scraping resilience.
- **Map Interaction**:
    - **Anti-White Screen**: Configured `maxNativeZoom: 18` and `maxZoom: 22` to enable auto-scaling of tiles, preventing white screens at high zoom levels.
    - **Performance**: Optimized `HttpClient` concurrency (`maxConnectionsPerHost: 15`) and disabled `RetinaMode` to prevent invalid tile requests.
    - **Anti-Scraping**: Implemented browser-like `User-Agent` headers in tile requests to prevent server blocking (missing tiles).
- **Settings UI**: Refined the User Profile card to support tap-to-edit interactions for both Avatar and Nickname.

### Fixed
- **iOS Build**:
    - Fixed `ffi` Ruby gem compatibility issues on Apple Silicon (M1/M2/M3) Macs.
    - Resolved `DVTBuildVersion` errors by correcting missing `version` numbers in `pubspec.yaml`.
    - Fixed `RetinaMode` constant instantiation syntax error.
- **iPad UX**: Fixed an issue where `showDialog` (Delete/Upload) would auto-dismiss on iPad due to accidental barrier touches by setting `barrierDismissible: false`.
- **Data Accuracy**: Fixed the visual offset (~500m) between the recorded trajectory and the map background.
