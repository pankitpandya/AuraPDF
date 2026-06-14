import SwiftUI
import PDFKit

struct PageCardView: View {
    let page: WorkspacePage
    @ObservedObject var state: WorkspaceState
    let size: CGFloat
    
    @State private var isHovered = false
    @State private var showZoom = false
    
    var isSelected: Bool {
        state.selectedPageIds.contains(page.id)
    }
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                // Main Page Thumbnail Image
                let thumb = state.getThumbnail(for: page, size: CGSize(width: size * 1.5, height: size * 2.0))
                Image(nsImage: thumb)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size * 1.35)
                    .background(Color.white)
                    .cornerRadius(6)
                    .shadow(color: Color.black.opacity(isHovered ? 0.2 : 0.1), radius: isHovered ? 6 : 3, x: 0, y: isHovered ? 3 : 1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isSelected ? Color.accentColor : Color.black.opacity(0.15), lineWidth: isSelected ? 3 : 1)
                    )
                
                // Hover Action Overlay
                if isHovered {
                    VStack {
                        Spacer()
                        HStack(spacing: 6) {
                            Button(action: { state.rotatePage(pageId: page.id, clockwise: false) }) {
                                Image(systemName: "rotate.left")
                                    .font(.system(size: 10, weight: .semibold))
                                    .padding(5)
                                    .background(Color.black.opacity(0.75))
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .help("Rotate Counterclockwise")

                            Button(action: { state.rotatePage(pageId: page.id, clockwise: true) }) {
                                Image(systemName: "rotate.right")
                                    .font(.system(size: 10, weight: .semibold))
                                    .padding(5)
                                    .background(Color.black.opacity(0.75))
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .help("Rotate Clockwise")

                            Button(action: { showZoom = true }) {
                                Image(systemName: "plus.magnifyingglass")
                                    .font(.system(size: 10, weight: .semibold))
                                    .padding(5)
                                    .background(Color.black.opacity(0.75))
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .help("Inspect Page")
                            .popover(isPresented: $showZoom) {
                                ZoomView(page: page, state: state)
                            }

                            Button(action: { state.deletePage(pageId: page.id) }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 10, weight: .semibold))
                                    .padding(5)
                                    .background(Color.red.opacity(0.85))
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .help("Delete Page")
                        }
                        .padding(.bottom, 6)
                    }
                    .frame(width: size, height: size * 1.35)
                    .background(Color.black.opacity(0.12))
                    .cornerRadius(6)
                }

                // Selection circular checkbox overlay (Layered on top of the hover overlay, bounded to avoid blocking lower controls)
                Button(action: {
                    if isSelected {
                        state.selectedPageIds.remove(page.id)
                    } else {
                        state.selectedPageIds.insert(page.id)
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.accentColor : Color.black.opacity(0.4))
                            .frame(width: 18, height: 18)
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 24, height: 24)
                }
                .buttonStyle(PlainButtonStyle())
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
                .padding(6)
            }
            .onHover { hovering in
                isHovered = hovering
            }
            
            // Text Labels Below Card
            VStack(alignment: .center, spacing: 2) {
                Text(page.isBlank ? "Blank Page" : "Page \(page.originalPageIndex + 1)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(page.fileName)
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: size - 12)
            }
            .frame(width: size)
        }
        .padding(6)
        .background(isHovered ? Color.primary.opacity(0.04) : Color.clear)
        .cornerRadius(8)
    }
}

struct ZoomView: View {
    let page: WorkspacePage
    let state: WorkspaceState
    
    var body: some View {
        VStack(spacing: 8) {
            let fullSizeThumb = state.getThumbnail(for: page, size: CGSize(width: 480, height: 640))
            Image(nsImage: fullSizeThumb)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 400, height: 540)
                .background(Color.white)
                .cornerRadius(4)
                .shadow(radius: 5)
                .padding()
            
            HStack {
                Text(page.isBlank ? "Blank Page" : page.fileName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                if !page.isBlank {
                    Text("- Page \(page.originalPageIndex + 1)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 12)
        }
        .frame(width: 440, height: 600)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
