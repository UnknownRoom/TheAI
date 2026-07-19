//
//  BandingView.swift
//  The AI
//
//  Created by 梓墨 on 2026/6/18.
//

import SwiftUI

struct BindingView: View {
    
  @StateObject var bandvm = BindViewModel()
    
    var body: some View {
        Form{
            GroupBox(label: Label("基础配置", systemImage: "key.fill")){
                TextField("BaseURL", text: $bandvm.BaseURL)
                TextField("APIKey",text: $bandvm.APIKey)
                TextField("Model Name", text:$bandvm.ModelName)
                    .autocorrectionDisabled(true)
                Button{
                    
                }label: {
                    Text("Save Changes")
                }
            }
            
        }
        .frame(width: 400,height: 500)
        .padding(6)
    }
}

