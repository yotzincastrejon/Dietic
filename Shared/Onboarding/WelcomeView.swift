//
//  WelcomeView.swift
//  Deficit2.0
//
//  Created by Yotzin Castrejon on 1/27/22.
//



import SwiftUI

struct WelcomeView: View {
    @Binding var showSheet: Bool
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack {
                Text("Welcome To\n Dietic")
                    .font(.largeTitle)
                    .bold()
                    .multilineTextAlignment(.center)
            }
            .padding()
            VStack(alignment: .leading) {
                IconAndLabel(image: "text.badge.checkmark", imageSize: .largeTitle, title: "Self-Solve", description: "Get helpful information to resolve your issue wherever you are.", color1: Color.green, color2: Color(uiColor: .systemGray3))
                
                IconAndLabel(image: "person.2.fill", imageSize: .title, title: "Get Support", description: "Get help from a real person by phone, chat, and more.", color1: Color.blue, color2: Color.cyan)
                
                IconAndLabel(image: "calendar", imageSize: .largeTitle, title: "Schedule a Repair", description: "Find  a genius Bar or Apple Authorized Service Provider near you.", color1: Color.red, color2: Color.gray)
                
            }
            .padding()
            Spacer()
            VStack {
                
                Text("Your Apple ID information and certain device identifiers will be used to authenticate you. Serial numbers associated with your Apple ID and entered into Check Coverage will be used to display Apple warranty status and eligibility for additional AppleCare coverage. [See how your data is managed...](https://apple.com)")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .frame(width: 340)
                    .padding()
                Button(action: {
                    showSheet.toggle()
                }) {
                    Text("Continue").bold()
                        .frame(width: 340, height: 50)
                        .foregroundColor(.white)
                        .background(Color.accentColor)
                        .cornerRadius(14)
                }
               
            }
            Spacer()
        }
        .interactiveDismissDisabled()
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WelcomeView(showSheet: Binding.constant(true))
            WelcomeView(showSheet: Binding.constant(true))
                .previewDevice("iPhone 8")
        }
    }
}

struct IconAndLabel: View {
    let image: String
    let imageSize: Font
    let title: String
    let description: String
    let color1: Color
    let color2: Color
    var body: some View {
        HStack {
            Image(systemName: image)
                .symbolRenderingMode(.palette)
                .foregroundStyle(color1, color2)
                .font(imageSize)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline).bold()
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
            }
        }
        .padding()
    }
}
