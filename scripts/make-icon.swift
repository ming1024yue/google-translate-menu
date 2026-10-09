import AppKit
import Foundation
let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = size * scale
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        let n = CGFloat(pixels)
        NSColor.clear.setFill()
        NSRect(x: 0, y: 0, width: n, height: n).fill()
        let box = NSBezierPath(roundedRect: NSRect(x: n * 0.06, y: n * 0.06, width: n * 0.88, height: n * 0.88), xRadius: n * 0.2, yRadius: n * 0.2)
        NSColor(calibratedRed: 0.12, green: 0.35, blue: 0.72, alpha: 1).setFill()
        box.fill()
        let bubble = NSBezierPath(roundedRect: NSRect(x: n * 0.17, y: n * 0.27, width: n * 0.66, height: n * 0.48), xRadius: n * 0.1, yRadius: n * 0.1)
        NSColor.white.setFill(); bubble.fill()
        let tail = NSBezierPath()
        tail.move(to: NSPoint(x: n * 0.27, y: n * 0.30))
        tail.line(to: NSPoint(x: n * 0.27, y: n * 0.18))
        tail.line(to: NSPoint(x: n * 0.43, y: n * 0.30))
        tail.close(); tail.fill()
        let label = "译" as NSString
        let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: n * 0.34, weight: .semibold), .foregroundColor: NSColor(calibratedRed: 0.12, green: 0.35, blue: 0.72, alpha: 1)]
        let bounds = label.size(withAttributes: attrs)
        label.draw(at: NSPoint(x: (n - bounds.width) / 2, y: n * 0.51 - bounds.height / 2), withAttributes: attrs)
        NSGraphicsContext.restoreGraphicsState()
        let data = bitmap.representation(using: .png, properties: [:])!
        let name = scale == 1 ? "icon_\(size)x\(size).png" : "icon_\(size)x\(size)@2x.png"
        try data.write(to: output.appendingPathComponent(name))
    }
}
