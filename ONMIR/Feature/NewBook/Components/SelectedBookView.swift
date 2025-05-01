import Nuke
import SnapKit
import UIKit

extension NewBookViewController {
  final class SelectedBookView: UIView {
    private let containerView: UIView = {
      let view = UIView()
      view.layer.cornerRadius = 12
      view.clipsToBounds = true
      view.backgroundColor = .clear
      return view
    }()

    private let coverImageView: UIImageView = {
      let imageView = UIImageView()
      imageView.contentMode = .scaleAspectFit
      imageView.backgroundColor = .clear
      imageView.layer.cornerRadius = 5
      imageView.clipsToBounds = true
      return imageView
    }()

    private let titleLabel: UILabel = {
      let label = UILabel()
      label.font = .systemFont(ofSize: 22, weight: .bold)
      label.numberOfLines = 2
      label.minimumScaleFactor = 0.75
      label.adjustsFontSizeToFitWidth = true
      label.textAlignment = .center
      label.textColor = .label
      return label
    }()

    private let authorLabel: UILabel = {
      let label = UILabel()
      label.font = .systemFont(ofSize: 12)
      label.numberOfLines = 2
      label.minimumScaleFactor = 0.75
      label.adjustsFontSizeToFitWidth = true
      label.textColor = .tertiaryLabel
      label.textAlignment = .center
      return label
    }()

    private var imageDownloadTask: Task<Void, Never>?

    override init(frame: CGRect) {
      super.init(frame: frame)
      setupSubviews()
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
      addSubview(containerView)

      containerView.snp.makeConstraints { make in
        make.edges.equalToSuperview().inset(20)
      }

      containerView.addSubview(coverImageView)
      containerView.addSubview(titleLabel)
      containerView.addSubview(authorLabel)

      coverImageView.snp.makeConstraints { make in
        make.top.equalToSuperview()
        make.centerX.equalToSuperview()
        make.horizontalEdges.equalToSuperview().inset(20)
        make.height.equalTo(225)
      }

      titleLabel.snp.makeConstraints { make in
        make.top.equalTo(coverImageView.snp.bottom).offset(12)
        make.leading.trailing.equalToSuperview().inset(20)
      }

      authorLabel.snp.makeConstraints { make in
        make.top.equalTo(titleLabel.snp.bottom).offset(0)
        make.leading.trailing.equalToSuperview().inset(20)
        make.bottom.lessThanOrEqualToSuperview()
      }
    }

    func configure(with book: BookSearchRepresentation) {
      titleLabel.text = book.title
      authorLabel.text = book.authors?.joined(separator: ", ")

      imageDownloadTask?.cancel()
      imageDownloadTask = nil
      if let thumbnailURL = book.thumbnailURL {
        let imageTask = ImagePipeline.shared.imageTask(with: thumbnailURL)

        imageDownloadTask = Task {
          do {
            let image = try await imageTask.image
            guard Task.isCancelled == false else { return }
            coverImageView.image = image
          } catch let error as CancellationError {
            Logger.info(error)
          } catch {
            Logger.error(error)
          }
        }
      }
    }

    func reset() {
      coverImageView.image = nil
      titleLabel.text = nil
      authorLabel.text = nil
    }
  }
}
