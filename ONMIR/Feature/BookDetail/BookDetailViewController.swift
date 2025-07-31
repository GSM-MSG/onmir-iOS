@preconcurrency import CoreData
import Nuke
import SnapKit
import UIKit

final class BookDetailViewController: UIViewController {
  enum Section: CaseIterable {
    case bookInfo
    case readingLogs
    case quotes
  }

  enum Item: Hashable, @unchecked Sendable {
    case book(BookEntity)
    case readingLog(ReadingLogEntity)
    case quote(QuoteEntity)
    case addRecord
    case addQuote
  }

  private let viewModel = BookDetailViewModel()
  private lazy var dataSource:
    UICollectionViewDiffableDataSource<Section, Item> = makeDataSource()
  private var observingTasks: Set<Task<Void, Never>> = []
  private var bookTitle: String?

  private let backgroundImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    return imageView
  }()

  private let blurEffectView = UIVisualEffectView(
    effect: UIBlurEffect(style: .light)
  )

  private let overlayView = {
    let view = UIView()
    view.backgroundColor = UIColor.black.withAlphaComponent(0.2)
    return view
  }()

  private let gradientView = UIView()

  private lazy var collectionView: UICollectionView = {
    let layout = createCompositionalLayout()
    let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
    cv.backgroundColor = .clear
    cv.delegate = self
    return cv
  }()

  private let bookObjectID: NSManagedObjectID

  init(bookObjectID: NSManagedObjectID) {
    self.bookObjectID = bookObjectID
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    observingTasks.forEach {
      $0.cancel()
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    startStateObserving()
    viewModel.loadBook(with: bookObjectID)
  }

  private func setupUI() {
    view.backgroundColor = .systemBackground
    navigationItem.largeTitleDisplayMode = .never

    setupBackgroundView()

    view.addSubview(collectionView)
    collectionView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }

  private func setupBackgroundView() {
    view.addSubview(backgroundImageView)
    view.addSubview(blurEffectView)
    view.addSubview(overlayView)
    view.addSubview(gradientView)

    backgroundImageView.snp.makeConstraints { make in
      make.top.leading.trailing.equalToSuperview()
      make.height.equalToSuperview().multipliedBy(0.6)
    }

    blurEffectView.snp.makeConstraints { make in
      make.edges.equalTo(backgroundImageView)
    }

    overlayView.snp.makeConstraints { make in
      make.edges.equalTo(backgroundImageView)
    }

    gradientView.snp.makeConstraints { make in
      make.top.leading.trailing.equalToSuperview()
      make.bottom.equalTo(backgroundImageView.snp.bottom)
    }

    setupGradientLayer()
  }

  private func setupGradientLayer() {
    let gradientLayer = CAGradientLayer()
    let colors = [
      UIColor.systemBackground.withAlphaComponent(0.0),
      UIColor.systemBackground.withAlphaComponent(0.2),
      UIColor.systemBackground.withAlphaComponent(0.2),
      UIColor.systemBackground.withAlphaComponent(1.0),
    ]
    gradientLayer.colors = colors.map(\.cgColor)
    gradientLayer.locations = [0.0, 0.52, 0.52, 1.0]
    gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
    gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)

    gradientView.layer.addSublayer(gradientLayer)
    gradientLayer.frame = self.gradientView.bounds
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    if let gradientLayer = gradientView.layer.sublayers?.first
      as? CAGradientLayer
    {
      let colors = [
        UIColor.systemBackground.withAlphaComponent(0.0),
        UIColor.systemBackground.withAlphaComponent(0.2),
        UIColor.systemBackground.withAlphaComponent(0.2),
        UIColor.systemBackground.withAlphaComponent(1.0),
      ]
      gradientLayer.colors = colors.map(\.cgColor)
      gradientLayer.frame = gradientView.bounds
    }
  }

  private func startStateObserving() {
    let stream = viewModel.$book.values
    let bookTask = Task { [weak self] in
      for await book in stream {
        guard let self = self else { break }
        guard !Task.isCancelled else { break }

        await MainActor.run { [weak self] in
          guard let self = self else { return }
          if let book = book {
            self.bookTitle = book.title
            self.updateBackgroundImage(with: book)
          }
          self.updateSnapshot()
        }
      }
    }

    let logsStream = viewModel.$recentReadingLogs.values
    let logsTask = Task { [weak self] in
      for await _ in logsStream {
        guard let self = self else { break }
        guard !Task.isCancelled else { break }

        await MainActor.run {
          self.updateSnapshot()
        }
      }
    }

    let quotesStream = viewModel.$recentQuotes.values
    let quotesTask = Task { [weak self] in
      for await _ in quotesStream {
        guard let self = self else { break }
        guard !Task.isCancelled else { break }

        await MainActor.run {
          self.updateSnapshot()
        }
      }
    }

    let timeStream = viewModel.$totalReadingTime.values
    let timeTask = Task { [weak self] in
      for await _ in timeStream {
        guard let self = self else { return }
        guard !Task.isCancelled else { break }

        await MainActor.run {
          self.updateSnapshot()
        }
      }
    }

    observingTasks = [bookTask, logsTask, quotesTask, timeTask]
  }

  private func updateSnapshot() {
    var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()

    snapshot.appendSections([.bookInfo, .readingLogs, .quotes])

    if let book = viewModel.book {
      snapshot.appendItems([.book(book)], toSection: .bookInfo)
    }

    let logItems: [Item] = [.addRecord] + viewModel.recentReadingLogs.map { Item.readingLog($0) }
    snapshot.appendItems(logItems, toSection: .readingLogs)

    let quoteItems: [Item] = [.addQuote] + viewModel.recentQuotes.map { Item.quote($0) }
    snapshot.appendItems(quoteItems, toSection: .quotes)

    dataSource.apply(snapshot, animatingDifferences: true)
  }

  private func makeDataSource() -> UICollectionViewDiffableDataSource<
    Section, Item
  > {
    let bookInfoCellRegistration = UICollectionView.CellRegistration<
      BookInfoCell, BookEntity
    > { [viewModel] cell, indexPath, book in
      cell.configure(with: book, totalReadingTime: viewModel.totalReadingTime)
    }

    let readingLogCellRegistration = UICollectionView.CellRegistration<
      ReadingLogCell, ReadingLogEntity
    > { [weak self] cell, indexPath, log in
      guard let self = self else { return }
      cell.configure(with: log, book: self.viewModel.book)
    }

    let quoteCellRegistration = UICollectionView.CellRegistration<
      QuoteCell, QuoteEntity
    > { cell, indexPath, quote in
      cell.configure(with: quote)
    }

    let addActionCellRegistration = UICollectionView.CellRegistration<
      AddActionCell, AddActionCell.ActionType
    > { [weak self] cell, indexPath, actionType in
      cell.configure(actionType: actionType) {
        self?.handleAddAction(actionType)
      }
    }

    let headerRegistration = UICollectionView.SupplementaryRegistration<
      SectionHeaderView
    >(elementKind: UICollectionView.elementKindSectionHeader) {
      [weak self] headerView, elementKind, indexPath in
      guard let self = self else { return }

      let sectionType = Section.allCases[indexPath.section]

      switch sectionType {
      case .readingLogs:
        headerView.configure(
          title: "Reading Logs",
          showViewAll: self.viewModel.hasMoreReadingLogs(),
          onViewAllTapped: { [weak self] in
            self?.showAllReadingLogs()
          }
        )

      case .quotes:
        headerView.configure(
          title: "Quotes",
          showViewAll: self.viewModel.hasMoreQuotes(),
          onViewAllTapped: { [weak self] in
            self?.showAllQuotes()
          }
        )

      default:
        break
      }
    }

    let dataSource = UICollectionViewDiffableDataSource<Section, Item>(
      collectionView: collectionView
    ) { collectionView, indexPath, item in
      switch item {
      case .book(let book):
        return collectionView.dequeueConfiguredReusableCell(
          using: bookInfoCellRegistration,
          for: indexPath,
          item: book
        )
      case .readingLog(let log):
        return collectionView.dequeueConfiguredReusableCell(
          using: readingLogCellRegistration,
          for: indexPath,
          item: log
        )
      case .quote(let quote):
        return collectionView.dequeueConfiguredReusableCell(
          using: quoteCellRegistration,
          for: indexPath,
          item: quote
        )
      case .addRecord:
        return collectionView.dequeueConfiguredReusableCell(
          using: addActionCellRegistration,
          for: indexPath,
          item: .newRecord
        )
      case .addQuote:
        return collectionView.dequeueConfiguredReusableCell(
          using: addActionCellRegistration,
          for: indexPath,
          item: .newQuote
        )
      }
    }

    dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
      return collectionView.dequeueConfiguredReusableSupplementary(
        using: headerRegistration,
        for: indexPath
      )
    }

    return dataSource
  }

  private func createCompositionalLayout()
    -> UICollectionViewCompositionalLayout
  {
    return UICollectionViewCompositionalLayout {
      [weak self] sectionIndex, environment in
      guard let self = self else { return nil }

      switch Section.allCases[sectionIndex] {
      case .bookInfo:
        return self.createBookInfoSection()
      case .readingLogs:
        return self.createReadingLogsSection()
      case .quotes:
        return self.createQuotesSection()
      }
    }
  }

  private func createBookInfoSection() -> NSCollectionLayoutSection {
    let itemSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .estimated(400)
    )
    let item = NSCollectionLayoutItem(layoutSize: itemSize)

    let groupSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .estimated(400)
    )
    let group = NSCollectionLayoutGroup.horizontal(
      layoutSize: groupSize,
      subitems: [item]
    )

    let section = NSCollectionLayoutSection(group: group)
    section.contentInsets = NSDirectionalEdgeInsets(
      top: 0,
      leading: 0,
      bottom: 24,
      trailing: 0
    )

    return section
  }

  private func createReadingLogsSection() -> NSCollectionLayoutSection {
    let itemSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .estimated(80)
    )
    let item = NSCollectionLayoutItem(layoutSize: itemSize)

    let groupSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .estimated(80)
    )
    let group = NSCollectionLayoutGroup.horizontal(
      layoutSize: groupSize,
      subitems: [item]
    )

    let section = NSCollectionLayoutSection(group: group)
    section.contentInsets = NSDirectionalEdgeInsets(
      top: 0,
      leading: 0,
      bottom: 24,
      trailing: 0
    )

    let headerSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .estimated(60)
    )
    let header = NSCollectionLayoutBoundarySupplementaryItem(
      layoutSize: headerSize,
      elementKind: UICollectionView.elementKindSectionHeader,
      alignment: .top
    )
    section.boundarySupplementaryItems = [header]

    return section
  }

  private func createQuotesSection() -> NSCollectionLayoutSection {
    let itemSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .estimated(100)
    )
    let item = NSCollectionLayoutItem(layoutSize: itemSize)

    let groupSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .estimated(100)
    )
    let group = NSCollectionLayoutGroup.horizontal(
      layoutSize: groupSize,
      subitems: [item]
    )

    let section = NSCollectionLayoutSection(group: group)
    section.contentInsets = NSDirectionalEdgeInsets(
      top: 0,
      leading: 0,
      bottom: 24,
      trailing: 0
    )

    let headerSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .estimated(60)
    )
    let header = NSCollectionLayoutBoundarySupplementaryItem(
      layoutSize: headerSize,
      elementKind: UICollectionView.elementKindSectionHeader,
      alignment: .top
    )
    section.boundarySupplementaryItems = [header]

    return section
  }

  private func updateBackgroundImage(with book: BookEntity) {
    guard let coverURL = book.coverImageURL else { return }

    let request = ImageRequest(url: coverURL)
    Task {
      do {
        let image = try await ImagePipeline.shared.image(for: request)
        await MainActor.run {
          self.backgroundImageView.image = image
        }
      } catch {
        await MainActor.run {
          self.backgroundImageView.backgroundColor = .systemGray6
        }
      }
    }
  }
}

