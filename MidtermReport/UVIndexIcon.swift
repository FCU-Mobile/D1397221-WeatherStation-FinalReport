//
//  UVIndexIcon.swift
//  MidtermReport
//
//  Created by Lulu Liao on 2025/8/1.
//

import SwiftUI

struct UVIndexIcon: View {
    let color: Color
    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 32, height: 32)
            Text("UV")
                .font(.caption)
                .foregroundColor(.white)
        }
    }
}
