import SwiftUI
import PhotosUI

struct MediaItem: Identifiable {
    let id: String
    var image: UIImage?
    var videoURL: URL?
    var uploadedURL: String?
    var isUploading: Bool = false

    var thumbnail: UIImage? { image }
    var isVideo: Bool { videoURL != nil }
}

struct MediaPickerView: View {
    @Binding var items: [MediaItem]
    @State private var photoPickerItems: [PhotosPickerItem] = []
    @State private var showVideoPicker = false

    private let maxImages = 4

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Selected thumbnails grid
            if !items.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(items) { item in
                            thumbnailCell(item)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }

            // Picker buttons
            HStack(spacing: 12) {
                PhotosPicker(
                    selection: $photoPickerItems,
                    maxSelectionCount: maxImages - items.filter { !$0.isVideo }.count,
                    matching: .images
                ) {
                    Label("Foto hinzufügen", systemImage: "photo")
                        .font(.caption)
                        .foregroundColor(items.count >= maxImages ? .textSecondary : .neonTeal)
                }
                .disabled(items.count >= maxImages)
                .onChange(of: photoPickerItems) { newItems in
                    Task { await loadPhotos(newItems) }
                }

                if items.filter(\.isVideo).isEmpty {
                    PhotosPicker(
                        selection: $photoPickerItems,
                        maxSelectionCount: 1,
                        matching: .videos
                    ) {
                        Label("Video hinzufügen", systemImage: "video")
                            .font(.caption)
                            .foregroundColor(items.isEmpty ? .neonTeal : .textSecondary)
                    }
                    .disabled(!items.isEmpty)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: – Thumbnail cell

    @ViewBuilder
    private func thumbnailCell(_ item: MediaItem) -> some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let image = item.thumbnail {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(Color.bgSurface)
                        .overlay(
                            Image(systemName: item.isVideo ? "video.fill" : "photo")
                                .foregroundColor(.textSecondary)
                        )
                }
            }
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            if item.isUploading {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.5))
                    .frame(width: 72, height: 72)
                ProgressView()
                    .tint(.white)
            }

            // Remove button
            Button {
                items.removeAll { $0.id == item.id }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color.neonMagenta, Color.bgPrimary)
                    .font(.system(size: 18))
            }
            .offset(x: 6, y: -6)
            .accessibilityLabel("Medien entfernen")
        }
    }

    // MARK: – Photo loading

    private func loadPhotos(_ pickerItems: [PhotosPickerItem]) async {
        for pickerItem in pickerItems {
            if let data = try? await pickerItem.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                let mediaItem = MediaItem(id: UUID().uuidString, image: image)
                await MainActor.run { items.append(mediaItem) }
            }
        }
        await MainActor.run { photoPickerItems = [] }
    }
}
