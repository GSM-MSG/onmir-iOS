import Nuke
import SnapKit
import UIKit

public final class BookRecordEditorViewController: UIViewController {
  enum Section: Int, CaseIterable {
    case bookInfo
    case date
    case readingProgress
    case readingTime
    case note
  }

  enum Item: Hashable {
    case bookInfo(BookEntity)
    case date
    case readingProgress
    case readingTime
    case note
  }

  private lazy var collectionView: UICollectionView = {
    let layout = createLayout()
    let collectionView = UICollectionView(
      frame: .zero, collectionViewLayout: layout)
    collectionView.backgroundColor = .systemGroupedBackground
    return collectionView
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

  private lazy var dataSource: UICollectionViewDiffableDataSource<Section, Item> = makeDataSource()
  private let viewModel: BookRecordEditorViewModel
  private let onSaveCompletion: (() -> Void)?

  init(viewModel: BookRecordEditorViewModel, onSaveCompletion: (() -> Void)? = nil) {
    self.viewModel = viewModel
    self.onSaveCompletion = onSaveCompletion
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func viewDidLoad() {
    super.viewDidLoad()
    setupNavigationBar()
    setupLayout()
    setupBinding()
    applySnapshot()
    setupPresentationController()
  }
  
  private func setupPresentationController() {
    if let presentationController = presentationController as? UISheetPresentationController {
      presentationController.delegate = self
    }
  }

  private func setupNavigationBar() {
    switch viewModel.editMode {
    case .create:
      title = "New Log"
    case .edit:
      title = "Edit Log"
    }
    
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      systemItem: .close,
      primaryAction: UIAction(handler: { [weak self] _ in
        self?.cancelButtonTapped()
      }),
      menu: nil
    )
  }

  private func setupBinding() {
    doneButton.addAction(
      UIAction(handler: { [weak self] _ in
        self?.doneButtonTapped()
      }),
      for: .primaryActionTriggered
    )
  }

  private func setupLayout() {
    view.backgroundColor = .systemGroupedBackground

    view.addSubview(collectionView)
    view.addSubview(doneButton)

    collectionView.snp.makeConstraints { make in
      make.top.leading.trailing.equalToSuperview()
      make.bottom.equalTo(doneButton.snp.top).offset(-8)
    }

    doneButton.snp.makeConstraints { make in
      make.leading.trailing.equalToSuperview().inset(20)
      make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
      make.height.equalTo(50)
    }
  }

  private func createLayout() -> UICollectionViewLayout {
    let layout = UICollectionViewCompositionalLayout {
      [weak self] sectionIndex, _ in
      guard let self = self,
        let section = Section(rawValue: sectionIndex)
      else {
        return nil
      }

      switch section {
      case .bookInfo:
        return createBookInfoSection()
      case .date:
        return createDateSection()
      case .readingProgress:
        return createReadingProgressSection()
      case .readingTime:
        return createReadingTimeSection()
      case .note:
        return createNoteSection()
      }
    }

    let configuration = UICollectionViewCompositionalLayoutConfiguration()
    configuration.interSectionSpacing = 15
    layout.configuration = configuration

    return layout
  }

  private func createBookInfoSection() -> NSCollectionLayoutSection {
    let itemSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .estimated(150)
    )
    let item = NSCollectionLayoutItem(layoutSize: itemSize)

    let groupSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .estimated(150)
    )
    let group = NSCollectionLayoutGroup.horizontal(
      layoutSize: groupSize, subitems: [item])

    let section = NSCollectionLayoutSection(group: group)
    section.contentInsets = NSDirectionalEdgeInsets(
      top: 10, leading: 20, bottom: 0, trailing: 20
    )

