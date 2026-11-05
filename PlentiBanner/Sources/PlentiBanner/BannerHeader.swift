import SwiftUI

/// Location / wallet / avatar row and search row (Figma 3008:231), 357pt wide.
/// Uses the system font as a stand-in for Geist; swap in the brand font when bundled.
struct BannerHeader: View {
    var location = "4102  Pattom,Trivandrum"
    var walletBalance = "₹ 405"
    var onLocation: () -> Void = {}
    var onWallet: () -> Void = {}
    var onProfile: () -> Void = {}
    var onSearch: () -> Void = {}
    var onMic: () -> Void = {}
    @Binding var vegOnly: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 7) {
                VStack(alignment: .leading, spacing: 0) {
                    Button(action: onLocation) {
                        HStack(spacing: 3) {
                            Text("Current Location").font(.system(size: 14))
                            headerImage("icon_chevron_down").renderingMode(.template)
                                .resizable().frame(width: 20, height: 20)
                        }
                        .padding(.top, 10).padding(.bottom, 4).padding(.trailing, 10)
                    }
                    .padding(.bottom, -10)
                    Text(location)
                        .font(.system(size: 15, weight: .medium))
                        .lineLimit(1)
                        .padding(.vertical, 10).padding(.trailing, 10)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Current location, \(location)")
                .accessibilityAddTraits(.isButton)

                HStack(spacing: 16) {
                    Button(action: onWallet) { wallet }
                        .accessibilityLabel("Wallet balance \(walletBalance)")
                    Button(action: onProfile) { avatar }
                        .accessibilityLabel("Profile")
                }
            }
            .frame(height: 62)

            HStack(spacing: 0) {
                searchBar
                Spacer(minLength: 0)
                Button(action: onMic) {
                    headerImage("icon_mic").resizable().frame(width: 24, height: 24)
                        .frame(width: 58, height: 58)
                        .background(Circle().fill(.white))
                }
                .accessibilityLabel("Voice search")
            }
        }
        .buttonStyle(.plain)
        .frame(width: 357, height: 129, alignment: .topLeading)
    }

    private var wallet: some View {
        HStack(spacing: 2) {
            headerImage("header_coin").resizable().frame(width: 22, height: 22)
            Text(walletBalance)
                .font(.system(size: 11, weight: .bold))
                .tracking(-1)
                .foregroundStyle(.white)
        }
        .padding(.leading, 8).padding(.trailing, 11)
        .frame(height: 40)
        .background(
            Capsule().fill(headerColor(0x5F22D9))
                .overlay(InnerGlow(radius: 8.45, x: 0, y: -6))
                .overlay(InnerGlow(radius: 5.7, x: 5, y: 4))
        )
        .overlay(Capsule().strokeBorder(.white.opacity(0.1), lineWidth: 1))
    }

    private var avatar: some View {
        headerImage("header_avatar").resizable().scaledToFill()
            .frame(width: 40, height: 40)
            .background(headerColor(0xFFD4B8))
            .clipShape(Circle())
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Button(action: onSearch) {
                HStack(spacing: 10) {
                    headerImage("icon_search").resizable().frame(width: 20, height: 20)
                    Text("Restaurant name or a dish...")
                        .font(.system(size: 14))
                        .tracking(-0.42)
                        .foregroundStyle(headerColor(0x8A8F9C))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
            }
            .accessibilityLabel("Search restaurants or dishes")
            VegToggle(isOn: $vegOnly)
        }
        .padding(.leading, 14).padding(.trailing, 4)
        .frame(width: 286, height: 60)
        .background(Capsule().fill(.white))
        .overlay(Capsule().strokeBorder(headerColor(0xD2D2D2), lineWidth: 1))
        .clipShape(Capsule())
        .shadow(color: headerColor(0x120D26, opacity: 0.05), radius: 5, x: 0, y: 2)
    }
}

/// CSS-style inset shadow (`inset x y blur white/25%`) built from plain shapes, so it
/// compiles quickly and works on any deployment target (unlike `ShadowStyle.inner`).
/// `radius` is the Gaussian sigma, i.e. half the CSS blur value.
private struct InnerGlow: View {
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    var body: some View {
        CapsuleHole(margin: radius * 3 + max(abs(x), abs(y)))
            .fill(Color.white.opacity(0.25), style: FillStyle(eoFill: true))
            .offset(x: x, y: y)
            .blur(radius: radius)
            .mask(Capsule())
            .allowsHitTesting(false)
    }
}

/// Everything around a capsule: a padded rectangle with the capsule cut out.
private struct CapsuleHole: Shape {
    let margin: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path(rect.insetBy(dx: -margin, dy: -margin))
        path.addRoundedRect(in: rect, cornerSize: CGSize(width: rect.height / 2, height: rect.height / 2))
        return path
    }
}

private struct VegToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Button {
            withAnimation(.snappy(duration: 0.25)) { isOn.toggle() }
        } label: {
            VStack(spacing: 4) {
                Text("VEG")
                    .font(.system(size: 12, weight: .heavy).italic())
                    .tracking(-0.36)
                    .foregroundStyle(isOn ? headerColor(0x34C759) : headerColor(0x8A8F9C))
                ZStack(alignment: isOn ? .leading : .trailing) {
                    RoundedRectangle(cornerRadius: 1).fill(headerColor(0xF0F0F0))
                        .frame(width: 18, height: 6)
                    headerImage("icon_veg_knob").resizable()
                        .frame(width: 12, height: 12)
                        .frame(width: 10, height: 10)
                        .saturation(isOn ? 1 : 0)
                }
                .frame(width: 18, height: 10)
            }
            .padding(.horizontal, 10).padding(.vertical, 8)
            .background(Capsule().fill(.white))
            .overlay(Capsule().strokeBorder(headerColor(0xEDEDED), lineWidth: 1))
        }
        .accessibilityLabel("Veg only")
        .accessibilityValue(isOn ? "On" : "Off")
    }
}

// File-local helpers so this file compiles on its own, even when it is copied into an
// app target without the rest of the package (the shared `Color(hex:)` and
// `Image(banner:)` extensions are internal and invisible from another module).
private func headerColor(_ hex: UInt32, opacity: Double = 1) -> Color {
    Color(.sRGB,
          red: Double((hex >> 16) & 0xFF) / 255,
          green: Double((hex >> 8) & 0xFF) / 255,
          blue: Double(hex & 0xFF) / 255,
          opacity: opacity)
}

private func headerImage(_ name: String) -> Image {
    #if SWIFT_PACKAGE
    Image(name, bundle: .module)
    #else
    Image(name)
    #endif
}

