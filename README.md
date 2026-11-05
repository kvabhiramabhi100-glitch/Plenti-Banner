# Plenti Banner

Animated "Plenti turns one" home banner in SwiftUI (iOS 17+, macOS 14+).

- `PlentiBanner/`: Swift package with the banner view, its motion spec and its assets.
- `PlentiBannerDemo/`: a small iOS app that shows the banner.
- `PlentiBanner-preview.mp4`: a recording of the intro.

## Use

Add `PlentiBanner/` as a local package (File → Add Package Dependencies… → Add Local…), then:

```swift
import PlentiBanner

PlentiBannerView()
```

Tap the banner to replay the intro. All timings, springs and idle loops live in `MotionSpec`.
Pass `showsDebugScrubber: true` in debug builds to scrub through the animation.
With Reduce Motion on, the banner fades straight to its final state.
