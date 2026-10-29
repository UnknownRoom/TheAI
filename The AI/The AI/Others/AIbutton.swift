//
//  AIbutton.swift
//  The AI
//
//  Created by 梓墨 on 2026/3/12.
//

import SwiftUI

struct AIbutton: View {
    
    let title: String
    
    var body: some View {
        Text(title)
            .font(.title3)
            .fontWeight(.semibold)
            .frame(width: 300,height: 50)
            .foregroundStyle(Color.gray)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
