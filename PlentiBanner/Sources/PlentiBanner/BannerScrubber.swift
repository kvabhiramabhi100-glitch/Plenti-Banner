#if DEBUG
import SwiftUI

/// Debug-only timeline controls: pause, frame-step, and drag through the intro.
struct BannerScrubber: View {
    @Binding var start: Date
    @Binding var scrubTime: Double?
    let duration: Double
    let introEnd: Double

    private let step = 1.0 / 60

    var body: some View {
        TimelineView(.animation(paused: scrubTime != nil)) { context in
            let t = scrubTime ?? context.date.timeIntervalSince(start)
            VStack(spacing: 6) {
                HStack(spacing: 12) {
                    Button(scrubTime == nil ? "Pause" : "Play") {
                        if let paused = scrubTime {
                            start = Date().addingTimeInterval(-paused)
                            scrubTime = nil
                        } else {
                            scrubTime = t
                        }
                    }
                    Button("−1f") { scrubTime = max(0, t - step) }
                    Button("+1f") { scrubTime = min(duration, t + step) }
                    Button("Intro end") { scrubTime = introEnd }
                    Spacer()
                    Text(String(format: "%.3fs", t))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(t > introEnd ? Color.secondary : Color.primary)
                }
                .font(.caption.weight(.semibold))

                Slider(value: Binding(get: { min(t, duration) },
                                      set: { scrubTime = $0 }),
                       in: 0...duration)
            }
            .padding(.horizontal)
        }
    }
}
#endif
