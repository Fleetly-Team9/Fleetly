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
    @State private var showVehicleSheet = false
    @State private var showPersonnelSheet = false
    
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
                
                VStack(spacing: 10) {
                    Form {
                        Section(header: Text("TASK DETAILS").font(.caption).foregroundColor(.gray)) {
                            HStack {
                                Text("Vehicle")
                                Spacer()
                                Button(action: { showVehicleSheet = true }) {
                                    Text(selectedVehicle.isEmpty ? "Select Vehicle" : selectedVehicle)
                                        .foregroundColor(selectedVehicle.isEmpty ? .gray : .blue)
                                }
                            }
                            
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
                            
                            HStack {
                                Text("Maintenance Personnel")
                                Spacer()
                                Button(action: { showPersonnelSheet = true }) {
                                    Text(selectedPersonnel.isEmpty ? "Select Personnel" : selectedPersonnel)
                                        .foregroundColor(selectedPersonnel.isEmpty ? .gray : .blue)
                                }
                            }
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
            .sheet(isPresented: $showVehicleSheet) {
                VehicleListView(selectedVehicle: $selectedVehicle)
                    .presentationDetents([.medium, .large])
                    .cornerRadius(30)
            }
            .sheet(isPresented: $showPersonnelSheet) {
                PersonnelListView(selectedPersonnel: $selectedPersonnel)
                    .presentationDetents([.medium, .large])
                    .cornerRadius(30)
            }
        }
    }
}

struct VehicleListView: View {
    @Binding var selectedVehicle: String
    @Environment(\.dismiss) var dismiss
    
    let vehicles = [
        ("Tata 407", "AP12XY9087"),
        ("Mahindra Supro Maxitruck", "MH01GH2312"),
        ("Mahindra Bolero Maxx", "MP14TR5432")
    ]
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Select Vehicle").font(.title2).bold()) {
                    ForEach(vehicles, id: \.1) { vehicle in
                        Button(action: {
                            selectedVehicle = vehicle.1
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "car.fill")
                                    .foregroundColor(.blue)
                                    .frame(width: 24, height: 24)
                                VStack(alignment: .leading) {
                                    Text(vehicle.0)
                                        .font(.headline)
                                    Text(vehicle.1)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
    }
}

struct PersonnelListView: View {
    @Binding var selectedPersonnel: String
    @Environment(\.dismiss) var dismiss
    
    let personnel = [
        ("John Doe", "ID: 96033893868"),
        ("Jane Smith", "ID: 7908523797"),
        ("Mike Johnson", "ID: 8609131313")
    ]
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Select Maintenance Personnel").font(.title2).bold()) {
                    ForEach(personnel, id: \.1) { person in
                        Button(action: {
                            selectedPersonnel = person.0
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.green) // Changed to green
                                    .frame(width: 24, height: 24)
                                VStack(alignment: .leading) {
                                    Text(person.0)
                                        .font(.headline)
                                    Text(person.1)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
    }
}

struct AssignTaskView_Previews: PreviewProvider {
    static var previews: some View {
        AssignTaskView()
    }
}
