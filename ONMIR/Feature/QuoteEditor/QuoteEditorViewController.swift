import SnapKit
import UIKit

public final class QuoteEditorViewController: UIViewController {
  private let scrollView = UIScrollView()
  private let contentView = UIView()
  
  private let headerLabel = {
    let label = UILabel()
    label.text = "Quote"
    label.font = UIFont.preferredFont(forTextStyle: .largeTitle)
    label.textColor = .label
    return label
  }()
  
  private let quoteTextView = {
    let textView = UITextView()
    textView.font = UIFont.preferredFont(forTextStyle: .title3)
    textView.textColor = .label
    textView.backgroundColor = .systemBackground
    textView.textContainer.lineFragmentPadding = 0
    textView.textContainerInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    textView.layer.cornerRadius = 16
    textView.layer.borderWidth = 1.0
    textView.layer.borderColor = UIColor.separator.cgColor
    
    textView.layer.shadowColor = UIColor.black.cgColor
    textView.layer.shadowOffset = CGSize(width: 0, height: 1)
    textView.layer.shadowOpacity = 0.05
    textView.layer.shadowRadius = 2
    
    return textView
  }()
  
  private let placeholderLabel = {
    let label = UILabel()
    label.text = "Enter your quote here..."
    label.font = UIFont.preferredFont(forTextStyle: .title3)
    label.textColor = .placeholderText
    label.numberOfLines = 0
    return label
  }()
  
  private let pageLabel = {
    let label = UILabel()
    label.text = "Page"
    label.font = UIFont.preferredFont(forTextStyle: .subheadline)
    label.textColor = .label
    label.accessibilityLabel = "Page number"
    return label
  }()
  
  private let pageTextField = {
    let textField = UITextField()
    textField.font = UIFont.monospacedDigitSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .title3).pointSize, weight: .semibold)
    textField.textColor = .label
    textField.keyboardType = .numberPad
    textField.borderStyle = .none
    textField.backgroundColor = .systemBackground
    textField.layer.cornerRadius = 12
    textField.layer.borderWidth = 1.0
    textField.layer.borderColor = UIColor.separator.cgColor
    textField.placeholder = "1"
    textField.textAlignment = .center
    textField.accessibilityLabel = "Page number"
    textField.accessibilityHint = "Enter the page number for this quote"
    
    textField.layer.shadowColor = UIColor.black.cgColor
    textField.layer.shadowOffset = CGSize(width: 0, height: 1)
    textField.layer.shadowOpacity = 0.05
    textField.layer.shadowRadius = 2
    
    textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
    textField.leftViewMode = .always
    textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
    textField.rightViewMode = .always
    
    return textField
  }()
  
  private let pageRangeLabel = {
    let label = UILabel()
    label.font = UIFont.preferredFont(forTextStyle: .caption1)
    label.textColor = .secondaryLabel
    label.textAlignment = .center
    return label
  }()

  private let doneButton: UIButton = {
    let button = UIButton(type: .system)
    button.setTitle("Done", for: .normal)
    button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
    button.backgroundColor = .label
    button.setTitleColor(.systemBackground, for: .normal)
    button.layer.cornerRadius = 12
    return button
  }()

  private let viewModel: QuoteEditorViewModel
  private let onSaveCompletion: (() -> Void)?

  init(viewModel: QuoteEditorViewModel, onSaveCompletion: (() -> Void)? = nil) {
    self.viewModel = viewModel
    self.onSaveCompletion = onSaveCompletion
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    setupNavigationBar()
    setupActions()
    updateUI()
    updateDoneButtonState()
  }

  private func setupUI() {
    view.backgroundColor = .systemGroupedBackground

    view.addSubview(scrollView)
    view.addSubview(doneButton)
    scrollView.addSubview(contentView)
    
    contentView.addSubview(headerLabel)
    contentView.addSubview(quoteTextView)
    quoteTextView.addSubview(placeholderLabel)
    contentView.addSubview(pageLabel)
    contentView.addSubview(pageTextField)
    contentView.addSubview(pageRangeLabel)
    
    setupConstraints()
  }
  
  private func setupConstraints() {
    scrollView.snp.makeConstraints { make in
      make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
      make.bottom.equalTo(doneButton.snp.top).offset(-24)
    }
    
    contentView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
      make.width.equalToSuperview()
    }
    
    doneButton.snp.makeConstraints { make in
      make.leading.trailing.equalToSuperview().inset(20)
      make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
      make.height.equalTo(50)
    }
    
    // Header
    headerLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().inset(32)
      make.leading.equalToSuperview().inset(20)
    }
    
    // Quote Text View
    quoteTextView.snp.makeConstraints { make in
      make.top.equalTo(headerLabel.snp.bottom).offset(24)
      make.leading.trailing.equalToSuperview().inset(20)
      make.height.greaterThanOrEqualTo(200)
    }
    
    // Page section (Quote 입력 밑으로)
    pageLabel.snp.makeConstraints { make in
      make.top.equalTo(quoteTextView.snp.bottom).offset(24)
      make.leading.equalToSuperview().inset(20)
    }
    
    pageTextField.snp.makeConstraints { make in
      make.top.equalTo(pageLabel.snp.bottom).offset(8)
      make.leading.equalToSuperview().inset(20)
      make.width.equalTo(90)
      make.height.equalTo(44)
    }
    
    pageRangeLabel.snp.makeConstraints { make in
      make.top.equalTo(pageTextField.snp.bottom).offset(4)
      make.leading.equalTo(pageTextField)
      make.bottom.lessThanOrEqualToSuperview().inset(32)
    }
    
    placeholderLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(20)
      make.leading.trailing.equalToSuperview().inset(20)
    }
  }

  private func setupNavigationBar() {
    switch viewModel.editMode {
    case .create:
      title = "New Quote"
    case .edit:
      title = "Edit Quote"
    }

    navigationItem.leftBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .cancel,
      target: self,
      action: #selector(handleCancelButtonTapped)
    )
    
    navigationItem.largeTitleDisplayMode = .never
  }
  
  private func setupActions() {
    doneButton.addAction(UIAction { [weak self] _ in self?.handleDoneButtonTapped() }, for: .primaryActionTriggered)
    
    quoteTextView.delegate = self
    pageTextField.delegate = self
    pageTextField.addAction(UIAction { [weak self] _ in self?.handlePageTextFieldChanged() }, for: .editingChanged)
    
    setupKeyboardToolbar()
  }
  
  private func setupKeyboardToolbar() {
    let toolbar = UIToolbar()
    toolbar.sizeToFit()
    
    let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(handleKeyboardDoneButtonTapped))
    
    toolbar.setItems([flexSpace, doneButton], animated: false)
    
    quoteTextView.inputAccessoryView = toolbar
    pageTextField.inputAccessoryView = toolbar
  }
  
  @objc private func handleKeyboardDoneButtonTapped() {
    view.endEditing(true)
  }
  
  private func updateUI() {
    quoteTextView.text = viewModel.content
    pageTextField.text = "\(viewModel.page)"
    
    placeholderLabel.isHidden = !viewModel.content.isEmpty
    
    if viewModel.totalPages > 0 {
      pageRangeLabel.text = "of \(viewModel.totalPages)"
    } else {
      pageRangeLabel.text = "No limit"
    }
  }

  @objc private func handleCancelButtonTapped() {
    if viewModel.hasChanges {
      let alert = UIAlertController(
        title: "Discard Changes?",
        message: "You have unsaved changes.",
        preferredStyle: .alert
      )

      alert.addAction(UIAlertAction(title: "Keep Editing", style: .cancel))
      alert.addAction(UIAlertAction(title: "Discard", style: .destructive) { _ in
        self.dismiss(animated: true)
      })

      present(alert, animated: true)
    } else {
      dismiss(animated: true)
    }
  }

  private func handleDoneButtonTapped() {
    guard viewModel.isValid else { return }

    Task {
      do {
        try await viewModel.save()
        await MainActor.run {
          self.dismiss(animated: true) {
            self.onSaveCompletion?()
          }
        }
      } catch {
        await MainActor.run {
          let alert = UIAlertController(
            title: "Error",
            message: "Failed to save quote: \(error.localizedDescription)",
            preferredStyle: .alert
          )
          alert.addAction(UIAlertAction(title: "OK", style: .default))
          self.present(alert, animated: true)
        }
      }
    }
  }
  
  private func handlePageTextFieldChanged() {
    guard let text = pageTextField.text, let page = Int(text) else {
      viewModel.page = 1
      pageTextField.text = "1"
      return
    }
    
    let validPage = max(1, min(page, viewModel.totalPages > 0 ? viewModel.totalPages : Int.max))
    if validPage != page {
      pageTextField.text = "\(validPage)"
    }
    
    viewModel.page = validPage
    updateDoneButtonState()
  }
  

  private func updateDoneButtonState() {
    doneButton.isEnabled = viewModel.isValid
    
    if viewModel.isValid {
      doneButton.backgroundColor = .label
      doneButton.setTitleColor(.systemBackground, for: .normal)
      doneButton.alpha = 1.0
    } else {
      doneButton.backgroundColor = .tertiaryLabel
      doneButton.setTitleColor(.secondaryLabel, for: .normal)
      doneButton.alpha = 0.6
    }
  }

}

