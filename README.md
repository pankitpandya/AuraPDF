# AuraPDF 📄✨

AuraPDF is a lightweight, high-performance native macOS desktop application designed for visual PDF page manipulation. Built entirely using **Swift, SwiftUI, and Apple's native PDFKit framework**, it offers an intuitive, pixel-perfect drag-and-drop workspace to edit and compile PDF documents locally and securely.

---

## Features

- **Merge PDFs**: Load multiple PDF files, combine their pages, and export them into a single PDF.
- **Rearrange Pages**: Reorder pages interactively using a fluid drag-and-drop grid layout.
- **Delete Pages**: Remove unwanted pages individually or in bulk.
- **Rotate Pages**: Rotate individual pages or batch-rotate selected pages (90° increments, clockwise/counterclockwise).
- **Extract Pages**: Select a subset of pages and export them into a separate PDF.
- **Insert Blank Pages**: Create empty pages of various sizes (Letter, A4, US Legal) and orientations (Portrait, Landscape) and insert them anywhere in the document sequence.
- **Inspect Pages**: Click the magnifying glass on any page card to open a high-resolution detail popover preview.
- **Dynamic Grid Zoom**: Adjust card sizes using the toolbar slider for optimal visibility.
- **Drag-and-Drop Imports**: Drag and drop PDF files from Finder directly onto the empty grid canvas.
- **100% Client-Side & Secure**: All document processing occurs completely offline on your Mac. No files are uploaded to any server, preserving document confidentiality.

---

## Technology Stack

- **Frontend Interface**: SwiftUI (Native macOS views, NavigationSplitView, Sheets, Popovers, LazyVGrid).
- **Core Processing**: Apple's native `PDFKit` (provides fast, lossless page cloning, rotation, rendering, and vector detail preservation).
- **Compilation Tooling**: Standard Command Line Tools (`swiftc` compiler, `sips` image processing, and `iconutil` app icon packaging).
- **Application Icon**: Programmatically drawn using Cocoa's `NSGraphicsContext` to build a vector app logo compiled to native `.icns` format.

---

## Getting Started

### Prerequisites

To compile the application, you must have the Xcode Command Line Tools installed on your Mac. You can verify this or install them by running:
```bash
xcode-select --install
```

### Installation and Compilation

1. Clone this repository (if not already downloaded):
   ```bash
   git clone https://github.com/pankitpandya/AuraPDF.git
   cd AuraPDF
   ```
2. Build the application by running the provided build script:
   ```bash
   ./build.sh
   ```
   *This script will:*
   - Compile the programmatic logo script to draw a high-resolution icon.
   - Resize and bundle the icon into a macOS-compliant `AppIcon.icns`.
   - Compile all SwiftUI and PDFKit Swift files into a native ARM64/Intel binary.
   - Assemble the native `AuraPDF.app` bundle directory tree.
   - Ad-hoc code-sign the bundle locally so it launches without macOS Gatekeeper warnings.

### Running the Application

You can open the app directly from your terminal:
```bash
open AuraPDF.app
```
Alternatively, double-click **AuraPDF.app** in Finder inside the project folder.

---

## File Structure

- **[App.swift](file:///Users/pandya/Dev Project/PDF Tools/App.swift)**: Application entry point and window scene configuration.
- **[WorkspaceState.swift](file:///Users/pandya/Dev Project/PDF Tools/WorkspaceState.swift)**: Application state controller carrying PDFKit logic (load, merge, rotate, export).
- **[ContentView.swift](file:///Users/pandya/Dev Project/PDF Tools/ContentView.swift)**: Main layout containing the sidebar, batch toolbar, grid canvas, and drop zone.
- **[PageCardView.swift](file:///Users/pandya/Dev Project/PDF Tools/PageCardView.swift)**: Page card grid elements with interactive selection, action menus, and inspection popovers.
- **[GenerateIcon.swift](file:///Users/pandya/Dev Project/PDF Tools/GenerateIcon.swift)**: Cocoa script that outputs a custom brand logo.
- **[Info.plist](file:///Users/pandya/Dev Project/PDF Tools/Info.plist)**: App metadata definition.
- **[build.sh](file:///Users/pandya/Dev Project/PDF Tools/build.sh)**: Compilation orchestration and bundling pipeline.

---

## License

This project is open-source and available under the GNU GPL v3 License (see the [LICENSE](file:///Users/pandya/Dev Project/PDF Tools/LICENSE) file for details).