extension BookDetailViewController: UICollectionViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let contentOffsetY = scrollView.contentOffset.y
    let fadeStartOffset: CGFloat = 100
    let fadeEndOffset: CGFloat = 300

    let alpha: CGFloat
    if contentOffsetY <= fadeStartOffset {
      alpha = 1.0
    } else if contentOffsetY >= fadeEndOffset {
      alpha = 0.0
    } else {
      let progress =
        (contentOffsetY - fadeStartOffset) / (fadeEndOffset - fadeStartOffset)
      alpha = 1.0 - progress
    }

    backgroundImageView.alpha = alpha
  }

  private func showAllReadingLogs() {
    let allLogsVC = AllReadingLogsViewController(bookObjectID: bookObjectID)
    navigationController?.pushViewController(allLogsVC, animated: true)
  }

  private func showAllQuotes() {
    let allQuotesVC = AllQuotesViewController(bookObjectID: bookObjectID)
    navigationController?.pushViewController(allQuotesVC, animated: true)
  }
  
  private func handleAddAction(_ actionType: AddActionCell.ActionType) {
    switch actionType {
    case .newRecord:
      showAddNewRecord()
    case .newQuote:
      showAddNewQuote()
    }
  }
  
  private func showAddNewRecord() {
    print("Add new reading record tapped")
  }
  
  private func showAddNewQuote() {
    print("Add new quote tapped")
  }
}

