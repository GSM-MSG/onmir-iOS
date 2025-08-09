import Accelerate
import Nuke
import SnapKit
import UIKit

extension BookDetailViewController {
  final class BookInfoCell: UICollectionViewCell {
    private let coverImageView = {
      let imageView = UIImageView()
      imageView.contentMode = .scaleAspectFill
      imageView.clipsToBounds = true
      imageView.backgroundColor = .systemGray6
      imageView.layer.cornerRadius = 16
      
      imageView.layer.shadowColor = UIColor.black.cgColor
      imageView.layer.shadowOffset = CGSize(width: 0, height: 10)
      imageView.layer.shadowRadius = 24
      imageView.layer.shadowOpacity = 0.15
      imageView.layer.masksToBounds = false
      
      return imageView
    }()
    
    private let titleLabel = {
      let label = UILabel()
      label.font = .systemFont(ofSize: 28, weight: .bold)
      label.numberOfLines = 2
      label.textColor = .label
      label.textAlignment = .center
      return label
    }()
    
    private let authorLabel = {
      let label = UILabel()
      label.font = .systemFont(ofSize: 18, weight: .medium)
      label.numberOfLines = 1
      label.textColor = .secondaryLabel
      label.textAlignment = .center
      return label
    }()
    
    private let ratingStackView = {
      let stackView = UIStackView()
      stackView.axis = .horizontal
      stackView.spacing = 4
      stackView.alignment = .center
      return stackView
    }()
    
    private let pageCountLabel = {
      let label = UILabel()
      label.textColor = .secondaryLabel
      return label
    }()
    
    private let horizontalInfoView = {
      let stackView = UIStackView()
      stackView.axis = .horizontal
      stackView.spacing = 24
      stackView.alignment = .center
      stackView.distribution = .equalSpacing
      return stackView
    }()
    
    private let timeLabel = {
      let label = UILabel()
      label.font = .systemFont(ofSize: 16, weight: .medium)
      label.textColor = .systemGray
      return label
    }()
    
    private let ratingLabel = {
      let label = UILabel()
      label.font = .systemFont(ofSize: 16, weight: .medium)
      label.textColor = .systemGray
      return label
    }()
    
    private let timeContainer = {
      let container = UIStackView()
      container.axis = .horizontal
      container.spacing = 6
      container.alignment = .center
      return container
    }()
    
    private let ratingContainer = {
      let container = UIStackView()
      container.axis = .horizontal
      container.spacing = 6
      container.alignment = .center
      return container
    }()
    
    private var imageLoadingTask: Task<Void, Never>?
    
    private static let timeFormatter = {
      let formatter = DateComponentsFormatter()
      formatter.allowedUnits = [.hour, .minute]
      formatter.unitsStyle = .abbreviated
      formatter.maximumUnitCount = 2
      return formatter
    }()
    
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
      coverImageView.image = nil
      titleLabel.text = nil
      authorLabel.text = nil
      pageCountLabel.text = nil
      timeLabel.text = nil
      ratingLabel.text = nil
    }
    
    private func setupUI() {
      [coverImageView, titleLabel, authorLabel, horizontalInfoView].forEach {
        contentView.addSubview($0)
      }
      
      setupTimeContainer()
      setupRatingContainer()
      
      horizontalInfoView.addArrangedSubview(timeContainer)
      horizontalInfoView.addArrangedSubview(ratingContainer)
      
      setupConstraints()
    }
    
    private func setupTimeContainer() {
      let iconImageView = UIImageView()
      iconImageView.image = UIImage(systemName: "clock")
      iconImageView.tintColor = .systemGray2
      iconImageView.contentMode = .scaleAspectFit
      iconImageView.snp.makeConstraints { make in
        make.width.height.equalTo(16)
      }
      
      timeContainer.addArrangedSubview(iconImageView)
      timeContainer.addArrangedSubview(timeLabel)
    }
    
    private func setupRatingContainer() {
      let iconImageView = UIImageView()
      iconImageView.image = UIImage(systemName: "star")
      iconImageView.tintColor = .systemGray2
      iconImageView.contentMode = .scaleAspectFit
      iconImageView.snp.makeConstraints { make in
        make.width.height.equalTo(16)
      }
      
      ratingContainer.addArrangedSubview(iconImageView)
      ratingContainer.addArrangedSubview(ratingLabel)
    }
    
    private func setupConstraints() {
      coverImageView.snp.makeConstraints { make in
        make.top.centerX.equalToSuperview().inset(24)
        make.width.equalTo(180)
        make.height.equalTo(240)
      }
      
      titleLabel.snp.makeConstraints { make in
        make.top.equalTo(coverImageView.snp.bottom).offset(24)
        make.leading.trailing.equalToSuperview().inset(20)
      }
      
      authorLabel.snp.makeConstraints { make in
        make.top.equalTo(titleLabel.snp.bottom).offset(12)
        make.leading.trailing.equalToSuperview().inset(20)
      }
      
      horizontalInfoView.snp.makeConstraints { make in
        make.top.equalTo(authorLabel.snp.bottom).offset(20)
        make.centerX.equalToSuperview()
        make.bottom.lessThanOrEqualToSuperview().inset(24)
      }
    }
    
    func configure(with book: BookEntity, totalReadingTime: TimeInterval) {
      titleLabel.text = book.title
      authorLabel.text = book.author
      
      if let coverURL = book.coverImageURL {
        let request = ImageRequest(url: coverURL)
        imageLoadingTask = Task {
          do {
            let image = try await ImagePipeline.shared.image(for: request)
            guard Task.isCancelled == false else { return }

            await MainActor.run {
              coverImageView.image = image
            }
          } catch {
            guard Task.isCancelled == false else { return }
            await MainActor.run {
              coverImageView.backgroundColor = .systemGray6
            }
          }
        }
      }
      
      updateRatingInfo(rating: book.rating)
      updateTotalReadingTime(for: book, totalReadingTime: totalReadingTime)
    }
    
    private func updateRatingInfo(rating: Double) {
      ratingLabel.text = String(format: "%.1f", rating)
    }
    
    private func updateTotalReadingTime(for book: BookEntity, totalReadingTime: TimeInterval) {
      let timeText = Self.timeFormatter.string(from: totalReadingTime) ?? "0m"
      self.timeLabel.text = timeText
    }
  }
}
