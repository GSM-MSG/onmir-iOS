import SwiftUI
import UIKit

struct BookRatingView: View {
  let title: String
  let initialRating: Double
  let onRatingChanged: (Double) -> Void
  
  @Environment(\.dismiss) var dismiss
  @State private var currentRating: Double
  
  init(
    title: String,
    initialRating: Double,
    onRatingChanged: @escaping (Double) -> Void,
  ) {
    self.title = title
    self.initialRating = initialRating
    self.onRatingChanged = onRatingChanged
    self._currentRating = State(initialValue: initialRating)
  }
  
  var body: some View {
    VStack(spacing: 24) {
      VStack(spacing: 8) {
        Text("Rate this book")
          .font(.title2)
          .fontWeight(.semibold)
        
        Text(title)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .lineLimit(2)
      }
      
      VStack(spacing: 16) {
        StarRatingSlider(
          rating: $currentRating,
          minimum: 0.5,
          maximum: 5.0,
          spacing: 12,
          starSize: 40,
          allowHalfStars: true
        )
        
        Text(ratingText)
          .font(.headline)
          .foregroundStyle(.orange)
          .contentTransition(.numericText())
      }
      
      Button("Rate Book") {
        onRatingChanged(currentRating)
        dismiss()
      }
      .foregroundStyle(Color.buttonText)
      .frame(maxWidth: .infinity)
      .padding()
      .background {
        RoundedRectangle(cornerRadius: 16)
          .fill(Color.buttonBackground)
      }
      .disabled(currentRating == 0)
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemBackground))
  }
  
  private var ratingText: String {
    if currentRating == 0 {
      return "Tap stars to rate"
    } else {
      let ratingString = currentRating.truncatingRemainder(dividingBy: 1) == 0 
        ? String(format: "%.0f", currentRating)
        : String(format: "%.1f", currentRating)
      return "\(ratingString) out of 5 stars"
    }
  }
}

final class BookRatingViewController: UIViewController {
  private let bookTitle: String
  private let initialRating: Double
  private let onRatingChanged: (Double) -> Void
  
  init(title: String, initialRating: Double, onRatingChanged: @escaping (Double) -> Void) {
    self.bookTitle = title
    self.initialRating = initialRating
    self.onRatingChanged = onRatingChanged
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupSwiftUIView()
  }
  
  private func setupSwiftUIView() {
    let ratingView = BookRatingView(
      title: bookTitle,
      initialRating: initialRating,
      onRatingChanged: onRatingChanged
    )
    
    let hostingController = UIHostingController(rootView: ratingView)
    addChild(hostingController)
    view.addSubview(hostingController.view)
    hostingController.didMove(toParent: self)
    
    hostingController.view.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
      hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])
  }
}
