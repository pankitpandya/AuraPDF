import Cocoa

let size = CGSize(width: 512, height: 512)
let image = NSImage(size: size)
image.lockFocus()

// Draw background gradient (rounded squircle representation)
let rect = NSRect(origin: .zero, size: size)
let bgPath = NSBezierPath(roundedRect: rect.insetBy(dx: 20, dy: 20), xRadius: 100, yRadius: 100)
let bgGradient = NSGradient(
    starting: NSColor(red: 0.08, green: 0.12, blue: 0.22, alpha: 1.0),
    ending: NSColor(red: 0.03, green: 0.04, blue: 0.08, alpha: 1.0)
)
bgGradient?.draw(in: bgPath, angle: -45)

// Draw glowing accent border
bgPath.lineWidth = 4
NSColor(red: 0.0, green: 0.65, blue: 0.9, alpha: 0.3).setStroke()
bgPath.stroke()

// Draw Document Fold Representation
let docRect = NSRect(x: 140, y: 120, width: 232, height: 272)
let docPath = NSBezierPath(roundedRect: docRect, xRadius: 28, yRadius: 28)

// Fill doc outline with gradient
let docGradient = NSGradient(
    starting: NSColor(red: 0.0, green: 0.45, blue: 0.85, alpha: 1.0),
    ending: NSColor(red: 0.0, green: 0.75, blue: 0.75, alpha: 1.0)
)
docGradient?.draw(in: docPath, angle: 45)

// Draw inner paper element
let innerRect = docRect.insetBy(dx: 24, dy: 24)
let innerPath = NSBezierPath(roundedRect: innerRect, xRadius: 16, yRadius: 16)
NSColor.white.withAlphaComponent(0.12).set()
innerPath.fill()

// Draw horizontal lines representing PDF content
let linePath = NSBezierPath()
linePath.move(to: NSPoint(x: 188, y: 310))
linePath.line(to: NSPoint(x: 324, y: 310))

linePath.move(to: NSPoint(x: 188, y: 260))
linePath.line(to: NSPoint(x: 324, y: 260))

linePath.move(to: NSPoint(x: 188, y: 210))
linePath.line(to: NSPoint(x: 270, y: 210))

linePath.lineWidth = 10
linePath.lineCapStyle = .round
NSColor.white.set()
linePath.stroke()

image.unlockFocus()

// Save image as PNG
if let tiffData = image.tiffRepresentation,
   let bitmap = NSBitmapImageRep(data: tiffData),
   let pngData = bitmap.representation(using: .png, properties: [:]) {
    do {
        try pngData.write(to: URL(fileURLWithPath: "logo.png"))
        print("Logo generated successfully.")
    } catch {
        print("Failed to save logo.png: \(error)")
    }
} else {
    print("Failed to convert image to PNG.")
}
