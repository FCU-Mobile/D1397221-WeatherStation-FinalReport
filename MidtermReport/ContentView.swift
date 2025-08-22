//
//  ContentView.swift
//  MidtermReport
//
//  Created by Lulu Liao on 2025/7/30.
//
import SwiftUI

struct ContentView: View {
    @State private var city = "Quickborn"
    @State private var weather: WeatherResponse?
    @State private var isLoading = false
    @State private var showFahrenheit = false
    @State private var shakeAngle: Double = 0
    @State private var isShaking = false
    @State private var showUVIcon = false
    let service = WeatherService()
    
    // 將 WeatherAPI 圖標 URL 轉換為較大尺寸
    private func getLargerIconURL(from originalURL: String) -> String {
        var largerURL = originalURL
        
        // 確保有 https 前綴
        if largerURL.hasPrefix("//") {
            largerURL = "https:" + largerURL
        }
        
        // 將 64x64 替換為 128x128 以獲得更清晰的圖標
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
            return hour >= 6 && hour < 18 // 6:00-17:59 為白天
        }
        return true
    }
    
    // 背景漸層
    private var backgroundGradient: LinearGradient {
        if weather == nil {
            // 還沒查詢時使用淺灰藍色背景
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0xf8/255.0, green: 0xfa/255.0, blue: 0xfc/255.0),
                    Color(red: 0xf8/255.0, green: 0xfa/255.0, blue: 0xfc/255.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isDaytime {
            // 白天背景
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0x8e/255.0, green: 0xc5/255.0, blue: 0xfc/255.0),
                    Color(red: 0xe0/255.0, green: 0xc3/255.0, blue: 0xfc/255.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // 晚上背景
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
        case 0..<3: return .green      // 0.0 ~ 2.999...
        case 3..<6: return .yellow     // 3.0 ~ 5.999...
        case 6..<8: return .orange     // 6.0 ~ 7.999...
        case 8...:  return .red        // 8.0 以上
        default:    return .gray
        }
    }
    
    var body: some View {
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
                        isShaking = false // 重新查詢時重置搖動
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
                
                LocalTimeView(localTime: w.location.localtime, textColor: textColor) // 傳入文字顏色
                
                Text("目前天氣：\(w.current.condition.text)")
                    .foregroundColor(textColor)
                
                Text("溫度：\(showFahrenheit ? (w.current.temp_c * 9/5 + 32) : w.current.temp_c, specifier: "%.1f")\(showFahrenheit ? "°F" : "°C")")
                    .foregroundColor(textColor)
                    .onTapGesture {
                        showFahrenheit.toggle()
                    }
                
                Text("濕度：\(w.current.humidity)%")
                    .foregroundColor(textColor)
                
                // 紫外線指數顯示與分級圖示
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
                        .frame(width: 128, height: 128) // 這裡設128
                        .rotationEffect(.degrees(shakeAngle))
                        .onAppear {
                            startShaking()
                        }
                } placeholder: {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                }
                .id(w.current.condition.icon)
                
                // 分隔線
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
                .padding(.vertical, 20) // 相當於 my-10
            }
        }
        .padding()
        .frame(width: 300)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundGradient)
        .animation(.easeInOut(duration: 0.5), value: weather?.location.localtime)
    }
    
    // 持續旋轉動畫
    func startShaking() {
        shakeAngle = -18        // 先移到 -18 度（動畫起點）
        if !isShaking {
            isShaking = true
            withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                shakeAngle = 18 // 動畫目標值設為 +18 度
            }
        }
    }
}

#Preview {
    ContentView()
}
