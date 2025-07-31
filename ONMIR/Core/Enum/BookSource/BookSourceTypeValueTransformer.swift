import Foundation

@objc(BookSourceTypeValueTransformer)
final class BookSourceTypeValueTransformer: ValueTransformer {
  static let name = NSValueTransformerName(
    rawValue: String(describing: BookSourceTypeValueTransformer.self)
  )

  override public class func transformedValueClass() -> AnyClass {
    return BookSourceTypeKind.self
  }

  override public class func allowsReverseTransformation() -> Bool {
    return true
  }

  override public func transformedValue(_ value: Any?) -> Any? {
    guard let bookSourceKind = value as? BookSourceTypeKind else {
      return nil
    }
    
    do {
      return try NSKeyedArchiver.archivedData(withRootObject: bookSourceKind, requiringSecureCoding: true)
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
      return try NSKeyedUnarchiver.unarchivedObject(ofClasses: BookSourceTypeKind.secureCodingClasses, from: data)
    } catch {
      print(error)
      return nil
    }
  }
}
