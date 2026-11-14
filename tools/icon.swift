// Draws the launcher icon: a dark lock on lime, matching the Welcome badge.
// Usage: swift tools/icon.swift ThinkTwice/Assets.xcassets/AppIcon.appiconset/icon-1024.png
import AppKit

let size = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4,
                           hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext
let space = CGColorSpaceCreateDeviceRGB()
func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> CGColor { CGColor(colorSpace: space, components: [r / 255, g / 255, b / 255, 1])! }
let lime = rgb(0x9B, 0xF0, 0x5C), limeTop = rgb(0xB6, 0xF7, 0x7E), ink = rgb(0x06, 0x14, 0x0A)

// Background: lime, a little lighter at the top. No transparency; iOS rounds the corners itself.
let gradient = CGGradient(colorsSpace: space, colors: [limeTop, lime] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 1024), end: CGPoint(x: 0, y: 0), options: [])

// Shackle (origin is bottom-left, so y is flipped from the design grid).
ctx.setStrokeColor(ink); ctx.setLineWidth(84); ctx.setLineCap(.round)
ctx.move(to: CGPoint(x: 372, y: 520))
ctx.addLine(to: CGPoint(x: 372, y: 640))
ctx.addArc(center: CGPoint(x: 512, y: 640), radius: 140, startAngle: .pi, endAngle: 0, clockwise: true)
ctx.addLine(to: CGPoint(x: 652, y: 520))
ctx.strokePath()

// Body
ctx.setFillColor(ink)
ctx.addPath(CGPath(roundedRect: CGRect(x: 272, y: 196, width: 480, height: 360), cornerWidth: 84, cornerHeight: 84, transform: nil))
ctx.fillPath()

// Keyhole
ctx.setFillColor(lime)
ctx.fillEllipse(in: CGRect(x: 512 - 46, y: 392 - 46, width: 92, height: 92))
ctx.addPath(CGPath(roundedRect: CGRect(x: 512 - 18, y: 290, width: 36, height: 110), cornerWidth: 18, cornerHeight: 18, transform: nil))
ctx.fillPath()

ctx.flush()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
