import SwiftUI

// MARK: - Building blocks

/// Animatable transform for one layer, relative to its resting Figma placement.
/// `x`/`y` are in design points (390×422 space); `rotation` is in degrees.
public struct LayerState: Equatable, Sendable {
    public var x: Double = 0
    public var y: Double = 0
    public var scale: Double = 1
    /// Extra vertical scale multiplier, used for squash & stretch.
    public var stretch: Double = 1
    public var rotation: Double = 0
    public var opacity: Double = 1

    public init(x: Double = 0, y: Double = 0, scale: Double = 1, stretch: Double = 1,
                rotation: Double = 0, opacity: Double = 1) {
        self.x = x; self.y = y; self.scale = scale; self.stretch = stretch
        self.rotation = rotation; self.opacity = opacity
    }

    public static let rest = LayerState()
}

/// Reach `state` at absolute time `at` (seconds from intro start), driven by `spring`.
public struct Beat {
    public var at: Double
    public var state: LayerState
    public var spring: Spring

    public init(at: Double, _ state: LayerState, _ spring: Spring = MotionSpec.Springs.settle) {
        self.at = at; self.state = state; self.spring = spring
    }
}

/// A layer's intro choreography: a start state plus a sequence of beats.
public struct Track {
    public var from: LayerState
    public var beats: [Beat]

    public init(from: LayerState = .rest, beats: [Beat]) {
        self.from = from; self.beats = beats
    }

    /// Hold `from` until `start`, then spring to rest by `arrive`.
    public static func enter(from: LayerState, start: Double, arrive: Double,
                             spring: Spring = MotionSpec.Springs.settle) -> Track {
        Track(from: from, beats: [Beat(at: start, from, MotionSpec.Springs.hold),
                                  Beat(at: arrive, .rest, spring)])
    }

    /// Hold `from` until `start`, overshoot to `peak` at `peakAt`, then settle by `arrive`.
    public static func pop(from: LayerState, start: Double, peak: LayerState, peakAt: Double,
                           arrive: Double, settle: Spring = MotionSpec.Springs.pop) -> Track {
        Track(from: from, beats: [Beat(at: start, from, MotionSpec.Springs.hold),
                                  Beat(at: peakAt, peak, MotionSpec.Springs.snap),
                                  Beat(at: arrive, .rest, settle)])
    }

    public var end: Double { beats.map(\.at).max() ?? 0 }
}

/// Subtle post-intro loop. Keep travel ≤ 6pt and rotation ≤ 3°.
public struct IdleLoop: Sendable {
    public var period: Double
    public var dx: Double = 0
    public var dy: Double = 0
    public var rotation: Double = 0
    public var scale: Double = 0
    /// 0…1 fraction of a period, so neighbours don't move in lockstep.
    public var phase: Double = 0

    public init(period: Double, dx: Double = 0, dy: Double = 0, rotation: Double = 0,
                scale: Double = 0, phase: Double = 0) {
        self.period = period; self.dx = dx; self.dy = dy; self.rotation = rotation
        self.scale = scale; self.phase = phase
    }

    public static let none = IdleLoop(period: 1)
}

public struct ConfettiSpec {
    public var at: Double = 1.0
    public var count: Int = 40
    /// Burst origin in design points (mouth of the gift box).
    public var origin = CGPoint(x: 195, y: 392)
    public var lifetime: Double = 1.8
    public var speed: ClosedRange<Double> = 420...680
    /// Cone around straight up, in degrees either side.
    public var spread: Double = 62
    public var gravity: Double = 620
    /// Exponential air drag on the launch velocity (1/s).
    public var drag: Double = 1.2
    public var size: ClosedRange<Double> = 5...9
    public var fadeFraction: Double = 0.4
    public var seed: UInt64 = 0x9E3779B97F4A7C15
    public var palette: [Color] = [
        Color(hex: 0x923CF6), Color(hex: 0x5F22D9), Color(hex: 0x34C759), Color(hex: 0x098A44),
        Color(hex: 0xFFC93C), Color(hex: 0xFF5FA2), Color(hex: 0xFF8A3D), .white,
    ]
}

// MARK: - The spec

/// Every timing, offset and spring for the banner lives here.
/// Times are absolute seconds from the start of the intro.
public struct MotionSpec {
    public enum Springs {
        public static let hold   = Spring(duration: 0.3, bounce: 0)
        public static let soft   = Spring(duration: 0.6, bounce: 0)
        public static let settle = Spring(duration: 0.5, bounce: 0.25)
        public static let pop    = Spring(duration: 0.45, bounce: 0.45)
        public static let snap   = Spring(duration: 0.28, bounce: 0)
        public static let float  = Spring(duration: 0.75, bounce: 0.35)
    }

    // Scene
    public var header       = Track.enter(from: .init(y: -12, opacity: 0), start: 0.05, arrive: 0.5, spring: Springs.soft)
    public var background   = Track.enter(from: .init(scale: 1.08, opacity: 0), start: 0, arrive: 0.55, spring: Springs.soft)
    public var logoRows: [Track] = (0..<3).map { i in
        Track.enter(from: .init(y: 18, opacity: 0), start: 0.05 + 0.08 * Double(i),
                    arrive: 0.6 + 0.08 * Double(i), spring: Springs.soft)
    }
    public var glow = Track(from: .init(scale: 0.3, opacity: 0), beats: [
        Beat(at: 0.85, .init(scale: 0.3, opacity: 0), Springs.hold),
        Beat(at: 1.1, .init(scale: 1.3, opacity: 1), Springs.snap),
        Beat(at: 1.5, .rest, Springs.settle),
    ])

