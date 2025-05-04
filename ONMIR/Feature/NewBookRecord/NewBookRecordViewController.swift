import Nuke
import SnapKit
import UIKit

public final class NewBookRecordViewController: UIViewController {
  enum Section: Int, CaseIterable {
    case bookInfo
    case readingProgress
    case readingTime
    case note
  }

  enum Item: Hashable {
    case bookInfo(BookRepresentation)
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
  private let viewModel: NewBookRecordViewModel

  init(viewModel: NewBookRecordViewModel) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func viewDidLoad() {
    super.viewDidLoad()
    setupNavigationBar()
    setupLayout()
    applySnapshot()
  }

  private func setupNavigationBar() {
    title = "New Record"
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      title: "Cancel",
      primaryAction: UIAction(handler: { [weak self] _ in
        self?.cancelButtonTapped()
      })
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
      make.bottom.equalTo(doneButton.snp.top).offset(-20)
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

  private func createReadingProgressSection() -> NSCollectionLayoutSection {
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
      BookInfoCell, BookRepresentation
    > { cell, _, book in
      cell.configure(with: book)
    }

    let readingProgressCellRegistration = UICollectionView.CellRegistration<
      ReadingProgressCell, Item
    > { [viewModel] cell, _, _ in
      cell.configure(
        title: "Reading Progress",
        currentPage: viewModel.currentPage,
        totalPages: viewModel.totalPages,
        valueChangedHandler: { value in
          viewModel.currentPage = value
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
    snapshot.appendItems([.readingProgress], toSection: .readingProgress)
    snapshot.appendItems([.readingTime], toSection: .readingTime)
    snapshot.appendItems([.note], toSection: .note)

    dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
  }

  private func cancelButtonTapped() {
    dismiss(animated: true)
  }

  private func doneButtonTapped() {
    Task {
      await viewModel.save()

      await MainActor.run {
        dismiss(animated: true)
      }
    }
  }
}
