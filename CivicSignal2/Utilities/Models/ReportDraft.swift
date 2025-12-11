import Foundation
import CoreLocation

final class ReportDraft: ObservableObject {
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var category: String = ""
    @Published var priority: String = "medium"

    @Published var latitude: Double?
    @Published var longitude: Double?
    @Published var address: String?
    @Published var district: String?
    @Published var sector: String?
}