#Preview {
  let context = ContextManager.shared.mainContext
  let book = BookEntity(context: context)
  book.title = "Advanced Apple Debugging & Reverse Engineering"
  book.author = "Walter Tyree"
  book.rating = 4.9
  book.pageCount = 350
  book.coverImageURL = .init(
    string: "https://m.media-amazon.com/images/I/619+wjNLTyL._SY522_.jpg"
  )

  for i in 0..<5 {
    let log = ReadingLogEntity(context: context)
    log.startPage = Int64(i * 20 + 1)
    log.endPage = Int64((i + 1) * 20)
    log.readingSeconds = Double(30 + i * 15) * 60
    log.note = "Note"
    log.book = book
  }
  let quotes = [
    ("Debugging is twice as hard as writing the code in the first place.", 45),
    (
      "The best debugger ever written is a clear mind and a good night's sleep.",
      87
    ),
    (
      "If debugging is the process of removing bugs, then programming must be the process of putting them in.",
      123
    ),
    ("Debugging is like detective work. You have to follow the clues.", 156),
    (
      "The most effective debugging tool is still careful thought, coupled with judiciously placed print statements.",
      203
    ),
    ("Code never lies, comments sometimes do.", 234),
  ]

  for (content, page) in quotes {
    let quote = QuoteEntity(context: context)
    quote.content = content
    quote.page = Int64(page)
    quote.book = book
  }

  return UINavigationController(
    rootViewController: BookDetailViewController(bookObjectID: book.objectID)
  )
}
