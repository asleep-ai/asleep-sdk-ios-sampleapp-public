//  ConfigView.swift - Copyright 2023 Asleep

import SwiftUI

struct ConfigView: View {
    
    @Binding var apiKey: String
    @Binding var userId: String
    
    var body: some View  {
        Text("Asleep SDK Sample App")
            .font(.title.bold())
            .frame(maxWidth: .infinity, alignment: .leading)
        
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
                   userId: .constant(""))
    }
}
