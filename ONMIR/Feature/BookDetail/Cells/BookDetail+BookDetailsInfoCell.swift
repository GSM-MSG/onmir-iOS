import SnapKit
import UIKit

private final class PaddedLabel: UILabel {
  var textInsets = UIEdgeInsets.zero {
    didSet { invalidateIntrinsicContentSize() }
  }
  
  override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
    let insetRect = bounds.inset(by: textInsets)
    let textRect = super.textRect(forBounds: insetRect, limitedToNumberOfLines: numberOfLines)
    let invertedInsets = UIEdgeInsets(
      top: -textInsets.top,
      left: -textInsets.left,
      bottom: -textInsets.bottom,
      right: -textInsets.right
    )
    return textRect.inset(by: invertedInsets)
  }
  
  override func drawText(in rect: CGRect) {
    super.drawText(in: rect.inset(by: textInsets))
  }
}

extension BookDetailViewController {
  final class BookDetailsInfoCell: UICollectionViewCell {
    private let cardView = {
      let view = UIView()
      view.backgroundColor = .secondarySystemBackground
      view.layer.cornerRadius = 16
      view.layer.masksToBounds = false
      return view
    }()
    
    private let stackView = {
      let stackView = UIStackView()
      stackView.axis = .vertical
      stackView.spacing = 16
      stackView.alignment = .fill
      return stackView
    }()
    
    private let statusContainer = {
      let container = UIView()
      return container
    }()
    
    private let statusLabel = {
      let label = PaddedLabel()
      label.font = .systemFont(ofSize: 14, weight: .medium)
      label.textColor = .systemBlue
      label.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
      label.layer.cornerRadius = 8
      label.layer.masksToBounds = true
      label.textAlignment = .center
      label.textInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
      return label
    }()
    
    private let descriptionContainer = {
      let container = UIView()
      return container
    }()
    
    private let descriptionTitleLabel = {
      let label = UILabel()
      label.font = .systemFont(ofSize: 17, weight: .semibold)
      label.text = "Description"
      label.textColor = .label
      return label
    }()
    
    private let descriptionLabel = {
      let label = UILabel()
      label.font = .systemFont(ofSize: 15, weight: .regular)
      label.numberOfLines = 3
      label.textColor = .secondaryLabel
      label.lineBreakMode = .byTruncatingTail
      return label
    }()
    
    private let expandButton = {
      let button = UIButton(type: .system)
      button.setTitle("Expand", for: .normal)
      button.setTitle("Collapse", for: .selected)
      button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
      button.setTitleColor(.systemBlue, for: .normal)
      button.contentHorizontalAlignment = .leading
      return button
    }()
    
    private let metadataContainer = {
      let container = UIView()
      container.backgroundColor = .tertiarySystemBackground
      container.layer.cornerRadius = 12
      container.layer.masksToBounds = true
      return container
    }()
    
    private let metadataStackView = {
      let stackView = UIStackView()
      stackView.axis = .vertical
      stackView.spacing = 8
      stackView.alignment = .fill
      return stackView
    }()
    
    private let isbnLabel = {
      let label = UILabel()
      label.font = .systemFont(ofSize: 14, weight: .regular)
      label.textColor = .secondaryLabel
      return label
    }()
    
    private let publisherLabel = {
      let label = UILabel()
      label.font = .systemFont(ofSize: 14, weight: .regular)
      label.textColor = .secondaryLabel
      return label
    }()
    
    private let publishedDateLabel = {
      let label = UILabel()
      label.font = .systemFont(ofSize: 14, weight: .regular)
      label.textColor = .secondaryLabel
      return label
    }()
    
    private var isDescriptionExpanded = false
    private var fullDescriptionText: String?
    private var onLayoutUpdate: (() -> Void)?
    
    override init(frame: CGRect) {
      super.init(frame: frame)
      setupUI()
    }
    
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
      super.layoutSubviews()
      checkIfTextNeedsTruncation()
    }
    
    override func prepareForReuse() {
      super.prepareForReuse()
      statusLabel.text = nil
      descriptionLabel.text = nil
      isbnLabel.text = nil
      publisherLabel.text = nil
      publishedDateLabel.text = nil
      
      statusContainer.isHidden = false
      descriptionContainer.isHidden = false
      metadataContainer.isHidden = false
      
      isDescriptionExpanded = false
      fullDescriptionText = nil
      expandButton.isSelected = false
      expandButton.isHidden = true
    }
    
    private func setupUI() {
      contentView.addSubview(cardView)
      cardView.addSubview(stackView)
      
      setupStatusContainer()
      setupDescriptionContainer()
      setupMetadataContainer()
      
      stackView.addArrangedSubview(statusContainer)
      stackView.addArrangedSubview(descriptionContainer)
      stackView.addArrangedSubview(metadataContainer)
      
      setupConstraints()
      setupActions()
    }
    
