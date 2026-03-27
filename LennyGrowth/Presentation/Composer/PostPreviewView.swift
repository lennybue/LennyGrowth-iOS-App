import SwiftUI

// MARK: - PostPreviewView

struct PostPreviewView: View {
    let content: String
    let platform: SocialPlatform
    let hashtags: [String]

    @Environment(\.dismiss) private var dismiss
    @State private var isExpanded = false

    private var characterCount: Int { content.count }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Character count badge
                        HStack {
                            Spacer()
                            characterCountBadge
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)

                        // Preview card
                        if platform == .linkedin {
                            linkedInPreview
                        } else {
                            threadsPreview
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Vorschau")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.bgPrimary, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .font(.lgBodySemibold)
                        .foregroundColor(.neonTeal)
                }
            }
        }
    }

    // MARK: - Character Count Badge

    private var characterCountBadge: some View {
        let limit = platform.characterLimit
        let isOver = characterCount > limit
        return Text("\(characterCount) / \(limit)")
            .font(.lgCaption)
            .fontWeight(.semibold)
            .foregroundColor(isOver ? .red : .white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(isOver ? Color.red.opacity(0.2) : Color.bgSurface)
                    .overlay(
                        Capsule()
                            .strokeBorder(isOver ? Color.red.opacity(0.5) : Color.glassBorder, lineWidth: 1)
                    )
            )
    }

    // MARK: - LinkedIn Preview

    private var linkedInPreview: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Platform label
            HStack(spacing: 6) {
                Image(systemName: "person.crop.square")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "#0A66C2"))
                Text("LinkedIn Vorschau")
                    .font(.lgCaption)
                    .fontWeight(.semibold)
                    .foregroundColor(.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)

            // Simulated LinkedIn card (light mode)
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(alignment: .top, spacing: 10) {
                    // Avatar
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.neonMagenta, Color(hex: "#FF006E").opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .overlay(
                            Text("L")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Lennard Büssow")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black)
                        Text("Digital Marketing · IT-Consultant")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#666666"))
                        HStack(spacing: 4) {
                            Text("Gerade eben")
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: "#999999"))
                            Text("·")
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: "#999999"))
                            Image(systemName: "globe")
                                .font(.system(size: 10))
                                .foregroundColor(Color(hex: "#999999"))
                        }
                    }

                    Spacer()

                    Image(systemName: "ellipsis")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#666666"))
                }

                // Post content
                VStack(alignment: .leading, spacing: 4) {
                    hashtaggedText(
                        content,
                        hashtagColor: Color(hex: "#0A66C2"),
                        textColor: .black,
                        lineLimit: isExpanded ? nil : 3
                    )
                    .font(.system(size: 14))

                    if !isExpanded && content.count > 200 {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded = true
                            }
                        } label: {
                            Text("...mehr")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: "#0A66C2"))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Divider()
                    .background(Color(hex: "#E5E5E5"))

                // Action row
                HStack {
                    linkedInAction(icon: "hand.thumbsup", label: "Gefällt mir")
                    Spacer()
                    linkedInAction(icon: "bubble.left", label: "Kommentieren")
                    Spacer()
                    linkedInAction(icon: "arrow.2.squarepath", label: "Teilen")
                    Spacer()
                    linkedInAction(icon: "paperplane", label: "Senden")
                }
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 2)
            .padding(.horizontal, 16)
        }
    }

    private func linkedInAction(icon: String, label: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "#666666"))
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "#666666"))
        }
    }

    // MARK: - Threads Preview

    private var threadsPreview: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Platform label
            HStack(spacing: 6) {
                Image(systemName: "at.circle")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textSecondary)
                Text("Threads Vorschau")
                    .font(.lgCaption)
                    .fontWeight(.semibold)
                    .foregroundColor(.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)

            // Simulated Threads card (dark mode)
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(alignment: .top, spacing: 10) {
                    // Avatar stack
                    ZStack(alignment: .bottom) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.neonTeal, .iceBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text("L")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("lennybue")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.iceBlue)
                        }
                        Text("@lennybue")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#999999"))
                    }

                    Spacer()

                    HStack(spacing: 12) {
                        Text("Jetzt")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#999999"))
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#999999"))
                    }
                }

                // Post content
                hashtaggedText(
                    content,
                    hashtagColor: .neonTeal,
                    textColor: .white,
                    lineLimit: nil
                )
                .font(.system(size: 15))

                // Thread reply indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: "#333333"))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Text("A")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                        )
                    Circle()
                        .fill(Color(hex: "#333333"))
                        .frame(width: 16, height: 16)
                        .overlay(
                            Text("B")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                        )
                    Text("Antworte zuerst")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#666666"))
                }

                // Action row
                HStack(spacing: 20) {
                    threadsAction(icon: "heart")
                    threadsAction(icon: "bubble.left")
                    threadsAction(icon: "arrow.2.squarepath")
                    threadsAction(icon: "paperplane")
                    Spacer()
                }
            }
            .padding(16)
            .background(Color(hex: "#181818"))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            )
            .padding(.horizontal, 16)
        }
    }

    private func threadsAction(icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: 20))
            .foregroundColor(.white)
    }

    // MARK: - Hashtag-colored Text

    @ViewBuilder
    private func hashtaggedText(
        _ text: String,
        hashtagColor: Color,
        textColor: Color,
        lineLimit: Int?
    ) -> some View {
        let words = text.components(separatedBy: .whitespaces)
        let result = words.reduce(Text("")) { accumulated, word in
            let isHashtag = word.hasPrefix("#") && word.count > 1
            let styledWord = isHashtag
                ? Text(word).foregroundColor(hashtagColor)
                : Text(word).foregroundColor(textColor)
            let space = Text(" ").foregroundColor(textColor)
            if accumulated == Text("") {
                return styledWord
            }
            return accumulated + space + styledWord
        }

        if let lineLimit {
            result.lineLimit(lineLimit)
        } else {
            result
        }
    }
}
