# RoomView v1 — Implementation Plan

## Context

RoomView solves a real problem the user has: 3D scanning apps (Polycam, 3d Scanner App) capture rooms as raw meshes with baked textures, but there's no good way to actually *look inside* a scanned room from a desk — existing viewers either strand you outside looking at a solid blob, or drop you inside surrounded by geometry with nothing visible. The user wants a native iOS + macOS app purpose-built for viewing interior scans: cut away the near-side geometry with a clip plane to see inside like a dollhouse, and pin high-resolution photos of specific areas (e.g. a pegboard) onto the 3D scan for detail the scan mesh can't capture.

The repo is currently empty except for `README.md` (the agreed product spec). This plan scaffolds the app from nothing through a working v1: import a USDZ scan, orbit it, slice it open with a clip plane, and pin in-situ photos to it. Explicitly out of scope for v1: inventory/cataloging on pins, in-app scanning, incremental re-scanning — all noted as future work in the README already.

This plan was originally drafted in a Linux session that couldn't compile Swift, so it was broken into small milestones for the user to build/test on their own Mac between rounds. Later sessions run directly on the user's Mac with a full Xcode toolchain, so builds, `xcodebuild`, and even launching the app/simulator can now be verified directly — the milestone structure is kept anyway since it's still the right way to catch design issues early.

## Platform decisions

- iOS + macOS, one codebase (visionOS not targeted now, not precluded later)
- SwiftUI + RealityKit
- Minimum: **iOS 26 / macOS 26** (raised from an original iOS 17/macOS 14 target during M1 — see note below)
- USDZ as the v1 import format
- No cataloging features on pins in v1

