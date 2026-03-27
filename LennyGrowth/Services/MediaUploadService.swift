import Foundation
import UIKit

struct MediaAttachmentResponse: Codable, Identifiable {
    let id: String
    let url: String
    let thumbnailUrl: String?
    let type: String
    let fileSize: Int
    let width: Int?
    let height: Int?
}

@MainActor
final class MediaUploadService: ObservableObject {

    @Published var isUploading = false
    @Published var uploadProgress: Double = 0

    private let tokenManager: TokenManager
    private let baseURL: URL

    init(tokenManager: TokenManager, baseURL: URL = URL(string: Constants.API.baseURL)!) {
        self.tokenManager = tokenManager
        self.baseURL      = baseURL
    }

    // MARK: – Image upload

    func upload(image: UIImage) async throws -> MediaAttachmentResponse {
        // Resize to max 2048px, compress to JPEG
        let resized  = resized(image, maxDimension: 2048)
        guard let data = resized.jpegData(compressionQuality: 0.8) else {
            throw URLError(.badURL)
        }
        return try await uploadData(data, filename: "photo.jpg", mimeType: "image/jpeg")
    }

    // MARK: – Video upload

    func upload(videoURL: URL) async throws -> MediaAttachmentResponse {
        let data = try Data(contentsOf: videoURL)
        let filename = videoURL.lastPathComponent
        return try await uploadData(data, filename: filename, mimeType: "video/mp4")
    }

    // MARK: – Core multipart upload

    private func uploadData(_ data: Data, filename: String, mimeType: String) async throws -> MediaAttachmentResponse {
        isUploading    = true
        uploadProgress = 0
        defer { isUploading = false; uploadProgress = 0 }

        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        body.append("--\(boundary)\r\n".utf8Data)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".utf8Data)
        body.append("Content-Type: \(mimeType)\r\n\r\n".utf8Data)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".utf8Data)

        var request = URLRequest(url: baseURL.appendingPathComponent("/media/upload"))
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody   = body

        if let token = await tokenManager.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (responseData, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(MediaAttachmentResponse.self, from: responseData)
    }

    // MARK: – Delete

    func delete(mediaId: String) async throws {
        guard let token = await tokenManager.accessToken else { return }
        var request = URLRequest(url: baseURL.appendingPathComponent("/media/\(mediaId)"))
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        _ = try await URLSession.shared.data(for: request)
    }

    // MARK: – Helpers

    private func resized(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let larger = max(size.width, size.height)
        guard larger > maxDimension else { return image }
        let scale = maxDimension / larger
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}

private extension String {
    var utf8Data: Data { Data(utf8) }
}
