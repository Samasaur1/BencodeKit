import Foundation

infix operator |<|

func |<|(lhs: String, rhs: String) -> Bool {
    let left = lhs.data(using: .utf8)!
    let right = rhs.data(using: .utf8)!

    for (l, r) in zip(left, right) {
        if l < r { return true }
        if l > r { return false }
    }

    return left.count < right.count
}
