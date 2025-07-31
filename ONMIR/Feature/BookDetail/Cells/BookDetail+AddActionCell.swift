import UIKit
import SnapKit

extension BookDetailViewController {
  final class AddActionCell: UICollectionViewCell {
    enum ActionType {
      case newRecord
      case newQuote
      
      var title: String {
        switch self {
        case .newRecord:
          return "+ New Record"
        case .newQuote:
          return "+ New Quote"
        }
      }
    }
    
    private let containerView = {
      let view = UIView()
      view.backgroundColor = .secondarySystemBackground
      view.layer.cornerRadius = 12
      view.layer.masksToBounds = true
      return view
    }()
    
    private let titleLabel = {
      let label = UILabel()
      label.font = .systemFont(ofSize: 16, weight: .medium)
      label.textColor = .label
      label.textAlignment = .center
      return label
    }()
    
    private var actionType: ActionType = .newRecord
    private var onTapped: (() -> Void)?
    
    override init(frame: CGRect) {
      super.init(frame: frame)
      setupUI()
    }
    
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
      super.prepareForReuse()
      titleLabel.text = nil
      onTapped = nil
    }
    
    private func setupUI() {
      contentView.addSubview(containerView)
      containerView.addSubview(titleLabel)
      
      setupConstraints()
      setupTapGesture()
    }
    
    private func setupConstraints() {
      containerView.snp.makeConstraints { make in
        make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
      }
      
      titleLabel.snp.makeConstraints { make in
        make.centerX.equalToSuperview()
        make.verticalEdges.equalToSuperview().inset(12)
      }
    }
    
    private func setupTapGesture() {
      let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
      contentView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleTap() {
      onTapped?()
    }
    
    func configure(actionType: ActionType, onTapped: @escaping () -> Void) {
      self.actionType = actionType
      self.titleLabel.text = actionType.title
      self.onTapped = onTapped
    }
  }
}
