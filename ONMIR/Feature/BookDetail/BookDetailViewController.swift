@preconcurrency import CoreData
import Nuke
import SnapKit
import UIKit

final class BookDetailViewController: UIViewController {
  enum Section: CaseIterable {
    case bookInfo
    case readingLogs
    case quotes
    case bookDetails
  }

  enum Item: Hashable, @unchecked Sendable {
    case book(BookEntity)
    case readingLog(ReadingLogEntity)
    case quote(QuoteEntity)
    case addRecord
    case addQuote
    case bookDetails(BookEntity)
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

  private static let gradientColors = [
    UIColor.systemBackground.withAlphaComponent(0.0),
    UIColor.systemBackground.withAlphaComponent(0.2),
    UIColor.systemBackground.withAlphaComponent(0.2),
    UIColor.systemBackground.withAlphaComponent(1.0),
  ]
  private let gradientLayer = {
    let gradientLayer = CAGradientLayer()
    let colors = BookDetailViewController.gradientColors
    gradientLayer.colors = colors.map(\.cgColor)
    gradientLayer.locations = [0.0, 0.52, 0.52, 1.0]
    gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
    gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
    return gradientLayer
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

    registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (traitEnvironment: Self, previousTraitCollection) in
      if previousTraitCollection.userInterfaceStyle != traitEnvironment.traitCollection.userInterfaceStyle {
        traitEnvironment.gradientLayer.colors = Self.gradientColors.map(\.cgColor)
      }
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    let colors = Self.gradientColors
    gradientLayer.colors = colors.map(\.cgColor)
    gradientLayer.frame = gradientView.bounds
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
    gradientView.layer.addSublayer(gradientLayer)
    gradientLayer.frame = self.gradientView.bounds
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

    snapshot.appendSections([.bookInfo, .readingLogs, .quotes, .bookDetails])

    if let book = viewModel.book {
      snapshot.appendItems([.book(book)], toSection: .bookInfo)
      snapshot.appendItems([.bookDetails(book)], toSection: .bookDetails)
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

    let bookDetailsInfoCellRegistration = UICollectionView.CellRegistration<
      BookDetailsInfoCell, BookEntity
    > { [weak self] cell, indexPath, book in
      cell.configure(with: book) {
        self?.collectionView.performBatchUpdates(nil, completion: nil)
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
      case .bookDetails(let book):
        return collectionView.dequeueConfiguredReusableCell(
          using: bookDetailsInfoCellRegistration,
          for: indexPath,
          item: book
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
        return self.createReadingLogsListSection(environment: environment)
      case .quotes:
        return self.createQuotesListSection(environment: environment)
      case .bookDetails:
        return self.createBookDetailsSection()
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

  private func createReadingLogsListSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
    var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
    configuration.showsSeparators = false
    configuration.backgroundColor = .clear
    
    configuration.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in
      guard let self = self,
            let item = self.dataSource.itemIdentifier(for: indexPath) else { 
        return nil 
      }
      
      switch item {
      case .readingLog(let readingLog):
        let editAction = UIContextualAction(style: .normal, title: "Edit") { _, _, completion in
          self.showEditReadingLog(readingLog)
          completion(true)
        }
        editAction.backgroundColor = .systemBlue
        editAction.image = UIImage(systemName: "pencil")
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, completion in
          self.showDeleteConfirmation(readingLogs: [readingLog])
          completion(true)
        }
        deleteAction.image = UIImage(systemName: "trash")
        
        return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
      default:
        return nil
      }
    }

    let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
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

  private func createQuotesListSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
    var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
    configuration.showsSeparators = false
    configuration.backgroundColor = .clear
    
    configuration.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in
      guard let self = self,
            let item = self.dataSource.itemIdentifier(for: indexPath) else { 
        return nil 
      }
      
      switch item {
      case .quote(let quote):
        let editAction = UIContextualAction(style: .normal, title: "Edit") { _, _, completion in
          #warning("TODO: Quote edit")
          completion(true)
        }
        editAction.backgroundColor = .systemBlue
        editAction.image = UIImage(systemName: "pencil")
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, completion in
          #warning("TODO: Quote delete")
          completion(true)
        }
        deleteAction.image = UIImage(systemName: "trash")
        
        return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
      default:
        return nil
      }
    }

    let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
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

  private func createBookDetailsSection() -> NSCollectionLayoutSection {
    let itemSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .estimated(200)
    )
    let item = NSCollectionLayoutItem(layoutSize: itemSize)

    let groupSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .estimated(200)
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
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    collectionView.deselectItem(at: indexPath, animated: true)
    
    guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
    
    switch item {
    case .readingLog(let readingLog):
      showEditReadingLog(readingLog)
    default:
      break
    }
  }

