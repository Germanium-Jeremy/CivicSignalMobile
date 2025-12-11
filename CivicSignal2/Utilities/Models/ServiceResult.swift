import Foundation

struct ServiceResult<Value> {
    let success: Bool
    let data: Value?
    let error: String?
    
    init(success: Bool, data: Value? = nil, error: String? = nil) {
        self.success = success
        self.data = data
        self.error = error
    }
}
