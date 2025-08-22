//
//  LocalTimeView.swift
//  MidtermReport
//
//  Created by Guest User on 2025/8/1.
//

import SwiftUI

struct LocalTimeView: View {
    let localTime: String // 來自 API，例如 "2025-08-01 21:02"
    let textColor: Color // 新增文字顏色參數

    var body: some View {
        Text("\(formatLocalTime(localTime))") // 當地時間
            .font(.system(size: 32, weight: .bold))
            .foregroundColor(textColor)
    }

    func formatLocalTime(_ localTime: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        inputFormatter.locale = Locale(identifier: "en_US_POSIX") // 保證格式解讀

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "hh:mma"
        outputFormatter.locale = Locale(identifier: "en_US_POSIX") // AM/PM

        if let date = inputFormatter.date(from: localTime) {
            return outputFormatter.string(from: date)
        } else {
            return localTime // 解析失敗就原樣顯示
        }
    }
}
