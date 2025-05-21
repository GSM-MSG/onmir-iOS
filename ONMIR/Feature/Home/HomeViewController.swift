import SnapKit
import UIKit

public final class HomeViewController: UIViewController {
    private let bookListSectionRowView = BookListSectionRowView(title: "All")
    
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
        
        view.addSubview(bookListSectionRowView)
        view.addSubview(addBookButton)
        view.addSubview(readingBookCollectionView)
        
        bookListSectionRowView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).inset(24)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        readingBookCollectionView.snp.makeConstraints { make in
            make.top.equalTo(bookListSectionRowView.snp.bottom).offset(30)
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
    
    private func configureSectionRowAction() {
        bookListSectionRowView.onTapped = { [weak self] in
            self?.handleSectionTapped()
        }
    }
    
    private func handleSectionTapped() {
        print("📚 BookListSectionRowView was tapped.")
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
