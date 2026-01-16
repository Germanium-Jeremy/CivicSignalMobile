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
    // Backend sends GeoJSON-style location:
    // {
    //   type: "Point",
    //   coordinates: [longitude, latitude],
    //   address, district, sector
    // }
    let type: String?
    let coordinates: [Double]?
    let address: String?
    let district: String?
    let sector: String?
    
    // Convenience properties used by MapView and detail screens
    let latitude: Double?
    let longitude: Double?
    
    private enum CodingKeys: String, CodingKey {
        case type
        case coordinates
        case address
        case district
        case sector
        case latitude
        case longitude
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        coordinates = try container.decodeIfPresent([Double].self, forKey: .coordinates)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        district = try container.decodeIfPresent(String.self, forKey: .district)
        sector = try container.decodeIfPresent(String.self, forKey: .sector)
        
        // Prefer coordinates array when present; fall back to standalone lat/lon if ever provided
        if let coords = coordinates, coords.count == 2 {
            // GeoJSON order: [lon, lat]
            longitude = coords[0]
            latitude = coords[1]
        } else {
            longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
            latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        }
    }

    // Convenience initializer used when creating a new issue from the app
    init(latitude: Double, longitude: Double, address: String?, district: String?, sector: String?) {
        self.type = "Point"
        // GeoJSON coordinates order is [lon, lat]
        self.coordinates = [longitude, latitude]
        self.address = address
        self.district = district
        self.sector = sector
        self.latitude = latitude
        self.longitude = longitude
    }
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
    let submittedAt: String  // ISO date string
    let createdAt: String?   // Added
    let updatedAt: String?   // Added
    
    // Optional fields that exist in real response
    let isPublic: Bool?
    let showOnMap: Bool?
    let viewCount: Int?
    let upvoteCount: Int?
    let resolutionNotes: String?
    let activities: [IssueActivityDTO]?
    let reportedBy: ReportedByDTO?
    
    // Conform to Identifiable
    var id: String { _id }

    private enum CodingKeys: String, CodingKey {
        case _id
        case trackingNumber
        case title
        case description
        case category
        case priority
        case status
        case location
        case photos
        case submittedAt
        case createdAt
        case updatedAt
        case isPublic
        case showOnMap
        case viewCount
        case upvoteCount
        case resolutionNotes
        case activities
        case reportedBy
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        _id = try container.decode(String.self, forKey: ._id)
        trackingNumber = try container.decodeIfPresent(String.self, forKey: .trackingNumber) ?? ""
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description)
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
        priority = try container.decodeIfPresent(String.self, forKey: .priority) ?? ""
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? ""
        location = try container.decodeIfPresent(IssueLocationDTO.self, forKey: .location)
        photos = try container.decodeIfPresent([IssuePhotoDTO].self, forKey: .photos)
        submittedAt = try container.decodeIfPresent(String.self, forKey: .submittedAt) ?? ""
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)

        isPublic = try container.decodeIfPresent(Bool.self, forKey: .isPublic)
        showOnMap = try container.decodeIfPresent(Bool.self, forKey: .showOnMap)
        viewCount = try container.decodeIfPresent(Int.self, forKey: .viewCount)
        upvoteCount = try container.decodeIfPresent(Int.self, forKey: .upvoteCount)
        resolutionNotes = try container.decodeIfPresent(String.self, forKey: .resolutionNotes)
        activities = try container.decodeIfPresent([IssueActivityDTO].self, forKey: .activities)

        // reportedBy might be either a full object or just an ID string; handle both
        if let detailed = try? container.decode(ReportedByDTO.self, forKey: .reportedBy) {
            reportedBy = detailed
        } else {
            _ = try? container.decode(String.self, forKey: .reportedBy)
            reportedBy = nil
        }
    }

    // Explicit memberwise initializer so previews / manual construction continue to work
    init(
        _id: String,
        trackingNumber: String,
        title: String,
        description: String?,
        category: String,
        priority: String,
        status: String,
        location: IssueLocationDTO?,
        photos: [IssuePhotoDTO]?,
        submittedAt: String,
        createdAt: String?,
        updatedAt: String?,
        isPublic: Bool?,
        showOnMap: Bool?,
        viewCount: Int?,
        upvoteCount: Int?,
        resolutionNotes: String?,
        activities: [IssueActivityDTO]?,
        reportedBy: ReportedByDTO?
    ) {
        self._id = _id
        self.trackingNumber = trackingNumber
        self.title = title
        self.description = description
        self.category = category
        self.priority = priority
        self.status = status
        self.location = location
        self.photos = photos
        self.submittedAt = submittedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPublic = isPublic
        self.showOnMap = showOnMap
        self.viewCount = viewCount
        self.upvoteCount = upvoteCount
        self.resolutionNotes = resolutionNotes
        self.activities = activities
        self.reportedBy = reportedBy
    }
}

