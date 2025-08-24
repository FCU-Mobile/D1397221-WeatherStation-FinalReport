import Foundation

class WeatherService {
    let indicator = "f0f54816d5e842a1a48121637250702"
    
    func fetchWeather(city: String, completion: @escaping (WeatherResponse?) -> Void) {
        // 修改 days=3 取得三天預報
        let urlStr = "https://api.weatherapi.com/v1/forecast.json?key=\(indicator)&q=\(city)&lang=zh_tw&days=3"
        guard let url = URL(string: urlStr) else { completion(nil); return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { completion(nil); return }
            let weather = try? JSONDecoder().decode(WeatherResponse.self, from: data)
            completion(weather)
        }.resume()
    }
}
