import SwiftUI

/// Resting placement of every layer in the Figma frame's 390×422 coordinate space
/// (Home page banner, node 3008:16). Rects for exported layers are the PDF export
/// bounds, which Figma clips to the frame.
enum BannerLayout {
    static let size = CGSize(width: 390, height: 422)

    static let glow          = CGRect(x: 75, y: 83, width: 248, height: 248)            // 3008:17 (incl. blur)
    static let background    = CGRect(x: 1, y: 0, width: 388, height: 422)              // 3008:18
    static let logoRows      = [CGRect(x: 0, y: 0, width: 390, height: 102.87),          // 3008:102
                                CGRect(x: 0, y: 12.12, width: 390, height: 179.77),     // 3008:139
                                CGRect(x: 0, y: 106, width: 390, height: 179.77)]       // 3008:176
    static let buntingLeft   = CGRect(x: 0, y: 0, width: 217.23, height: 87.79)         // 3008:213
    static let buntingRight  = CGRect(x: 223.63, y: 0, width: 148.29, height: 53.22)    // 3008:29
    static let balloonsLeft  = CGRect(x: 0, y: 321.18, width: 76.99, height: 100.82)    // 3008:50
    static let balloonsRight = CGRect(x: 316, y: 297, width: 74, height: 125)           // 3008:76

    // Gift box 3008:22
    static let boxBody       = CGRect(x: 113.57, y: 377, width: 163.79, height: 45)     // 3008:23
    static let boxRibbon     = CGRect(x: 183.95, y: 407.56, width: 22.81, height: 14.44) // 3008:24
    static let boxLid        = CGRect(x: 97, y: 377, width: 196.5, height: 32.28)       // 3008:25
    static let boxFront      = CGRect(x: 132.73, y: 409.28, width: 144.42, height: 12.72) // 3008:28
    /// The box squashes/rotates around its base centre.
    static let boxPivot      = UnitPoint(x: 195.0 / 390, y: 1)

    // Products (unrotated image rect + Figma rotation, or a baked export)
    static let speaker       = CGRect(center: CGPoint(x: 156.46, y: 371.45), size: CGSize(width: 80, height: 80))
    static let speakerAngle  = -28.89                                                    // 3008:19
    static let ps5           = CGRect(x: 155, y: 304, width: 91.97, height: 118)        // 3008:20 (export, -15° baked)
    static let headphones    = CGRect(center: CGPoint(x: 247.33, y: 367.33), size: CGSize(width: 62, height: 62))
    static let headphonesAngle = 15.97                                                   // 3008:21

    // Copy
    static let title         = CGRect(x: 109, y: 209, width: 171.32, height: 97.84)     // 3008:259
    static let subtitle      = CGRect(x: 114.2, y: 295.7, width: 122.63, height: 10.39) // 3008:263 (glyph bounds)
    static let popper        = CGRect(center: CGPoint(x: 273.46, y: 278.11), size: CGSize(width: 54.4, height: 51))
    static let popperAngle   = 10.7                                                      // 3008:262
    static let pill          = CGRect(x: 238, y: 278, width: 61.12, height: 35.68)      // 3008:264 (export, -13° baked)

    static let header        = CGRect(x: 16, y: 64, width: 357, height: 129)            // 3008:231

    /// linear-gradient(158.5deg, #923CF6 0%, #5F22D9 17.76%, #FFFFFF 94.79%) mapped to unit points.
    static let backgroundGradient = LinearGradient(
        stops: [.init(color: Color(hex: 0x923CF6), location: 0),
                .init(color: Color(hex: 0x5F22D9), location: 0.17758),
                .init(color: Color(hex: 0x34009C), location: 0.94787)],
        startPoint: UnitPoint(x: 0.2485, y: -0.0905),
        endPoint: UnitPoint(x: 0.7515, y: 1.0905))
}

extension CGRect {
    init(center: CGPoint, size: CGSize) {
        self.init(x: center.x - size.width / 2, y: center.y - size.height / 2,
                  width: size.width, height: size.height)
    }
}

/// Applies a `LayerState` around `anchor`, then pins the layer at its Figma rect.
struct Layer<Content: View>: View {
    let rect: CGRect
    let state: LayerState
    var anchor: UnitPoint = .center
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(width: rect.width, height: rect.height)
            .scaleEffect(x: max(state.scale, 0.001), y: max(state.scale * state.stretch, 0.001), anchor: anchor)
            .rotationEffect(.degrees(state.rotation), anchor: anchor)
            .offset(x: state.x, y: state.y)
            .opacity(min(max(state.opacity, 0), 1))
            .position(x: rect.midX, y: rect.midY)
    }
}

extension Image {
    /// Loads from the package bundle when built as the PlentiBanner package,
    /// or from the app's main bundle when these files are added to an app target.
    init(banner name: String) {
        #if SWIFT_PACKAGE
        self.init(name, bundle: .module)
        #else
        self.init(name)
        #endif
    }
}
