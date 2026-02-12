import Foundation
import Logging

struct UserLogService {
    let client: NetworkClient
    private let logger = Logger(label: "com.migmig.MobileAdmin.UserLogService")

    private func normalizeUserLogNo(_ sno: String) -> String {
        if sno.hasPrefix("UT") {
            let index = sno.index(sno.startIndex, offsetBy: 2)
            return String(sno[index...])
        } else {
            return sno
        }
    }

    private func makeUserLogFileName(no: String) -> String {
        let digits = no.filter { $0.isNumber }
        let padded = String(repeating: "0", count: max(0, 11 - digits.count)) + digits
        return "UT\(padded).log"
    }

    func downloadUserLog(_ sno: String) async throws -> URL {
        try await client.ensureValidToken()

        let no = normalizeUserLogNo(sno)
        let urlString = "\(client.baseUrl)/admin/getUserLog/\(no)"

        var request = try client.makeAuthenticatedRequest(url: urlString)
        request.httpMethod = "POST"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NetworkError.httpError(statusCode: statusCode, url: urlString)
        }

        #if os(macOS)
        let directory = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        #else
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        #endif

        guard let saveDir = directory else {
            throw NetworkError.noData
        }

        let fileName = makeUserLogFileName(no: no)
        let fileURL = saveDir.appendingPathComponent(fileName)

        try data.write(to: fileURL, options: .atomic)

        logger.info("User log downloaded: \(fileURL.path)")

        return fileURL
    }
}
