import SwiftUI

struct AssignTaskView: View {
    @State private var selectedVehicle: String = ""
    @State private var selectedIssue: String = ""
    @State private var showOtherIssue: Bool = false
    @State private var otherIssueDescription: String = ""
    @State private var completionDate = Date()
    @State private var completionTime = Date()
    @State private var priority: String = "Medium"
    @State private var selectedPersonnel: String = ""
    
    let vehicleNumbers = ["KA12AH8879", "KA13BH9901", "KA14CJ1123"]
    let genericIssues = ["Engine Overheating", "Brake Failure", "Tire Puncture", "Oil Leak", "Other"]
    let priorities = ["High", "Medium", "Low"]
    let personnel = ["John Doe", "Jane Smith", "Mike Johnson"]
    
    private var minimumDate: Date {
        return Date()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color(.systemGray6).opacity(0.8), Color(.systemBackground)]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Task Details Sheet
                    Form {
                        Section(header: Text("TASK DETAILS").font(.caption).foregroundColor(.gray)) {
                            Picker("Vehicle", selection: $selectedVehicle) {
                                Text("Select Vehicle").tag("")
                                ForEach(vehicleNumbers, id: \.self) { vehicle in
                                    Text(vehicle).tag(vehicle)
                                }
                            }
                            .pickerStyle(.menu)
                            
                            Picker("Issue", selection: $selectedIssue) {
                                ForEach(genericIssues, id: \.self) { issue in
                                    Text(issue).tag(issue)
                                }
                            }
                            .pickerStyle(.menu)
                            .onChange(of: selectedIssue) { newValue in
                                withAnimation {
                                    showOtherIssue = (newValue == "Other")
                                }
                            }
                            
                            if showOtherIssue {
                                TextField("Other Issue Description", text: $otherIssueDescription)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            DatePicker("Expected Completion Date", selection: $completionDate, in: minimumDate..., displayedComponents: [.date])
                                .datePickerStyle(.compact)
                            
                            DatePicker("Expected Completion Time", selection: $completionTime, in: minimumDate..., displayedComponents: [.hourAndMinute])
                                .datePickerStyle(.compact)
                            
                            Picker("Priority", selection: $priority) {
                                ForEach(priorities, id: \.self) { priority in
                                    Text(priority).tag(priority)
                                }
                            }
                            .pickerStyle(.menu)
                            
                            Picker("Maintenance Personnel", selection: $selectedPersonnel) {
                                Text("Select Personnel").tag("")
                                ForEach(personnel, id: \.self) { person in
                                    Text(person).tag(person)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        .frame(maxHeight: 400)
                        
                        Spacer() // Spacer to create space between Form and Card
                        
                        // Independent Work Order Card
                        VStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGroupedBackground)) // Match Form background
                                    .shadow(radius: 4)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Work Order #\(Int.random(in: 1...100))")
                                            .font(.headline)
                                        Spacer()
                                        Text(selectedVehicle.isEmpty ? "N/A" : selectedVehicle)
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.top, 8)
                                    
                                    Text(selectedIssue == "Other" ? otherIssueDescription : (selectedIssue.isEmpty ? "N/A" : selectedIssue))
                                        .font(.subheadline)
                                    
                                    Text("Due: \(formattedDate(from: completionDate)) \(formattedTime(from: completionTime))")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    if !selectedIssue.isEmpty {
                                        Text("Issues: \(selectedIssue == "Other" ? otherIssueDescription : selectedIssue)")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                    
                                    HStack {
                                        Text("To Be Done")
                                            .font(.caption)
                                        Spacer()
                                        Text(priority.isEmpty ? "N/A" : priority)
                                            .font(.caption)
                                            .foregroundColor(.red)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(priorityColor(priority: priority))
                                            .cornerRadius(4)
                                    }
                                    
                                    Text("Assigned to: \(selectedPersonnel.isEmpty ? "N/A" : selectedPersonnel)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                            }
                            
                        }
                    }
                    // Spacer to create space between Card and Button
                    
                    // Independent Assign Button Section
                    VStack {
                        Button(action: {
                            let issue = showOtherIssue ? otherIssueDescription : selectedIssue
                            print("Assigned Task - Vehicle: \(selectedVehicle), Issue: \(issue), Completion Date: \(completionDate), Completion Time: \(completionTime), Priority: \(priority), Personnel: \(selectedPersonnel)")
                        }) {
                            Text("Assign")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .disabled(selectedVehicle.isEmpty || selectedPersonnel.isEmpty || (selectedIssue.isEmpty && otherIssueDescription.isEmpty) || (showOtherIssue && otherIssueDescription.isEmpty))
                        .opacity(selectedVehicle.isEmpty || selectedPersonnel.isEmpty || (selectedIssue.isEmpty && otherIssueDescription.isEmpty) || (showOtherIssue && otherIssueDescription.isEmpty) ? 0.5 : 1.0)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                    
                    Spacer() // Extra Spacer to push content up if needed
                }
            }
            .navigationTitle("Assign Task")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func formattedDate(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formattedTime(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func priorityColor(priority: String) -> Color {
        switch priority {
        case "High":
            return Color.red.opacity(0.1)
        case "Medium":
            return Color.yellow.opacity(0.1)
        case "Low":
            return Color.green.opacity(0.1)
        default:
            return Color.gray.opacity(0.1)
        }
    }
}

struct AssignTaskView_Previews: PreviewProvider {
    static var previews: some View {
        AssignTaskView()
    }
}