  func collectionView(
    _ collectionView: UICollectionView,
    contextMenuConfigurationForItemsAt indexPaths: [IndexPath],
    point: CGPoint
  ) -> UIContextMenuConfiguration? {
    guard !indexPaths.isEmpty else { return nil }
    
    let items = indexPaths.compactMap { dataSource.itemIdentifier(for: $0) }
    
    let readingLogs = items.compactMap { item -> ReadingLogEntity? in
      if case .readingLog(let log) = item { return log }
      return nil
    }
    
    let quotes = items.compactMap { item -> QuoteEntity? in
      if case .quote(let quote) = item { return quote }
      return nil
    }
    
    if readingLogs.count == items.count && !readingLogs.isEmpty {
      return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
        let deleteAction = UIAction(
          title: "Delete \(readingLogs.count) Reading Logs",
          image: UIImage(systemName: "trash"),
          attributes: .destructive
        ) { [weak self] _ in
          self?.showDeleteConfirmation(readingLogs: readingLogs)
        }
        
        return UIMenu(title: "", children: [deleteAction])
      }
    } else if quotes.count == items.count && !quotes.isEmpty {
      return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
        let deleteAction = UIAction(
          title: "Delete \(quotes.count) Quotes",
          image: UIImage(systemName: "trash"),
          attributes: .destructive
        ) { [weak self] _ in
          #warning("TODO: Multiple quote delete")
        }
        
        return UIMenu(title: "", children: [deleteAction])
      }
    }
    
