//
//  AuthTextFieldStyle.swift
//  InterviewSim
//
//  Created by Ammar Sufyan on 23/06/25.
//

import SwiftUI

struct AuthTextFieldStyle: TextFieldStyle {
    let isValid: Bool
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.subheadline)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isValid ? Color.clear : Color.red.opacity(0.5),
                        lineWidth: 1
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isValid)
    }
}

#Preview {
    VStack(spacing: 16) {
        TextField("Valid field", text: .constant("test@example.com"))
            .textFieldStyle(AuthTextFieldStyle(isValid: true))
        
        TextField("Invalid field", text: .constant("invalid-email"))
            .textFieldStyle(AuthTextFieldStyle(isValid: false))
    }
    .padding()
}