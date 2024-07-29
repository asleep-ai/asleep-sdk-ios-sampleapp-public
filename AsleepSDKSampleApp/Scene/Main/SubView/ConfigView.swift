//  ConfigView.swift - Copyright 2023 Asleep

import SwiftUI

struct ConfigView: View {
    
    @Binding var apiKey: String
    @Binding var isTracking: Bool
    @Binding var userId: String
    
    var body: some View  {
        HStack() {
            Text("Asleep SDK")
                .font(.title.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
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
                   isTracking: .constant(false),
                   userId: .constant(""))
    }
}
