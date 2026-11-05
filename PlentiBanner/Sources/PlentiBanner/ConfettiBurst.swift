import SwiftUI

/// One deterministic confetti piece. Position is a pure function of time,
/// so the burst can be scrubbed and replayed without any simulation state.
struct ConfettiParticle {
    var velocity: CGVector
    var size: CGSize
    var isCircle: Bool
    var colorIndex: Int
    var spin: Double        // rad/s
    var flutter: Double     // rad/s, paper "flip" around its long axis
    var phase: Double

    static func make(_ spec: ConfettiSpec) -> [ConfettiParticle] {
        var rng = SplitMix64(seed: spec.seed)
        return (0..<spec.count).map { _ in
            let angle = (-90 + Double.random(in: -spec.spread...spec.spread, using: &rng)) * .pi / 180
            let speed = Double.random(in: spec.speed, using: &rng)
            let side = Double.random(in: spec.size, using: &rng)
            let circle = Double.random(in: 0...1, using: &rng) < 0.3
            return ConfettiParticle(
                velocity: CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed),
                size: circle ? CGSize(width: side * 0.8, height: side * 0.8) : CGSize(width: side, height: side * 0.5),
                isCircle: circle,
                colorIndex: Int.random(in: 0..<max(spec.palette.count, 1), using: &rng),
                spin: Double.random(in: -9...9, using: &rng),
                flutter: Double.random(in: 6...14, using: &rng),
                phase: Double.random(in: 0...(2 * .pi), using: &rng))
        }
    }
}

/// Canvas-drawn burst in design coordinates. Draws nothing outside its lifetime.
struct ConfettiBurst: View {
    let spec: ConfettiSpec
    let particles: [ConfettiParticle]
    let time: Double

    var body: some View {
        let local = time - spec.at
        if local >= 0, local <= spec.lifetime, !spec.palette.isEmpty {
            Canvas { ctx, _ in
                let fadeStart = spec.lifetime * (1 - spec.fadeFraction)
                let alpha = local < fadeStart ? 1 : max(0, 1 - (local - fadeStart) / (spec.lifetime - fadeStart))
                // Air drag on the launch velocity, plain gravity on top.
                let travel = (1 - exp(-spec.drag * local)) / spec.drag
                for p in particles {
                    let x = spec.origin.x + p.velocity.dx * travel
                    let y = spec.origin.y + p.velocity.dy * travel + 0.5 * spec.gravity * local * local
                    var c = ctx
                    c.opacity = alpha
                    c.translateBy(x: x, y: y)
                    c.rotate(by: .radians(p.phase + p.spin * local))
                    c.scaleBy(x: 1, y: max(abs(cos(p.phase + p.flutter * local)), 0.15))
                    let r = CGRect(x: -p.size.width / 2, y: -p.size.height / 2, width: p.size.width, height: p.size.height)
                    let path = p.isCircle ? Path(ellipseIn: r) : Path(roundedRect: r, cornerRadius: 1)
                    c.fill(path, with: .color(spec.palette[p.colorIndex]))
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