    return nil
  }
  
  func collectionView(
    _ collectionView: UICollectionView,
    contextMenuConfigurationForItemAt indexPath: IndexPath,
    point: CGPoint
  ) -> UIContextMenuConfiguration? {
    guard let item = dataSource.itemIdentifier(for: indexPath) else { return nil }
    
    switch item {
    case .readingLog(let readingLog):
      return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
        let editAction = UIAction(
          title: "Edit",
          image: UIImage(systemName: "pencil")
        ) { [weak self] _ in
          self?.showEditReadingLog(readingLog)
        }
        
        let deleteAction = UIAction(
          title: "Delete",
          image: UIImage(systemName: "trash"),
          attributes: .destructive
        ) { [weak self] _ in
          self?.showDeleteConfirmation(readingLogs: [readingLog])
        }
        
        return UIMenu(title: "", children: [editAction, deleteAction])
      }
    case .quote(let quote):
      return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
        let editAction = UIAction(
          title: "Edit",
          image: UIImage(systemName: "pencil")
        ) { [weak self] _ in
          #warning("TODO: Quote edit")
        }
        
        let deleteAction = UIAction(
          title: "Delete",
          image: UIImage(systemName: "trash"),
          attributes: .destructive
        ) { [weak self] _ in
          #warning("TODO: Quote delete")
        }
        
        return UIMenu(title: "", children: [editAction, deleteAction])
      }
    default:
      return nil
    }
  }
  
  func collectionView(
    _ collectionView: UICollectionView,
    contextMenuConfiguration configuration: UIContextMenuConfiguration,
    highlightPreviewForItemAt indexPath: IndexPath
  ) -> UITargetedPreview? {
    guard let item = dataSource.itemIdentifier(for: indexPath) else { return nil }
    
    switch item {
    case .readingLog:
      guard let cell = collectionView.cellForItem(at: indexPath) as? BookDetailViewController.ReadingLogCell,
            let highlightView = cell.contextMenuHighlightView() else {
        return nil
      }
      
      let parameters = UIPreviewParameters()
      parameters.backgroundColor = .clear
      
      return UITargetedPreview(view: highlightView, parameters: parameters)
      
    case .quote:
      guard let cell = collectionView.cellForItem(at: indexPath) as? BookDetailViewController.QuoteCell,
            let highlightView = cell.contextMenuHighlightView() else {
        return nil
      }
      
      let parameters = UIPreviewParameters()
      parameters.backgroundColor = .clear
      
      return UITargetedPreview(view: highlightView, parameters: parameters)
      
    default:
      return nil
    }
  }

  func collectionView(
    _ collectionView: UICollectionView,
    contextMenuConfiguration configuration: UIContextMenuConfiguration,
    dismissalPreviewForItemAt indexPath: IndexPath
  ) -> UITargetedPreview? {
    guard let item = dataSource.itemIdentifier(for: indexPath) else { return nil }
    
    switch item {
    case .readingLog:
      guard let cell = collectionView.cellForItem(at: indexPath) as? BookDetailViewController.ReadingLogCell,
            let highlightView = cell.contextMenuHighlightView() else {
        return nil
      }
      
      let parameters = UIPreviewParameters()
      parameters.backgroundColor = .clear
      
      return UITargetedPreview(view: highlightView, parameters: parameters)
      
    case .quote:
      guard let cell = collectionView.cellForItem(at: indexPath) as? BookDetailViewController.QuoteCell,
            let highlightView = cell.contextMenuHighlightView() else {
        return nil
      }
      
      let parameters = UIPreviewParameters()
      parameters.backgroundColor = .clear
      
      return UITargetedPreview(view: highlightView, parameters: parameters)
      
    default:
      return nil
    }
  }
  
  func collectionView(
    _ collectionView: UICollectionView,
    canPerformPrimaryActionForItemAt indexPath: IndexPath
  ) -> Bool {
    guard let item = dataSource.itemIdentifier(for: indexPath) else { return false }
    
    switch item {
    case .readingLog, .quote:
      return true
    default:
      return false
    }
  }
  
  func collectionView(
    _ collectionView: UICollectionView,
    performPrimaryActionForItemAt indexPath: IndexPath
  ) {
    guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
    
    switch item {
    case .readingLog(let readingLog):
      showEditReadingLog(readingLog)
    default:
      break
    }
  }
  
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
    guard let book = viewModel.book else { return }
    
    let recordViewModel = BookRecordEditorViewModel(book: book, editMode: .create)
    let recordViewController = BookRecordEditorViewController(viewModel: recordViewModel) { [weak self] in
      self?.refreshBookData()
    }
    let navigationController = UINavigationController(rootViewController: recordViewController)
    
    if let sheet = navigationController.sheetPresentationController {
      sheet.detents = [.medium(), .large()]
      sheet.prefersGrabberVisible = true
    }
    
    present(navigationController, animated: true)
  }
  
  private func showAddNewQuote() {
    print("Add new quote tapped")
  }
  
  private func refreshBookData() {
    viewModel.loadBook(with: bookObjectID)
  }
  
  private func showEditReadingLog(_ readingLog: ReadingLogEntity) {
    guard let book = viewModel.book else { return }
    
    let recordViewModel = BookRecordEditorViewModel(book: book, editMode: .edit(readingLog))
    let recordViewController = BookRecordEditorViewController(viewModel: recordViewModel) { [weak self] in
      self?.refreshBookData()
    }
    let navigationController = UINavigationController(rootViewController: recordViewController)
    
    if let sheet = navigationController.sheetPresentationController {
      sheet.detents = [.medium(), .large()]
      sheet.prefersGrabberVisible = true
    }
    
    present(navigationController, animated: true)
  }
  
  private func showDeleteConfirmation(readingLogs: [ReadingLogEntity]) {
    let count = readingLogs.count
    let title = count == 1 ? "Delete Reading Log" : "Delete \(count) Reading Logs"
    let message = count == 1 ? 
      "Are you sure you want to delete this reading log?" :
      "Are you sure you want to delete these \(count) reading logs?"
    
    let alert = UIAlertController(
      title: title,
      message: message,
      preferredStyle: .alert
    )
    
    let deleteAction = UIAlertAction(
      title: "Delete",
      style: .destructive
    ) { [weak self] _ in
      self?.deleteReadingLogs(readingLogs)
    }
    
    let cancelAction = UIAlertAction(
      title: "Cancel",
      style: .cancel
    )
    
    alert.addAction(deleteAction)
    alert.addAction(cancelAction)
    
    present(alert, animated: true)
  }
  
  private func deleteReadingLogs(_ readingLogs: [ReadingLogEntity]) {
    Task {
      do {
        try await ContextManager.shared.performAndSave { context in
          for readingLog in readingLogs {
            let objectToDelete = context.object(with: readingLog.objectID)
            context.delete(objectToDelete)
          }
        }
        
        await MainActor.run {
          self.refreshBookData()
        }
      } catch {
        await MainActor.run {
          let count = readingLogs.count
          let message = "Failed to delete reading logs: \(error.localizedDescription)"
            
          let errorAlert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
          )
          errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
          self.present(errorAlert, animated: true)
        }
      }
    }
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
