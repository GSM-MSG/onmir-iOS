import UIKit
import SnapKit

final class QuoteTableViewCell: UITableViewCell {
  private let containerView = {
    let view = UIView()
    view.backgroundColor = .secondarySystemBackground
    view.layer.cornerRadius = 12
    view.layer.masksToBounds = false
    return view
  }()
  
  private let quoteIconImageView = {
    let imageView = UIImageView()
    let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
    imageView.image = UIImage(systemName: "quote.opening", withConfiguration: config)
    imageView.tintColor = .secondaryLabel
    imageView.contentMode = .scaleAspectFit
    return imageView
  }()
  
  private let contentLabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 16, weight: .medium)
    label.textColor = .label
    label.numberOfLines = 0
    return label
  }()
  
  private let pageLabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 14, weight: .regular)
    label.textColor = .secondaryLabel
    return label
  }()
  
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
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
    backgroundColor = .clear
    selectionStyle = .none
    
    contentView.addSubview(containerView)
    
    [quoteIconImageView, contentLabel, pageLabel].forEach {
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
      make.top.equalToSuperview().inset(16)
      make.size.equalTo(24)
    }
    
    contentLabel.snp.makeConstraints { make in
      make.leading.equalTo(quoteIconImageView.snp.trailing).offset(12)
      make.trailing.equalToSuperview().inset(16)
      make.top.equalTo(quoteIconImageView.snp.top)
    }
    
    pageLabel.snp.makeConstraints { make in
      make.leading.trailing.equalTo(contentLabel)
      make.top.equalTo(contentLabel.snp.bottom).offset(8)
      make.bottom.equalToSuperview().inset(16)
    }
  }
  
  func configure(with quote: QuoteEntity) {
    contentLabel.text = quote.content ?? ""
    
    let page = quote.page
    if page > 0 {
      pageLabel.text = "Page \(page)"
    } else {
      pageLabel.text = "No page specified"
    }
  }
}