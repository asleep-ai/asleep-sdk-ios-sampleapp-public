//  ConfigView.swift - Copyright 2023 Asleep

import SwiftUI

struct ConfigView: View {

    @Binding var apiKey: String
    @Binding var isTracking: Bool
    @Binding var userId: String
    var sessionId: String?
    var isLoading: Bool
    var onViewReport: (() -> Void)?

    var body: some View  {
        HStack() {
            Text("Asleep SDK")
                .font(.title.bold())

            Spacer()

            if !isTracking, let onViewReport = onViewReport {
                Button("View Report") {
                    onViewReport()
                }
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isLoading ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(isLoading)
            }
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
                   userId: .constant(""),
                   sessionId: "sample-session-id",
                   isLoading: false,
                   onViewReport: { print("View Report tapped") })
    }
}
