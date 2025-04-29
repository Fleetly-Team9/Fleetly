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
    
    // Define the minimum date and time (current date and time)
    private var minimumDate: Date {
        return Date()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color(.systemGray6).opacity(0.8), Color(.systemBackground)]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 10) {
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
                            
                            // Date Picker with restriction to present/future dates
                            DatePicker("Expected Completion Date", selection: $completionDate, in: minimumDate..., displayedComponents: [.date])
                                .datePickerStyle(.compact)
                            
                            // Time Picker with restriction to present/future times
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
                    }
                    .frame(maxHeight: .infinity)
                    
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
                    
                    Spacer()
                }
            }
            .navigationTitle("Assign Task")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct AssignTaskView_Previews: PreviewProvider {
    static var previews: some View {
        AssignTaskView()
    }
}
