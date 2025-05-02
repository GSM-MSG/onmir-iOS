import SnapKit
import UIKit

extension NewBookRecordViewController {
  final class ReadingProgressCell: UICollectionViewCell {
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

    private let pageInfoContainer: UIControl = {
      let view = UIControl()
      view.isUserInteractionEnabled = true
      return view
    }()

    private let pageInfoLabel: UILabel = {
      let label = UILabel()
      label.font = .systemFont(ofSize: 14)
      label.textColor = .secondaryLabel
      return label
    }()

    private let pageTextField: UITextField = {
      let textField = UITextField()
      textField.font = .systemFont(ofSize: 14)
      textField.textColor = .secondaryLabel
      textField.textAlignment = .left
      textField.keyboardType = .numberPad
      textField.borderStyle = .none
      textField.isHidden = true
      return textField
    }()

    private let pencilImageView: UIImageView = {
      let imageView = UIImageView()
      imageView.image = UIImage(systemName: "pencil")
      imageView.tintColor = .gray
      return imageView
    }()

    private let slider: UISlider = {
      let slider = UISlider()
      slider.minimumTrackTintColor = .systemBlue
      return slider
    }()

    private let minLabel: UILabel = {
      let label = UILabel()
      label.font = .systemFont(ofSize: 14)
      label.textColor = .tertiaryLabel
      label.text = "0"
      return label
    }()

    private let maxLabel: UILabel = {
      let label = UILabel()
      label.font = .systemFont(ofSize: 14)
      label.textColor = .tertiaryLabel
      label.textAlignment = .right
      return label
    }()

    private var totalPages: Int = 0
    private var valueChangedHandler: (@MainActor (Int) -> Void)?

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
      currentPage: Int,
      totalPages: Int,
      valueChangedHandler: @MainActor @escaping (Int) -> Void
    ) {
      titleLabel.text = title
      self.totalPages = totalPages
      self.valueChangedHandler = valueChangedHandler

      updatePageInfoDisplay(page: currentPage)
      maxLabel.text = "\(totalPages)"

      slider.minimumValue = 0
      slider.maximumValue = Float(totalPages)
      slider.value = Float(currentPage)
    }

    private func setupSubview() {
      contentView.addSubview(containerView)

      containerView.addSubview(titleLabel)
      containerView.addSubview(pageInfoContainer)
      pageInfoContainer.addSubview(pageInfoLabel)
      pageInfoContainer.addSubview(pageTextField)

      containerView.addSubview(pencilImageView)
      containerView.addSubview(slider)
      containerView.addSubview(minLabel)
      containerView.addSubview(maxLabel)

      containerView.snp.makeConstraints { make in
        make.edges.equalToSuperview()
      }

      titleLabel.snp.makeConstraints { make in
        make.top.leading.trailing.equalToSuperview().inset(16)
      }

      pageInfoContainer.snp.makeConstraints { make in
        make.top.equalTo(titleLabel.snp.bottom).offset(4)
        make.leading.equalToSuperview().inset(16)
        make.height.equalTo(30)
      }

      pageInfoLabel.snp.makeConstraints { make in
        make.edges.equalToSuperview()
      }

      pageTextField.snp.makeConstraints { make in
        make.edges.equalToSuperview()
        make.width.greaterThanOrEqualTo(60)
      }

      pencilImageView.snp.makeConstraints { make in
        make.centerY.equalTo(pageInfoContainer)
        make.leading.equalTo(pageInfoContainer.snp.trailing).offset(2)
        make.height.equalTo(16)
        make.width.equalTo(14)
      }

      slider.snp.makeConstraints { make in
        make.top.equalTo(pageInfoContainer.snp.bottom).offset(20)
        make.horizontalEdges.equalToSuperview().inset(16)
      }

      minLabel.snp.makeConstraints { make in
        make.top.equalTo(slider.snp.bottom).offset(8)
        make.leading.equalToSuperview().inset(16)
        make.bottom.equalToSuperview().inset(16)
      }

      maxLabel.snp.makeConstraints { make in
        make.top.equalTo(slider.snp.bottom).offset(8)
        make.trailing.equalToSuperview().inset(16)
        make.bottom.equalToSuperview().inset(16)
      }

      pageTextField.delegate = self
    }

    private func setupBinding() {
      slider.addAction(
        UIAction(handler: { [weak self] _ in
          self?.sliderValueChanged()
        }),
        for: .valueChanged
      )

      pageInfoContainer.addAction(
        UIAction(handler: { [weak self] _ in
          self?.pageInfoTapped()
        }),
        for: .touchUpInside
      )

      let toolBar = UIToolbar()
      toolBar.sizeToFit()
      let doneButton = UIBarButtonItem(
        title: "Done",
        primaryAction: UIAction(handler: { [weak self] _ in
          self?.doneButtonTapped()
        })
      )
      let flexSpace = UIBarButtonItem(
        barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
      toolBar.items = [flexSpace, doneButton]
      pageTextField.inputAccessoryView = toolBar
    }

    private func updatePageInfoDisplay(page: Int) {
      pageInfoLabel.text = "\(page) - \(totalPages)"
      pageTextField.text = "\(page)"
    }

    private func sliderValueChanged() {
      let value = Int(slider.value)
      updatePageInfoDisplay(page: value)
      valueChangedHandler?(value)
    }

    private func pageInfoTapped() {
      pageInfoLabel.isHidden = true
      pageTextField.isHidden = false
      pageTextField.becomeFirstResponder()
    }

    private func doneButtonTapped() {
      submitTextFieldValue()
    }

    private func submitTextFieldValue() {
      if let text = pageTextField.text, let page = Int(text) {
        let validPage = min(max(0, page), totalPages)
        slider.value = Float(validPage)
        updatePageInfoDisplay(page: validPage)
        valueChangedHandler?(validPage)
      }

      pageTextField.resignFirstResponder()
      pageTextField.isHidden = true
      pageInfoLabel.isHidden = false
    }
  }
}

extension NewBookRecordViewController.ReadingProgressCell: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    submitTextFieldValue()
    return true
  }

  func textField(
    _ textField: UITextField, shouldChangeCharactersIn range: NSRange,
    replacementString string: String
  ) -> Bool {
    let allowedCharacters = CharacterSet.decimalDigits
    let characterSet = CharacterSet(charactersIn: string)
    return allowedCharacters.isSuperset(of: characterSet)
  }
}
