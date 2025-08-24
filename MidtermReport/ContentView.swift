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
    @State private var shakeKey = UUID()
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
    
    // 靜態背景漸層（非 weather==nil 時用）
    private var backgroundGradient: LinearGradient {
        if isDaytime {
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
    
    func weekdayString(from dateStr: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "zh_TW")
        guard let date = formatter.date(from: dateStr) else { return "" }
        let chineseWeekdays = ["星期日", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六"]
        let weekday = Calendar.current.component(.weekday, from: date)
        return chineseWeekdays[weekday-1]
    }
    
    var body: some View {
        ZStack {
            if weather == nil {
                // 呼叫SunMoonStarBackground程式
                SunMoonStarBackground()
            } else {
                backgroundGradient.ignoresSafeArea()
            }
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
                .offset(y: weather == nil ? -15 : 0)


            Button("查詢天氣") {
                isLoading = true
                service.fetchWeather(city: city) { result in
                    DispatchQueue.main.async {
                        weather = result
                        isLoading = false
                        isShaking = false
                        shakeAngle = -18   // 每次查詢直接重設
                        shakeKey = UUID()  // 觸發 AsyncImage 重新 onAppear
                    }
                }
            }
            .padding()
            .offset(y: weather == nil ? 10 : 0)
            
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
                
                // 氣溫圖示
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
                .id(shakeKey)   // 用唯一 key 強制刷新
                
                // --- 未來三日天氣預報 ---
                if let forecasts = w.forecast?.forecastday.prefix(3) {
                    VStack(spacing: 8) {
                        ForEach(Array(forecasts.enumerated()), id: \.element.date) { index, day in
                            HStack {
                                Text(weekdayString(from: day.date))
                                    .foregroundColor(textColor)
                                    .frame(width: 56, alignment: .leading)
                                AsyncImage(url: URL(string: "https:\(day.day.condition.icon)")) { image in
                                    image.resizable().frame(width: 32, height: 32)
                                } placeholder: {
                                    Image(systemName: "cloud")
                                        .resizable()
                                        .frame(width: 32, height: 32)
                                        .opacity(0.5)
                                }
                                Spacer()
                                // 這裡開始改
                                let minTemp = showFahrenheit ? (day.day.mintemp_c * 9/5 + 32) : day.day.mintemp_c
                                let maxTemp = showFahrenheit ? (day.day.maxtemp_c * 9/5 + 32) : day.day.maxtemp_c
                                let unit = showFahrenheit ? "°F" : "°C"
                                Text("\(Int(minTemp)) / \(Int(maxTemp))\(unit)")
                                    .foregroundColor(textColor)
                                    .frame(width: 80, alignment: .trailing) // 寬度略大一點比較保險
                                    .onTapGesture {
                                        showFahrenheit.toggle()
                                    }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                
                // --- 分隔線 ---
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
                let rainMM = w.forecast?.forecastday.first?.day.totalprecip_mm ?? w.current.precip_mm ?? 0
                let feelslikeC = w.current.feelslike_c ?? w.current.temp_c
                let feelslike = showFahrenheit ? (feelslikeC * 9/5 + 32) : feelslikeC
                let feelslikeUnit = showFahrenheit ? "°F" : "°C"
                let sunrise = w.forecast?.forecastday.first?.astro.sunrise ?? "--:--"
                let sunset = w.forecast?.forecastday.first?.astro.sunset ?? "--:--"
                // 六項資料組成 grid
                let infos: [(icon: String, value: String, label: String, tappable: Bool)] = [
                    ("wind", "\(String(format: "%.1f", w.current.wind_kph)) km/h", "風速", false),
                    ("umbrella.fill", "\(String(format: "%.1f", rainMM)) mm", "雨量", false),
                    ("s.circle.fill", w.current.wind_dir, "風向", false),
                    ("thermometer", "\(String(format: "%.1f", feelslike))\(feelslikeUnit)", "體感溫度", true),
                    ("sunrise.fill", sunrise, "日出時間", false),
                    ("sunset.fill", sunset, "日落", false)
                ]
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 22) {
                    ForEach(0..<infos.count, id: \.self) { i in
                        let info = infos[i]
                        WeatherInfoItem(icon: info.icon, value: info.value, label: info.label, textColor: textColor)
                            .onTapGesture {
                                if info.tappable {
                                    showFahrenheit.toggle()
                                }
                            }
                    }
                }
                .padding(.horizontal)
            }
            Button("返回") {
                withAnimation { showMoreInfo = false }
            }
        }
        .padding()
    }

    struct WeatherInfoItem: View {
        let icon: String
        let value: String
        let label: String
        let textColor: Color
        var body: some View {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(textColor)
                Text(value)
                    .font(.headline)
                    .foregroundColor(textColor)
                Text(label)
                    .font(.footnote)
                    .foregroundColor(textColor)
            }
            .frame(maxWidth: .infinity, minHeight: 55)
        }
    }
    
    // 搖動動畫
    func startShaking() {
        shakeAngle = -25
        if !isShaking {
            isShaking = true
            withAnimation(Animation.easeInOut(duration: 0.75).repeatForever(autoreverses: true)) {
                shakeAngle = 26
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
