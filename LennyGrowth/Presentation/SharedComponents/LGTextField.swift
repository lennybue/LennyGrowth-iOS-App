import SwiftUI

struct LGTextField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var submitLabel: SubmitLabel = .done
    var onSubmit: (() -> Void)? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !title.isEmpty {
                Text(title)
                    .font(.lgLabel)
                    .foregroundColor(.textSecondary)
            }

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                }
            }
            .font(.lgBodyMD)
            .foregroundColor(.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.glassSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(
                                isFocused ? Color.neonMagenta.opacity(0.6) : Color.glassBorder,
                                lineWidth: 1
                            )
                    )
            )
            .focused($isFocused)
            .submitLabel(submitLabel)
            .onSubmit { onSubmit?() }
            .tint(.neonMagenta)
        }
    }
}

// MARK: - Multi-line text editor

struct LGTextEditor: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var maxCharacters: Int? = nil

    @FocusState private var isFocused: Bool

    private var charCount: Int { text.count }
    private var isNearLimit: Bool {
        guard let max = maxCharacters else { return false }
        return charCount >= Int(Double(max) * 0.85)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if !title.isEmpty {
                    Text(title)
                        .font(.lgLabel)
                        .foregroundColor(.textSecondary)
                }
                Spacer()
                if let max = maxCharacters {
                    Text("\(charCount)/\(max)")
                        .font(.lgCaption)
                        .foregroundColor(isNearLimit ? .neonMagenta : .textSecondary)
                        .animation(.easeInOut(duration: 0.2), value: isNearLimit)
                }
            }

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.lgBodyMD)
                        .foregroundColor(.textSecondary.opacity(0.6))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                }

                TextEditor(text: $text)
                    .font(.lgBodyMD)
                    .foregroundColor(.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .focused($isFocused)
                    .scrollContentBackground(.hidden)
                    .tint(.neonMagenta)
            }
            .frame(minHeight: 120)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.glassSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(
                                isFocused ? Color.neonMagenta.opacity(0.6) : Color.glassBorder,
                                lineWidth: 1
                            )
                    )
            )
        }
    }
}
