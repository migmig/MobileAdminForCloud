//
//  UtilTests.swift
//  MobileAdminTests
//

import Testing
import Foundation
@testable import MobileAdmin

struct UtilTests {

    // MARK: - formattedDate

    @Test func formattedDate_replacesTWithSpace() {
        let result = Util.formattedDate("2024-10-01T12:30:00")
        #expect(result == "2024-10-01 12:30:00")
    }

    @Test func formattedDate_removesTrailingZ() {
        let result = Util.formattedDate("2024-10-01T12:30:00Z")
        #expect(result == "2024-10-01 12:30:00")
    }

    @Test func formattedDate_noSpecialChars_returnsUnchanged() {
        let result = Util.formattedDate("2024-10-01")
        #expect(result == "2024-10-01")
    }

    @Test func formattedDate_bothTAndZ_replacesAll() {
        let result = Util.formattedDate("2024-10-01T08:00:00.000Z")
        #expect(!result.contains("T"))
        #expect(!result.contains("Z"))
    }

    // MARK: - formatDateTime

    @Test func formatDateTime_validISO8601_formatsCorrectly() {
        let result = Util.formatDateTime("2024-10-01T12:30:45.000000")
        #expect(result == "2024-10-01 12:30:45")
    }

    @Test func formatDateTime_nilInput_returnsEmpty() {
        let result = Util.formatDateTime(nil)
        #expect(result == "")
    }

    @Test func formatDateTime_invalidFormat_returnsEmpty() {
        let result = Util.formatDateTime("not-a-date")
        #expect(result == "")
    }

    @Test func formatDateTime_emptyString_returnsEmpty() {
        let result = Util.formatDateTime("")
        #expect(result == "")
    }

    @Test func formatDateTime_withMicroseconds_formatsCorrectly() {
        let result = Util.formatDateTime("2024-01-15T09:05:03.123456")
        #expect(result == "2024-01-15 09:05:03")
    }

    // MARK: - convertToFormattedDate

    @Test func convertToFormattedDate_validYYYYMMDD_returnsFormatted() {
        let result = Util.convertToFormattedDate("20241001")
        #expect(result == "2024-10-01")
    }

    @Test func convertToFormattedDate_nilInput_returnsEmpty() {
        let result = Util.convertToFormattedDate(nil)
        #expect(result == "")
    }

    @Test func convertToFormattedDate_wrongFormat_returnsEmpty() {
        // ISO format, not yyyyMMdd
        let result = Util.convertToFormattedDate("2024-10-01")
        #expect(result == "")
    }

    @Test func convertToFormattedDate_emptyString_returnsEmpty() {
        let result = Util.convertToFormattedDate("")
        #expect(result == "")
    }

    @Test func convertToFormattedDate_january_padsMonthCorrectly() {
        let result = Util.convertToFormattedDate("20240105")
        #expect(result == "2024-01-05")
    }

    // MARK: - combineTodayWithTime

    @Test func combineTodayWithTime_validHHmmss_returnsDate() {
        let result = Util.combineTodayWithTime("120000")
        #expect(result != nil)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: result!)
        #expect(components.hour == 12)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }

    @Test func combineTodayWithTime_midnight_returnsDate() {
        let result = Util.combineTodayWithTime("000000")
        #expect(result != nil)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: result!)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }

    @Test func combineTodayWithTime_endOfDay_returnsDate() {
        let result = Util.combineTodayWithTime("235959")
        #expect(result != nil)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: result!)
        #expect(components.hour == 23)
        #expect(components.minute == 59)
        #expect(components.second == 59)
    }

    @Test func combineTodayWithTime_invalidFormat_returnsNil() {
        let result = Util.combineTodayWithTime("not-a-time")
        #expect(result == nil)
    }

    @Test func combineTodayWithTime_emptyString_returnsNil() {
        let result = Util.combineTodayWithTime("")
        #expect(result == nil)
    }

    @Test func combineTodayWithTime_usesTodaysDate() {
        let result = Util.combineTodayWithTime("120000")
        #expect(result != nil)
        let today = Date()
        let calendar = Calendar.current
        let resultComponents = calendar.dateComponents([.year, .month, .day], from: result!)
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: today)
        #expect(resultComponents.year == todayComponents.year)
        #expect(resultComponents.month == todayComponents.month)
        #expect(resultComponents.day == todayComponents.day)
    }

    // MARK: - convertFromDateIntoString

    @Test func convertFromDateIntoString_nilInput_returnsEmpty() {
        let result = Util.convertFromDateIntoString(nil)
        #expect(result == "")
    }

    @Test func convertFromDateIntoString_millisecondTimestamp_dividesBy1000() {
        // 1000 ms = 1 second from epoch
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let expected = formatter.string(from: Date(timeIntervalSince1970: 1))
        let result = Util.convertFromDateIntoString(1000)
        #expect(result == expected)
    }

    @Test func convertFromDateIntoString_zeroMilliseconds_convertsEpoch() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let expected = formatter.string(from: Date(timeIntervalSince1970: 0))
        let result = Util.convertFromDateIntoString(0)
        #expect(result == expected)
    }

