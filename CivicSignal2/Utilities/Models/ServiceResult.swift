import Foundation

struct ServiceResult<Value> {
    let success: Bool
    let data: Value?
    let error: String?
    let details: String?
    
    init(success: Bool, data: Value? = nil, error: String? = nil, details: String? = nil) {
        self.success = success
        self.data = data
        self.error = error
        self.details = details
    }
}
