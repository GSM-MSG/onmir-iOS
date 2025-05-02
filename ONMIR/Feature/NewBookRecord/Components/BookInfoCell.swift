import Nuke
import SnapKit
import UIKit

extension NewBookRecordViewController {
  final class BookInfoCell: UICollectionViewCell {
    private let containerView: UIView = {
      let view = UIView()
      view.backgroundColor = .clear
      view.layer.cornerRadius = 12
      return view
    }()
    
    private let coverImageView: UIImageView = {
      let imageView = UIImageView()
      imageView.contentMode = .scaleAspectFit
      imageView.backgroundColor = .tertiarySystemBackground
      imageView.layer.cornerRadius = 8
      imageView.clipsToBounds = true
      return imageView
    }()
    
    private let titleLabel: UILabel = {
      let label = UILabel()
      label.font = .systemFont(ofSize: 16, weight: .bold)
      label.numberOfLines = 0
      label.textAlignment = .left
      return label
    }()
    
    private let authorsLabel: UILabel = {
      let label = UILabel()
      label.font = .systemFont(ofSize: 14)
      label.textColor = .secondaryLabel
      label.numberOfLines = 0
      label.textAlignment = .left
      return label
    }()
    
    private var imageLoadTask: Task<Void, Never>?
    
    override init(frame: CGRect) {
      super.init(frame: frame)
      setupView()
    }
    
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
      super.prepareForReuse()
      imageLoadTask?.cancel()
      imageLoadTask = nil
      coverImageView.image = nil
      titleLabel.text = nil
      authorsLabel.text = nil
    }
    
    private func setupView() {
      contentView.addSubview(containerView)
      containerView.addSubview(coverImageView)
      containerView.addSubview(titleLabel)
      containerView.addSubview(authorsLabel)
      
      containerView.snp.makeConstraints { make in
        make.edges.equalToSuperview()
      }
      
      coverImageView.snp.makeConstraints { make in
        make.leading.top.bottom.equalToSuperview()
        make.height.equalTo(100)
        make.width.equalTo(coverImageView.snp.height).multipliedBy(0.67)
      }
      
      titleLabel.snp.makeConstraints { make in
        make.leading.equalTo(coverImageView.snp.trailing).offset(16)
        make.top.equalToSuperview()
        make.trailing.equalToSuperview()
      }
      
      authorsLabel.snp.makeConstraints { make in
        make.leading.equalTo(coverImageView.snp.trailing).offset(16)
        make.top.equalTo(titleLabel.snp.bottom).offset(8)
        make.trailing.equalToSuperview()
      }
    }
    
    func configure(with book: BookRepresentation) {
      titleLabel.text = book.volumeInfo.title
      
      if let authors = book.volumeInfo.authors, !authors.isEmpty {
        authorsLabel.text = authors.joined(separator: ", ")
      }
      
      if let thumbnailURLString = book.volumeInfo.imageLinks?.thumbnail {
        let secureURL = thumbnailURLString.replacingOccurrences(
          of: "http://",
          with: "https://"
        )
        if let thumbnailURL = URL(string: secureURL) {
          imageLoadTask = Task {
            do {
              let image = try await ImagePipeline.shared.image(for: thumbnailURL)
              if !Task.isCancelled {
                self.coverImageView.image = image
              }
            } catch {
              print("이미지 로딩 실패: \(error)")
            }
          }
        }
      }
    }
  }
}
