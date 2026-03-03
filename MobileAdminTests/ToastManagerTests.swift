//
//  ToastManagerTests.swift
//  MobileAdminTests
//

import Testing
import Foundation
@testable import MobileAdmin

@MainActor
struct ToastManagerTests {

    // MARK: - Initial state

    @Test func toastManager_initialState_isNotShowing() {
        let manager = ToastManager()
        #expect(manager.isShowing == false)
    }

    @Test func toastManager_initialState_messageIsEmpty() {
        let manager = ToastManager()
        #expect(manager.message == "")
    }

    // MARK: - showToast immediate effects

    @Test func showToast_setsIsShowingTrue() {
        let manager = ToastManager()
        manager.showToast(message: "Hello")
        #expect(manager.isShowing == true)
    }

    @Test func showToast_setsProvidedMessage() {
        let manager = ToastManager()
        manager.showToast(message: "Test message")
        #expect(manager.message == "Test message")
    }

    @Test func showToast_emptyMessage_setsEmptyAndShows() {
        let manager = ToastManager()
        manager.showToast(message: "")
        #expect(manager.message == "")
        #expect(manager.isShowing == true)
    }

    @Test func showToast_unicodeMessage_preservesContent() {
        let manager = ToastManager()
        let message = "알림: 저장 완료 ✓"
        manager.showToast(message: message)
        #expect(manager.message == message)
    }

    @Test func showToast_calledTwice_latestMessageWins() {
        let manager = ToastManager()
        manager.showToast(message: "First")
        manager.showToast(message: "Second")
        #expect(manager.message == "Second")
        #expect(manager.isShowing == true)
    }

    // MARK: - Timed dismissal

    @Test func showToast_defaultDuration_dismissesAfterTwoSeconds() async throws {
        let manager = ToastManager()
        manager.showToast(message: "Brief", duration: 0.1)
        #expect(manager.isShowing == true)
        // Wait longer than the duration
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3s
        #expect(manager.isShowing == false)
    }

    @Test func showToast_customShortDuration_dismissesAfterDuration() async throws {
        let manager = ToastManager()
        manager.showToast(message: "Quick", duration: 0.05)
        #expect(manager.isShowing == true)
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2s
        #expect(manager.isShowing == false)
    }

    @Test func showToast_beforeDurationExpires_stillShowing() async throws {
        let manager = ToastManager()
        manager.showToast(message: "Persistent", duration: 1.0)
        // Check well before the 1s duration
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05s
        #expect(manager.isShowing == true)
        #expect(manager.message == "Persistent")
    }

    @Test func showToast_messageRemainsAfterDismissal() async throws {
        let manager = ToastManager()
        manager.showToast(message: "Remember me", duration: 0.1)
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3s
        // isShowing becomes false but message is not cleared
        #expect(manager.isShowing == false)
        #expect(manager.message == "Remember me")
    }
}
