import SwiftUI

public struct StarRatingSlider: View {
  @Binding public var rating: Double
  var minimum: Double = 0.5
  var maximum: Double = 5.0
  var spacing: CGFloat = 8
  var starSize: CGFloat = 40
  var allowHalfStars: Bool = true

  @State private var starWidth: CGFloat = 0

  public init(
    rating: Binding<Double>,
    minimum: Double = 0.5,
    maximum: Double = 5.0,
    spacing: CGFloat = 8,
    starSize: CGFloat = 40,
    allowHalfStars: Bool = true
  ) {
    self._rating = rating
    self.minimum = minimum
    self.maximum = maximum
    self.spacing = spacing
    self.starSize = starSize
    self.allowHalfStars = allowHalfStars
  }

  public var body: some View {
    HStack(spacing: spacing) {
      ForEach(1...Int(maximum), id: \.self) { index in
        starView(for: index)
          .frame(width: starSize, height: starSize)
          .contentSize(width: $starWidth)
          .onTapGesture {
            handleTap(for: index)
          }
      }
    }
    .gesture(
      DragGesture(coordinateSpace: .local)
        .onChanged(handleDragChanged)
    )
  }

  @ViewBuilder
  private func starView(for index: Int) -> some View {
    ZStack {
      Image(systemName: "star")
        .font(.system(size: starSize * 0.8))
        .foregroundColor(.orange.opacity(0.3))

      if Double(index) <= rating {
        Image(systemName: "star.fill")
          .font(.system(size: starSize * 0.8))
          .foregroundColor(.orange)
      } else if allowHalfStars && Double(index) - 0.5 <= rating {
        Image(systemName: "star.leadinghalf.filled")
          .font(.system(size: starSize * 0.8))
          .foregroundColor(.orange)
      }
    }
  }

  private func handleTap(for index: Int) {
    withAnimation(.easeInOut(duration: 0.2)) {
      let fullStarRating = Double(index)
      let halfStarRating = Double(index) - 0.5

      if allowHalfStars {
        if rating == fullStarRating {
          rating = halfStarRating
        } else if rating == halfStarRating {
          rating = fullStarRating
        } else {
          rating = fullStarRating
        }
      } else {
        rating = fullStarRating
      }

      rating = max(minimum, min(maximum, rating))
    }
  }

  private func handleDragChanged(_ value: DragGesture.Value) {
    let x = value.location.x

    let totalStars = Int(maximum)
    let totalWidth =
      CGFloat(totalStars) * starWidth + CGFloat(totalStars - 1) * spacing

    guard x >= 0 && x <= totalWidth else {
      if x < 0 {
        rating = minimum
      } else {
        rating = maximum
      }
      return
    }

    let starPosition = x / (starWidth + spacing)
    let starIndex = Int(starPosition)
    let positionInStar = starPosition - Double(starIndex)

    var newRating: Double

    if allowHalfStars {
      if positionInStar < 0.5 {
        newRating = Double(starIndex) + 0.5
      } else {
        newRating = Double(starIndex) + 1.0
      }
    } else {
      newRating = Double(starIndex) + 1.0
    }

    newRating = max(minimum, min(maximum, newRating))

    if newRating != rating {
      withAnimation(.easeInOut(duration: 0.1)) {
        rating = newRating
      }
    }
  }
}

#Preview {
  VStack(spacing: 30) {
    VStack {
      Text("Half Star Rating")
      StarRatingSlider(rating: .constant(3.5))
    }

    VStack {
      Text("Full Star Only")
      StarRatingSlider(
        rating: .constant(4.0),
        allowHalfStars: false
      )
    }

    VStack {
      Text("Custom Size")
      StarRatingSlider(
        rating: .constant(2.5),
        spacing: 12,
        starSize: 60
      )
    }
  }
  .padding()
}