    return section
  }

  private func createDateSection() -> NSCollectionLayoutSection {
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
      layoutSize: groupSize, subitems: [item])

    let section = NSCollectionLayoutSection(group: group)
    section.contentInsets = NSDirectionalEdgeInsets(
      top: 10, leading: 20, bottom: 0, trailing: 20
    )

    return section
  }

  private func createReadingProgressSection() -> NSCollectionLayoutSection {
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
      layoutSize: groupSize, subitems: [item])

    let section = NSCollectionLayoutSection(group: group)
    section.contentInsets = NSDirectionalEdgeInsets(
      top: 10, leading: 20, bottom: 0, trailing: 20
    )

    return section
  }

  private func createReadingTimeSection() -> NSCollectionLayoutSection {
    let itemSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .estimated(180)
    )
    let item = NSCollectionLayoutItem(layoutSize: itemSize)

    let groupSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .estimated(180)
    )
    let group = NSCollectionLayoutGroup.horizontal(
      layoutSize: groupSize, subitems: [item])

    let section = NSCollectionLayoutSection(group: group)
    section.contentInsets = NSDirectionalEdgeInsets(
      top: 10, leading: 20, bottom: 0, trailing: 20
    )

    return section
  }

  private func createNoteSection() -> NSCollectionLayoutSection {
    let estimatedHeight: CGFloat = 200

    let itemSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .estimated(estimatedHeight)
    )
    let item = NSCollectionLayoutItem(layoutSize: itemSize)

    let groupSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .estimated(estimatedHeight)
    )
    let group = NSCollectionLayoutGroup.horizontal(
      layoutSize: groupSize, subitems: [item])

    let section = NSCollectionLayoutSection(group: group)
    section.contentInsets = NSDirectionalEdgeInsets(
      top: 10, leading: 20, bottom: 0, trailing: 20
    )

    return section
  }

  private func makeDataSource() -> UICollectionViewDiffableDataSource<Section, Item> {
    let bookInfoCellRegistration = UICollectionView.CellRegistration<
      BookInfoCell, BookEntity
    > { cell, _, book in
      cell.configure(with: book)
    }

    let dateCellRegistration = UICollectionView.CellRegistration<
      DateCell, Item
    > { [viewModel] cell, _, _ in
      cell.configure(
        title: "Date",
        date: viewModel.date,
        dateChangedHandler: { date in
          viewModel.date = date
        }
      )
    }

    let readingProgressCellRegistration = UICollectionView.CellRegistration<
      ReadingRangeCell, Item
    > { [viewModel] cell, _, _ in
      cell.configure(
        title: "Reading Progress",
        startPage: viewModel.startPage,
        endPage: viewModel.currentPage,
        totalPages: viewModel.totalPages,
        rangeChangedHandler: { startPage, endPage in
          viewModel.startPage = startPage
          viewModel.currentPage = endPage
        }
      )
    }

    let readingTimeCellRegistration = UICollectionView.CellRegistration<
      ReadingTimeCell, Item
    > { [viewModel] cell, _, _ in
      cell.configure(
        title: "Reading Time",
        duration: viewModel.duration,
        durationChangedHandler: { duration in
          viewModel.duration = duration
        }
      )
    }

    let noteCellRegistration = UICollectionView.CellRegistration<NoteCell, Item>
    { [viewModel] cell, _, _ in
      cell.configure(
        title: "Note",
        note: viewModel.note,
        textChangedHandler: { text in
          viewModel.note = text
        }
      )
    }

    return UICollectionViewDiffableDataSource<Section, Item>(
      collectionView: collectionView
    ) { (collectionView, indexPath, item) -> UICollectionViewCell? in
      switch item {
      case .bookInfo(let book):
        return collectionView.dequeueConfiguredReusableCell(
          using: bookInfoCellRegistration,
          for: indexPath,
          item: book
        )
      case .date:
        return collectionView.dequeueConfiguredReusableCell(
          using: dateCellRegistration,
          for: indexPath,
          item: item
        )
      case .readingProgress:
        return collectionView.dequeueConfiguredReusableCell(
          using: readingProgressCellRegistration,
          for: indexPath,
          item: item
        )
      case .readingTime:
        return collectionView.dequeueConfiguredReusableCell(
          using: readingTimeCellRegistration,
          for: indexPath,
          item: item
        )
      case .note:
        return collectionView.dequeueConfiguredReusableCell(
          using: noteCellRegistration,
          for: indexPath,
          item: item
        )
      }
    }
  }

  private func applySnapshot(animatingDifferences: Bool = false) {
    var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
    snapshot.appendSections(Section.allCases)

    snapshot.appendItems([.bookInfo(viewModel.book)], toSection: .bookInfo)
    snapshot.appendItems([.date], toSection: .date)
    snapshot.appendItems([.readingProgress], toSection: .readingProgress)
    snapshot.appendItems([.readingTime], toSection: .readingTime)
    snapshot.appendItems([.note], toSection: .note)

    dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
  }

  private func cancelButtonTapped() {
    if viewModel.hasChanges {
      showDiscardChangesAlert()
    } else {
      dismiss(animated: true)
    }
  }
  
  private func showDiscardChangesAlert() {
    let alert = UIAlertController(
      title: "Discard Changes?",
      message: "Are you sure you want to discard your changes?",
      preferredStyle: .alert
    )
    alert.popoverPresentationController?.sourceItem = navigationItem.leftBarButtonItem
    
    let discardAction = UIAlertAction(
      title:"Discard",
      style: .destructive
    ) { [weak self] _ in
      self?.dismiss(animated: true)
    }
    
    let cancelAction = UIAlertAction(
      title: "Cancel",
      style: .cancel
    )
    
    alert.addAction(discardAction)
    alert.addAction(cancelAction)
    
    present(alert, animated: true)
  }

  private func doneButtonTapped() {
    Task {
      await viewModel.save()

      await MainActor.run {
        dismiss(animated: true) {
          self.onSaveCompletion?()
        }
      }
    }
  }
}

