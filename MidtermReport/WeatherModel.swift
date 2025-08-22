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
}

struct Location: Codable {
    let name: String
    let country: String
    let localtime: String // <--- 新增
}

struct Current: Codable {
    let temp_c: Double
    let condition: Condition
    let humidity: Int      // ← 加上濕度
    let uv: Double         // ← 加上uv
}

struct Condition: Codable {
    let text: String
    let icon: String
}
