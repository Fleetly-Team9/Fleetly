import SwiftUI

struct TicketRaiserView: View {
    @State private var isAnimating = false
    @State private var isPresentingAddTicket = false
    @StateObject private var ticketManager = TicketManager()
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.gray.opacity(0.15), Color.blue.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                VStack(spacing: 32) {
                    Image(systemName: "exclamationmark.bubble.fill")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundColor(.orange)
                        .scaleEffect(isAnimating ? 1.05 : 1.0)
                        .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                    
                    Text("No Tickets Yet!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("Facing an issue? Raise a ticket and we’ll help you out.")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button(action: {
                        isPresentingAddTicket = true
                    }) {
                        Text("Raise Ticket")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.orange.opacity(0.85), Color.orange]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(40)
                .frame(maxWidth: .infinity)
                .frame(height: UIScreen.main.bounds.height * 0.76)
                .background(
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
                )
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .onAppear {
            isAnimating = true
        }
        .navigationTitle("My Tickets")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isPresentingAddTicket) {
            AddTicketView(ticketManager: ticketManager)
        }
    }
}

struct TicketRaiserView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TicketRaiserView()
        }
    }
}
 
