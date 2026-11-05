import SwiftUI

/// "Plenti turns one" home banner (Figma 3008:16).
/// Laid out in a fixed 390×422 design space and scaled to the container width.
/// Tap to replay the intro.
public struct PlentiBannerView: View {
    private let choreography: Choreography
    private let showsDebugScrubber: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()
    @State private var scrubTime: Double?
    @State private var reducedOpacity = 0.0
    @State private var vegOnly = true

    public init(spec: MotionSpec = MotionSpec(), showsDebugScrubber: Bool = false) {
        choreography = Choreography(spec: spec)
        self.showsDebugScrubber = showsDebugScrubber
    }

    public var body: some View {
        VStack(spacing: 12) {
            banner
            #if DEBUG
            if showsDebugScrubber && !reduceMotion {
                BannerScrubber(start: $start, scrubTime: $scrubTime,
                               duration: choreography.introEnd + 4,
                               introEnd: choreography.introEnd)
            }
            #endif
        }
    }

    private var banner: some View {
        GeometryReader { geo in
            canvas
                .frame(width: BannerLayout.size.width, height: BannerLayout.size.height)
                .scaleEffect(geo.size.width / BannerLayout.size.width, anchor: .topLeading)
        }
        .aspectRatio(BannerLayout.size.width / BannerLayout.size.height, contentMode: .fit)
        .clipped()
        .contentShape(Rectangle())
        .onTapGesture(perform: replay)
    }

    @ViewBuilder private var canvas: some View {
        if reduceMotion {
            BannerCanvas(frame: choreography.frame(at: choreography.introEnd, idle: false),
                         choreography: choreography, showsConfetti: false, vegOnly: $vegOnly)
                .opacity(reducedOpacity)
                .onAppear(perform: fadeIn)
        } else {
            TimelineView(.animation(paused: scrubTime != nil)) { context in
                let t = scrubTime ?? context.date.timeIntervalSince(start)
                BannerCanvas(frame: choreography.frame(at: t), choreography: choreography,
                             showsConfetti: true, vegOnly: $vegOnly)
            }
        }
    }

    private func replay() {
        if reduceMotion {
            reducedOpacity = 0
            fadeIn()
        } else {
            scrubTime = nil
            start = Date()
        }
    }

    private func fadeIn() {
        withAnimation(.easeOut(duration: choreography.spec.reducedMotionFade)) { reducedOpacity = 1 }
    }
}

/// One rendered instant of the banner, in design points.
struct BannerCanvas: View {
    let frame: BannerFrame
    let choreography: Choreography
    let showsConfetti: Bool
    @Binding var vegOnly: Bool

    private typealias L = BannerLayout

    var body: some View {
        ZStack(alignment: .topLeading) {
            backdrop

            art
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Plenti turns one. Order and win a PS5 and more.")
                .accessibilityHint("Double-tap to replay the animation")
                .accessibilityAddTraits(.isButton)

            if showsConfetti {
                ConfettiBurst(spec: choreography.spec.confetti, particles: choreography.particles, time: frame.time)
            }

            Layer(rect: L.header, state: frame.header) {
                BannerHeader(vegOnly: $vegOnly)
            }
        }
        .frame(width: L.size.width, height: L.size.height)
    }

    /// Gradient, glow and the lighten-blended photo, flattened so the blend
    /// only sees the layers beneath it.
    private var backdrop: some View {
        ZStack(alignment: .topLeading) {
            L.backgroundGradient
            Layer(rect: L.glow, state: frame.glow) { image("banner_glow") }
            Layer(rect: L.background, state: frame.background) {
                // Sized to the banner's diagonal so the rotating rays never expose a corner.
                let cover = hypot(L.background.width, L.background.height)
                Image(banner: "banner_background").resizable().scaledToFill()
                    .frame(width: cover, height: cover)
                    .rotationEffect(.degrees(frame.raysRotation))
                    .frame(width: L.background.width, height: L.background.height)
                    .clipped()
                    .opacity(0.2)
            }
            .blendMode(.lighten)
        }
        .frame(width: L.size.width, height: L.size.height)
        .compositingGroup()
        .accessibilityHidden(true)
    }

    /// Decorative layers, bottom to top in Figma order (products moved inside the box).
    private var art: some View {
        ZStack(alignment: .topLeading) {
            giftBox

            Layer(rect: L.buntingRight, state: frame.buntingRight, anchor: .top) { image("banner_bunting_right") }
            Layer(rect: L.balloonsLeft, state: frame.balloonsLeft, anchor: .bottom) { image("banner_balloons_left") }
            Layer(rect: L.balloonsRight, state: frame.balloonsRight, anchor: .bottom) { image("banner_balloons_right") }
            ForEach(0..<3, id: \.self) { i in
                Layer(rect: L.logoRows[i], state: frame.logoRows[i]) { image("banner_logo_row_\(i + 1)") }
            }
            Layer(rect: L.buntingLeft, state: frame.buntingLeft, anchor: .top) { image("banner_bunting_left") }

            Layer(rect: L.title, state: frame.title) { image("banner_title") }
            Layer(rect: L.popper, state: frame.popper, anchor: .bottomLeading) {
                image("banner_popper").rotationEffect(.degrees(L.popperAngle))
            }
            Layer(rect: L.subtitle, state: frame.subtitle) { image("banner_subtitle") }
            Layer(rect: L.pill, state: frame.pill) { image("banner_more_pill") }
        }
        .frame(width: L.size.width, height: L.size.height)
    }

    /// Back → products → ribbon/lid/front, so products appear to pop out of the box.
    private var giftBox: some View {
        let box = frame.box
        return ZStack(alignment: .topLeading) {
            Layer(rect: L.boxBody, state: .rest) { image("banner_box_body") }

            ZStack(alignment: .topLeading) {
                Layer(rect: L.speaker, state: frame.speaker) {
                    image("banner_product_speaker").rotationEffect(.degrees(L.speakerAngle))
                }
                Layer(rect: L.ps5, state: frame.ps5, anchor: .bottom) { image("banner_product_ps5") }
                Layer(rect: L.headphones, state: frame.headphones) {
                    image("banner_product_headphones").rotationEffect(.degrees(L.headphonesAngle))
                }
            }
            .frame(width: L.size.width, height: L.size.height)
            .mask(alignment: .top) {
                Rectangle().frame(height: choreography.spec.productClipLine)
            }

            Layer(rect: L.boxRibbon, state: .rest) { image("banner_box_ribbon") }
            // Lid hinges near its left edge.
            Layer(rect: L.boxLid, state: frame.lid, anchor: UnitPoint(x: 0.08, y: 1)) { image("banner_box_lid") }
            Layer(rect: L.boxFront, state: .rest) { image("banner_box_front") }
        }
        .frame(width: L.size.width, height: L.size.height)
        .scaleEffect(x: max(box.scale, 0.001), y: max(box.scale * box.stretch, 0.001), anchor: L.boxPivot)
        .rotationEffect(.degrees(box.rotation), anchor: L.boxPivot)
        .offset(x: box.x, y: box.y)
        .opacity(min(max(box.opacity, 0), 1))
    }

    private func image(_ name: String) -> some View {
        Image(banner: name).resizable()
    }
}

#Preview("Banner") {
    PlentiBannerView(showsDebugScrubber: true)
        .padding(.vertical)
}
