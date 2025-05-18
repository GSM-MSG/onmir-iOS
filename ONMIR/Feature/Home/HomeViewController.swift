import UIKit
import SnapKit

public final class HomeViewController: UIViewController {
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
    
    private lazy var readingBookCollectionView: UICollectionView = {
        let layout = createCompositionalLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.register(HomeViewController.ReadingBookCell.self, forCellWithReuseIdentifier: HomeViewController.ReadingBookCell.id)
        return collectionView
    }()
    
    private let addBookButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.backgroundColor = UIColor(named: "ButtonBackground")
        button.tintColor = UIColor(named: "ButtonText")
        button.layer.cornerRadius = 30
        return button
    }()
    
    private let viewModel = HomeViewModel()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupNavigationBar()
        updateContentUnavailableView(isEmpty: viewModel.books.isEmpty)
    }
    
    private func setupNavigationBar() {
        navigationItem.title = "Library"
        navigationItem.largeTitleDisplayMode = .automatic
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    private func setupUI() {
        view.backgroundColor = .secondarySystemBackground
        
        view.addSubview(divider1)
        view.addSubview(listIcon)
        view.addSubview(listTitleLabel)
        view.addSubview(chevronRightIcon)
        view.addSubview(addBookButton)
        view.addSubview(readingBookCollectionView)
        view.addSubview(divider2)
        
        divider1.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).inset(24)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        listIcon.snp.makeConstraints { make in
            make.top.equalTo(divider1.snp.bottom).offset(12)
            make.leading.equalTo(view.safeAreaLayoutGuide).inset(16)
        }
        
        listTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(divider1.snp.bottom).offset(12)
            make.leading.equalTo(listIcon.snp.trailing).offset(12)
        }
        
        chevronRightIcon.snp.makeConstraints { make in
            make.top.equalTo(divider1.snp.bottom).offset(12)
            make.trailing.equalToSuperview().inset(16)
        }
        
        divider2.snp.makeConstraints { make in
            make.top.equalTo(listTitleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        readingBookCollectionView.snp.makeConstraints { make in
            make.top.equalTo(divider2.snp.bottom).offset(30)
            make.leading.equalToSuperview().inset(50)
            make.trailing.bottom.equalToSuperview()
        }
        
        addBookButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
            make.trailing.equalToSuperview().inset(16)
            make.height.width.equalTo(60)
        }
    }
    
    private func createCompositionalLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { sectionIndex, environment in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(0.7),
                heightDimension: .fractionalHeight(1.0)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .groupPagingCentered
            section.interGroupSpacing = 50
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 50)
            return section
        }
    }
    
    private func updateContentUnavailableView(isEmpty: Bool) {
        if isEmpty {
            var configuration = UIContentUnavailableConfiguration.empty()
            configuration.image = .init(systemName: "book")
            configuration.text = "No book in progress"
            configuration.secondaryText = "Books you're currently reading will appear here."
            configuration.button.title = "Add Book"
            configuration.button.background.backgroundColor = .systemBlue
            configuration.button.baseForegroundColor = .white

            self.contentUnavailableConfiguration = configuration
        } else {
            self.contentUnavailableConfiguration = nil
        }
    }
}

extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeViewController.ReadingBookCell.id, for: indexPath) as? HomeViewController.ReadingBookCell else {
            return UICollectionViewCell()
        }
        
        let book = viewModel.books[indexPath.item]
        cell.prepare(
            imageURL: book.imageURL,
            currentPage: book.currentPage,
            totalPage: book.totalPage
        )
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.books.count
    }
}
