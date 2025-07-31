import UIKit
import CoreData
import SnapKit

#warning("TODO: UI")
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
    
    tableView.delegate = self
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "QuoteCell")
    tableView.rowHeight = UITableView.automaticDimension
    tableView.estimatedRowHeight = 80
    
    view.addSubview(tableView)
    tableView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }
  
  private func makeDataSource() -> UITableViewDiffableDataSource<Int, NSManagedObjectID> {
    let dataSource = UITableViewDiffableDataSource<Int, NSManagedObjectID>(tableView: tableView) { [weak self] tableView, indexPath, objectID in
      let cell = tableView.dequeueReusableCell(withIdentifier: "QuoteCell", for: indexPath)

      guard let self = self
      else { return cell }

      let context = self.fetchedResultsController.managedObjectContext

      guard
        let quote = context.object(with: objectID) as? QuoteEntity
      else {
        return cell
      }
      
      context.perform {
        cell.textLabel?.text = quote.content ?? ""
        cell.detailTextLabel?.text = "\(quote.page) P"
        cell.textLabel?.numberOfLines = 0
        cell.accessoryType = .disclosureIndicator
      }
      
      return cell
    }
    
    tableView.dataSource = dataSource
    return dataSource
  }
  
  private func makeFetchedResultsController() -> NSFetchedResultsController<QuoteEntity> {
    let context = ContextManager.shared.mainContext
    
    guard let book = context.object(with: bookObjectID) as? BookEntity else {
      fatalError("Failed to load book entity")
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
  }
}

extension AllQuotesViewController: @preconcurrency NSFetchedResultsControllerDelegate {
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
    let typedSnapshot = snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>
    dataSource.apply(typedSnapshot, animatingDifferences: true)
  }
}
