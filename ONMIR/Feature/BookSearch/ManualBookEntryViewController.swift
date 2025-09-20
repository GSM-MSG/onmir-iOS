import SwiftUI
import UIKit

public final class ManualBookEntryViewController: UIHostingController<ManualBookEntryView> {
  private let completion: @MainActor (ManualBookRepresentation) -> Void
  
  init(completion: @MainActor @escaping (ManualBookRepresentation) -> Void) {
    self.completion = completion
    super.init(rootView: ManualBookEntryView(completion: completion))
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}