import CoreData

@objc(BookStatusTypeKind)
public final class BookStatusTypeKind: NSObject, NSSecureCoding, @unchecked Sendable {
  public static var supportsSecureCoding: Bool { true }

  static let secureCodingClasses: [AnyClass] = [
    BookStatusTypeKind.self,
    NSString.self
  ]

  let status: BookStatusType

  init(status: BookStatusType) {
    self.status = status
    super.init()
  }

  public init?(coder: NSCoder) {
    if
      let kindRawValue = coder.decodeObject(forKey: "kind") as? String,
      let kind = BookStatusType(rawValue: kindRawValue) {
      self.status = kind
    } else {
      print("No BookStatusType was found")
      self.status = .toRead
    }
    
    super.init()
  }

  public func encode(with coder: NSCoder) {
    coder.encode(status.rawValue, forKey: "kind")
  }
  
  public override func isEqual(_ object: Any?) -> Bool {
    let superResult = super.isEqual(object)
    guard
      !superResult,
      let other = object as? BookStatusTypeKind
    else {
      return superResult
    }
    
    return status.rawValue == other.status.rawValue
  }

  public override var hash: Int {
    status.hashValue
  }
}