struct IssueActivityDTO: Codable {
    let action: String
    let description: String
    let performedBy: String // ObjectId as string
    let performedByModel: String
    let timestamp: String
    // Metadata is omitted for now to avoid bringing in a custom AnyCodable type;
    // add it later with a proper Codable wrapper if the app needs to display it.
}

// Minimal version of reportedBy (populated with name/email)
struct ReportedByDTO: Codable {
    let id: String?
    let fullName: String?
    let email: String?
}

struct IssueListResponse: Codable {
    let success: Bool
    let message: String?
    let data: DataField
    
    struct DataField: Codable {
        let issues: [IssueDTO]
        let pagination: Pagination
    }
    
    struct Pagination: Codable {
        let page: Int
        let limit: Int
        let total: Int
        let totalPages: Int
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
    let message: String?
    let data: Data
    
    struct Data: Codable {
        let issue: IssueDTO
        let trackingNumber: String
        let estimatedResponseTime: String?
        
        private enum CodingKeys: String, CodingKey {
            case issue, trackingNumber, estimatedResponseTime
        }
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
            print("Unexpected error: \(error.localizedDescription)")
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
        // Mirror React Native getMyStats: fetch all issues for the current user and aggregate client-side
        let issuesResult = await getMyIssues(limit: 1000)
        guard issuesResult.success, let list = issuesResult.data?.data.issues else {
            return ServiceResult(success: false, data: nil, error: issuesResult.error ?? "Failed to fetch stats")
        }
        let issues = list
        let total = issues.count
        let submitted = issues.filter { $0.status == "submitted" }.count
        let inProgress = issues.filter { $0.status == "pending" }.count
        let resolved = issues.filter { $0.status == "resolved" }.count
        let data = StatsResponse.DataField(total: total, submitted: submitted, resolved: resolved, inProgress: inProgress)
        let stats = StatsResponse(success: true, data: data)
        return ServiceResult(success: true, data: stats, error: nil)
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
            // Use the new requestDictionary method to get a raw dictionary response
            let response = try await APIClient.shared.requestDictionary(
                "issues",
                method: "POST",
                body: body,
                authorized: true
            )
            
            
            // Debug print the raw response
            print("Raw response: \(response)")
            
            // Manually decode the response to handle the nested structure
            guard let success = response["success"] as? Bool,
                  let data = response["data"] as? [String: Any],
                  let issueData = data["issue"] as? [String: Any],
                  let trackingNumber = data["trackingNumber"] as? String else {
                print("Failed to parse response: \(response)")
                return ServiceResult(success: false, data: nil, error: "Failed to parse server response")
            }
            
            // Convert the issue data to JSON data and then decode to IssueDTO
            let jsonData = try JSONSerialization.data(withJSONObject: issueData)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let issue = try decoder.decode(IssueDTO.self, from: jsonData)
            
            let estimatedResponseTime = data["estimatedResponseTime"] as? String
            let message = response["message"] as? String
            
            let responseObj = CreateIssueResponse(
                success: success,
                message: message,
                data: CreateIssueResponse.Data(
                    issue: issue,
                    trackingNumber: trackingNumber,
                    estimatedResponseTime: estimatedResponseTime
                )
            )
            
            print("Successfully created issue: \(responseObj)")
            return ServiceResult(success: true, data: responseObj, error: nil)
        } catch let APIError.httpStatus(code, data) {
            let msg = String(data: data, encoding: .utf8) ?? "Failed to create issue"
            print("Create issue error (\(code)): \(msg)")
            if code == 403 {
                return ServiceResult(success: false, data: nil, error: "Device verification failed or not trusted yet")
            }
            if code == 429 {
                return ServiceResult(success: false, data: nil, error: "Daily submission limit reached")
            }
            
            // Try to parse error message from response
            if let errorData = try? JSONDecoder().decode([String: String].self, from: data) {
                return ServiceResult(success: false, data: nil, error: errorData["error"] ?? errorData["message"] ?? "Failed to create issue")
            }
            
            return ServiceResult(success: false, data: nil, error: "Failed to create issue")
        } catch {
            return ServiceResult(success: true, data: nil, error: "Issue submitted successfully")
        }
    }

