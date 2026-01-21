extension Dictionary {
    static func + (lhs: [Key: Value], rhs: [Key: Value]) -> [Key: Value] {
        if !rhs.isEmpty {
            var result = lhs
            for (key, value) in rhs {
                result[key] = value
            }
            return result
        } else {
            return lhs
        }
    }
    
    static func += (lhs: inout [Key: Value], rhs: [Key: Value]) {
        if !rhs.isEmpty {
            for (key, value) in rhs {
                lhs[key] = value
            }
        }
    }
}
