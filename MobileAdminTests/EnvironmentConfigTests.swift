//
//  EnvironmentConfigTests.swift
//  MobileAdminTests
//

import Testing
import Foundation
import SwiftData
@testable import MobileAdmin

// Serialized because tests mutate shared static state on EnvironmentConfig
@Suite(.serialized)
struct EnvironmentConfigTests {

    init() {
        // Each test starts from a clean, empty URL dictionary.
        // Tests that need a specific 'current' value set it explicitly.
        EnvironmentConfig.environmentUrls = [:]
    }

    // MARK: - EnvironmentType raw values

    @Test func environmentType_development_rawValue() {
        #expect(EnvironmentType.development.rawValue == "development")
    }

    @Test func environmentType_production_rawValue() {
        #expect(EnvironmentType.production.rawValue == "production")
    }

    @Test func environmentType_local_rawValue() {
        #expect(EnvironmentType.local.rawValue == "local")
    }

    @Test func environmentType_initFromRawValue_development() {
        #expect(EnvironmentType(rawValue: "development") == .development)
    }

    @Test func environmentType_initFromRawValue_production() {
        #expect(EnvironmentType(rawValue: "production") == .production)
    }

    @Test func environmentType_initFromRawValue_local() {
        #expect(EnvironmentType(rawValue: "local") == .local)
    }

    @Test func environmentType_initFromRawValue_unknown_returnsNil() {
        #expect(EnvironmentType(rawValue: "staging") == nil)
        #expect(EnvironmentType(rawValue: "") == nil)
        #expect(EnvironmentType(rawValue: "Development") == nil) // case-sensitive
    }

    // MARK: - EnvironmentConfig.current

    @Test func current_canBeSetToDevelopment() {
        EnvironmentConfig.current = .development
        #expect(EnvironmentConfig.current == .development)
    }

    @Test func current_canBeSetToProduction() {
        EnvironmentConfig.current = .production
        #expect(EnvironmentConfig.current == .production)
    }

    @Test func current_canBeSetToLocal() {
        EnvironmentConfig.current = .local
        #expect(EnvironmentConfig.current == .local)
    }

    @Test func current_canBeSwitchedMultipleTimes() {
        EnvironmentConfig.current = .development
        EnvironmentConfig.current = .production
        EnvironmentConfig.current = .local
        #expect(EnvironmentConfig.current == .local)
    }

    // MARK: - EnvironmentConfig.baseUrl (using direct dict manipulation)

    @Test func baseUrl_returnsUrlMatchingCurrentEnvironment_development() {
        EnvironmentConfig.environmentUrls = [
            .development: "http://dev.example.com",
            .production:  "http://prod.example.com",
            .local:       "http://localhost:8080"
        ]
        EnvironmentConfig.current = .development
        #expect(EnvironmentConfig.baseUrl == "http://dev.example.com")
    }

    @Test func baseUrl_returnsUrlMatchingCurrentEnvironment_production() {
        EnvironmentConfig.environmentUrls = [
            .development: "http://dev.example.com",
            .production:  "http://prod.example.com",
            .local:       "http://localhost:8080"
        ]
        EnvironmentConfig.current = .production
        #expect(EnvironmentConfig.baseUrl == "http://prod.example.com")
    }

    @Test func baseUrl_returnsUrlMatchingCurrentEnvironment_local() {
        EnvironmentConfig.environmentUrls = [
            .development: "http://dev.example.com",
            .production:  "http://prod.example.com",
            .local:       "http://localhost:8080"
        ]
        EnvironmentConfig.current = .local
        #expect(EnvironmentConfig.baseUrl == "http://localhost:8080")
    }

    @Test func baseUrl_emptyDict_returnsHardcodedDefault() {
        // environmentUrls is empty (set in init())
        EnvironmentConfig.current = .development
        #expect(EnvironmentConfig.baseUrl == "http://192.168.0.3:8080")
    }

    @Test func baseUrl_currentEnvNotInDict_returnsHardcodedDefault() {
        // Only production is configured; current is development
        EnvironmentConfig.environmentUrls = [.production: "http://prod.example.com"]
        EnvironmentConfig.current = .development
        #expect(EnvironmentConfig.baseUrl == "http://192.168.0.3:8080")
    }

    @Test func baseUrl_switchingEnvironment_returnsCorrespondingUrl() {
        EnvironmentConfig.environmentUrls = [
            .development: "http://dev.example.com",
            .production:  "http://prod.example.com"
        ]
        EnvironmentConfig.current = .development
        #expect(EnvironmentConfig.baseUrl == "http://dev.example.com")
        EnvironmentConfig.current = .production
        #expect(EnvironmentConfig.baseUrl == "http://prod.example.com")
    }