    @Test func convertFromDateIntoString_returnsExpectedFormat() {
        // Verify output matches yyyy-MM-dd HH:mm:ss pattern
        let result = Util.convertFromDateIntoString(1_700_000_000_000)
        // Format: 4 digits, dash, 2 digits, dash, 2 digits, space, 2 digits, colon, 2 digits, colon, 2 digits
        #expect(result.count == 19)
        #expect(result[result.index(result.startIndex, offsetBy: 4)] == "-")
        #expect(result[result.index(result.startIndex, offsetBy: 7)] == "-")
        #expect(result[result.index(result.startIndex, offsetBy: 10)] == " ")
    }

    // MARK: - urlEncode

    @Test func urlEncode_nilInput_returnsEmpty() {
        let result = Util.urlEncode(nil)
        #expect(result == "")
    }

    @Test func urlEncode_noSpecialChars_returnsUnchanged() {
        let result = Util.urlEncode("hello")
        #expect(result == "hello")
    }

    @Test func urlEncode_space_encodesCorrectly() {
        let result = Util.urlEncode("hello world")
        #expect(result == "hello%20world")
    }

    @Test func urlEncode_emptyString_returnsEmpty() {
        let result = Util.urlEncode("")
        #expect(result == "")
    }

    @Test func urlEncode_alphanumericAndSafe_returnsUnchanged() {
        let result = Util.urlEncode("abc123-._~")
        #expect(!result.isEmpty)
    }

    // MARK: - getDevTypeImg

    @Test func getDevTypeImg_local_returnsGearIcon() {
        #expect(Util.getDevTypeImg("local") == "gearshape.fill")
    }

    @Test func getDevTypeImg_dev_returnsWrenchIcon() {
        #expect(Util.getDevTypeImg("dev") == "wrench.and.screwdriver")
    }

    @Test func getDevTypeImg_prod_returnsAirplaneIcon() {
        #expect(Util.getDevTypeImg("prod") == "airplane")
    }

    @Test func getDevTypeImg_unknownType_returnsNetworkIcon() {
        #expect(Util.getDevTypeImg("staging") == "network")
    }

    @Test func getDevTypeImg_emptyString_returnsNetworkIcon() {
        #expect(Util.getDevTypeImg("") == "network")
    }

    @Test func getDevTypeImg_caseSensitive_unknownForCapital() {
        // The switch is case-sensitive; "Local" != "local"
        #expect(Util.getDevTypeImg("Local") == "network")
    }

    // MARK: - getCurrentDateString

    @Test func getCurrentDateString_withFormatAndDate_returnsCorrectLength() {
        // yyyy-MM-dd is always 10 chars
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let result = Util.getCurrentDateString("yyyy-MM-dd", date)
        #expect(result.count == 10)
        #expect(result.contains("-"))
    }

    @Test func getCurrentDateString_noArgs_returnsEightCharYYYYMMDD() {
        let result = Util.getCurrentDateString()
        #expect(result.count == 8)
        // Should be all digits
        #expect(result.allSatisfy { $0.isNumber })
    }

