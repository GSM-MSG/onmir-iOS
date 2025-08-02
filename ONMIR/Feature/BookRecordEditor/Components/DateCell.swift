import SnapKit
import UIKit

extension BookRecordEditorViewController {
  final class DateCell: UICollectionViewCell {
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

    private let dateLabel: UILabel = {
      let label = UILabel()
      label.font = .systemFont(ofSize: 14)
      label.textColor = .secondaryLabel
      return label
    }()

    private let datePicker: UIDatePicker = {
      let picker = UIDatePicker()
      picker.datePickerMode = .date
      picker.preferredDatePickerStyle = .compact
      picker.maximumDate = Date()
      return picker
    }()

    private var dateChangedHandler: (@MainActor (Date) -> Void)?

    override init(frame: CGRect) {
      super.init(frame: frame)
      setupView()
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    func configure(
      title: String,
      date: Date,
      dateChangedHandler: @MainActor @escaping (Date) -> Void
    ) {
      titleLabel.text = title
      self.dateChangedHandler = dateChangedHandler
      
      dateLabel.text = date.formatted(.dateTime.year().month().day())
      datePicker.date = date
    }

    private func setupView() {
      contentView.addSubview(containerView)
      containerView.addSubview(titleLabel)
      containerView.addSubview(dateLabel)
      containerView.addSubview(datePicker)

      containerView.snp.makeConstraints { make in
        make.edges.equalToSuperview()
      }

      titleLabel.snp.makeConstraints { make in
        make.top.leading.equalToSuperview().inset(16)
      }

      dateLabel.snp.makeConstraints { make in
        make.top.equalTo(titleLabel.snp.bottom).offset(0)
        make.leading.equalToSuperview().inset(16)
      }

      datePicker.snp.makeConstraints { make in
        make.verticalEdges.equalToSuperview().inset(16)
        make.trailing.equalToSuperview().inset(16)
      }

      datePicker.addAction(
        UIAction(handler: { [weak self] _ in
          self?.datePickerValueChanged()
        }),
        for: .valueChanged
      )
    }

    private func datePickerValueChanged() {
      let selectedDate = datePicker.date
      dateLabel.text = selectedDate.formatted(.dateTime.year().month().day())
      dateChangedHandler?(selectedDate)
    }
  }
}
