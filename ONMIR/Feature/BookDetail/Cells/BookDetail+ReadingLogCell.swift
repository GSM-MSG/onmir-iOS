import UIKit
import SnapKit
import Nuke

extension BookDetailViewController {
  final class ReadingLogCell: UICollectionViewCell {
    private let containerView = {
      let view = UIView()
      view.backgroundColor = .secondarySystemBackground
      view.layer.cornerRadius = 12
      view.layer.masksToBounds = false
      return view
    }()
    
    private let bookCoverImageView = {
      let imageView = UIImageView()
      imageView.contentMode = .scaleAspectFill
      imageView.clipsToBounds = true
      imageView.layer.cornerRadius = 6
      imageView.backgroundColor = .systemGray6
      return imageView
    }()
    
    private let pageRangeLabel = {
      let label = UILabel()
      label.font = .systemFont(ofSize: 20, weight: .bold)
      label.textColor = .label
      return label
    }()
    
    private let dateTimeLabel = {
      let label = UILabel()
      label.font = .systemFont(ofSize: 16, weight: .medium)
      label.textColor = .systemGray
      return label
    }()
    
    private let noteLabel = UILabel()

    private static let timeFormatter = {
      let formatter = DateComponentsFormatter()
      formatter.allowedUnits = [.hour, .minute]
      formatter.unitsStyle = .abbreviated
      return formatter
    }()
    
    private var imageLoadingTask: Task<Void, Never>?
    
    override init(frame: CGRect) {
      super.init(frame: frame)
      setupUI()
    }
    
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
      super.prepareForReuse()
      imageLoadingTask?.cancel()
      imageLoadingTask = nil
      bookCoverImageView.image = nil
      pageRangeLabel.text = nil
      dateTimeLabel.text = nil
      noteLabel.text = nil
    }
    
    private func setupUI() {
      contentView.addSubview(containerView)
      
      [bookCoverImageView, pageRangeLabel, dateTimeLabel].forEach {
        containerView.addSubview($0)
      }
      
      setupConstraints()
    }
    
    private func setupConstraints() {
      containerView.snp.makeConstraints { make in
        make.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16))
      }
      
      bookCoverImageView.snp.makeConstraints { make in
        make.leading.centerY.equalToSuperview().inset(16)
        make.width.equalTo(48)
        make.height.equalTo(64)
      }
      
      pageRangeLabel.snp.makeConstraints { make in
        make.top.equalToSuperview().inset(16)
        make.leading.equalTo(bookCoverImageView.snp.trailing).offset(16)
        make.trailing.equalToSuperview().inset(16)
      }
      
      dateTimeLabel.snp.makeConstraints { make in
        make.top.equalTo(pageRangeLabel.snp.bottom).offset(4)
        make.leading.equalTo(bookCoverImageView.snp.trailing).offset(16)
        make.trailing.equalToSuperview().inset(16)
        make.bottom.lessThanOrEqualToSuperview().inset(16)
      }
    }
    
    func configure(with log: ReadingLogEntity, book: BookEntity?) {
      let pageText = log.managedObjectContext?.performAndWait { @Sendable in
        "\(log.startPage) - \(log.endPage)"
      }
      pageRangeLabel.text = pageText

      let pageDateText = log.managedObjectContext?.performAndWait { @Sendable in
        log.date?.formatted(.dateTime.year().month().day())
      }

      let readingTime = Self.timeFormatter.string(from: log.readingSeconds) ?? "\(log.readingSeconds)s"
      
      dateTimeLabel.text = if let pageDateText {
        "\(pageDateText) • \(readingTime)"
      } else {
        "\(readingTime)"
      }
      
      if let book = book, let coverURL = book.coverImageURL {
        let request = ImageRequest(url: coverURL)
        imageLoadingTask = Task {
          do {
            let image = try await ImagePipeline.shared.image(for: request)

            guard Task.isCancelled == false else { return }

            await MainActor.run {
              bookCoverImageView.image = image
            }
          } catch {
            guard Task.isCancelled == false else { return }

            await MainActor.run {
              bookCoverImageView.backgroundColor = .systemGray5
            }
          }
        }
      } else {
        bookCoverImageView.backgroundColor = .systemGray5
      }
    }
    
    func contextMenuHighlightView() -> UIView? {
      return containerView
    }
  }
}
