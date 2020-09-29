public struct ImageRequestId: Hashable, Equatable {
    
    internal let intValue: Int
    
    // MARK: - Init
    
    internal init(intValue: Int) {
        self.intValue = intValue
    }
    
    public init<T: Hashable>(hashable: T) {
        self.init(intValue: hashable.hashValue)
    }
    
    // MARK: - Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(intValue)
    }
    
    // MARK: - Equatable
    public static func ==(id1: ImageRequestId, id2: ImageRequestId) -> Bool {
        return id1.intValue == id2.intValue
    }
}

// MARK: - Internal

extension Int32 {
    func toImageRequestId() -> ImageRequestId {
        return ImageRequestId(intValue: Int(self))
    }
}

extension Int {
    func toImageRequestId() -> ImageRequestId {
        return ImageRequestId(intValue: self)
    }
}
