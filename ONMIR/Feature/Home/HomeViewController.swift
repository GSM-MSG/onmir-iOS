import UIKit
import SnapKit

public final class HomeViewController: UIViewController {
    private let listIcon: UIImageView = {
        let imageview = UIImageView()
        imageview.contentMode = .scaleAspectFit
        imageview.backgroundColor = .clear
        imageview.image = UIImage(systemName: "list.bullet")
        imageview.tintColor = .black
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
        imageview.tintColor = .systemGray3
        return imageview
    }()

    private let addBookButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.backgroundColor = .black
        button.tintColor = .white
        button.layer.cornerRadius = 30
        return button
    }()

    public override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupNavigationBar()
    }

    func setupNavigationBar() {
        navigationItem.title = "Library"
        navigationItem.largeTitleDisplayMode = .automatic
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(listIcon)
        view.addSubview(listTitleLabel)
        view.addSubview(chevronRightIcon)
        view.addSubview(addBookButton)

        listIcon.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).inset(40)
            make.leading.equalTo(view.safeAreaLayoutGuide).inset(16)
        }
        listTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).inset(40)
            make.leading.equalTo(listIcon.snp.trailing).offset(12)
        }
        chevronRightIcon.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).inset(40)
            make.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
        }
        addBookButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
            make.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.height.width.equalTo(60)
        }
    }
}

