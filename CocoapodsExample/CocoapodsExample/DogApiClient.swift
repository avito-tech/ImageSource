import Foundation

final class DogApiClient {
    
    private let urlSession: URLSession
    
    init() {
        let apiKey = "1c9d81dc-8397-43ac-b2b5-769b2b423b95"
        
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = [
            "x-api-key": apiKey
        ]
        
        urlSession = URLSession(configuration: configuration)
    }
    
    func randomDogs(completion: @escaping ([Dog]) -> ()) {
        guard let url = URL(string: "https://api.thedogapi.com/v1/images/search?limit=50") else {
            assertionFailure("Invalid URL")
            return
        }
        
        let task = urlSession.dataTask(with: url) { data, response, error in
            if let data = data {
                let decoder = JSONDecoder()
                
                do {
                    let dogs = try decoder.decode([Dog].self, from: data)
                    completion(dogs)
                } catch {
                    completion([]) // TODO
                }
            }
        }
        
        task.resume()
    }
}