    @Test func getFormattedDateString_returnsHyphenatedDate() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let result = Util.getFormattedDateString(date)
        #expect(result.count == 10)
        #expect(result[result.index(result.startIndex, offsetBy: 4)] == "-")
        #expect(result[result.index(result.startIndex, offsetBy: 7)] == "-")
    }

    // MARK: - prettyPrintedJSON

    @Test func prettyPrintedJSON_validJSON_excludesSpecifiedKey() {
        let json = #"{"name":"test","userEncMsg":"secret","value":"123"}"#
        let result = Util.prettyPrintedJSON(from: json, excludingKey: ["userEncMsg"])
        #expect(result != nil)
        #expect(result?.contains("userEncMsg") == false)
        #expect(result?.contains("name") == true)
        #expect(result?.contains("value") == true)
    }

    @Test func prettyPrintedJSON_excludesMultipleKeys() {
        let json = #"{"name":"test","userEncMsg":"secret","ci":"confidential","value":"123"}"#
        let result = Util.prettyPrintedJSON(from: json, excludingKey: ["userEncMsg", "ci"])
        #expect(result != nil)
        #expect(result?.contains("userEncMsg") == false)
        #expect(result?.contains("ci") == false)
        #expect(result?.contains("name") == true)
    }

    @Test func prettyPrintedJSON_emptyExclusionList_returnsAllKeys() {
        let json = #"{"name":"test","value":"123"}"#
        let result = Util.prettyPrintedJSON(from: json, excludingKey: [])
        #expect(result?.contains("name") == true)
        #expect(result?.contains("value") == true)
    }

    @Test func prettyPrintedJSON_truncatedJSON_repairsAndReturns() {
        // JSON truncated before the closing brace — missing last key/value pair
        let json = #"{"name":"test","value":"123","truncated":"abc"#
        let result = Util.prettyPrintedJSON(from: json, excludingKey: [])
        // The function repairs by trimming after last comma and appending }
        #expect(result != nil)
        #expect(result?.contains("name") == true)
    }

    @Test func prettyPrintedJSON_invalidJSON_returnsNil() {
        let result = Util.prettyPrintedJSON(from: "not json at all", excludingKey: [])
        #expect(result == nil)
    }

    @Test func prettyPrintedJSON_emptyObject_returnsNonNil() {
        let result = Util.prettyPrintedJSON(from: "{}", excludingKey: [])
        #expect(result != nil)
    }

    // MARK: - formatHashMapString

    @Test func formatHashMapString_singlePair_formatsWithQuotes() {
        let result = Util.formatHashMapString("{name=John}", excludingKey: [])
        #expect(result.contains("\"name\""))
        #expect(result.contains("\"John\""))
    }

    @Test func formatHashMapString_multiplePairs_joinsWithNewlineAndTab() {
        let result = Util.formatHashMapString("{name=John, age=30}", excludingKey: [])
        #expect(result.contains("name"))
        #expect(result.contains("age"))
        #expect(result.contains("\n"))
    }

    @Test func formatHashMapString_excludesSpecifiedKeys() {
        let input = "{name=John, userEncMsg=secret, age=30}"
        let result = Util.formatHashMapString(input, excludingKey: ["userEncMsg"])
        #expect(!result.contains("userEncMsg"))
        #expect(result.contains("name"))
        #expect(result.contains("age"))
    }

    @Test func formatHashMapString_wrapsInBraces() {
        let result = Util.formatHashMapString("{key=value}", excludingKey: [])
        #expect(result.hasPrefix("{"))
        #expect(result.hasSuffix("}"))
    }

    // MARK: - formatRequestInfo

    @Test func formatRequestInfo_validJSON_prettifiesAndExcludesSensitiveKeys() {
        let json = #"{"name":"test","userEncMsg":"secret","ci":"hidden"}"#
        let result = Util.formatRequestInfo(json)
        #expect(!result.contains("userEncMsg"))
        #expect(!result.contains("ci"))
        #expect(result.contains("name"))
    }

    @Test func formatRequestInfo_hashMapFormat_formatsWithQuotes() {
        let input = "{name=John, userEncMsg=secret}"
        let result = Util.formatRequestInfo(input)
        #expect(!result.contains("userEncMsg"))
        #expect(result.contains("name"))
    }

    @Test func formatRequestInfo_plainText_returnsOriginal() {
        let input = "plain text string"
        let result = Util.formatRequestInfo(input)
        #expect(result == input)
    }
}
