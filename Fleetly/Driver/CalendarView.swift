//
//  CalendarView.swift
//  historyTab
//
//  Created by Sayal Singh on 24/04/25.
// MARK:- Calendar.swift
import SwiftUI

/*struct CalendarView: View {
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

*/

import SwiftUI

struct CalendarView: View {
    @ObservedObject var viewModel: PastRidesViewModel
    @Environment(\.colorScheme) var colorScheme

    private let calendar = Calendar.current
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack {
            // Month navigation
            HStack {
                Button(action: {
                    viewModel.previousMonth()
                    print("Navigated to previous month: \(viewModel.monthString(from: viewModel.currentMonth))")
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                }

                Spacer()

                Text(viewModel.monthString(from: viewModel.currentMonth))
                    .font(.headline)

                Spacer()

                Button(action: {
                    viewModel.nextMonth()
                    print("Navigated to next month: \(viewModel.monthString(from: viewModel.currentMonth))")
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)

            // Weekday headers
            HStack {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 5)

            // Days grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(viewModel.daysInMonth().flatMap { $0 }, id: \.self) { date in
                    if let date = date {
                        ZStack {
                            Circle()
                                .fill(viewModel.selectedDate == date ? Color.blue : Color.clear)
                                .frame(width: 36, height: 36)

                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 16))
                                .foregroundColor(dateIsToday(date) ? .red : (viewModel.isDateInCurrentMonth(date) ? .primary : .gray))
                                .frame(width: 36, height: 36)

                            if viewModel.dayHasRides(date) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 12, y: 12)
                            }
                        }
                        .onTapGesture {
                            print("Tapped date: \(date)")
                            viewModel.updateSelectedDate(date)
                        }
                    } else {
                        Color.clear
                            .frame(width: 36, height: 36)
                    }
                }
            }
        }
        .padding()
    }

    private func dateIsToday(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: Date())
    }
}
