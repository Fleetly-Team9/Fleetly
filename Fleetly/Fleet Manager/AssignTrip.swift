
import SwiftUI
import MapKit// AssignTripView.swift
struct AssignView: View {
    @State private var fromLocation = ""
    @State private var toLocation = ""
    @ObservedObject var viewModel = LocationSearchViewModel()
    @State private var journeyDate = Date()
    @State private var passengers = 1
    @State private var selectedVehicle: Vehicle1?
    @State private var showVehicleSheet = false
    @State private var showDriverSheet = false
    @State private var selectedDriver: Driver1?
    @State private var journeyTime = Date()
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Journey Details").font(.headline)) {
                    // From Location
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                            .foregroundColor(.blue)
                            .frame(width: 24, height: 24)
                        TextField("From Location", text: $fromLocation)
                            .padding(.vertical, 10)
                            .onChange(of: fromLocation) { newValue in
                                viewModel.searchForLocations(newValue, isFrom: true)
                            }
                    }
                    .padding(.vertical, 4)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    
                    // Suggestions for From Location
                    if !viewModel.fromSearchResults.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(viewModel.fromSearchResults, id: \.self) { result in
                                Button(action: {
                                    viewModel.selectLocation(result, isPickup: true)
                                    fromLocation = result.title
                                    viewModel.fromSearchResults = [] // Clear from suggestions
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "mappin.and.ellipse")
                                            .foregroundColor(.blue)
                                            .frame(width: 24, height: 24)
                                            .padding(.trailing, 4)
                                        
                                        Text(result.title)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(Color(.systemBackground))
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Divider()
                                    .padding(.leading, 44)
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .animation(.easeInOut(duration: 0.25), value: viewModel.fromSearchResults)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // To Location
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.circle")
                            .foregroundColor(.blue)
                            .frame(width: 24, height: 24)
                        TextField("To Location", text: $toLocation)
                            .padding(.vertical, 10)
                            .onChange(of: toLocation) { newValue in
                                viewModel.searchForLocations(newValue, isFrom: false)
                            }
                    }
                    .padding(.vertical, 4)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    
                    // Suggestions for To Location
                    if !viewModel.toSearchResults.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(viewModel.toSearchResults, id: \.self) { result in
                                Button(action: {
                                    viewModel.selectLocation(result, isPickup: false)
                                    toLocation = result.title
                                    viewModel.toSearchResults = [] // Clear to suggestions
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "mappin.and.ellipse")
                                            .foregroundColor(.green)
                                            .frame(width: 24, height: 24)
                                            .padding(.trailing, 4)
                                        
                                        Text(result.title)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(Color(.systemBackground))
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Divider()
                                    .padding(.leading, 44)
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .animation(.easeInOut(duration: 0.25), value: viewModel.toSearchResults)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Date of Journey
                    HStack(spacing: 12) {
                        Image(systemName: "calendar.circle.fill")
                            .foregroundColor(.blue)
                            .frame(width: 24, height: 24)
                        DatePicker(
                            "Date of Journey",
                            selection: $journeyDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.compact)
                    }
                    .padding(.vertical, 4)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    
                    // Time of Journey
                    HStack(spacing: 12) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                            .frame(width: 24, height: 24)
                        DatePicker(
                            "Time of Journey",
                            selection: $journeyTime,
                            displayedComponents: [.hourAndMinute]
                        )
                        .datePickerStyle(.compact)
                    }
                    .padding(.vertical, 4)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                
                Section(header: Text("Passengers").font(.subheadline)) {
                    HStack {
                        Image(systemName: "person.2.fill")
                        Stepper(value: $passengers, in: 1...10) {
                            Text("Passengers: \(passengers)")
                        }
                    }
                }
                
                Section(header: Text("Assignments").font(.headline)) {
                    HStack {
                        Image(systemName: "car.fill")
                        Button(action: { showVehicleSheet = true }) {
                            Text(selectedVehicle?.model ?? "Not Assigned")
                                .foregroundStyle(.primary)
                        }
                    }
                    HStack {
                        Image(systemName: "person.fill")
                        Button(action: { showDriverSheet = true }) {
                            Text("\(selectedDriver?.firstName ?? "Not Assigned") \(selectedDriver?.lastName ?? "")")
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { /* Action */ }) {
                        Text("Assign")
                            .foregroundColor(.blue)
                            .font(.system(size: 17))
                    }
                }
            }
            .sheet(isPresented: $showVehicleSheet) {
                MockVehicleListView(selectedVehicle: $selectedVehicle)
                    .presentationDetents([.medium, .large])
                    .cornerRadius(30)
            }
            .sheet(isPresented: $showDriverSheet) {
                MockDriverListView(selectedDriver: $selectedDriver)
                    .presentationDetents([.medium, .large])
                    .cornerRadius(30)
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}
