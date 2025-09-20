import UIKit
import CoreData

extension BookEntity {
  enum CoverImageResult {
    case url(URL)
    case image(UIImage)
    case none
  }
  
  var coverImageResult: CoverImageResult {
    // Priority: local image data > remote URL
    if let coverImageData = coverImageData?.data,
       let image = UIImage(data: coverImageData) {
      return .image(image)
    }
    
    if let coverImageURL = coverImageURL {
      return .url(coverImageURL)
    }
    
    return .none
  }
  
  var hasCoverImage: Bool {
    switch coverImageResult {
    case .none:
      return false
    default:
      return true
    }
  }
}