extension QuoteEditorViewController: UITextViewDelegate {
  public func textViewDidChange(_ textView: UITextView) {
    viewModel.content = textView.text
    placeholderLabel.isHidden = !textView.text.isEmpty
    updateDoneButtonState()
  }
  
  public func textViewDidBeginEditing(_ textView: UITextView) {
    if textView == quoteTextView {
      UIView.animate(withDuration: 0.2) {
        textView.layer.borderColor = UIColor.label.cgColor
        textView.layer.borderWidth = 1.5
        textView.layer.shadowOpacity = 0.1
        textView.layer.shadowRadius = 4
      }
    }
  }
  
  public func textViewDidEndEditing(_ textView: UITextView) {
    if textView == quoteTextView {
      UIView.animate(withDuration: 0.2) {
        textView.layer.borderColor = UIColor.separator.cgColor
        textView.layer.borderWidth = 1.0
        textView.layer.shadowOpacity = 0.05
        textView.layer.shadowRadius = 2
      }
    }
  }
}

extension QuoteEditorViewController: UITextFieldDelegate {
  public func textFieldDidBeginEditing(_ textField: UITextField) {
    if textField == pageTextField {
      UIView.animate(withDuration: 0.2) {
        textField.layer.borderColor = UIColor.label.cgColor
        textField.layer.borderWidth = 1.5
        textField.layer.shadowOpacity = 0.1
        textField.layer.shadowRadius = 4
      }
    }
  }
  
  public func textFieldDidEndEditing(_ textField: UITextField) {
    if textField == pageTextField {
      UIView.animate(withDuration: 0.2) {
        textField.layer.borderColor = UIColor.separator.cgColor
        textField.layer.borderWidth = 1.0
        textField.layer.shadowOpacity = 0.05
        textField.layer.shadowRadius = 2
      }
    }
  }
}