    private func setupStatusContainer() {
      statusContainer.addSubview(statusLabel)
      
      statusLabel.snp.makeConstraints { make in
        make.leading.equalToSuperview()
        make.top.bottom.equalToSuperview()
        make.height.equalTo(28)
      }
    }
    
    private func setupDescriptionContainer() {
      descriptionContainer.addSubview(descriptionTitleLabel)
      descriptionContainer.addSubview(descriptionLabel)
      descriptionContainer.addSubview(expandButton)
      
      descriptionTitleLabel.snp.makeConstraints { make in
        make.top.leading.trailing.equalToSuperview()
      }
      
      descriptionLabel.snp.makeConstraints { make in
        make.top.equalTo(descriptionTitleLabel.snp.bottom).offset(8)
        make.leading.trailing.equalToSuperview()
      }
      
      expandButton.snp.makeConstraints { make in
        make.top.equalTo(descriptionLabel.snp.bottom).offset(8)
        make.leading.trailing.bottom.equalToSuperview()
        make.height.equalTo(20)
      }
    }
    
    private func setupMetadataContainer() {
      metadataContainer.addSubview(metadataStackView)
      
      metadataStackView.addArrangedSubview(isbnLabel)
      metadataStackView.addArrangedSubview(publisherLabel)
      metadataStackView.addArrangedSubview(publishedDateLabel)
      
      metadataStackView.snp.makeConstraints { make in
        make.edges.equalToSuperview().inset(12)
      }
    }
    
    private func setupConstraints() {
      cardView.snp.makeConstraints { make in
        make.edges.equalToSuperview().inset(16)
      }
      
      stackView.snp.makeConstraints { make in
        make.edges.equalToSuperview().inset(20)
      }
    }
    
    private func setupActions() {
      expandButton.addTarget(self, action: #selector(expandButtonTapped), for: .touchUpInside)
    }
    
    @objc private func expandButtonTapped() {
      isDescriptionExpanded.toggle()
      expandButton.isSelected = isDescriptionExpanded
      
      UIView.animate(withDuration: 0.3, animations: {
        if self.isDescriptionExpanded {
          self.descriptionLabel.numberOfLines = 0
        } else {
          self.descriptionLabel.numberOfLines = 3
        }
        self.layoutIfNeeded()
      }) { _ in
        self.onLayoutUpdate?()
      }
    }
    
    func configure(with book: BookEntity, onLayoutUpdate: @escaping () -> Void = {}) {
      self.onLayoutUpdate = onLayoutUpdate
      updateStatusInfo(status: book.status)
      updateDescriptionInfo(description: book.bookDescription)
      updateMetadataInfo(book: book)
    }
    
    private func updateStatusInfo(status: BookStatusTypeKind?) {
      if let status = status {
        statusLabel.text = status.displayName
        statusContainer.isHidden = false
      } else {
        statusContainer.isHidden = true
      }
    }
    
    private func updateDescriptionInfo(description: String?) {
      if let description = description, !description.isEmpty {
        fullDescriptionText = description
        descriptionLabel.text = description
        descriptionContainer.isHidden = false
      } else {
        descriptionContainer.isHidden = true
        expandButton.isHidden = true
      }
    }
    
    private func checkIfTextNeedsTruncation() {
      guard let description = fullDescriptionText else {
        expandButton.isHidden = true
        return
      }
      
      let labelWidth = descriptionLabel.bounds.width
      guard labelWidth > 0 else {
        expandButton.isHidden = true
        return
      }
      
      let tempLabel = UILabel()
      tempLabel.font = descriptionLabel.font
      tempLabel.numberOfLines = 3
      tempLabel.text = description
      tempLabel.lineBreakMode = .byTruncatingTail
      
      let constrainedSize = CGSize(width: labelWidth, height: .greatestFiniteMagnitude)
      let threeLineSize = tempLabel.sizeThatFits(constrainedSize)
      
      tempLabel.numberOfLines = 0
      let fullSize = tempLabel.sizeThatFits(constrainedSize)
      
      expandButton.isHidden = fullSize.height <= threeLineSize.height
    }
    
    private func updateMetadataInfo(book: BookEntity) {
      var hasMetadata = false
      
      if let isbn = book.isbn, !isbn.isEmpty {
        isbnLabel.text = "ISBN: \(isbn)"
        isbnLabel.isHidden = false
        hasMetadata = true
      } else {
        isbnLabel.isHidden = true
      }
      
      if let publisher = book.publisher, !publisher.isEmpty {
        publisherLabel.text = "Publisher: \(publisher)"
        publisherLabel.isHidden = false
        hasMetadata = true
      } else {
        publisherLabel.isHidden = true
      }
      
      if let publishedDate = book.publishedDate {
        publishedDateLabel.text = "Published: \(publishedDate.formatted(.dateTime.year().month().day()))"
        publishedDateLabel.isHidden = false
        hasMetadata = true
      } else {
        publishedDateLabel.isHidden = true
      }
      
      metadataContainer.isHidden = !hasMetadata
    }
  }
}
