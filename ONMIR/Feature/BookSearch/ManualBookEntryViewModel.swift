import SwiftUI
import PhotosUI
import Observation

@MainActor
@Observable
class ManualBookEntryViewModel {
  var title = ""
  var author = ""
  var publisher = ""
  var publishedDate = ""
  var description = ""
  var isbn = ""
  var isbn13 = ""
  var pageCountText = ""
  var readingStatus: BookStatusType = .toRead
  
  var coverImage: UIImage?
  var selectedPhoto: PhotosPickerItem? {
    didSet {
      loadSelectedPhoto()
    }
  }
  
  var showPhotoPicker = false
  var showMissingTitleAlert = false
  
  var isValid: Bool {
    true
  }
  
  private func loadSelectedPhoto() {
    guard let selectedPhoto = selectedPhoto else { return }
    
    Task {
      do {
        if let data = try await selectedPhoto.loadTransferable(type: Data.self),
           let uiImage = UIImage(data: data) {
          await MainActor.run {
            self.coverImage = uiImage
          }
        }
      } catch {
        Logger.error("Failed to load selected photo: \(error)")
      }
    }
  }
}