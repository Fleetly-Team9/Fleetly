import SwiftUICore
import UIKit
import SwiftUI

extension View {
    func dismissKeyboardOnTap() -> some View {
        self.background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
        )
    }
    
    func dismissKeyboardOnScroll() -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
        )
    }
    
    func dismissKeyboard() -> some View {
        self.dismissKeyboardOnTap()
            .dismissKeyboardOnScroll()
    }
} 
