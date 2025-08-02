import Nuke
import SnapKit
import UIKit

extension BookSearchViewController {
  final class BookCell: UICollectionViewCell {
    private let coverImageView: UIImageView = {
      let imageView = UIImageView()
      imageView.contentMode = .scaleAspectFit
      imageView.layer.cornerRadius = 5
      imageView.clipsToBounds = true
      return imageView
    }()

    private let titleLabel: UILabel = {
      let label = UILabel()
      label.font = .systemFont(ofSize: 13, weight: .bold)
      label.numberOfLines = 2
      label.minimumScaleFactor = 0.75
      label.adjustsFontSizeToFitWidth = true
      label.textColor = .label
      return label
    }()

    private let authorLabel: UILabel = {
      let label = UILabel()
      label.font = .systemFont(ofSize: 12)
      label.textColor = .tertiaryLabel
      label.numberOfLines = 2
      label.adjustsFontSizeToFitWidth = true
      label.minimumScaleFactor = 0.75
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
      imageDownloadTask = nil
      coverImageView.image = nil
      titleLabel.text = nil
      authorLabel.text = nil
    }

    private func setupUI() {
      self.backgroundColor = .clear
      contentView.backgroundColor = .clear

      contentView.addSubview(coverImageView)
      contentView.addSubview(titleLabel)
      contentView.addSubview(authorLabel)

      coverImageView.snp.makeConstraints { make in
        make.leading.equalToSuperview().inset(32)
        make.verticalEdges.equalToSuperview().inset(8)
        make.height.equalTo(100)
        make.width.equalTo(coverImageView.snp.height).multipliedBy(0.75)
      }

      titleLabel.snp.makeConstraints { make in
        make.top.equalToSuperview().inset(8)
        make.leading.equalTo(coverImageView.snp.trailing).offset(10)
        make.trailing.equalToSuperview().inset(12)
      }

      authorLabel.snp.makeConstraints { make in
        make.top.equalTo(titleLabel.snp.bottom).offset(0)
        make.leading.equalTo(coverImageView.snp.trailing).offset(10)
        make.trailing.equalToSuperview().inset(32)
        make.bottom.lessThanOrEqualToSuperview()
      }
    }

    func configure(with book: BookSearchRepresentation) {
      titleLabel.text = book.title
      authorLabel.text = book.authors?.joined(separator: ", ")

      if let thumbnailURL = book.thumbnailURL {
        self.imageDownloadTask = Task {
          do {
            let image = try await ImagePipeline.shared.image(for: thumbnailURL)

            await MainActor.run {
              self.coverImageView.image = image
            }
          } catch let error as CancellationError {
            Logger.info(error)
          } catch {
            Logger.error(error)
          }
        }
      }
    }
  }
}
