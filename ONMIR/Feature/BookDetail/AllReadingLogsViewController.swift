import UIKit
import CoreData
import SnapKit

#warning("TODO: UI")
final class AllReadingLogsViewController: UIViewController {
  private let tableView = UITableView()
  private let bookObjectID: NSManagedObjectID
  private lazy var fetchedResultsController = makeFetchedResultsController()
  private lazy var dataSource = makeDataSource()

  private static let timeFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute]
    formatter.unitsStyle = .abbreviated
    return formatter
  }()
  
  
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
      print("Failed to fetch reading logs: \(error)")
    }
  }
  
  private func setupUI() {
    title = "All Book Logs"
    view.backgroundColor = .systemBackground
    
    tableView.delegate = self
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ReadingLogCell")
    
    view.addSubview(tableView)
    tableView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }
  
  private func makeDataSource() -> UITableViewDiffableDataSource<Int, NSManagedObjectID> {
    let dataSource = UITableViewDiffableDataSource<Int, NSManagedObjectID>(tableView: tableView) { [weak self] tableView, indexPath, objectID in
      let cell = tableView.dequeueReusableCell(withIdentifier: "ReadingLogCell", for: indexPath)
      
      guard let self else { return cell }
            
      let context = self.fetchedResultsController.managedObjectContext
      guard
        let log = context.object(with: objectID) as? ReadingLogEntity
      else {
        return cell
      }
      
      context.perform {
        cell.textLabel?.text = "\(log.startPage) - \(log.endPage)"
        cell.detailTextLabel?.text = Self.timeFormatter.string(from: log.readingSeconds)
        cell.accessoryType = .disclosureIndicator
      }
      
      return cell
    }
    
    tableView.dataSource = dataSource
    return dataSource
  }
  
  private func makeFetchedResultsController() -> NSFetchedResultsController<ReadingLogEntity> {
    let context = ContextManager.shared.mainContext
    
    guard let book = context.object(with: bookObjectID) as? BookEntity else {
      fatalError("Failed to load book entity")
    }
    
    let request: NSFetchRequest<ReadingLogEntity> = ReadingLogEntity.fetchRequest()
    request.predicate = NSPredicate(format: "book == %@", book)
    request.sortDescriptors = [NSSortDescriptor(keyPath: \ReadingLogEntity.startPage, ascending: false)]
    
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


extension AllReadingLogsViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
  }
}

extension AllReadingLogsViewController: @preconcurrency NSFetchedResultsControllerDelegate {
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
    let typedSnapshot = snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>
    dataSource.apply(typedSnapshot, animatingDifferences: true)
  }
}
