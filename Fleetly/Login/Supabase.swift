import Supabase
import Foundation

class SupabaseManager {
    static let shared = SupabaseManager()
    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://sacsqexpmtxcbjjnyfkj.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNhY3NxZXhwbXR4Y2Jqam55ZmtqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU1MjQ3NDIsImV4cCI6MjA2MTEwMDc0Mn0.V9VpncgB5jz3l0DmHjiJplsz-f-22CQVZgOtxI16xOg"
        )
    }
}

