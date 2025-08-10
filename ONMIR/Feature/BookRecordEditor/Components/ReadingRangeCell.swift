import SnapKit
import UIKit

extension BookRecordEditorViewController {
  final class ReadingRangeCell: UICollectionViewCell {
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

    private let rangeDisplayLabel: UILabel = {
      let label = UILabel()
      label.font = .systemFont(ofSize: 14)
      label.textColor = .secondaryLabel
      return label
    }()

    private let stackView: UIStackView = {
      let stack = UIStackView()
      stack.axis = .horizontal
      stack.spacing = 16
      stack.alignment = .center
      stack.distribution = .fillEqually
      return stack
    }()

    private let startPageTextField: UITextField = {
      let textField = UITextField()
      textField.font = .systemFont(ofSize: 16, weight: .medium)
      textField.textColor = .label
      textField.textAlignment = .center
      textField.keyboardType = .numberPad
      textField.borderStyle = .roundedRect
      textField.backgroundColor = .tertiarySystemGroupedBackground
      return textField
    }()

    private let separatorLabel: UILabel = {
      let label = UILabel()
      label.text = "–"
      label.font = .systemFont(ofSize: 18, weight: .medium)
      label.textColor = .secondaryLabel
      label.textAlignment = .center
      return label
    }()

    private let endPageTextField: UITextField = {
      let textField = UITextField()
      textField.font = .systemFont(ofSize: 16, weight: .medium)
      textField.textColor = .label
      textField.textAlignment = .center
      textField.keyboardType = .numberPad
      textField.borderStyle = .roundedRect
      textField.backgroundColor = .tertiarySystemGroupedBackground
      return textField
    }()

    private var totalPages: Int = 0
    private var rangeChangedHandler: (@MainActor (Int, Int) -> Void)?

    override init(frame: CGRect) {
      super.init(frame: frame)
      setupSubview()
      setupBinding()
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    func configure(
      title: String,
      startPage: Int,
      endPage: Int,
      totalPages: Int,
      rangeChangedHandler: @MainActor @escaping (Int, Int) -> Void
    ) {
      titleLabel.text = title
      self.totalPages = totalPages
      self.rangeChangedHandler = rangeChangedHandler

      startPageTextField.text = "\(startPage)"
      endPageTextField.text = "\(endPage)"
      
      updateRangeDisplay(start: startPage, end: endPage, total: totalPages)
    }

    private func setupSubview() {
      contentView.addSubview(containerView)
      containerView.addSubview(titleLabel)
      containerView.addSubview(rangeDisplayLabel)
      containerView.addSubview(stackView)

      stackView.addArrangedSubview(startPageTextField)
      stackView.addArrangedSubview(separatorLabel)
      stackView.addArrangedSubview(endPageTextField)

      containerView.snp.makeConstraints { make in
        make.edges.equalToSuperview()
      }

      titleLabel.snp.makeConstraints { make in
        make.top.leading.trailing.equalToSuperview().inset(16)
      }

      rangeDisplayLabel.snp.makeConstraints { make in
        make.top.equalTo(titleLabel.snp.bottom).offset(4)
        make.leading.trailing.equalToSuperview().inset(16)
      }

      stackView.snp.makeConstraints { make in
        make.top.equalTo(rangeDisplayLabel.snp.bottom).offset(12)
        make.leading.trailing.equalToSuperview().inset(16)
        make.bottom.equalToSuperview().inset(16)
        make.height.equalTo(44)
      }

      separatorLabel.snp.makeConstraints { make in
        make.width.equalTo(20)
      }

      startPageTextField.delegate = self
      endPageTextField.delegate = self
    }

    private func setupBinding() {
      startPageTextField.addAction(
        UIAction(handler: { [weak self] _ in
          self?.textFieldChanged()
        }),
        for: .editingChanged
      )

      endPageTextField.addAction(
        UIAction(handler: { [weak self] _ in
          self?.textFieldChanged()
        }),
        for: .editingChanged
      )

      let toolBar = UIToolbar()
      toolBar.sizeToFit()
      let doneButton = UIBarButtonItem(
        barButtonSystemItem: .done,
        target: self,
        action: #selector(doneButtonTapped)
      )
      let flexSpace = UIBarButtonItem(
        barButtonSystemItem: .flexibleSpace,
        target: nil,
        action: nil
      )
      toolBar.items = [flexSpace, doneButton]
      
      startPageTextField.inputAccessoryView = toolBar
      endPageTextField.inputAccessoryView = toolBar
    }

    private func textFieldChanged() {
      let startPage = Int(startPageTextField.text ?? "0") ?? 0
      let endPage = Int(endPageTextField.text ?? "0") ?? 0
      
      let validStartPage = max(0, min(startPage, totalPages))
      let validEndPage = max(validStartPage, min(endPage, totalPages))
      
      updateRangeDisplay(start: validStartPage, end: validEndPage, total: totalPages)
      rangeChangedHandler?(validStartPage, validEndPage)
    }

    private func updateRangeDisplay(start: Int, end: Int, total: Int) {
      let pagesRead = max(0, end - start)
      rangeDisplayLabel.text = "\(pagesRead) pages read of \(total) total"
    }

    @objc private func doneButtonTapped() {
      startPageTextField.resignFirstResponder()
      endPageTextField.resignFirstResponder()
    }
  }
}

extension BookRecordEditorViewController.ReadingRangeCell: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    if textField == startPageTextField {
      endPageTextField.becomeFirstResponder()
    } else {
      textField.resignFirstResponder()
    }
    return true
  }

  func textField(
    _ textField: UITextField,
    shouldChangeCharactersIn range: NSRange,
    replacementString string: String
  ) -> Bool {
    let allowedCharacters = CharacterSet.decimalDigits
    let characterSet = CharacterSet(charactersIn: string)
    return allowedCharacters.isSuperset(of: characterSet)
  }
}
