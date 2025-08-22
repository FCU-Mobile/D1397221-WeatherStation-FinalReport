import SwiftUI

struct ContentView: View {
    @State private var city = "Quickborn"
    @State private var weather: WeatherResponse?
    @State private var isLoading = false
    @State private var showFahrenheit = false
    @State private var shakeAngle: Double = 0
    @State private var isShaking = false
    @State private var showUVIcon = false
    @State private var showMoreInfo = false
    let service = WeatherService()
    
    // 將 WeatherAPI 圖標 URL 轉換為較大尺寸
    private func getLargerIconURL(from originalURL: String) -> String {
        var largerURL = originalURL
        if largerURL.hasPrefix("//") {
            largerURL = "https:" + largerURL
        }
        if largerURL.contains("64x64") {
            largerURL = largerURL.replacingOccurrences(of: "64x64", with: "128x128")
        }
        return largerURL
    }
    
    // 判斷是否為白天
    private var isDaytime: Bool {
        guard let weather = weather else { return true }
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")
        if let date = inputFormatter.date(from: weather.location.localtime) {
            let hour = Calendar.current.component(.hour, from: date)
            return hour >= 6 && hour < 18
        }
        return true
    }
    
    // 背景漸層
    private var backgroundGradient: LinearGradient {
        if weather == nil {
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0xf8/255.0, green: 0xfa/255.0, blue: 0xfc/255.0),
                    Color(red: 0xf8/255.0, green: 0xfa/255.0, blue: 0xfc/255.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isDaytime {
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0x8e/255.0, green: 0xc5/255.0, blue: 0xfc/255.0),
                    Color(red: 0xe0/255.0, green: 0xc3/255.0, blue: 0xfc/255.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0x0a/255.0, green: 0x2a/255.0, blue: 0x4a/255.0),
                    Color(red: 0x27/255.0, green: 0x08/255.0, blue: 0x45/255.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // 文字顏色
    private var textColor: Color {
        return weather == nil ? Color.black : Color.white
    }
    
    // UV分級顏色
    private func uvColor(for uv: Double) -> Color {
        switch uv {
        case 0..<3: return .green
        case 3..<6: return .yellow
        case 6..<8: return .orange
        case 8...:  return .red
        default:    return .gray
        }
    }
    
    var body: some View {
        ZStack {
            backgroundGradient.ignoresSafeArea()
            FlipView(
                isFlipped: $showMoreInfo,
                front: { mainInfoView },
                back: { moreInfoView }
            )
            .frame(width: 300)
        }
        .animation(.easeInOut(duration: 0.6), value: showMoreInfo)
    }
    
    // 主頁內容
    var mainInfoView: some View {
        VStack(spacing: 20) {
            TextField("輸入城市", text: $city)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("查詢天氣") {
                isLoading = true
                service.fetchWeather(city: city) { result in
                    DispatchQueue.main.async {
                        weather = result
                        isLoading = false
                        isShaking = false
                        shakeAngle = 0
                    }
                }
            }
            .padding()
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: textColor))
            }
            
            if let w = weather {
                HStack {
                    Image(systemName: "dot.scope")
                        .foregroundColor(textColor)
                    Text("\(w.location.name), \(w.location.country)")
                        .font(.system(size: 32, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.1)
                        .layoutPriority(1)
                        .foregroundColor(textColor)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
                LocalTimeView(localTime: w.location.localtime, textColor: textColor)
                Text("目前天氣：\(w.current.condition.text)")
                    .foregroundColor(textColor)
                Text("溫度：\(showFahrenheit ? (w.current.temp_c * 9/5 + 32) : w.current.temp_c, specifier: "%.1f")\(showFahrenheit ? "°F" : "°C")")
                    .foregroundColor(textColor)
                    .onTapGesture {
                        showFahrenheit.toggle()
                    }
                Text("濕度：\(w.current.humidity)%")
                    .foregroundColor(textColor)
                
                if showUVIcon {
                    HStack(spacing: 8) {
                        Text("紫外線指數：")
                            .foregroundColor(textColor)
                        UVIndexIcon(color: uvColor(for: w.current.uv))
                    }
                    .onTapGesture { showUVIcon.toggle() }
                } else {
                    Text("紫外線指數：\(w.current.uv == 0 ? "0" : String(format: "%.1f", w.current.uv))")
                        .foregroundColor(textColor)
                        .onTapGesture { showUVIcon.toggle() }
                }
                
                AsyncImage(url: URL(string: getLargerIconURL(from: w.current.condition.icon))) { image in
                    image
                        .resizable()
                        .frame(width: 128, height: 128)
                        .rotationEffect(.degrees(shakeAngle))
                        .onAppear {
                            startShaking()
                        }
                } placeholder: {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                }
                .id(w.current.condition.icon)
                
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.9),
                        Color.white.opacity(0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 1)
                .padding(.vertical, 20)
                
                Button("更多資訊") {
                    withAnimation {
                        showMoreInfo = true
                    }
                }
            }
        }
        .padding()
    }
    
    // 第二頁內容
    var moreInfoView: some View {
        VStack(spacing: 24) {
            Text("更多天氣資訊")
                .font(.title)
                .foregroundColor(textColor)
            if let w = weather {
                Text("風速：\(w.current.wind_kph, specifier: "%.1f") kph")
                    .foregroundColor(textColor)
                let rainMM = w.forecast?.forecastday.first?.day.totalprecip_mm ?? w.current.precip_mm ?? 0
                Text("雨量：\(rainMM, specifier: "%.1f") mm")
                    .foregroundColor(textColor)
                Text("風向：\(w.current.wind_dir)")
                    .foregroundColor(textColor)
                if let feelslike = w.current.feelslike_c {
                    Text("體感溫度：\(feelslike, specifier: "%.1f")°C")
                        .foregroundColor(textColor)
                }
                if let astro = w.forecast?.forecastday.first?.astro {
                    Text("日出：\(astro.sunrise)")
                        .foregroundColor(textColor)
                    Text("日落：\(astro.sunset)")
                        .foregroundColor(textColor)
                }
            }
            Button("返回") {
                withAnimation {
                    showMoreInfo = false
                }
            }
        }
        .padding()
    }
    
    // 搖動動畫
    func startShaking() {
        shakeAngle = -18
        if !isShaking {
            isShaking = true
            withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                shakeAngle = 18
            }
        }
    }
}

// 卡片翻轉效果元件
struct FlipView<Front: View, Back: View>: View {
    @Binding var isFlipped: Bool
    let front: () -> Front
    let back: () -> Back
    
    var body: some View {
        ZStack {
            front()
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            back()
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
    }
}

#Preview {
    ContentView()
}
