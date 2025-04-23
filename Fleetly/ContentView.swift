import SwiftUI
import Charts




struct MainTabView: View {
    @ObservedObject var authVM: AuthViewModel
    var body: some View {
        TabView {
            DashboardHomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Homme")
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



// MARK: - Placeholder Views (Unchanged)
struct UserManagementView: View {
    var body: some View {
        NavigationView {
            Text("User Management Screen")
                .navigationTitle("Users")
        }
    }
}




import SwiftUI
import Charts

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
                            QuickActionButton(icon: "person.fill.badge.plus", title: "Assign ")
                            QuickActionButton(icon: "calendar.badge.clock", title: "Maintain")
                            QuickActionButton(icon: "doc.text.magnifyingglass", title: "Reports")
                            QuickActionButton(icon: "map.fill", title: "Track")
                        }
                                            .padding(.horizontal)
                                        }
                                        .padding() // Inner padding for content
                                        .background(Color(.white))
                                        .cornerRadius(30) // Rounded corners
                                        .shadow(radius: 4) // Subtle shadow
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
            .navigationTitle("Hello,Fleet !") // Fixed navigation bar title
        }
    }
}

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



// MARK: - Stat Card View
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

// MARK: - Dashboard Button
struct DashboardButton: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundColor(.white)
                .padding(16)
                .background(color)
                .clipShape(Circle())
            Text(title)
                .font(.headline)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 140)
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .gray.opacity(0.15), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Chart View (Mock Data)
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

// MARK: - Alert Row
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


