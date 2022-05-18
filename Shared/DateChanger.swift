//
//  DateChanger.swift
//  Deficit2.0
//
//  Created by Yotzin Castrejon on 10/20/21.
//

import SwiftUI

struct DateChanger: View {
    @ObservedObject var fastingManager: FastingManager
    @State var dateDay = 0
    var body: some View {
        HStack {
            Spacer()
            HStack {
                Button(action: {
                    dateDay -= 1
                    Task {
                        fastingManager.subtractDate()
                        await fastingManager.requestAuthorization()
                    }
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
//                Text(addingDate().formatted(.dateTime.month().day()))
//                    .font(.subheadline).monospacedDigit()
//                    .frame(width: 50)
                Text(fastingManager.todaysDate.formatted(.dateTime.month().day()))
                    .font(.subheadline).monospacedDigit()
                    .frame(width: 60)
                
                Button(action: {
                    dateDay += 1
                    Task {
                        fastingManager.addDate()
                        await fastingManager.requestAuthorization()
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                }
            }
        }
    }
    
    
    
    func addingDate() -> Date {
        let currentDate = Date()
        var dateComponent = DateComponents()
        
        dateComponent.day = dateDay
        
        let futureDate = Calendar.current.date(byAdding: dateComponent, to: currentDate)!
        return futureDate
    }
    
    
}

struct DateChanger_Previews: PreviewProvider {
    static var previews: some View {
        DateChanger(fastingManager: FastingManager())
        Home(fastingManager: FastingManager())
    }
}
