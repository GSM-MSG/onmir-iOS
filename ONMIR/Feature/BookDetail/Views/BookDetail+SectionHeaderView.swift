import UIKit
import SnapKit

extension BookDetailViewController {
  final class SectionHeaderView: UICollectionReusableView {
    private let titleLabel = {
      let label = UILabel()
      label.font = .systemFont(ofSize: 24, weight: .heavy)
      label.textColor = .label
      return label
    }()
    
    private let viewAllButton = {
      var config = UIButton.Configuration.plain()
      config.title = "More"
      config.baseForegroundColor = .systemGray
      config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
        var outgoing = incoming
        outgoing.font = .systemFont(ofSize: 15, weight: .medium)
        return outgoing
      }
      let button = UIButton(configuration: config)
      return button
    }()
    
    private var onViewAllTapped: (() -> Void)?
    
    override init(frame: CGRect) {
      super.init(frame: frame)
      setupUI()
    }
    
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
      backgroundColor = .clear
      
      let viewAllAction = UIAction { [weak self] _ in
        self?.onViewAllTapped?()
      }
      viewAllButton.addAction(viewAllAction, for: .primaryActionTriggered)
      
      [titleLabel, viewAllButton].forEach {
        addSubview($0)
      }
      
      setupConstraints()
    }
    
    private func setupConstraints() {
      titleLabel.snp.makeConstraints { make in
        make.centerY.equalToSuperview()
        make.leading.equalToSuperview().inset(16)
      }
      
      viewAllButton.snp.makeConstraints { make in
        make.centerY.equalToSuperview()
        make.trailing.equalToSuperview().inset(16)
        make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(8)
      }
    }
    
    
    func configure(title: String, showViewAll: Bool, onViewAllTapped: @escaping () -> Void) {
      titleLabel.text = title
      viewAllButton.isHidden = !showViewAll
      self.onViewAllTapped = onViewAllTapped
    }
  }
}
