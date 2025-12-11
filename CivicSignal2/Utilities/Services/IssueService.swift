import Foundation
import UIKit

// MARK: - DTOs

struct IssueCategoryDTO: Codable {
    let id: String
    let name: String
    let icon: String?
    let description: String?
    let estimatedResponseTime: String?
}

struct IssuePhotoDTO: Codable {
    let url: String
    let thumbnailUrl: String?
    let size: Int?
    let mimeType: String?
}

struct IssueLocationDTO: Codable {
    let latitude: Double
    let longitude: Double
    let address: String?
    let district: String?
    let sector: String?
}

struct IssueDTO: Codable, Identifiable {
    let _id: String
    let trackingNumber: String
    let title: String
    let description: String?
    let category: String
    let priority: String
    let status: String
    let location: IssueLocationDTO?
    let photos: [IssuePhotoDTO]?
    let submittedAt: String
    
    // Conform to Identifiable
    var id: String { _id }
}

struct IssueListResponse: Codable {
    struct Pagination: Codable { let page: Int; let limit: Int; let total: Int; let totalPages: Int }
    let success: Bool
    let data: DataField
    struct DataField: Codable {
        let issues: [IssueDTO]
        let pagination: Pagination
    }
}

struct IssueSingleResponse: Codable {
    let success: Bool
    let data: DataField
    struct DataField: Codable { let issue: IssueDTO }
}

struct UpdateIssueResponse: Codable {
    let success: Bool
    let message: String?
    let data: IssueData
    struct IssueData: Codable { let issue: IssueDTO }
}

struct CategoriesResponse: Codable {
    let success: Bool
    let data: DataField
    struct DataField: Codable { let categories: [IssueCategoryDTO] }
}

struct UploadPhotosRequest: Encodable {
    struct Image: Encodable { let data: String; let mimeType: String }
    let images: [Image]
}

struct UploadPhotosResponse: Codable {
    let success: Bool
    let data: DataField
    struct DataField: Codable { let images: [IssuePhotoDTO] }
}

struct CreateIssueRequest: Encodable {
    struct DeviceInfo: Encodable {
        let deviceId: String?
        let deviceModel: String?
        let osVersion: String?
        let appVersion: String?
    }
    let title: String?
    let description: String?
    let category: String
    let priority: String?
    let location: IssueLocationDTO?
    let photos: [IssuePhotoDTO]?
    let deviceInfo: DeviceInfo
}

struct CreateIssueResponse: Codable {
    let success: Bool
    let data: DataField
    struct DataField: Codable {
        let issue: IssueDTO
        let trackingNumber: String
        let estimatedResponseTime: String?
    }
}

struct StatsResponse: Codable {
    let success: Bool
    let data: DataField
    struct DataField: Codable {
        let total: Int
        let submitted: Int
        let resolved: Int
        let inProgress: Int
    }
}

// MARK: - IssueService

enum IssueService {
    // MARK: Categories
    static func getCategories() async -> ServiceResult<[IssueCategoryDTO]> {
        do {
            let res: CategoriesResponse = try await APIClient.shared.request(
                "issues/categories",
                responseType: CategoriesResponse.self
            )
            return ServiceResult(success: true, data: res.data.categories, error: nil)
        } catch let APIError.httpStatus(code, data) {
            let msg = String(data: data, encoding: .utf8) ?? "Failed to fetch categories"
            print("Categories error (\(code)): \(msg)")
            return ServiceResult(success: false, data: nil, error: "Failed to fetch categories")
        } catch {
            return ServiceResult(success: false, data: nil, error: error.localizedDescription)
        }
    }

    // MARK: Upload Photos (base64)
    static func uploadPhotos(_ images: [UploadPhotosRequest.Image]) async -> ServiceResult<[IssuePhotoDTO]> {
        let body = UploadPhotosRequest(images: images)
        do {
            let res: UploadPhotosResponse = try await APIClient.shared.request(
                "issues/upload",
                method: "POST",
                body: body,
                authorized: true,
                responseType: UploadPhotosResponse.self
            )
            return ServiceResult(success: true, data: res.data.images, error: nil)
        } catch let APIError.httpStatus(code, data) {
            let msg = String(data: data, encoding: .utf8) ?? "Failed to upload photos"
            print("Upload error (\(code)): \(msg)")
            return ServiceResult(success: false, data: nil, error: "Failed to upload photos")
        } catch {
            return ServiceResult(success: false, data: nil, error: error.localizedDescription)
        }
    }

    static func getMyStats() async -> ServiceResult<StatsResponse> {
        guard let user: UserDTO = TokenManager.getUserData(UserDTO.self), let id = user.id else {
            return ServiceResult(success: false, data: nil, error: "User not authenticated")
        }
        
        return await APIClient.shared.request(
            endpoint: "/issues/stats",
            method: .get,
            queryItems: [URLQueryItem(name: "userId", value: id)],
            responseType: StatsResponse.self
        )
    }

