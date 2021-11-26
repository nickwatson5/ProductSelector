import UIKit

struct ImageModel: Hashable {
    let image: UIImage
    let identifier = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}
