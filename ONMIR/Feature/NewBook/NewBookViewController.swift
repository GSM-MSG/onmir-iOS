import SnapKit
import UIKit

public final class NewBookViewController: UIViewController {
  private lazy var searchController: UISearchController = {
    let searchController = UISearchController(searchResultsController: nil)
    searchController.searchBar.placeholder = "Search by title, author or keyword"
    searchController.obscuresBackgroundDuringPresentation = false
    searchController.searchResultsUpdater = self
    searchController.searchBar.delegate = self
    return searchController
  }()

  private let selectedBookView: SelectedBookView = {
    let view = SelectedBookView()
    view.isHidden = true
    view.backgroundColor = .clear
    return view
  }()

  private lazy var collectionView: UICollectionView = {
    let layout = createCompositionalLayout()
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.backgroundColor = .clear
    collectionView.delegate = self
    return collectionView
  }()

  private let viewModel = NewBookViewModel()

  private typealias DataSource = UICollectionViewDiffableDataSource<Int, BookSearchRepresentation>
  private typealias Snapshot = NSDiffableDataSourceSnapshot<Int, BookSearchRepresentation>

  private let bookCellRegistration: UICollectionView.CellRegistration<BookCell, BookSearchRepresentation> =
  UICollectionView.CellRegistration<BookCell, BookSearchRepresentation> {
    cell, indexPath, book in
    cell.configure(with: book)
  }

  private lazy var dataSource: DataSource = DataSource(
    collectionView: collectionView
  ) { [weak self] (collectionView, indexPath, book) -> UICollectionViewCell? in
    guard let self = self else { return nil }
    return collectionView.dequeueConfiguredReusableCell(
      using: self.bookCellRegistration,
      for: indexPath,
      item: book
    )
  }

  private let completion: @MainActor () -> Void

  private var searchTask: Task<Void, Never>?
  private let searchDebounceTime: TimeInterval = 0.3

  private let loadingIndicator: UIActivityIndicatorView = {
    let indicator = UIActivityIndicatorView(style: .medium)
    indicator.hidesWhenStopped = true
    return indicator
  }()

  init(completion: @MainActor @escaping () -> Void) {
    self.completion = completion
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    setupNavigationBar()
    setupBindings()

    var configuration = UIContentUnavailableConfiguration.search()
    configuration.image = .init(systemName: "magnifyingglass.circle")
    configuration.text = "Discover Your Next Great Read"
    configuration.secondaryText = "Search for books by title, author, or genre to begin exploring"

    self.contentUnavailableConfiguration = configuration
  }

