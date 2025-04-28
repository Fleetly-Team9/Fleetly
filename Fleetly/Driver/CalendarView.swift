//
//  CalendarView.swift
//  historyTab
//
//  Created by Sayal Singh on 24/04/25.
// MARK:- Calendar.swift
import SwiftUI

struct CalendarView: View {
    @ObservedObject var viewModel: PastRidesViewModel
    @Environment(\.colorScheme) var colorScheme
    let weekDays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(viewModel.monthString(from: viewModel.currentMonth))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 20) {
                    Button(action: {
                        viewModel.previousMonth()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        viewModel.nextMonth()
                    }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal)
            
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)
            
            // Calendar grid
            VStack(spacing: 10) {
                ForEach(viewModel.daysInMonth(), id: \.self) { week in
                    HStack(spacing: 0) {
                        ForEach(0..<7, id: \.self) { index in
                            if let date = week[index] {
                                let day = Calendar.current.component(.day, from: date)
                                let isSelected = Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate)
                                let isToday = Calendar.current.isDateInToday(date)
                                
                                Button(action: {
                                    viewModel.selectedDate = date
                                }) {
                                    Text("\(day)")
                                        .font(.body)
                                        .foregroundColor(viewModel.isDateInCurrentMonth(date) ? .blue : .gray)
                                        .frame(width: 36, height: 36)
                                        .background(
                                            ZStack {
                                                if isSelected {
                                                    Circle()
                                                        .fill(Color.blue.opacity(0.3))
                                                }
                                                
                                                if viewModel.dayHasRides(date) && !isSelected {
                                                    Circle()
                                                        .fill(Color.blue.opacity(0.2))
                                                        .frame(width: 5, height: 5)
                                                        .offset(y: 12)
                                                }
                                            }
                                        )
                                }
                                .disabled(date > Date()) // Disable future dates
                                .opacity(date > Date() ? 0.5 : 1) // Make future dates translucent
                                .frame(maxWidth: .infinity)
                            } else {
                                Text("")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
        }
    }
}
