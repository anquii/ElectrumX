actor RequestID {
    private var value = 0

    func next() -> String {
        value += 1
        return "\(value)"
    }
}