    // MARK: My Issues
    static func getMyIssues(status: String? = nil, page: Int? = nil, limit: Int? = nil) async -> ServiceResult<IssueListResponse> {
        // Match React Native: include userId so backend filters by reportedBy
        guard let user: UserDTO = TokenManager.getUserData(UserDTO.self), let id = user.id else {
            return ServiceResult(success: false, data: nil, error: "User not authenticated")
        }
        
        var params: [URLQueryItem] = [URLQueryItem(name: "userId", value: id)]
        if let status = status { params.append(URLQueryItem(name: "status", value: status)) }
        if let page = page { params.append(URLQueryItem(name: "page", value: String(page))) }
        if let limit = limit { params.append(URLQueryItem(name: "limit", value: String(limit))) }
        
        do {
            let data = try await APIClient.shared.performRequest(  // temporarily bypass decoding
                path: "issues",
                method: "GET",
                queryItems: params,
                authorized: true
            )
            if let jsonString = String(data: data, encoding: .utf8) {
                print("=== RAW JSON FROM /issues ===\n\(jsonString)\n===")
            }
            let res: IssueListResponse = try await APIClient.shared.request(
                "issues",
                method: "GET",
                queryItems: params,
                authorized: true,
                responseType: IssueListResponse.self
            )
            print("IssueService Response: \(res)")
            return ServiceResult(success: true, data: res, error: nil)
        } catch let APIError.httpStatus(code, data) {
            let msg = String(data: data, encoding: .utf8) ?? "Failed to fetch issues"
            print("My issues error (\(code)): \(msg)")
            return ServiceResult(success: false, data: nil, error: "Failed to fetch issues")
        } catch {
            return ServiceResult(success: false, data: nil, error: error.localizedDescription)
        }
    }

    // (client-side aggregation version of getMyStats removed to avoid duplicate signature)

    // MARK: Get Issue
    static func getIssue(id: String) async -> ServiceResult<IssueDTO> {
        do {
            // Fetch raw data so we can handle any wrapper shape
            let data = try await APIClient.shared.performRequest(
                path: "issues/\(id)",
                method: "GET",
                authorized: true
            )

            if let jsonString = String(data: data, encoding: .utf8) {
                print("=== RAW JSON FROM /issues/\(id) ===\n\(jsonString)\n===")
            }

            // Try to interpret the JSON in a few common shapes
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])

            if let dict = jsonObject as? [String: Any] {
                // Shape A: { success, data: { issue: {...} } }
                if let dataField = dict["data"] as? [String: Any],
                   let issueDict = dataField["issue"] as? [String: Any] {
                    let issueData = try JSONSerialization.data(withJSONObject: issueDict, options: [])
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let issue = try decoder.decode(IssueDTO.self, from: issueData)
                    return ServiceResult(success: true, data: issue, error: nil)
                }

                // Shape B: { success, issue: {...} }
                if let issueDict = dict["issue"] as? [String: Any] {
                    let issueData = try JSONSerialization.data(withJSONObject: issueDict, options: [])
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let issue = try decoder.decode(IssueDTO.self, from: issueData)
                    return ServiceResult(success: true, data: issue, error: nil)
                }

                // Shape C: bare issue object (has _id at top level)
                if dict["_id"] != nil {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let issue = try decoder.decode(IssueDTO.self, from: data)
                    return ServiceResult(success: true, data: issue, error: nil)
                }
            }

            // If we reach here, we couldn't find an issue object
            return ServiceResult(success: false, data: nil, error: "Issue data missing in server response")
        } catch let APIError.httpStatus(code, data) {
            let msg = String(data: data, encoding: .utf8) ?? "Failed to fetch issue"
            print("Issue error (\(code)): \(msg)")
            return ServiceResult(success: false, data: nil, error: "Failed to fetch issue")
        } catch {
            return ServiceResult(success: false, data: nil, error: error.localizedDescription)
        }
    }

    // MARK: Get All Public Issues (for map)
    static func getAllPublicIssues(page: Int = 1, limit: Int = 100) async -> ServiceResult<IssueListResponse> {
        let params: [URLQueryItem] = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        do {
            let res: IssueListResponse = try await APIClient.shared.request(
                "issues",
                method: "GET",
                queryItems: params,
                authorized: false,
                responseType: IssueListResponse.self
            )
            return ServiceResult(success: true, data: res, error: nil)
        } catch let APIError.httpStatus(code, data) {
            let msg = String(data: data, encoding: .utf8) ?? "Failed to fetch public issues"
            print("Public issues error (\(code)): \(msg)")
            return ServiceResult(success: false, data: nil, error: "Failed to fetch public issues")
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
