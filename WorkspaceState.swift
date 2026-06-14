import SwiftUI
import PDFKit

struct PDFFile: Identifiable {
    let id = UUID()
    let name: String
    let url: URL
    let pageCount: Int
}

struct WorkspacePage: Identifiable, Equatable {
    let id: UUID
    let sourceDocument: PDFDocument? // nil if blank page
    let originalPageIndex: Int // -1 if blank page
    var rotation: Int // Relative rotation offset in degrees: 0, 90, 180, 270
    let fileName: String
    let isBlank: Bool
    let pageSize: CGSize // Standard size in points (e.g. Letter or A4)

    static func == (lhs: WorkspacePage, rhs: WorkspacePage) -> Bool {
        return lhs.id == rhs.id && lhs.rotation == rhs.rotation
    }
}

class WorkspaceState: ObservableObject {
    @Published var pages: [WorkspacePage] = []
    @Published var importedFiles: [PDFFile] = []
    @Published var selectedPageIds: Set<UUID> = []
    @Published var isProcessing: Bool = false
    @Published var progressMessage: String = ""
    @Published var progressValue: Double = 0.0
    @Published var thumbnailCache: [UUID: NSImage] = [:]

    // Size profiles
    static let letterSize = CGSize(width: 612, height: 792)
    static let a4Size = CGSize(width: 595.27, height: 841.89)
    static let legalSize = CGSize(width: 612, height: 1008)

    func importPDFs(urls: [URL]) {
        isProcessing = true
        progressMessage = "Importing PDF files..."
        progressValue = 0.0

        let totalFiles = Double(urls.count)
        var importedCount = 0.0

        DispatchQueue.global(qos: .userInitiated).async {
            for url in urls {
                guard url.startAccessingSecurityScopedResource() else {
                    // Try to load directly if security access is not required/granted
                    self.loadPDF(from: url)
                    continue
                }
                defer { url.stopAccessingSecurityScopedResource() }
                self.loadPDF(from: url)

                importedCount += 1.0
                let progress = importedCount / totalFiles
                DispatchQueue.main.async {
                    self.progressValue = progress
                }
            }

            DispatchQueue.main.async {
                self.isProcessing = false
                self.progressMessage = ""
                self.progressValue = 0.0
            }
        }
    }

    private func loadPDF(from url: URL) {
        guard let doc = PDFDocument(url: url) else {
            return
        }

        let fileName = url.lastPathComponent
        let pageCount = doc.pageCount
        let file = PDFFile(name: fileName, url: url, pageCount: pageCount)

        var newPages: [WorkspacePage] = []
        for i in 0..<pageCount {
            if let pdfPage = doc.page(at: i) {
                let bounds = pdfPage.bounds(for: .mediaBox)
                let page = WorkspacePage(
                    id: UUID(),
                    sourceDocument: doc,
                    originalPageIndex: i,
                    rotation: 0,
                    fileName: fileName,
                    isBlank: false,
                    pageSize: bounds.size
                )
                newPages.append(page)
            }
        }

        DispatchQueue.main.async {
            self.importedFiles.append(file)
            self.pages.append(contentsOf: newPages)
        }
    }

    func addBlankPage(size: String, isLandscape: Bool) {
        let baseSize: CGSize
        switch size.lowercased() {
        case "a4":
            baseSize = WorkspaceState.a4Size
        case "legal":
            baseSize = WorkspaceState.legalSize
        default:
            baseSize = WorkspaceState.letterSize
        }

        let pageSize = isLandscape ? CGSize(width: baseSize.height, height: baseSize.width) : baseSize
        let newPage = WorkspacePage(
            id: UUID(),
            sourceDocument: nil,
            originalPageIndex: -1,
            rotation: 0,
            fileName: "Blank Page",
            isBlank: true,
            pageSize: pageSize
        )

        // If there's a selection, insert after the last selected page. Otherwise, append to the end.
        if let lastSelectedId = pages.last(where: { selectedPageIds.contains($0.id) })?.id,
           let lastSelectedIndex = pages.firstIndex(where: { $0.id == lastSelectedId }) {
            pages.insert(newPage, at: lastSelectedIndex + 1)
        } else {
            pages.append(newPage)
        }
    }

    func deleteSelectedPages() {
        pages.removeAll { selectedPageIds.contains($0.id) }
        selectedPageIds.removeAll()
    }

