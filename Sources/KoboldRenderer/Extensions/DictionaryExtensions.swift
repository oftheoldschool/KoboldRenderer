extension Dictionary {
    static func + (lhs: [Key: Value], rhs: [Key: Value]) -> [Key: Value] {
        var result = lhs
        for (key, value) in rhs {
            result[key] = value
        }
        return result
    }
    
    static func += (lhs: inout [Key: Value], rhs: [Key: Value]) {
        for (key, value) in rhs {
            lhs[key] = value
        }
    }
}
