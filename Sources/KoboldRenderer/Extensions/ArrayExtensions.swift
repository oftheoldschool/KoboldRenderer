extension Array {
    func sliding(_ size: Int) -> Array<(offset: Int, window: Array.SubSequence)> {
        let (q, r) = self.count.quotientAndRemainder(dividingBy: size)
        return stride(from: 0, to: self.count - r, by: size).map { i in
            (i, self[i..<i+size])
        } + (r > 0 ? [(q * size, self[(q * size)..<(q * size + r)])] : [])
    }
}
