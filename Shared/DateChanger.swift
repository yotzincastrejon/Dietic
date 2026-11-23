//
//  DateChanger.swift
//  Deficit2.0
//
//  Created by Yotzin Castrejon on 10/20/21.
//

import SwiftUI

struct DateChanger: View {
    @ObservedObject var fastingManager: FastingManager
    var body: some View {
        HStack {
            Button(action: {
                fastingManager.moveDay(by: -1)
            }) {
                Image(systemName: "chevron.left")
                    .font(.subheadline)
                    .padding(.trailing, 10)

            }

            Image("Calender")
                .resizable()
                .renderingMode(.template)
                .foregroundColor(Color(uiColor: .label))
                .frame(width: 16, height: 16)
            Text(fastingManager.todaysDate.formatted(.dateTime.month().day()))
                .font(.subheadline).monospacedDigit()
                .frame(width: 60)

            Button(action: {
                fastingManager.moveDay(by: 1)
            }) {
                Image(systemName: "chevron.right")
                    .font(.subheadline)
            }
        }
    }
}

struct DateChanger_Previews: PreviewProvider {
    static var previews: some View {
        DateChanger(fastingManager: FastingManager())
//        Home(fastingManager: FastingManager())
    }
}
