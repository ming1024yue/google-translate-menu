import AppKit
import Foundation
let root = URL(fileURLWithPath: CommandLine.arguments[1])
let source = NSImage(contentsOf: root.appendingPathComponent("Resources/AppIcon.png"))!
let output = root.appendingPathComponent("build/AppIcon.iconset")
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
var payload = Data()
let types = [16:"icp4",32:"icp5",64:"icp6",128:"ic07",256:"ic08",512:"ic09",1024:"ic10"]
func integer(_ value: Int) -> Data { var big = UInt32(value).bigEndian; return Data(bytes: &big, count: 4) }
for pixels in [16,32,64,128,256,512,1024] {
 let bitmap = NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:pixels,pixelsHigh:pixels,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
 NSGraphicsContext.saveGraphicsState()
 NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep:bitmap)
 NSGraphicsContext.current?.imageInterpolation = .high
 let n=CGFloat(pixels)
 source.draw(in:NSRect(x:n*0.06,y:n*0.06,width:n*0.88,height:n*0.88),from:.zero,operation:.copy,fraction:1)
 NSGraphicsContext.restoreGraphicsState()
 let png=bitmap.representation(using:.png,properties:[:])!
 try png.write(to:output.appendingPathComponent("icon-\(pixels).png"))
 payload.append(types[pixels]!.data(using:.ascii)!); payload.append(integer(png.count+8));payload.append(png)
}
var icns="icns".data(using:.ascii)!;icns.append(integer(payload.count+8));icns.append(payload)
try icns.write(to:root.appendingPathComponent("Resources/AppIcon.icns"))
