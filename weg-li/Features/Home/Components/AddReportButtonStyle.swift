// Created for weg-li in 2021.

import SwiftUI

struct AddReportButtonStyle: ButtonStyle {
    let diameter: CGFloat = 70

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .font(.system(.largeTitle))
            .frame(width: diameter, height: diameter)
            .lineLimit(1)
            .background(configuration.isPressed ? Color.wegliBlue.opacity(0.85) : Color.wegliBlue)
            .clipShape(RoundedRectangle(cornerRadius: diameter / 2))
            .overlay(
                RoundedRectangle(cornerRadius: diameter / 2)
                    .stroke(Color.white, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 6, x: 3, y: 3)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

struct AddReportButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        Preview {
            Button(
                action: {}/*@END_MENU_TOKEN@*/,
                label: {
                    Text("+")
                }
            )
            .buttonStyle(AddReportButtonStyle())
        }
    }
}
