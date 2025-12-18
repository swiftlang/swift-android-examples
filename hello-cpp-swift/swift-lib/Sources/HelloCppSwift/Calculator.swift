#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import HelloWorldCpp

public func addNumbers(_ a: Int32, _ b: Int32) -> Int32 {
    return add(a, b)
}

public func multiplyNumbers(_ a: Int32, _ b: Int32) -> Int32 {
    return multiply(a, b)
}