extension BookRecordEditorViewController: UISheetPresentationControllerDelegate {
  public func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
    return !viewModel.hasChanges
  }
  
  public func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
    showDiscardChangesAlert()
  }
}

#Preview("Create Mode") {
  {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    
    let sampleBook = BookEntity(context: ContextManager.shared.mainContext)
    sampleBook.originalBookID = "sample-book-id"
    sampleBook.title = "Advanced Apple Debugging & Reverse Engineering"
    sampleBook.author = "Derek Selander, Walter Tyree"
    sampleBook.isbn = "1942878842"
    sampleBook.isbn13 = "9781942878841"
    sampleBook.pageCount = 586
    sampleBook.publishedDate = dateFormatter.date(from: "2024-03-15")
    sampleBook.publisher = "Razeware LLC"
    sampleBook.rating = 4.8
    sampleBook.source = BookSourceTypeKind(sourceType: .googleBooks)
    sampleBook.status = BookStatusTypeKind(status: .reading)
    sampleBook.coverImageURL = URL(string: "https://m.media-amazon.com/images/I/619+wjNLTyL._SY522_.jpg")
    
    let viewModel = BookRecordEditorViewModel(book: sampleBook, editMode: .create)
    let viewController = BookRecordEditorViewController(viewModel: viewModel)
    return UINavigationController(rootViewController: viewController)
  }()
}

#Preview("Edit Mode") {
  {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    
    let sampleBook = BookEntity(context: ContextManager.shared.mainContext)
    sampleBook.originalBookID = "sample-book-id"
    sampleBook.title = "Advanced Apple Debugging & Reverse Engineering"
    sampleBook.author = "Derek Selander, Walter Tyree"
    sampleBook.pageCount = 586
    
    // Create sample reading log
    let readingLog = ReadingLogEntity(context: ContextManager.shared.mainContext)
    readingLog.date = dateFormatter.date(from: "2024-03-10")
    readingLog.startPage = 50
    readingLog.endPage = 75
    readingLog.readingSeconds = 45 * 60 // 45 minutes
    readingLog.note = "Great chapter on advanced debugging techniques!"
    readingLog.book = sampleBook
    
    let viewModel = BookRecordEditorViewModel(book: sampleBook, editMode: .edit(readingLog))
    let viewController = BookRecordEditorViewController(viewModel: viewModel)
    return UINavigationController(rootViewController: viewController)
  }()
}
