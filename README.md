# RoomView

A native Apple app (iOS + macOS) for viewing 3D scans of interior spaces — built to solve a specific problem: planning a garage reorganization without needing to be in the garage at the time.

## The problem

3D scanning apps (Polycam, 3d Scanner App, etc.) are built around scanning *objects* — things you walk around, viewed from the outside. They fall apart for *rooms*, where the useful viewpoint is from the inside looking out. Every generic viewer either traps you outside the mesh looking at a solid blob, or drops you inside with no way to see anything because you're surrounded by geometry (and often stuck inside walls/clutter). There's no good way to sit at a desk, pull up a scan of your garage, and actually study what's on the shelves and where things are.

RoomView is a viewer purpose-built for that use case: look at the *inside* of a scanned room from the outside, as if the near wall (or ceiling) were cut away.

## Core concept

- Load a 3D scan of an interior (starting with USDZ exports from Polycam / 3d Scanner App).
- Slice the scan with a draggable clip plane, cutting away the near geometry so you can see and navigate the inside of the room like a dollhouse or cutaway diagram.
- Pin high-resolution photos of specific areas (e.g. a pegboard, a shelf) to points in the 3D scan, so you can zoom into detail that the scan's mesh resolution can't capture, while still seeing it in spatial context (in situ).

## Platform & tech stack

- **Targets:** iOS and macOS (shared codebase)
- **UI:** SwiftUI
- **Rendering:** RealityKit — chosen over SceneKit for native USDZ support, cross-platform reach (iOS/macOS, with visionOS as a possible future target), and a smoother path to ARKit-based in-app scanning later
- **Import format:** USDZ to start (Polycam's native Apple-ecosystem export); other mesh/point cloud formats (OBJ, PLY) may be added later if needed

## Features

### v1 — Viewer
- Import a USDZ room scan
- Navigate/orbit the scan in 3D
- Draggable clip plane to cut away near-side geometry and reveal the interior (start with a single plane; multi-plane/box cropping is a possible future refinement)
- Pin photos to 3D points in the scan
  - Tap a location in the scan to drop a pin and attach a photo
  - Tap a pin to view the attached high-res photo in context
- No cataloging/inventory features yet (no naming, tagging, or search on pins) — kept out of scope for v1 to keep the viewer itself solid first

### Future
- In-app scanning (ARKit-based capture), removing the dependency on external scanning apps
- Adding to the room mesh with addition scanning after the fact
- Allowing close-up scanning of particular areas to get better detail (e.g., a pegboard full of tools)
- Possible inventory features on top of photo pins (naming, notes, search) if useful once the viewer is in daily use
- Possible visionOS support

## Status

Early planning stage — no code yet. This README is the working spec; next step is turning it into an implementation plan.
