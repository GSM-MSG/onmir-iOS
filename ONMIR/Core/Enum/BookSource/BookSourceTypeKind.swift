import CoreData

@objc(BookSourceTypeKind)
public final class BookSourceTypeKind: NSObject, NSSecureCoding, @unchecked Sendable {
  public static var supportsSecureCoding: Bool { true }

  static let secureCodingClasses: [AnyClass] = [
    BookSourceTypeKind.self,
    NSString.self
  ]

  let sourceType: BookSourceType

  init(sourceType: BookSourceType) {
    self.sourceType = sourceType
    super.init()
  }

  public init?(coder: NSCoder) {
    if
      let kindRawValue = coder.decodeObject(forKey: "kind") as? String,
      let kind = BookSourceType(rawValue: kindRawValue) {
      self.sourceType = kind
    } else {
      print("No BookSourceType was found")
      self.sourceType = .googleBooks
    }
    
    super.init()
  }

  public func encode(with coder: NSCoder) {
    coder.encode(sourceType.rawValue, forKey: "kind")
  }
  
  public override func isEqual(_ object: Any?) -> Bool {
    let superResult = super.isEqual(object)
    guard
      !superResult,
      let other = object as? BookSourceTypeKind
    else {
      return superResult
    }
    
    return sourceType.rawValue == other.sourceType.rawValue
  }

  public override var hash: Int {
    sourceType.hashValue
  }
}
