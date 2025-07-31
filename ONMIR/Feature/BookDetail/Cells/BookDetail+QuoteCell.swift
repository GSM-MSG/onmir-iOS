import UIKit
import SnapKit

extension BookDetailViewController {
  final class QuoteCell: UICollectionViewCell {
    private let containerView = {
      let view = UIView()
      view.backgroundColor = .secondarySystemBackground
      view.layer.cornerRadius = 12
      view.layer.masksToBounds = false
      return view
    }()
    
    private let quoteIconImageView = {
      let imageView = UIImageView()
      let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .bold)
      imageView.image = UIImage(systemName: "quote.opening", withConfiguration: config)
      imageView.tintColor = .label
      imageView.contentMode = .scaleAspectFit
      return imageView
    }()
    
    private let contentLabel = {
      let label = UILabel()
      label.font = .systemFont(ofSize: 17, weight: .bold)
      label.textColor = .label
      label.numberOfLines = 0
      label.textAlignment = .center
      return label
    }()
    
    private let pageLabel = {
      let label = UILabel()
      label.isHidden = true
      return label
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
      contentLabel.text = nil
      pageLabel.text = nil
    }
    
    private func setupUI() {
      contentView.addSubview(containerView)
      
      [quoteIconImageView, contentLabel].forEach {
        containerView.addSubview($0)
      }
      
      setupConstraints()
    }
    
    private func setupConstraints() {
      containerView.snp.makeConstraints { make in
        make.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16))
      }
      
      quoteIconImageView.snp.makeConstraints { make in
        make.leading.equalToSuperview().inset(16)
        make.size.equalTo(32)
        make.centerY.equalToSuperview()
      }
      
      contentLabel.snp.makeConstraints { make in
        make.leading.equalTo(quoteIconImageView.snp.trailing).offset(16)
        make.trailing.equalToSuperview().inset(16)
        make.centerY.equalToSuperview()
        make.top.bottom.equalToSuperview().inset(16)
      }
    }
    
    func configure(with quote: QuoteEntity) {
      contentLabel.text = quote.content ?? ""
    }
  }
}
