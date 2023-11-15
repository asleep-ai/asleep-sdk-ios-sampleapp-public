//  ConfigView.swift - Copyright 2023 Asleep

import SwiftUI

struct ConfigView: View {
    
    @Binding var apiKey: String
    @Binding var isDeveloperMode: Bool
    @Binding var isTracking: Bool
    @Binding var userId: String
    
    var body: some View  {
        HStack() {
            Text("Asleep SDK")
                .font(.title.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            Toggle("Dev Mode", isOn: $isDeveloperMode)
                .disabled(isTracking)
                .font(.body)
                .padding(.leading, 30)
        }
        
        Spacer()
        
        HStack() {
            Text("User ID: \(userId)")
                .font(.caption.bold())
            Spacer()
        }
    }
}

struct ConfigView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigView(apiKey: .constant("Enter Your API Key"),
                   isDeveloperMode: .constant(false),
                   isTracking: .constant(false),
                   userId: .constant(""))
    }
}