**Deployment target note (discovered during M1):** `ARView` (RealityKit's UIKit-based view) is only available on iOS and Mac Catalyst — never on native macOS. The actual cross-platform way to host RealityKit content in SwiftUI on real macOS is `RealityView`, which requires iOS 18/macOS 15+. Since this is a personal app that only needs to run on the user's own current-OS devices, the floor was raised to iOS 26/macOS 26 (matching the installed Xcode 26.5 SDK) rather than reaching for Mac Catalyst.

## Project structure

Avoid hand-authoring `project.pbxproj` (fragile, and can't be verified without Xcode). Split into a thin Xcode-GUI-owned app shell plus a local Swift Package holding essentially all logic, so nearly every file I add afterward is picked up automatically by SwiftPM with zero manual "add to project" steps in Xcode.

```
RoomView/
├── README.md
├── RoomView.xcodeproj/            # user creates via Xcode GUI in Milestone 0
├── RoomViewApp/
│   ├── RoomViewApp.swift          # @main App entry point
│   └── Info.plist                 # usage-description keys (photo library, camera)
├── RoomViewKit/                   # local Swift Package, added via Xcode "Add Local Package"
│   ├── Package.swift
│   ├── Sources/RoomViewKit/
│   │   ├── App/RootView.swift
│   │   ├── Scan/
│   │   │   ├── Scan.swift             # SwiftData model
│   │   │   ├── ScanImporter.swift     # fileImporter + copy into app storage
│   │   │   └── ScanLibrary.swift      # on-disk layout under Application Support
│   │   ├── Rendering/
│   │   │   ├── SceneContainerView.swift   # RealityView-based scene host (shared, no per-platform wrapping needed)
│   │   │   ├── SceneCoordinator.swift     # entity graph, raycasts
│   │   │   ├── OrbitCameraController.swift
│   │   │   ├── PlaceholderRoomBuilder.swift  # M1 synthetic room (no assets needed)
│   │   │   └── ClipPlane/
│   │   │       ├── ClipPlaneController.swift
│   │   │       ├── ClipPlaneMaterial.swift
│   │   │       └── Shaders/ClipPlane.metal
│   │   ├── Pins/
│   │   │   ├── PhotoPin.swift          # SwiftData model
│   │   │   ├── PinPlacementController.swift
│   │   │   ├── PinMarkerEntity.swift
│   │   │   └── PinDetailView.swift
│   │   ├── Persistence/ModelContainerProvider.swift
│   │   └── UI/
│   │       ├── ImportView.swift
│   │       ├── ViewerView.swift        # 3D view + slider chrome + toolbar
│   │       └── ScanLibraryView.swift   # M7
│   └── Tests/RoomViewKitTests/         # plane-math / coordinate-transform unit tests
```

Grouped by feature (Scan, Rendering, Pins), appropriate for a small solo-dev app.

## Key architecture decisions

**Clip-plane cutaway (highest technical risk).** Keep the imported scan entity's transform static (identity) — only the camera orbits — so the clip plane's world-space equation never has to be re-derived relative to a moving room. After USDZ load, walk the entity hierarchy for every `ModelEntity` and wrap its existing material with `CustomMaterial(from:surfaceShader:geometryModifier:)` (supported iOS 15+/macOS 12+, comfortably within our floor), passing a hand-written Metal surface shader (`RoomViewKit/Sources/RoomViewKit/Rendering/ClipPlane/Shaders/ClipPlane.metal`) that computes signed distance to a plane — stored as a `SIMD4<Float>` in `CustomMaterial.custom.value` — and discards fragments on the near side. The plane offset is a plain `Float` driven by a SwiftUI slider; changing it just updates the uniform on each `ModelEntity`, cheap and real-time.

A few exact API specifics (world-position accessor name, `discard_fragment()` usability inside RealityKit's shader hook) can't be verified without compiling in Xcode — Milestone 3 is scoped specifically to nail this down with the user's help. If shader-discard proves infeasible: **Fallback A** is CPU-side procedural mesh clipping via `MeshResource`/`MeshDescriptor` (clip triangle list against the plane, rebuild the mesh), recomputed on drag-end/throttled rather than per-frame. **Fallback B** (lowest risk, coarsest UX) is pre-slicing the room into a handful of slabs at import time and toggling slab visibility on a discrete slider.

**USDZ import.** SwiftUI `.fileImporter(allowedContentTypes: [.usdz])` is genuinely shared across iOS/macOS (no `#if os()` needed at the call site). On selection, copy the file into `Application Support/RoomView/Scans/<scan-uuid>/model.usdz` rather than referencing the original (Polycam exports often live in Files/iCloud locations that can move). Load asynchronously off the main actor with a loading-state UI. Recursively collect all `ModelEntity`s for both clip-plane material application and `generateCollisionShapes(recursive:)` (needed for pin raycasting). Use `visualBounds(relativeTo: nil)` to auto-frame the camera and seed a default clip-plane position.

**Persistence.** SwiftData (natural fit at this exact deployment floor). Two models:

```swift
@Model final class Scan {
    var id: UUID
    var name: String
    var importedAt: Date
    @Relationship(deleteRule: .cascade, inverse: \PhotoPin.scan)
    var pins: [PhotoPin] = []
}

@Model final class PhotoPin {
    var id: UUID
    var x: Double; var y: Double; var z: Double   // local-space coords
    var createdAt: Date
    var photoFilename: String                      // relative filename, not a blob
    var scan: Scan?
}
```

Photos are copied to `Application Support/RoomView/Scans/<scan-uuid>/Photos/<pin-uuid>.jpg` and referenced by filename, not stored as SwiftData blobs. Pin coordinates are stored in the scan's local space (`entity.convert(position:from: nil)` at placement time), so they stay correct regardless of camera position.

**Gesture model — three non-overlapping input surfaces**, to avoid orbit/clip/pin gesture conflicts:
1. Orbit: one-finger/mouse drag in the viewport background rotates the camera around the scan's bounds center (the scan itself never moves); pinch/scroll zooms.
2. Clip plane: a plain SwiftUI `Slider` + a 2-preset axis picker ("cut from near wall" / "cut from ceiling") in fixed UI chrome outside the viewport — not a free-floating 3D drag handle. This is a deliberate v1 scope reduction to avoid gesture conflicts; a true in-viewport handle can come later.
3. Pins: an explicit "Add Pin" toolbar toggle disambiguates placement from looking-around. Tapping an existing marker (checked first) opens its photo; tapping elsewhere while in Add-Pin mode raycasts against mesh collision shapes and drops a new pin.

**Photo attach.** `PhotosPicker` (SwiftUI, cross-platform) for library selection on both platforms. Camera capture is iOS-only (`UIImagePickerController` wrapped in `UIViewControllerRepresentable`) — macOS gets library-only, plus optionally drag-and-drop as a cheap macOS-idiomatic bonus.

## Milestones

Each one is independently buildable/testable by the user on their Mac before the next starts.

- **M0 — Scaffold.** User creates the Xcode Multiplatform App project + adds the local `RoomViewKit` package (exact click-by-click steps provided). *Done when:* "Hello RoomView" builds and runs on both an iOS simulator and macOS.
- **M1 — Procedural viewer + orbit camera. ✅ Done.** Built a placeholder room entirely in code (`MeshResource.generateBox` floor/3 walls + 3 prop boxes) via `RealityView` with built-in `.realityViewCameraControls(.orbit)`, plus an explicit `PerspectiveCamera` using `.horizontal` field-of-view orientation so room width frames consistently across portrait/landscape (the default vertical-FOV auto-fit looked zoomed-out in landscape). Verified building and running on both macOS and iOS Simulator via `xcodebuild`.
- **M2 — USDZ import pipeline.** `.fileImporter`, copy-into-storage, `Scan` SwiftData record, async load replaces the procedural scene, camera auto-frames, scan persists across relaunch. Test with any `.usdz` the user has on hand (a real Polycam scan isn't needed yet). *Done when:* pick a file, see it rendered/orbitable, still there after relaunch.
- **M3 — Clip plane, primary approach.** `CustomMaterial` shader-discard along one axis, driven by a slider. This is the milestone to jointly debug the exact RealityKit API surface in Xcode. *Done when:* dragging the slider makes near-side geometry disappear/reappear in real time.
- **M4 — Clip plane hardening + first real scan.** Add the second orientation preset; ask the user to import an actual Polycam garage scan here to validate against real, dense mesh data (pivot to Fallback A/B here if needed). *Done when:* clip plane behaves acceptably on a real scan with both presets.
- **M5 — Photo pins: placement + storage.** Add-Pin mode, raycast placement, `PhotoPin` SwiftData model, `PhotosPicker` attach, photo copied to disk, marker entity rendered in-scene. *Done when:* a pin survives relaunch, correctly positioned relative to the scan.
- **M6 — Pin viewing + iOS camera capture.** Tap marker → view photo; add camera-capture on iOS. *Done when:* full place → attach → view round trip works on both platforms.
- **M7 — Polish.** Multi-scan library view, delete-scan (cascades pins/photos/usdz), basic import error handling, app icon. *Done when:* the app feels coherent as a v1 across both platforms with 2+ scans.

## Verification

Each milestone's "done when" above is the checkpoint before starting the next. When working directly on the user's Mac, this can be verified directly via `xcodebuild` (and even launching the built app / simulator); otherwise the user builds in Xcode and reports back. Milestone 3 in particular is expected to need iteration once real RealityKit compiler errors surface for the clip-plane shader approach.
