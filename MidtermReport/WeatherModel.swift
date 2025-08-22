//
//  WeatherResponse.swift
//  MidtermReport
//
//  Created by Lulu Liao on 2025/7/30.
//

import Foundation

struct WeatherResponse: Codable {
    let location: Location
    let current: Current
    let forecast: Forecast? // 新增: 預報資料
}

struct Location: Codable {
    let name: String
    let country: String
    let localtime: String
}

struct Current: Codable {
    let temp_c: Double
    let condition: Condition
    let humidity: Int
    let uv: Double
    let wind_kph: Double
    let wind_dir: String
    let vis_km: Double
    let precip_mm: Double?
    let feelslike_c: Double?
}

struct Condition: Codable {
    let text: String
    let icon: String
}

// 以下為預報用 struct
struct Forecast: Codable {
    let forecastday: [ForecastDay]
}

struct ForecastDay: Codable {
    let date: String
    let day: ForecastDayDetail
    let astro: Astro
}

struct ForecastDayDetail: Codable {
    let totalprecip_mm: Double
}

struct Astro: Codable {
    let sunrise: String
    let sunset: String
}
