import UIKit

final class DividerView: UIView {
    init(height: CGFloat = 1.0, color: UIColor = UIColor.quaternaryLabel) {
        super.init(frame: .zero)

        self.backgroundColor = color
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.heightAnchor.constraint(equalToConstant: height)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
