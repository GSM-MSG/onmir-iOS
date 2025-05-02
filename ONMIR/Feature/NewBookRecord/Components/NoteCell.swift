import SnapKit
import UIKit

extension NewBookRecordViewController {
  final class NoteCell: UICollectionViewCell {
    private let containerView: UIView = {
      let view = UIView()
      view.backgroundColor = .secondarySystemGroupedBackground
      view.layer.cornerRadius = 12
      return view
    }()

    private let titleLabel: UILabel = {
      let label = UILabel()
      label.font = .systemFont(ofSize: 16, weight: .bold)
      label.textColor = .label
      return label
    }()

    private let textView: UITextView = {
      let textView = UITextView()
      textView.font = .systemFont(ofSize: 14)
      textView.backgroundColor = .clear
      textView.isScrollEnabled = false
      textView.textContainerInset = UIEdgeInsets(
        top: 8,
        left: 8,
        bottom: 8,
        right: 8
      )
      textView.layer.borderColor = UIColor.systemGray5.cgColor
      textView.layer.borderWidth = 0.5
      textView.layer.cornerRadius = 8
      return textView
    }()

    private var textChangedHandler: (@MainActor (String) -> Void)?

    private var textViewHeightConstraint: Constraint?
    private var currentTextHeight: CGFloat = 100

    override init(frame: CGRect) {
      super.init(frame: frame)
      setupView()
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
      contentView.addSubview(containerView)
      containerView.addSubview(titleLabel)
      containerView.addSubview(textView)

      containerView.snp.makeConstraints { make in
        make.edges.equalToSuperview()
      }

      titleLabel.snp.makeConstraints { make in
        make.top.horizontalEdges.equalToSuperview().inset(16)
      }

      textView.snp.makeConstraints { make in
        make.top.equalTo(titleLabel.snp.bottom).offset(8)
        make.horizontalEdges.equalToSuperview().inset(16)
        make.bottom.lessThanOrEqualToSuperview().inset(16)
        textViewHeightConstraint = make.height.equalTo(100).constraint
      }

      textView.delegate = self
    }

    override func layoutSubviews() {
      super.layoutSubviews()

      if textView.bounds.width > 0 {
        updateTextViewHeight()
      }
    }

    func configure(
      title: String,
      note: String,
      textChangedHandler: @MainActor @escaping (String) -> Void
    ) {
      titleLabel.text = title
      self.textChangedHandler = textChangedHandler

      textView.text = note

      setNeedsLayout()
      layoutIfNeeded()
      updateTextViewHeight()
    }

    private func updateTextViewHeight() {
      guard textView.bounds.width > 0 else {
        return
      }

      let fixedWidth =
        textView.frame.width - textView.textContainerInset.left
        - textView.textContainerInset.right - 2
        * textView.textContainer.lineFragmentPadding

      let textString = textView.text ?? ""
      let textStorage = NSTextStorage(
        string: textString,
        attributes: [
          .font: textView.font ?? UIFont.systemFont(ofSize: 14)
        ]
      )

      let textContainer = NSTextContainer(
        size: CGSize(width: fixedWidth, height: .greatestFiniteMagnitude))
      textContainer.lineFragmentPadding =
        textView.textContainer.lineFragmentPadding
      textContainer.lineBreakMode = .byWordWrapping

      let layoutManager = NSLayoutManager()
      layoutManager.addTextContainer(textContainer)
      textStorage.addLayoutManager(layoutManager)

      layoutManager.ensureLayout(for: textContainer)

      let usedRect = layoutManager.usedRect(for: textContainer)
      let newHeight = max(
        100,
        ceil(usedRect.height + textView.textContainerInset.top
            + textView.textContainerInset.bottom)
      )

      if abs(newHeight - currentTextHeight) > 1 {
        textViewHeightConstraint?.update(offset: newHeight)
        currentTextHeight = newHeight

        invalidateIntrinsicContentSize()
      }
    }

    override func preferredLayoutAttributesFitting(
      _ layoutAttributes: UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutAttributes {
      let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)

      let titleHeight = titleLabel.frame.height
      let spacing: CGFloat = 8
      let verticalInsets: CGFloat = 32

      let totalHeight =
        titleHeight + spacing + currentTextHeight + verticalInsets
      attributes.frame.size.height = totalHeight

      return attributes
    }
  }
}

extension NewBookRecordViewController.NoteCell: UITextViewDelegate {
  func textViewDidChange(_ textView: UITextView) {
    textChangedHandler?(textView.text)
    updateTextViewHeight()
  }
}
