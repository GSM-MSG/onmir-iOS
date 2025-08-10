import Nuke
import SnapKit
import UIKit

extension HomeViewController {
    final class ReadingBookCell: UICollectionViewCell {
        static let id: String = "ReadingBookCell"
        private let coverImageView: UIImageView = {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            return imageView
        }()

        private let readingProgressLabel: UILabel = {
            let label = UILabel()
            label.font = .systemFont(ofSize: 27, weight: .bold)
            return label
        }()

        private var imageDownloadTask: Task<Void, Never>?

        override init(frame: CGRect) {
            super.init(frame: frame)
            setupUI()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func prepareForReuse() {
            super.prepareForReuse()
            imageDownloadTask?.cancel()
        }

        private func setupUI() {
            self.backgroundColor = .clear
            contentView.backgroundColor = .clear

            contentView.addSubview(coverImageView)
            contentView.addSubview(readingProgressLabel)

            coverImageView.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(392)
            }

            readingProgressLabel.snp.makeConstraints { make in
                make.top.equalTo(coverImageView.snp.bottom).offset(8)
                make.leading.equalToSuperview()
            }
        }

        func prepare(imageURL: URL?, currentPage: Int, totalPage: Int) {
            if totalPage <= 0 {
                self.readingProgressLabel.text = ""
            } else {
                let rawPercentage = Double(currentPage) / Double(totalPage) * 100
                let percentage: Int
                if rawPercentage.isNaN || rawPercentage.isInfinite {
                    percentage = 0
                } else {
                    percentage = max(0, min(100, Int(rawPercentage)))
                }
                self.readingProgressLabel.text = "\(percentage)%"
            }

            if let thumbnailURL = imageURL {
                imageDownloadTask = Task {
                    do {
                        let image = try await ImagePipeline.shared.image(for: thumbnailURL)
                        if !Task.isCancelled {
                            self.coverImageView.image = image
                        }
                    } catch {
                        Logger.error(error)
                    }
                }
            }
        }
    }
}
