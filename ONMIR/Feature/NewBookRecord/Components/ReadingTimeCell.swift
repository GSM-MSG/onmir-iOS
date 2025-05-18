import SnapKit
import UIKit

extension NewBookRecordViewController {
  final class ReadingTimeCell: UICollectionViewCell {
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

    private let timeLabel: UILabel = {
      let label = UILabel()
      label.font = .systemFont(ofSize: 14)
      label.textColor = .label
      return label
    }()

    private let datePicker: UIDatePicker = {
      let picker = UIDatePicker()
      picker.datePickerMode = .countDownTimer
      picker.backgroundColor = .secondarySystemGroupedBackground
      picker.preferredDatePickerStyle = .wheels
      return picker
    }()

    private let dateComponentsFormatter: DateComponentsFormatter = {
      let formatter = DateComponentsFormatter()
      formatter.allowedUnits = [.hour, .minute]
      formatter.unitsStyle = .abbreviated
      return formatter
    }()

    private var durationChangedHandler: (@MainActor (TimeInterval) -> Void)?

    override init(frame: CGRect) {
      super.init(frame: frame)
      setupView()
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    func configure(
      title: String,
      duration: TimeInterval,
      durationChangedHandler: @MainActor @escaping (TimeInterval) -> Void
    ) {
      titleLabel.text = title
      self.durationChangedHandler = durationChangedHandler
      
      timeLabel.text = dateComponentsFormatter.string(from: duration)
      
      datePicker.countDownDuration = duration
    }

    private func setupView() {
      contentView.addSubview(containerView)
      containerView.addSubview(titleLabel)
      containerView.addSubview(timeLabel)
      containerView.addSubview(datePicker)

      containerView.snp.makeConstraints { make in
        make.edges.equalToSuperview()
      }

      titleLabel.snp.makeConstraints { make in
        make.top.horizontalEdges.equalToSuperview().inset(16)
      }

      timeLabel.snp.makeConstraints { make in
        make.top.equalTo(titleLabel.snp.bottom).offset(4)
        make.leading.equalToSuperview().inset(16)
      }

      datePicker.snp.makeConstraints { make in
        make.top.equalTo(timeLabel.snp.bottom).offset(8)
        make.leading.trailing.equalToSuperview()
        make.bottom.equalToSuperview().inset(16)
        make.height.equalTo(160)
      }

      datePicker.addAction(
        UIAction(handler: { [weak self] _ in
          self?.datePickerValueChanged()
        }),
        for: .valueChanged
      )
    }

    private func datePickerValueChanged() {
      let duration = datePicker.countDownDuration
      let string = dateComponentsFormatter.string(from: duration)

      timeLabel.text = string

      durationChangedHandler?(duration)
    }
  }
}
