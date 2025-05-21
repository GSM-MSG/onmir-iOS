import SnapKit
import UIKit

final class BookListSectionRowView: UIView {
    private let bookListStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .leading 
        stackView.distribution = .fill
        return stackView
    }()

    private let listContentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.alignment = .center
        stackView.distribution = .fill
        return stackView
    }()

    private let divider1 = DividerView()
    private let divider2 = DividerView()
    
    private let listIcon: UIImageView = {
        let imageview = UIImageView()
        imageview.contentMode = .scaleAspectFit
        imageview.backgroundColor = .clear
        imageview.image = UIImage(systemName: "list.bullet")
        imageview.tintColor = .label
        return imageview
    }()
    
    private let listTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "All"
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private let chevronRightIcon: UIImageView = {
        let imageview = UIImageView()
        imageview.contentMode = .scaleAspectFit
        imageview.backgroundColor = .clear
        imageview.image = UIImage(systemName: "chevron.right")
        imageview.tintColor = UIColor.quaternaryLabel
        return imageview
    }()
    
    private lazy var tapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        return gesture
    }()
    
    var onTapped: (() -> Void)?
    
    init(title: String) {
        super.init(frame: .zero)
        self.listTitleLabel.text = title

        setupView()
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        self.backgroundColor = .clear

        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true

        listContentStackView.addArrangedSubview(listIcon)
        listContentStackView.addArrangedSubview(listTitleLabel)
        listContentStackView.addArrangedSubview(chevronRightIcon)

        bookListStackView.addArrangedSubview(divider1)
        bookListStackView.addArrangedSubview(listContentStackView)
        bookListStackView.addArrangedSubview(divider2)

        addSubview(bookListStackView)
    }
    
    private func setupLayout() {
        bookListStackView.snp.makeConstraints { make in
            make.top.leading.trailing.bottom.equalToSuperview()
        }
        
        listContentStackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
        }
    
        listIcon.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }

        chevronRightIcon.snp.makeConstraints { make in
            make.width.equalTo(12)
            make.height.equalTo(17)
        }

        divider1.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
        }

        divider2.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
        }
    }
    
    @objc private func handleTap() {
        onTapped?()
    }
}