    // Decorations
    public var buntingLeft    = Track.enter(from: .init(y: -95, rotation: -6), start: 0.12, arrive: 0.62, spring: Springs.pop)
    public var buntingRight   = Track.enter(from: .init(y: -70, rotation: 6), start: 0.2, arrive: 0.7, spring: Springs.pop)
    public var balloonsLeft   = Track.enter(from: .init(y: 140, rotation: -8), start: 0.25, arrive: 1.0, spring: Springs.float)
    public var balloonsRight  = Track.enter(from: .init(y: 150, rotation: 8), start: 0.32, arrive: 1.08, spring: Springs.float)

    // Gift box: rises, lands with a squash, then the lid pops.
    public var box = Track(from: .init(y: 110), beats: [
        Beat(at: 0.2, .init(y: 110), Springs.hold),
        Beat(at: 0.68, .rest, Springs.settle),
        Beat(at: 0.78, .init(scale: 1.04, stretch: 0.9), Springs.snap),
        Beat(at: 0.95, .rest, Springs.pop),
    ])
    public var lid = Track(beats: [
        Beat(at: 0.9, .rest, Springs.hold),
        Beat(at: 1.02, .init(y: -30, rotation: -14), Springs.snap),
        Beat(at: 1.22, .init(y: -30, rotation: -14), Springs.hold),
        Beat(at: 1.6, .rest, Springs.pop),
    ])

    // Products emerge from inside the box, staggered.
    public var speaker    = Track.pop(from: .init(y: 95, scale: 0.6, rotation: 20), start: 0.98,
                                      peak: .init(y: -10, scale: 1.06, rotation: -4), peakAt: 1.4, arrive: 1.72)
    public var ps5        = Track.pop(from: .init(y: 110, scale: 0.7), start: 1.05,
                                      peak: .init(y: -14, scale: 1.05), peakAt: 1.47, arrive: 1.8)
    public var headphones = Track.pop(from: .init(y: 95, scale: 0.6, rotation: -20), start: 1.12,
                                      peak: .init(y: -10, scale: 1.06, rotation: 6), peakAt: 1.54, arrive: 1.86)
    /// Products are clipped at the box mouth (box-local design Y): the box face in
    /// the body artwork sits below this line, so products never draw over it.
    public var productClipLine: Double = 409.3

    // Copy
    public var title    = Track.pop(from: .init(scale: 0.2, opacity: 0), start: 1.15,
                                    peak: .init(scale: 1.12), peakAt: 1.48, arrive: 1.82)
    public var subtitle = Track.enter(from: .init(y: 10, opacity: 0), start: 1.45, arrive: 1.9, spring: Springs.soft)
    public var popper   = Track.pop(from: .init(scale: 0.01, rotation: -40), start: 1.6,
                                    peak: .init(scale: 1.2, rotation: 8), peakAt: 1.88, arrive: 2.15)
    public var pill     = Track.pop(from: .init(scale: 1.8, rotation: -20, opacity: 0), start: 1.75,
                                    peak: .init(scale: 0.92, rotation: 4), peakAt: 1.95, arrive: 2.28)

    public var confetti = ConfettiSpec()

    // Idle loops (start after the intro, ramped in). Periods are deliberately coprime-ish.
    public var idleRampIn: Double = 0.8
    public var idle = Idle()
    /// Seconds per full turn of the background light rays (runs from t = 0; 0 disables).
    public var raysRotationPeriod: Double = 120

    public struct Idle {
        public var glow          = IdleLoop(period: 5.3, scale: 0.06)
        public var logoRows      = [IdleLoop(period: 6.1, dx: 4),
                                    IdleLoop(period: 6.7, dx: -4, phase: 0.3),
                                    IdleLoop(period: 7.3, dx: 4, phase: 0.6)]
        public var buntingLeft   = IdleLoop(period: 3.1, rotation: 2)
        public var buntingRight  = IdleLoop(period: 3.7, rotation: -2.4, phase: 0.25)
        public var balloonsLeft  = IdleLoop(period: 4.3, dy: -6, rotation: 2)
        public var balloonsRight = IdleLoop(period: 3.9, dy: -5, rotation: -2.5, phase: 0.4)
        public var speaker       = IdleLoop(period: 2.6, dy: -4, rotation: 2)
        public var ps5           = IdleLoop(period: 3.3, dy: -3, rotation: 1, phase: 0.35)
        public var headphones    = IdleLoop(period: 2.9, dy: -4, rotation: -2.5, phase: 0.7)
        // The headline lock-up (title, subtitle, popper, pill) holds still after the intro.
        public var title         = IdleLoop.none
        public var popper        = IdleLoop.none
        public var pill          = IdleLoop.none
        public init() {}
    }

    /// Reduce Motion: cross-fade duration to the composed state.
    public var reducedMotionFade: Double = 0.35

    public init() {}

    var allTracks: [Track] {
        [header, background, glow, buntingLeft, buntingRight, balloonsLeft, balloonsRight, box, lid,
         speaker, ps5, headphones, title, subtitle, popper, pill] + logoRows
    }

    /// When the last intro beat lands; idle loops start here.
    public var introEnd: Double { allTracks.map(\.end).max() ?? 0 }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}
