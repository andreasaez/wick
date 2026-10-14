// Draws Wick's app icon into an .iconset folder. Run by build.sh; the result
// is never committed. Usage: make-icon <output.iconset>
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

func rgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha)
}

func gradient(_ colors: [CGColor]) -> CGGradient {
    CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors as CFArray, locations: nil)!
}

func drawIcon(in ctx: CGContext, size: CGFloat) {
    ctx.scaleBy(x: size / 1024, y: size / 1024)

    // Background tile on Apple's macOS icon grid: 824pt square, 185pt corners.
    let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
    let tilePath = CGPath(roundedRect: tile, cornerWidth: 185, cornerHeight: 185, transform: nil)
    ctx.saveGState()
    ctx.addPath(tilePath)
    ctx.clip()
    ctx.drawLinearGradient(gradient([rgb(0x15_0C_08), rgb(0x33_1C_12)]),
                           start: CGPoint(x: 512, y: 100), end: CGPoint(x: 512, y: 924), options: [])
    // Warm glow behind the flame.
    ctx.drawRadialGradient(gradient([rgb(0xFF_6A_1F, 0.45), rgb(0xFF_6A_1F, 0)]),
                           startCenter: CGPoint(x: 512, y: 400), startRadius: 0,
                           endCenter: CGPoint(x: 512, y: 400), endRadius: 400, options: [])
    ctx.restoreGState()

    let box = CGRect(x: 262, y: 215, width: 500, height: 600)

    ctx.saveGState()
    ctx.addPath(Flame.outer(in: box))
    ctx.clip()
    ctx.drawLinearGradient(gradient([rgb(0xFF_8A_1A), rgb(0xFF_4A_1C), rgb(0xE8_2A_18)]),
                           start: CGPoint(x: 512, y: box.minY), end: CGPoint(x: 512, y: box.maxY), options: [])
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(Flame.inner(in: box))
    ctx.clip()
    ctx.drawLinearGradient(gradient([rgb(0xFF_F4_C2), rgb(0xFF_D2_3A), rgb(0xFF_A8_1E)]),
                           start: CGPoint(x: 512, y: box.minY), end: CGPoint(x: 512, y: box.minY + box.height * 0.64),
                           options: [])
    ctx.restoreGState()
}

func writePNG(size: Int, to url: URL) {
    let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    drawIcon(in: ctx, size: CGFloat(size))
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
    guard CGImageDestinationFinalize(dest) else { fatalError("Couldn't write \(url.lastPathComponent)") }
}

let output = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
for points in [16, 32, 128, 256, 512] {
    writePNG(size: points, to: output.appendingPathComponent("icon_\(points)x\(points).png"))
    writePNG(size: points * 2, to: output.appendingPathComponent("icon_\(points)x\(points)@2x.png"))
}
