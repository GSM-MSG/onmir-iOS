import UIKit
import CoreData
import SnapKit

final class AllQuotesViewController: UIViewController {
  private let tableView = UITableView()
  private let bookObjectID: NSManagedObjectID
  private lazy var fetchedResultsController = makeFetchedResultsController()
  private lazy var dataSource = makeDataSource()
  
  init(bookObjectID: NSManagedObjectID) {
    self.bookObjectID = bookObjectID
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    
    do {
      try fetchedResultsController.performFetch()
      updateSnapshot()
    } catch {
      print("Failed to fetch quotes: \(error)")
    }
  }
  
  private func setupUI() {
    title = "All Quotes"
    view.backgroundColor = .systemBackground
    
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .add,
      target: self,
      action: #selector(addQuoteTapped)
    )
    
    tableView.delegate = self
    tableView.register(QuoteTableViewCell.self, forCellReuseIdentifier: "QuoteCell")
    tableView.rowHeight = UITableView.automaticDimension
    tableView.estimatedRowHeight = 80
    tableView.separatorStyle = .none
    tableView.backgroundColor = .systemGroupedBackground
    
    view.addSubview(tableView)
    tableView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }
  
  @objc private func addQuoteTapped() {
    guard let book = getBook() else { return }
    
    let quoteViewModel = QuoteEditorViewModel(book: book, editMode: .create)
    let quoteViewController = QuoteEditorViewController(viewModel: quoteViewModel) { [weak self] in
      // Refresh will happen automatically via NSFetchedResultsController
    }
    let navigationController = UINavigationController(rootViewController: quoteViewController)
    
    if let sheet = navigationController.sheetPresentationController {
      sheet.detents = [.medium(), .large()]
      sheet.prefersGrabberVisible = true
    }
    
    present(navigationController, animated: true)
  }
  
  private func getBook() -> BookEntity? {
    let context = ContextManager.shared.mainContext
    return context.object(with: bookObjectID) as? BookEntity
  }
  
  private func makeDataSource() -> UITableViewDiffableDataSource<Int, NSManagedObjectID> {
    let dataSource = UITableViewDiffableDataSource<Int, NSManagedObjectID>(tableView: tableView) { [weak self] tableView, indexPath, objectID in
      let cell = tableView.dequeueReusableCell(withIdentifier: "QuoteCell", for: indexPath) as! QuoteTableViewCell

      guard let self = self else { return cell }

      let context = self.fetchedResultsController.managedObjectContext

      guard let quote = context.object(with: objectID) as? QuoteEntity else {
        return cell
      }
      
      cell.configure(with: quote)
      
      return cell
    }
    
    tableView.dataSource = dataSource
    return dataSource
  }
  
  private func makeFetchedResultsController() -> NSFetchedResultsController<QuoteEntity> {
    let context = ContextManager.shared.mainContext
    
    guard let book = context.object(with: bookObjectID) as? BookEntity else {
      assertionFailure("Book not found")
      self.dismiss(animated: true)
      return .init()
    }
    
    let request: NSFetchRequest<QuoteEntity> = QuoteEntity.fetchRequest()
    request.predicate = NSPredicate(format: "book == %@", book)
    request.sortDescriptors = [NSSortDescriptor(keyPath: \QuoteEntity.page, ascending: false)]
    
    let controller = NSFetchedResultsController(
      fetchRequest: request,
      managedObjectContext: context,
      sectionNameKeyPath: nil,
      cacheName: nil
    )
    
    controller.delegate = self
    return controller
  }
  
  private func updateSnapshot() {
    var snapshot = NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>()
    snapshot.appendSections([0])
    
    let objectIDs = fetchedResultsController.fetchedObjects?.map { $0.objectID } ?? []
    snapshot.appendItems(objectIDs, toSection: 0)
    
    dataSource.apply(snapshot, animatingDifferences: true)
  }
}


extension AllQuotesViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    
    guard let objectID = dataSource.itemIdentifier(for: indexPath),
          let quote = fetchedResultsController.managedObjectContext.object(with: objectID) as? QuoteEntity,
          let book = getBook() else { return }
    
    let quoteViewModel = QuoteEditorViewModel(book: book, editMode: .edit(quote))
    let quoteViewController = QuoteEditorViewController(viewModel: quoteViewModel) { [weak self] in
      // Refresh will happen automatically via NSFetchedResultsController
    }
    let navigationController = UINavigationController(rootViewController: quoteViewController)
    
    if let sheet = navigationController.sheetPresentationController {
      sheet.detents = [.medium(), .large()]
      sheet.prefersGrabberVisible = true
    }
    
    present(navigationController, animated: true)
  }
  
  func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    guard let objectID = dataSource.itemIdentifier(for: indexPath),
          let quote = fetchedResultsController.managedObjectContext.object(with: objectID) as? QuoteEntity else {
      return nil
    }
    
    let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
      self?.showDeleteConfirmation(for: quote)
      completion(true)
    }
    deleteAction.image = UIImage(systemName: "trash")
    
    let editAction = UIContextualAction(style: .normal, title: "Edit") { [weak self] _, _, completion in
      guard let book = self?.getBook() else {
        completion(false)
        return
      }
      
      let quoteViewModel = QuoteEditorViewModel(book: book, editMode: .edit(quote))
      let quoteViewController = QuoteEditorViewController(viewModel: quoteViewModel) { [weak self] in
        // Refresh will happen automatically via NSFetchedResultsController
      }
      let navigationController = UINavigationController(rootViewController: quoteViewController)
      
      if let sheet = navigationController.sheetPresentationController {
        sheet.detents = [.medium(), .large()]
        sheet.prefersGrabberVisible = true
      }
      
      self?.present(navigationController, animated: true)
      completion(true)
    }
    editAction.backgroundColor = .systemBlue
    editAction.image = UIImage(systemName: "pencil")
    
    return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
  }
  
  private func showDeleteConfirmation(for quote: QuoteEntity) {
    let alert = UIAlertController(
      title: "Delete Quote",
      message: "Are you sure you want to delete this quote?",
      preferredStyle: .alert
    )
    
    let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
      self?.deleteQuote(quote)
    }
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
    
    alert.addAction(deleteAction)
    alert.addAction(cancelAction)
    
    present(alert, animated: true)
  }
  
  private func deleteQuote(_ quote: QuoteEntity) {
    Task {
      do {
        let deleteInteractor = DeleteQuoteInteractor()
        let request = DeleteQuoteInteractor.Request(quoteObjectID: quote.objectID)
        try await deleteInteractor(request: request)
      } catch {
        await MainActor.run {
          let errorAlert = UIAlertController(
            title: "Error",
            message: "Failed to delete quote: \(error.localizedDescription)",
            preferredStyle: .alert
          )
          errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
          self.present(errorAlert, animated: true)
        }
      }
    }
  }
}

extension AllQuotesViewController: @preconcurrency NSFetchedResultsControllerDelegate {
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
    let typedSnapshot = snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>
    dataSource.apply(typedSnapshot, animatingDifferences: true)
  }
}
