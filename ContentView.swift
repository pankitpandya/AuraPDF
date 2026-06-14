import SwiftUI
import UniformTypeIdentifiers
import PDFKit

struct ContentView: View {
    @StateObject private var state = WorkspaceState()
    @State private var thumbnailSize: CGFloat = 140
    @State private var draggedItem: WorkspacePage?
    @State private var showBlankPageSheet = false
    
    // Blank page configuration state
    @State private var blankPageSizeSelection = "Letter"
    @State private var blankPageOrientationLandscape = false

    var body: some View {
        NavigationView {
            // LEFT SIDEBAR
            VStack(alignment: .leading, spacing: 0) {
                // Branding Header
                HStack(spacing: 8) {
                    Image(systemName: "doc.on.doc.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("AuraPDF")
                            .font(.system(size: 16, weight: .bold))
                        Text("Desktop Editor")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 15)

                Divider()

                // File Operations & File List
                VStack(alignment: .leading, spacing: 12) {
                    Text("IMPORTED FILES")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    
                    if state.importedFiles.isEmpty {
                        Text("No PDF documents loaded")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    } else {
                        List {
                            ForEach(state.importedFiles) { file in
                                HStack(spacing: 6) {
                                    Image(systemName: "doc.text.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                    
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(file.name)
                                            .font(.system(size: 11, weight: .medium))
                                            .lineLimit(1)
                                        Text("\(file.pageCount) pages")
                                            .font(.system(size: 9))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .listStyle(SidebarListStyle())
                        .frame(minHeight: 120, maxHeight: .infinity)
                    }
                }
                
                Spacer()

                Divider()

                // Sidebar Bottom Actions
                VStack(spacing: 8) {
                    Button(action: selectPDFs) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add PDF Files...")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Button(action: { showBlankPageSheet = true }) {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                            Text("Insert Blank Page...")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    
                    Button(action: { state.clearWorkspace() }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear Workspace")
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.red)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .disabled(state.pages.isEmpty)
                }
                .padding(16)
            }
            .frame(minWidth: 220, idealWidth: 240, maxWidth: 300)
            
            // MAIN WORKSPACE CANVAS
            VStack(spacing: 0) {
                // Top control bar
                HStack(spacing: 16) {
                    // Selection Summary
                    if state.pages.isEmpty {
                        Text("Workspace empty")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(state.pages.count) pages (\(state.selectedPageIds.count) selected)")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    
                    Spacer()
                    
                    // Zoom level controls
                    HStack(spacing: 4) {
                        Image(systemName: "rectangle.and.paperclip")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Slider(value: $thumbnailSize, in: 90...240)
                            .frame(width: 80)
                        Image(systemName: "rectangle.and.paperclip")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .padding(.trailing, 8)
                    
                    Divider().frame(height: 20)
                    
                    // Batch actions
                    Group {
                        Button(action: selectAllPages) {
                            Text("Select All")
                        }
                        .disabled(state.pages.isEmpty)
                        
                        Button(action: selectNonePages) {
                            Text("Clear Selection")
                        }
                        .disabled(state.selectedPageIds.isEmpty)
                        
                        Button(action: { state.rotateSelectedPages(clockwise: true) }) {
                            Image(systemName: "rotate.right")
                        }
                        .help("Rotate Selected Clockwise")
                        .disabled(state.selectedPageIds.isEmpty)
                        
                        Button(action: { state.deleteSelectedPages() }) {
                            Image(systemName: "trash")
                        }
                        .help("Delete Selected")
                        .disabled(state.selectedPageIds.isEmpty)
                        
                        Button(action: { state.duplicateSelectedPages() }) {
                            Image(systemName: "doc.on.doc")
                        }
                        .help("Duplicate Selected")
                        .disabled(state.selectedPageIds.isEmpty)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(NSColor.windowBackgroundColor))
                
                Divider()
                
                // Workspace Grid Canvas
                ZStack {
                    if state.pages.isEmpty {
                        // Empty State Dropzone
                        VStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(
                                        Color.accentColor.opacity(0.4),
                                        style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [8, 6])
                                    )
                                    .frame(width: 420, height: 260)
                                    .background(Color.primary.opacity(0.01))
                                
                                VStack(spacing: 12) {
                                    Image(systemName: "arrow.down.doc.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.accentColor.opacity(0.8))
                                    
                                    Text("Drag & Drop PDF documents here")
                                        .font(.system(size: 14, weight: .bold))
                                    
                                    Text("or click 'Add PDF Files' in the sidebar to begin editing")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                    
                                    Button(action: selectPDFs) {
                                        Text("Browse Files")
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.regular)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Scrollable Page Grid
                        ScrollView {
                            LazyVGrid(
                                columns: [GridItem(.adaptive(minimum: thumbnailSize + 12), spacing: 16)],
                                spacing: 20
                            ) {
                                ForEach(state.pages) { page in
                                    PageCardView(page: page, state: state, size: thumbnailSize)
                                        .onDrag {
                                            self.draggedItem = page
                                            return NSItemProvider(object: page.id.uuidString as NSString)
                                        }
                                        .onDrop(of: [.text], delegate: PageDropDelegate(item: page, state: state, draggedItem: $draggedItem))
                                }
                            }
                            .padding(24)
                        }
                    }
                    
                    // Processing overlay / progress indicator
                    if state.isProcessing {
                        ZStack {
                            Color.black.opacity(0.4)
                                .edgesIgnoringSafeArea(.all)
                            
                            VStack(spacing: 12) {
                                ProgressView(value: state.progressValue)
                                    .progressViewStyle(LinearProgressViewStyle())
                                    .frame(width: 200)
                                
                                Text(state.progressMessage)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .padding(20)
                            .background(Color(NSColor.windowBackgroundColor))
                            .cornerRadius(10)
                            .shadow(radius: 10)
                        }
                    }
                }
                .background(Color(NSColor.underPageBackgroundColor))
                .onDrop(of: [.fileURL], delegate: FileDropDelegate(state: state))
                
                Divider()
                
                // Bottom Status Bar and Export Action
                HStack {
                    if !state.pages.isEmpty {
                        HStack(spacing: 12) {
                            Button(action: { exportPDF(selectedOnly: false) }) {
                                HStack {
                                    Image(systemName: "arrow.down.doc")
                                    Text("Save Merged PDF...")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            
                            Button(action: { exportPDF(selectedOnly: true) }) {
                                HStack {
                                    Image(systemName: "doc.badge.ellipsis")
                                    Text("Extract Selected...")
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            .disabled(state.selectedPageIds.isEmpty)
                        }
                    } else {
                        Spacer()
                    }
                    Spacer()
                }
                .padding(16)
                .background(Color(NSColor.windowBackgroundColor))
            }
        }
        .sheet(isPresented: $showBlankPageSheet) {
            // Blank Page Custom Modal Dialog
            VStack(spacing: 16) {
                Text("Insert Blank Page")
                    .font(.system(size: 14, weight: .bold))
                    .padding(.top, 12)
                
                Form {
                    Picker("Page Size:", selection: $blankPageSizeSelection) {
                        Text("Letter (8.5 x 11 in)").tag("Letter")
                        Text("A4 (210 x 297 mm)").tag("A4")
                        Text("US Legal (8.5 x 14 in)").tag("Legal")
                    }
                    .pickerStyle(DefaultPickerStyle())
                    
                    Toggle("Landscape Orientation", isOn: $blankPageOrientationLandscape)
                        .padding(.vertical, 4)
                }
                .padding(.horizontal, 20)
                
                HStack(spacing: 12) {
                    Button("Cancel") {
                        showBlankPageSheet = false
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Insert") {
                        state.addBlankPage(size: blankPageSizeSelection, isLandscape: blankPageOrientationLandscape)
                        showBlankPageSheet = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.bottom, 12)
            }
            .frame(width: 320, height: 180)
        }
    }
    
    // FILE OPEN PANEL DIALOG
    private func selectPDFs() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.pdf]
        panel.title = "Select PDF Files"
        
        if panel.runModal() == .OK {
            state.importPDFs(urls: panel.urls)
        }
    }
    
    // FILE SAVE PANEL DIALOG
    private func exportPDF(selectedOnly: Bool) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = selectedOnly ? "ExtractedPages.pdf" : "MergedDocument.pdf"
        panel.title = selectedOnly ? "Extract Selected Pages" : "Save Merged PDF"
        
        if panel.runModal() == .OK, let url = panel.url {
            state.isProcessing = true
            state.progressMessage = "Generating PDF..."
            state.progressValue = 0.5
            
            DispatchQueue.global(qos: .userInitiated).async {
                let success = state.savePDF(to: url, selectedOnly: selectedOnly)
                
                DispatchQueue.main.async {
                    state.isProcessing = false
                    if !success {
                        // Display error (using alert triggers or print)
                        print("Failed to save PDF")
                    }
                }
            }
        }
    }
    
    // Selection helpers
    private func selectAllPages() {
        state.selectedPageIds = Set(state.pages.map { $0.id })
    }
    
    private func selectNonePages() {
        state.selectedPageIds.removeAll()
    }
}

// DRAG AND DROP REORDER DELEGATE
struct PageDropDelegate: DropDelegate {
    let item: WorkspacePage
    @ObservedObject var state: WorkspaceState
    @Binding var draggedItem: WorkspacePage?
    
    func performDrop(info: DropInfo) -> Bool {
        self.draggedItem = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let draggedItem = draggedItem, draggedItem.id != item.id else { return }
        guard let from = state.pages.firstIndex(where: { $0.id == draggedItem.id }),
              let to = state.pages.firstIndex(where: { $0.id == item.id }) else { return }
        
        if state.pages[to].id != draggedItem.id {
            withAnimation(.easeInOut(duration: 0.2)) {
                state.pages.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
            }
        }
    }
}

// WINDOW FILE DROP DELEGATE
struct FileDropDelegate: DropDelegate {
    @ObservedObject var state: WorkspaceState
    
    func performDrop(info: DropInfo) -> Bool {
        let providers = info.itemProviders(for: [.fileURL])
        var pdfURLs: [URL] = []
        let group = DispatchGroup()
        
        for provider in providers {
            group.enter()
            _ = provider.loadObject(ofClass: URL.self) { url, error in
                if let url = url, url.pathExtension.lowercased() == "pdf" {
                    DispatchQueue.main.async {
                        pdfURLs.append(url)
                    }
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if !pdfURLs.isEmpty {
                state.importPDFs(urls: pdfURLs)
            }
        }
        return true
    }
}
