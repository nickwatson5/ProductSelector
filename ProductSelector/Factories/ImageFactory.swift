import UIKit

struct ImageFactory {
    
    enum Mode {
        case random
        case next
    }
    
    private static var index: Int = 0
    private static let maxIndex: Int = ImageNamesDataSource.names.count
    
    static func produce(using mode: Mode = .random) -> UIImage? {
        var localIndex: Int
        
        switch mode {
        case .random:
            localIndex = Int.random(in: 0..<maxIndex)
        case .next:
            incrementPointingIndex()
            localIndex = index
        }
        
        let imageName = ImageNamesDataSource.names[localIndex]
        return UIImage(named: imageName)
    }
    
    static func resetPoitingIndex() {
        index = 0
    }
    
    static func incrementPointingIndex() {
        index = (index + 1) % maxIndex
    }
}

struct ImageNamesDataSource {
    static var names: [String] = [
        "hsbc-1-1", "hsbc-1-2", "hsbc-1-3"
    ]
}
