import DetentionCore
import SwiftUI

/// The broker request, already written from the clock. Share it through Mail or copy it, then mark it sent.
struct EmailSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var draft: String

    init(snapshot: DetentionSnapshot) {
        _draft = State(initialValue: DetentionEmail.body(for: snapshot))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("To", value: DetentionEmail.recipient)
                    LabeledContent("Subject", value: DetentionEmail.subject)
                }
                Section {
                    TextEditor(text: $draft)
                        .frame(minHeight: 320)
                        .font(.callout)
                } header: {
                    Text("Already written. Edit anything.")
                }
            }
            .navigationTitle("Detention request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Mark as sent", systemImage: "paperplane") {
                        model.markRequestSent()
                        dismiss()
                    }
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Button("Copy", systemImage: "doc.on.doc") {
                        UIPasteboard.general.string = draft
                        model.say("Email copied")
                    }
                    Spacer()
                    ShareLink("Send", item: draft, subject: Text(DetentionEmail.subject))
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