    func deletePage(pageId: UUID) {
        pages.removeAll { $0.id == pageId }
        selectedPageIds.remove(pageId)
        thumbnailCache.removeValue(forKey: pageId)
    }

    func rotateSelectedPages(clockwise: Bool) {
        let angle = clockwise ? 90 : -90
        for i in 0..<pages.count {
            if selectedPageIds.contains(pages[i].id) {
                let currentRot = pages[i].rotation
                let newRot = (currentRot + angle + 360) % 360
                pages[i].rotation = newRot
                thumbnailCache.removeValue(forKey: pages[i].id) // Invalidate cache
            }
        }
    }

    func rotatePage(pageId: UUID, clockwise: Bool) {
        guard let index = pages.firstIndex(where: { $0.id == pageId }) else { return }
        let angle = clockwise ? 90 : -90
        let currentRot = pages[index].rotation
        pages[index].rotation = (currentRot + angle + 360) % 360
        thumbnailCache.removeValue(forKey: pageId) // Invalidate cache
    }

    func duplicateSelectedPages() {
        var newPages: [WorkspacePage] = []
        for page in pages {
            newPages.append(page)
            if selectedPageIds.contains(page.id) {
                let duplicate = WorkspacePage(
                    id: UUID(),
                    sourceDocument: page.sourceDocument,
                    originalPageIndex: page.originalPageIndex,
                    rotation: page.rotation,
                    fileName: page.fileName,
                    isBlank: page.isBlank,
                    pageSize: page.pageSize
                )
                newPages.append(duplicate)
            }
        }
        pages = newPages
    }

    func clearWorkspace() {
        pages.removeAll()
        importedFiles.removeAll()
        selectedPageIds.removeAll()
        thumbnailCache.removeAll()
    }

    func getThumbnail(for page: WorkspacePage, size: CGSize) -> NSImage {
        if let cached = thumbnailCache[page.id] {
            return cached
        }

        let img: NSImage
        if page.isBlank {
            img = NSImage(size: size)
            img.lockFocus()
            NSColor.white.set()
            NSRect(origin: .zero, size: size).fill()
            
            // Draw border
            NSColor.lightGray.withAlphaComponent(0.4).setStroke()
            let path = NSBezierPath(rect: NSRect(origin: .zero, size: size).insetBy(dx: 1, dy: 1))
            path.lineWidth = 1
            path.stroke()
            
            // Draw a subtle "Blank" text placeholder in the center
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: NSColor.lightGray,
                .font: NSFont.systemFont(ofSize: 10),
                .paragraphStyle: paragraphStyle
            ]
            let str = "BLANK"
            let strSize = str.size(withAttributes: attributes)
            let textRect = NSRect(
                x: (size.width - strSize.width) / 2,
                y: (size.height - strSize.height) / 2,
                width: strSize.width,
                height: strSize.height
            )
            str.draw(in: textRect, withAttributes: attributes)
            
            img.unlockFocus()
        } else {
            if let pdfPage = page.sourceDocument?.page(at: page.originalPageIndex) {
                let originalRotation = pdfPage.rotation
                pdfPage.rotation = (originalRotation + page.rotation) % 360
                img = pdfPage.thumbnail(of: size, for: .mediaBox)
                pdfPage.rotation = originalRotation // restore
            } else {
                img = NSImage()
            }
        }

        thumbnailCache[page.id] = img
        return img
    }

    func savePDF(to url: URL, selectedOnly: Bool = false) -> Bool {
        let pagesToSave = selectedOnly ? pages.filter { selectedPageIds.contains($0.id) } : pages
        guard !pagesToSave.isEmpty else { return false }

        let outputDoc = PDFDocument()
        var newIndex = 0

        for page in pagesToSave {
            if page.isBlank {
                let blankPage = PDFPage()
                blankPage.setBounds(NSRect(origin: .zero, size: page.pageSize), for: .mediaBox)
                outputDoc.insert(blankPage, at: newIndex)
                newIndex += 1
            } else if let sourceDoc = page.sourceDocument,
                      let sourcePage = sourceDoc.page(at: page.originalPageIndex) {
                if let pageCopy = sourcePage.copy() as? PDFPage {
                    pageCopy.rotation = (sourcePage.rotation + page.rotation) % 360
                    outputDoc.insert(pageCopy, at: newIndex)
                    newIndex += 1
                }
            }
        }

        return outputDoc.write(to: url)
    }
}