  public override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    searchController.searchBar.becomeFirstResponder()
  }
  
  private func setupBindings() {
    observeBooks()
    observeSelectedBooks()
    observeLoadingState()
  }

  private func observeBooks() {
    withObservationTracking {
      _ = viewModel.books
    } onChange: { [weak self] in
      Task { @MainActor in
        guard let self else { return }

        self.updateDataSource(books: self.viewModel.books)
        self.observeBooks()
      }
    }
  }

  private func observeSelectedBooks() {
    withObservationTracking {
      _ = viewModel.selectedBook
    } onChange: { [weak self] in
      Task { @MainActor in
        guard let self else { return }

        self.updateSelectedBook(selectedBook: self.viewModel.selectedBook)
        self.navigationItem.rightBarButtonItem?.isEnabled = self.viewModel.selectedBook != nil
        self.observeSelectedBooks()
      }
    }
  }
  
  private func observeLoadingState() {
    withObservationTracking {
      _ = viewModel.isLoading
    } onChange: { [weak self] in
      Task { @MainActor in
        guard let self else { return }
        
        if self.viewModel.isLoading {
          self.loadingIndicator.startAnimating()
        } else {
          self.loadingIndicator.stopAnimating()
        }
        
        self.observeLoadingState()
      }
    }
  }

  private func setupUI() {
    view.backgroundColor = .secondarySystemBackground

    view.addSubview(selectedBookView)
    view.addSubview(collectionView)
    view.addSubview(loadingIndicator)

    selectedBookView.snp.makeConstraints { make in
      make.top.equalTo(view.safeAreaLayoutGuide)
      make.leading.trailing.equalToSuperview()
    }

    collectionView.snp.makeConstraints { make in
      make.top.equalTo(selectedBookView.snp.bottom)
      make.leading.trailing.bottom.equalToSuperview()
    }
    
    loadingIndicator.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
    }

    updateCollectionViewConstraints()
  }

  private func updateCollectionViewConstraints() {
    if viewModel.selectedBook == nil {
      collectionView.snp.remakeConstraints { make in
        make.top.equalTo(view.safeAreaLayoutGuide)
        make.leading.trailing.bottom.equalToSuperview()
      }
      selectedBookView.isHidden = true
    } else {
      collectionView.snp.remakeConstraints { make in
        make.top.equalTo(selectedBookView.snp.bottom)
        make.leading.trailing.bottom.equalToSuperview()
      }
      selectedBookView.isHidden = false
    }

    UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut) {
      self.view.layoutIfNeeded()
    }
  }

  private func setupNavigationBar() {
    navigationItem.title = "New Book"
    navigationItem.searchController = searchController
    navigationItem.hidesSearchBarWhenScrolling = false
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      title: "Cancel",
      primaryAction: UIAction { [weak self] _ in
        self?.cancelButtonTapped()
      }
    )
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Done",
      primaryAction: UIAction { [weak self] _ in
        self?.doneButtonTapped()
      }
    )
    navigationItem.rightBarButtonItem?.style = .done
    navigationItem.rightBarButtonItem?.isEnabled = false
  }

  private func updateDataSource(books: [BookSearchRepresentation]) {
    var snapshot = Snapshot()

    snapshot.appendSections([0])
    snapshot.appendItems(books)

    dataSource.apply(snapshot, animatingDifferences: true)
    
    updateContentUnavailableConfiguration(isEmpty: books.isEmpty)
  }

  private func updateSelectedBook(selectedBook: BookSearchRepresentation?) {
    if let selectedBook = viewModel.selectedBook {
      selectedBookView.configure(with: selectedBook)
    } else {
      selectedBookView.reset()
    }

    updateCollectionViewConstraints()
  }

  private func cancelButtonTapped() {
    dismiss(animated: true)
  }

  private func doneButtonTapped() {
    guard viewModel.hasSelectedBook else {
      let alert = UIAlertController(
        title: "No Book Selected",
        message: "Please select at least one book to continue.",
        preferredStyle: .alert
      )
      alert.addAction(UIAlertAction(title: "OK", style: .default))
      present(alert, animated: true)
      return
    }

    dismiss(animated: true) { [weak self] in
      self?.completion()
    }
  }

  private func createCompositionalLayout() -> UICollectionViewCompositionalLayout {
    return UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
      var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
      configuration.backgroundColor = .clear
      configuration.separatorConfiguration.bottomSeparatorInsets = .init(top: 0, leading: 90, bottom: 0, trailing: 0)

      let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
      section.interGroupSpacing = 16
      return section
    }
  }

  private func updateContentUnavailableConfiguration(isEmpty: Bool) {
    if isEmpty {
      var configuration = UIContentUnavailableConfiguration.search()
      configuration.image = .init(systemName: "book.closed")
      configuration.text = "No Books Found"
      configuration.secondaryText = "Try different keywords or check for typos in your search"
      
      self.contentUnavailableConfiguration = configuration
    } else {
      self.contentUnavailableConfiguration = nil
    }
  }
  
  private func debouncedSearch(query: String) {
    searchTask?.cancel()
    searchTask = nil
    
    if query.isEmpty {
      updateContentUnavailableConfiguration(isEmpty: true)
      return
    }
    
    searchTask = Task { [weak self] in
      guard let self = self else { return }
      
      try? await Task.sleep(for: .seconds(0.3))
      
      guard !Task.isCancelled else { return }
      
      await self.viewModel.fetchBooks(query: query)
    }
  }
}

extension NewBookViewController: UICollectionViewDelegate {
  public func collectionView(
    _ collectionView: UICollectionView,
    didSelectItemAt indexPath: IndexPath
  ) {
    guard let book = dataSource.itemIdentifier(for: indexPath) else { return }
    viewModel.toggleBookSelection(book: book)
  }
  
  public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let offsetY = scrollView.contentOffset.y
    let contentHeight = scrollView.contentSize.height
    let height = scrollView.frame.size.height
    
    if offsetY > contentHeight - height {
      if let visibleItems = collectionView.indexPathsForVisibleItems.map({ $0.row }).max() {
        viewModel.loadMoreBooksIfNeeded(currentIndex: visibleItems)
      }
    }
  }
}

extension NewBookViewController: UISearchBarDelegate {
  public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    if searchText.isEmpty {
      searchTask?.cancel()
      searchTask = nil
      return
    }
    
    debouncedSearch(query: searchText)
  }
}

extension NewBookViewController: UISearchResultsUpdating {
  public func updateSearchResults(for searchController: UISearchController) {
    guard let searchText = searchController.searchBar.text, !searchText.isEmpty else { return }
    debouncedSearch(query: searchText)
  }
}
