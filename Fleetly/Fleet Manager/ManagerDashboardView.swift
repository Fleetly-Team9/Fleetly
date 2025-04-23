import SwiftUI
import Charts

// Main Tab View
struct MainTabView: View {
    @ObservedObject var authVM: AuthViewModel
    var body: some View {
        TabView {
            DashboardHomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

            DriverManagerView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Personnel")
                }

            VehicleManagementView()
                .tabItem {
                    Image(systemName: "car.2.fill")
                    Text("Vehicles")
                }
        }
    }
}

// Dashboard Home View
struct DashboardHomeView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // MARK: - Stat Cards Grid
                    let columns = [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ]

                    LazyVGrid(columns: columns, spacing: 16) {
                        StatCardGridView(icon: "car.fill", title: "Total Vehicles", value: "120", color: .blue)
                        StatCardGridView(icon: "location.fill", title: "Active Trips", value: "24", color: .green)
                        StatCardGridView(icon: "wrench.fill", title: "Maintenance", value: "12", color: .orange)
                        StatCardGridView(icon: "exclamationmark.triangle.fill", title: "Alerts", value: "5", color: .red)
                    }
                    .padding(.horizontal)

                    // MARK: - Quick Actions
                    VStack(alignment: .center, spacing: 8) {
                        Text("Quick Actions")
                            .font(.headline)
                            .padding(.horizontal)

                        HStack(spacing: 20) {
                            QuickActionButton(icon: "person.fill.badge.plus", title: "Assign")
                            QuickActionButton(icon: "calendar.badge.clock", title: "Maintain")
                            QuickActionButton(icon: "doc.text.magnifyingglass", title: "Reports")
                            QuickActionButton(icon: "map.fill", title: "Track")
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(30)
                    .shadow(radius: 4)
                    .padding(.horizontal)

                    // MARK: - Analytics and Alerts
                    VStack(alignment: .leading, spacing: 16) {
                        // Chart Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Performance Overview")
                                .font(.headline)
                            ChartView()
                                .frame(height: 200)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(30)
                        .shadow(radius: 5)
                        .padding(.horizontal)

                        // Alerts Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Alerts")
                                .font(.headline)

                            VStack(spacing: 12) {
                                AlertRowView(message: "Vehicle #23 speed exceeded", time: "5 mins ago")
                                AlertRowView(message: "Vehicle #45 needs maintenance", time: "10 mins ago")
                                AlertRowView(message: "Trip delay reported on Route 8", time: "30 mins ago")
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(30)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Hello, Fleet!")
            .navigationBarTitleDisplayMode(.inline) // Ensures title stays fixed and centered
        }
    }
}

// Placeholder Views

// Rest of the code remains unchanged (StatCardGridView, QuickActionButton, ChartView, etc.)
// Including these for completeness
struct QuickActionButton: View {
    let icon: String
    let title: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 60, height: 60)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct StatCardGridView: View {
    var icon: String
    var title: String
    var value: String
    var color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 16, weight: .semibold))
                }
                Spacer()
                Text(value)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
            }

            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(30)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct ChartView: View {
    var body: some View {
        Chart {
            ForEach(MockData.weekData) { entry in
                BarMark(
                    x: .value("Day", entry.day),
                    y: .value("Trips", entry.value)
                )
                .foregroundStyle(by: .value("Day", entry.day))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartXAxis {
            AxisMarks(values: MockData.weekData.map { $0.day })
        }
    }
}

struct DataEntry: Identifiable {
    var id = UUID()
    let day: String
    let value: Int
}

struct MockData {
    static let weekData: [DataEntry] = [
        .init(day: "Mon", value: 40),
        .init(day: "Tue", value: 60),
        .init(day: "Wed", value: 45),
        .init(day: "Thu", value: 70),
        .init(day: "Fri", value: 65),
        .init(day: "Sat", value: 55),
        .init(day: "Sun", value: 50)
    ]
}

struct AlertRowView: View {
    let message: String
    let time: String

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .padding(8)
                .background(Color.red.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading) {
                Text(message)
                    .font(.subheadline)
                Text(time)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}


