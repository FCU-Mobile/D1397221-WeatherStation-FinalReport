import SwiftUI

struct SunMoonStarBackground: View {
    // 進度 0~1（0 = 日出, 0.5 = 日落, 1 = 隔天日出），這裡用 Timer 模擬一天循環
    @State private var progress: Double = 0.0
    // 星星亂數種子
    @State private var starSeed: UInt64 = 42

    let dayDuration: Double = 20 // 1天動畫時長（秒）

    var isDaytime: Bool {
        progress >= 0 && progress < 0.5
    }
    var isNight: Bool {
        !isDaytime
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 背景漸層（可替換成你的 AnimatedGradientBackground）
                LinearGradient(
                    gradient: Gradient(colors: isDaytime
                        ? [Color(red: 0xFF/255, green: 0xED/255, blue: 0xBC/255), Color(red: 0x8e/255, green: 0xc5/255, blue: 0xfc/255)]
                        : [Color(red: 0x0A/255, green: 0x2A/255, blue: 0x4A/255), Color(red: 0x27/255, green: 0x08/255, blue: 0x45/255)]
                    ),
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // 星星（夜晚出現，閃爍）
                if isNight {
                    StarField(width: geo.size.width, height: geo.size.height * 0.7, seed: starSeed, progress: progress)
                        .transition(.opacity)
                }

                // 太陽圓弧軌跡
                ArcTrack(progress: progress, color: .white.opacity(0.2))

                // 太陽或月亮
                if isDaytime {
                    SunView(progress: progress)
                } else {
                    MoonView(progress: progress)
                }
            }
            .onAppear {
                // 每隔0.05秒推進時間
                Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                    progress += 0.0018 // 這個數字控制速度，越大越快
                    if progress > 1.0 { progress = 0; starSeed += 1 }
                }
            }
        }
    }
}

// 軌跡圓弧
struct ArcTrack: View {
    let progress: Double
    let color: Color
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let radius = width * 0.38
            let centerY = height * 0.7
            Path { path in
                path.addArc(center: CGPoint(x: width/2, y: centerY),
                            radius: radius,
                            startAngle: .degrees(180),
                            endAngle: .degrees(0),
                            clockwise: false)
            }
            .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [6,8]))
        }
        .allowsHitTesting(false)
    }
}

// 太陽
struct SunView: View {
    let progress: Double
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let radius = width * 0.38
            let angle = Angle(degrees: 180 * progress * 2) // 0~0.5 -> 0~180°
            let centerY = height * 0.7
            let sunX = width/2 + cos(angle.radians - .pi) * radius
            let sunY = centerY + sin(angle.radians - .pi) * radius
            Circle()
                .fill(
                    RadialGradient(gradient: Gradient(colors: [.yellow.opacity(0.9), .orange.opacity(0.6), .clear]), center: .center, startRadius: 8, endRadius: 48)
                )
                .frame(width: 48, height: 48)
                .position(x: sunX, y: sunY)
                .shadow(color: .yellow.opacity(0.8), radius: 24)
        }
        .allowsHitTesting(false)
    }
}

// 月亮
struct MoonView: View {
    let progress: Double
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let radius = width * 0.38
            let nightProg = (progress - 0.5) * 2 // 0~1
            let angle = Angle(degrees: 180 * nightProg)
            let centerY = height * 0.7
            let moonX = width/2 + cos(angle.radians - .pi) * radius
            let moonY = centerY + sin(angle.radians - .pi) * radius
            Image(systemName: "moon.stars.fill")
                .resizable()
                .foregroundColor(.white)
                .frame(width: 38, height: 38)
                .position(x: moonX, y: moonY)
                .shadow(color: .white.opacity(0.5), radius: 10)
        }
        .allowsHitTesting(false)
    }
}

// 星星場景
struct StarField: View {
    let width: CGFloat
    let height: CGFloat
    let seed: UInt64
    let progress: Double
    
    var body: some View {
        let starCount = 100
        ForEach(0..<starCount, id: \.self) { idx in
            var rng = SeededRandomNumberGenerator(seed: seed + UInt64(idx*17))
            let x = CGFloat.random(in: 0...width, using: &rng)
            let y = CGFloat.random(in: 0...height, using: &rng)
            let size = CGFloat.random(in: 1.2...2.9, using: &rng)
            let baseOpacity = Double.random(in: 0.5...0.95, using: &rng)
            let twinkle = 0.65 + 0.3 * sin(progress*6 + Double(idx))
            Circle()
                .fill(Color.white.opacity(baseOpacity * twinkle))
                .frame(width: size, height: size)
                .position(x: x, y: y)
        }
    }
}

// 可重現亂數
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var rng: UInt64
    init(seed: UInt64) { self.rng = seed }
    mutating func next() -> UInt64 {
        rng ^= rng >> 12; rng ^= rng << 25; rng ^= rng >> 27
        return rng &* 2685821657736338717
    }
}
