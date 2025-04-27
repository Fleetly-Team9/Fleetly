//
//  PastRideContentView.swift
//  historyTab
//
//  Created by Sayal Singh on 24/04/25.
//


// MARK: - PastRideContentView.swift
import SwiftUI

struct PastRideContentView: View {
    @StateObject private var viewModel = PastRidesViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Calendar View
                    CalendarView(viewModel: viewModel)
                        .padding(.vertical)
                        .background(colorScheme == .dark ? Color(UIColor.systemGray4) : Color.white)
                        .cornerRadius(12)
                        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                        .padding(.horizontal)
                    
                    // Rides List for selected date
                    VStack(spacing: 16) {
                        let filteredRides = viewModel.filteredRides(for: viewModel.selectedDate)
                        if filteredRides.isEmpty {
                            Text("No rides on this date")
                                .foregroundColor(.gray)
                                .padding(.top, 40)
                        } else {
                            ForEach(filteredRides) { ride in
                                NavigationLink(destination: RideDetailView(ride: ride)) {
                                    RideCard(ride: ride)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }
            .navigationBarTitle("Past Rides", displayMode: .large)
            .background(colorScheme == .dark ? Color(UIColor.systemBackground) : Color(UIColor.systemGray6))
            .edgesIgnoringSafeArea(.bottom)
        }
    }
}

// MARK: - Preview Provider
struct PastRideContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PastRideContentView()
                .previewDisplayName("Light Mode")
            
            PastRideContentView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}