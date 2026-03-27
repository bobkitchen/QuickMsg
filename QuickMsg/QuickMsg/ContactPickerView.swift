import SwiftUI
import ContactsUI

@MainActor
struct ContactPickerView: UIViewControllerRepresentable {
    @Binding var recipientName: String
    @Binding var recipientPhone: String
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        picker.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0")
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, @preconcurrency CNContactPickerDelegate {
        var parent: ContactPickerView

        init(_ parent: ContactPickerView) {
            self.parent = parent
        }

        @MainActor
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            let name = CNContactFormatter.string(from: contact, style: .fullName) ?? "Unknown"
            parent.recipientName = name

            if let phone = contact.phoneNumbers.first?.value {
                let raw = phone.stringValue
                let digits = raw.filter { $0.isNumber || $0 == "+" }
                parent.recipientPhone = digits
            }

            parent.dismiss()
        }

        @MainActor
        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            parent.dismiss()
        }
    }
}
