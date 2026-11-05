import SwiftUI

/// A `Track` compiled into a SwiftUI `KeyframeTimeline` — the same engine that drives
/// `KeyframeAnimator` — so it can be sampled at any time (playback, replay and scrubbing).
struct CompiledTrack {
    private let timeline: KeyframeTimeline<LayerState>

    init(_ track: Track) {
        var segments: [(state: LayerState, duration: Double, spring: Spring)] = []
        var last = 0.0
        for beat in track.beats.sorted(by: { $0.at < $1.at }) {
            segments.append((beat.state, max(beat.at - last, 0.001), beat.spring))
            last = beat.at
        }
        timeline = KeyframeTimeline(initialValue: track.from) {
            KeyframeTrack(\.x) { for s in segments { SpringKeyframe(s.state.x, duration: s.duration, spring: s.spring) } }
            KeyframeTrack(\.y) { for s in segments { SpringKeyframe(s.state.y, duration: s.duration, spring: s.spring) } }
            KeyframeTrack(\.scale) { for s in segments { SpringKeyframe(s.state.scale, duration: s.duration, spring: s.spring) } }
            KeyframeTrack(\.stretch) { for s in segments { SpringKeyframe(s.state.stretch, duration: s.duration, spring: s.spring) } }
            KeyframeTrack(\.rotation) { for s in segments { SpringKeyframe(s.state.rotation, duration: s.duration, spring: s.spring) } }
            KeyframeTrack(\.opacity) { for s in segments { SpringKeyframe(s.state.opacity, duration: s.duration, spring: s.spring) } }
        }
    }

    func value(at t: Double) -> LayerState { timeline.value(time: t) }
}

/// Every layer's state for one instant of the banner.
struct BannerFrame {
    var time: Double
    var header = LayerState.rest, background = LayerState.rest, glow = LayerState.rest
    var logoRows = [LayerState](repeating: .rest, count: 3)
    var buntingLeft = LayerState.rest, buntingRight = LayerState.rest
    var balloonsLeft = LayerState.rest, balloonsRight = LayerState.rest
    var box = LayerState.rest, lid = LayerState.rest
    var speaker = LayerState.rest, ps5 = LayerState.rest, headphones = LayerState.rest
    var title = LayerState.rest, subtitle = LayerState.rest, popper = LayerState.rest, pill = LayerState.rest
    /// Degrees; the sunburst photo turns continuously behind everything.
    var raysRotation: Double = 0
}

struct Choreography {
    let spec: MotionSpec
    let particles: [ConfettiParticle]

    private let header, background, glow, buntingLeft, buntingRight, balloonsLeft, balloonsRight,
                box, lid, speaker, ps5, headphones, title, subtitle, popper, pill: CompiledTrack
    private let logoRows: [CompiledTrack]

    init(spec: MotionSpec) {
        self.spec = spec
        particles = ConfettiParticle.make(spec.confetti)
        header = .init(spec.header); background = .init(spec.background); glow = .init(spec.glow)
        logoRows = spec.logoRows.map(CompiledTrack.init)
        buntingLeft = .init(spec.buntingLeft); buntingRight = .init(spec.buntingRight)
        balloonsLeft = .init(spec.balloonsLeft); balloonsRight = .init(spec.balloonsRight)
        box = .init(spec.box); lid = .init(spec.lid)
        speaker = .init(spec.speaker); ps5 = .init(spec.ps5); headphones = .init(spec.headphones)
        title = .init(spec.title); subtitle = .init(spec.subtitle)
        popper = .init(spec.popper); pill = .init(spec.pill)
    }

    var introEnd: Double { spec.introEnd }

    func frame(at t: Double, idle idleEnabled: Bool = true) -> BannerFrame {
        let i = spec.idle
        let ramp = idleEnabled ? smoothstep((t - introEnd) / spec.idleRampIn) : 0
        func v(_ track: CompiledTrack, _ loop: IdleLoop = .none) -> LayerState {
            track.value(at: t).adding(loop, at: t - introEnd, amount: ramp)
        }

        var f = BannerFrame(time: t)
        f.header = v(header)
        f.background = v(background)
        f.glow = v(glow, i.glow)
        f.logoRows = zip(logoRows, i.logoRows).map { v($0, $1) }
        f.buntingLeft = v(buntingLeft, i.buntingLeft)
        f.buntingRight = v(buntingRight, i.buntingRight)
        f.balloonsLeft = v(balloonsLeft, i.balloonsLeft)
        f.balloonsRight = v(balloonsRight, i.balloonsRight)
        f.box = v(box)
        f.lid = v(lid)
        // Products are drawn inside the box group, so they inherit its rise and squash.
        f.speaker = v(speaker, i.speaker)
        f.ps5 = v(ps5, i.ps5)
        f.headphones = v(headphones, i.headphones)
        f.title = v(title, i.title)
        f.subtitle = v(subtitle)
        f.popper = v(popper, i.popper)
        f.pill = v(pill, i.pill)
        if idleEnabled, spec.raysRotationPeriod > 0 {
            f.raysRotation = (t / spec.raysRotationPeriod).truncatingRemainder(dividingBy: 1) * 360
        }
        return f
    }
}

private func smoothstep(_ x: Double) -> Double {
    let c = min(max(x, 0), 1)
    return c * c * (3 - 2 * c)
}

extension LayerState {
    func adding(_ loop: IdleLoop, at t: Double, amount: Double) -> LayerState {
        guard amount > 0 else { return self }
        let s = sin(2 * .pi * (t / loop.period + loop.phase)) * amount
        var r = self
        r.x += loop.dx * s
        r.y += loop.dy * s
        r.rotation += loop.rotation * s
        r.scale *= 1 + loop.scale * s
        return r
    }
}