    // MARK: - EnvironmentConfig.initializeUrls (with in-memory SwiftData container)

    private func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([EnvironmentModel.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    @Test func initializeUrls_validEnvironments_populatesAllThree() throws {
        let container = try makeInMemoryContainer()
        let context   = ModelContext(container)

        let devModel  = EnvironmentModel(); devModel.envType  = "development"; devModel.url  = "http://dev.test"
        let prodModel = EnvironmentModel(); prodModel.envType = "production";  prodModel.url = "http://prod.test"
        let localModel = EnvironmentModel(); localModel.envType = "local";     localModel.url = "http://local.test"
        context.insert(devModel)
        context.insert(prodModel)
        context.insert(localModel)

        EnvironmentConfig.initializeUrls(from: [devModel, prodModel, localModel])

        #expect(EnvironmentConfig.environmentUrls[.development] == "http://dev.test")
        #expect(EnvironmentConfig.environmentUrls[.production]  == "http://prod.test")
        #expect(EnvironmentConfig.environmentUrls[.local]       == "http://local.test")
        #expect(EnvironmentConfig.environmentUrls.count == 3)
    }

    @Test func initializeUrls_invalidEnvType_excludedByCompactMap() throws {
        let container = try makeInMemoryContainer()
        let context   = ModelContext(container)

        let badModel = EnvironmentModel()
        badModel.envType = "staging"   // not a valid EnvironmentType raw value
        badModel.url     = "http://staging.test"
        context.insert(badModel)

        EnvironmentConfig.initializeUrls(from: [badModel])

        #expect(EnvironmentConfig.environmentUrls.isEmpty)
    }

    @Test func initializeUrls_emptyArray_resultsDictIsEmpty() throws {
        // Pre-populate the dict, then overwrite with an empty list
        EnvironmentConfig.environmentUrls = [.development: "http://old.url"]
        EnvironmentConfig.initializeUrls(from: [])
        #expect(EnvironmentConfig.environmentUrls.isEmpty)
    }

    @Test func initializeUrls_mixedValidAndInvalid_onlyValidIncluded() throws {
        let container = try makeInMemoryContainer()
        let context   = ModelContext(container)

        let validModel   = EnvironmentModel(); validModel.envType   = "local";   validModel.url   = "http://localhost:9090"
        let invalidModel = EnvironmentModel(); invalidModel.envType = "unknown"; invalidModel.url = "http://unknown.test"
        context.insert(validModel)
        context.insert(invalidModel)

        EnvironmentConfig.initializeUrls(from: [validModel, invalidModel])

        #expect(EnvironmentConfig.environmentUrls.count == 1)
        #expect(EnvironmentConfig.environmentUrls[.local] == "http://localhost:9090")
        #expect(EnvironmentConfig.environmentUrls[.development] == nil)
    }

    @Test func initializeUrls_replacesExistingDict() throws {
        // Set an old URL, then call initializeUrls with a new one
        EnvironmentConfig.environmentUrls = [.development: "http://old-dev.com"]
        let container = try makeInMemoryContainer()
        let context   = ModelContext(container)

        let newModel = EnvironmentModel(); newModel.envType = "development"; newModel.url = "http://new-dev.com"
        context.insert(newModel)

        EnvironmentConfig.initializeUrls(from: [newModel])

        #expect(EnvironmentConfig.environmentUrls[.development] == "http://new-dev.com")
    }

    @Test func initializeUrls_emptyEnvType_excluded() throws {
        let container = try makeInMemoryContainer()
        let context   = ModelContext(container)

        let emptyModel = EnvironmentModel() // envType defaults to ""
        context.insert(emptyModel)

        EnvironmentConfig.initializeUrls(from: [emptyModel])

        // Empty string does not match any EnvironmentType raw value
        #expect(EnvironmentConfig.environmentUrls.isEmpty)
    }

    // MARK: - initializeUrls → baseUrl integration

    @Test func initializeUrls_thenBaseUrl_returnsConfiguredUrl() throws {
        let container = try makeInMemoryContainer()
        let context   = ModelContext(container)

        let model = EnvironmentModel(); model.envType = "production"; model.url = "http://prod.configured.com"
        context.insert(model)

        EnvironmentConfig.initializeUrls(from: [model])
        EnvironmentConfig.current = .production

        #expect(EnvironmentConfig.baseUrl == "http://prod.configured.com")
    }
}
