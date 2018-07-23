import Foundation

final class Dog: Decodable {
    
    let url: URL
    
    init(url: URL) {
        self.url = url
    }
}
