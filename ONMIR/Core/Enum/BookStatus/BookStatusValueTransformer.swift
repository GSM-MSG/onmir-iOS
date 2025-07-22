import Foundation

@objc(BookStatusValueTransformer)
final class BookStatusValueTransformer: ValueTransformer {
  static let name = NSValueTransformerName(
    rawValue: String(describing: BookStatusValueTransformer.self)
  )

  override public class func transformedValueClass() -> AnyClass {
    BookStatusTypeKind.self
  }

  override public class func allowsReverseTransformation() -> Bool {
    return true
  }

  override public func transformedValue(_ value: Any?) -> Any? {
    guard let bookStatusKind = value as? BookStatusTypeKind else {
      return nil
    }
    
    do {
      return try NSKeyedArchiver.archivedData(withRootObject: bookStatusKind, requiringSecureCoding: true)
    } catch {
      print(error)
      return nil
    }
  }

  override public func reverseTransformedValue(_ value: Any?) -> Any? {
    guard let data = value as? Data else {
      return nil
    }

    do {
      return try NSKeyedUnarchiver.unarchivedObject(ofClasses: BookStatusTypeKind.secureCodingClasses, from: data)
    } catch {
      print(error)
      return nil
    }
  }
}