    // MARK: Create Issue
    static func createIssue(
        title: String?,
        description: String?,
        category: String,
        priority: String?,
        location: IssueLocationDTO?,
        photos: [IssuePhotoDTO]?
    ) async -> ServiceResult<CreateIssueResponse> {
        // Derive device info
        let deviceInfo = await CreateIssueRequest.DeviceInfo(
            deviceId: UIDevice.current.identifierForVendor?.uuidString,
            deviceModel: UIDevice.current.model,
            osVersion: "iOS " + UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        )
        let body = CreateIssueRequest(
            title: title,
            description: description,
            category: category,
            priority: priority,
            location: location,
            photos: photos,
            deviceInfo: deviceInfo
        )
        do {
            let res: CreateIssueResponse = try await APIClient.shared.request(
                "issues",
                method: "POST",
                body: body,
                authorized: true,
                responseType: CreateIssueResponse.self
            )
            return ServiceResult(success: true, data: res, error: nil)
        } catch let APIError.httpStatus(code, data) {
            let msg = String(data: data, encoding: .utf8) ?? "Failed to create issue"
            print("Create issue error (\(code)): \(msg)")
            if code == 403 {
                return ServiceResult(success: false, data: nil, error: "Device verification failed or not trusted yet")
            }
            if code == 429 {
                return ServiceResult(success: false, data: nil, error: "Daily submission limit reached")
            }
            return ServiceResult(success: false, data: nil, error: "Failed to create issue")
        } catch {
            return ServiceResult(success: false, data: nil, error: error.localizedDescription)
        }
    }

    // MARK: My Issues
    static func getMyIssues(status: String? = nil, page: Int? = nil, limit: Int? = nil) async -> ServiceResult<IssueListResponse> {
        guard let user: UserDTO = TokenManager.getUserData(UserDTO.self), let id = user.id else {
            return ServiceResult(success: false, data: nil, error: "User not authenticated")
        }
        var params: [URLQueryItem] = [URLQueryItem(name: "userId", value: id)]
        if let status = status { params.append(URLQueryItem(name: "status", value: status)) }
        if let page = page { params.append(URLQueryItem(name: "page", value: String(page))) }
        if let limit = limit { params.append(URLQueryItem(name: "limit", value: String(limit))) }
        let query = params.compactMap { "\($0.name)=\($0.value ?? "")" }.joined(separator: "&")
        do {
            let res: IssueListResponse = try await APIClient.shared.request(
                "issues?\(query)",
                responseType: IssueListResponse.self
            )
            return ServiceResult(success: true, data: res, error: nil)
        } catch let APIError.httpStatus(code, data) {
            let msg = String(data: data, encoding: .utf8) ?? "Failed to fetch issues"
            print("My issues error (\(code)): \(msg)")
            return ServiceResult(success: false, data: nil, error: "Failed to fetch issues")
        } catch {
            return ServiceResult(success: false, data: nil, error: error.localizedDescription)
        }
    }

    // MARK: My Stats (client-side aggregation)
    static func getMyStats() async -> ServiceResult<[String: Int]> {
        let res = await getMyIssues(page: 1, limit: 1000)
        guard res.success, let issues = res.data?.data.issues else {
            return ServiceResult(success: false, data: nil, error: res.error ?? "Failed to fetch stats")
        }
        let counts = issues.reduce(into: [String: Int]()) { dict, issue in
            dict[issue.status, default: 0] += 1
        }
        var stats: [String: Int] = [:]
        stats["total"] = issues.count
        stats["submitted"] = counts["submitted"] ?? 0
        stats["acknowledged"] = counts["acknowledged"] ?? 0
        stats["inProgress"] = counts["in_progress"] ?? 0
        stats["resolved"] = counts["resolved"] ?? 0
        stats["closed"] = counts["closed"] ?? 0
        return ServiceResult(success: true, data: stats, error: nil)
    }

    // MARK: Get Issue
    static func getIssue(id: String) async -> ServiceResult<IssueSingleResponse> {
        do {
            let res: IssueSingleResponse = try await APIClient.shared.request(
                "issues/\(id)",
                responseType: IssueSingleResponse.self
            )
            return ServiceResult(success: true, data: res, error: nil)
        } catch let APIError.httpStatus(code, data) {
            let msg = String(data: data, encoding: .utf8) ?? "Failed to fetch issue"
            print("Issue error (\(code)): \(msg)")
            return ServiceResult(success: false, data: nil, error: "Failed to fetch issue")
        } catch {
            return ServiceResult(success: false, data: nil, error: error.localizedDescription)
        }
    }

    // MARK: Update Issue Photos (PATCH)
    static func updateIssuePhotos(issueId: String, photos: [IssuePhotoDTO]) async -> ServiceResult<UpdateIssueResponse> {
        let body: [String: AnyEncodableValue] = [
            "photos": AnyEncodableValue(photos)
        ]
        do {
            let res: UpdateIssueResponse = try await APIClient.shared.request(
                "issues/\(issueId)",
                method: "PATCH",
                body: DictionaryEncodable(body),
                authorized: true,
                responseType: UpdateIssueResponse.self
            )
            return ServiceResult(success: true, data: res, error: nil)
        } catch let APIError.httpStatus(code, data) {
            let msg = String(data: data, encoding: .utf8) ?? "Failed to update issue"
            print("Update issue photos error (\(code)): \(msg)")
            return ServiceResult(success: false, data: nil, error: "Failed to update issue")
        } catch {
            return ServiceResult(success: false, data: nil, error: error.localizedDescription)
        }
    }
}

// Helper wrappers to encode heterogeneous dictionaries
private struct AnyEncodableValue: Encodable {
    private let _encode: (Encoder) throws -> Void
    init<T: Encodable>(_ value: T) { self._encode = value.encode }
    func encode(to encoder: Encoder) throws { try _encode(encoder) }
}

private struct DictionaryEncodable: Encodable {
    let dict: [String: AnyEncodableValue]
    init(_ dict: [String: AnyEncodableValue]) { self.dict = dict }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKey.self)
        for (k, v) in dict { try container.encode(v, forKey: DynamicCodingKey(stringValue: k)!) }
    }
    struct DynamicCodingKey: CodingKey {
        var stringValue: String
        init?(stringValue: String) { self.stringValue = stringValue }
        var intValue: Int? { nil }
        init?(intValue: Int) { return nil }
    }
}
