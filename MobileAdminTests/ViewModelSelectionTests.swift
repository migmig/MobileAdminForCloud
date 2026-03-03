//
//  ViewModelSelectionTests.swift
//  MobileAdminTests
//

import Testing
import Foundation
@testable import MobileAdmin

@MainActor
struct ViewModelSelectionTests {

    // MARK: - toggleSelection

    @Test func toggleSelection_newId_addsToSelectedSet() {
        let vm = ViewModel()
        vm.toggleSelection(errorId: 1)
        #expect(vm.selectedErrors.contains(1))
    }

    @Test func toggleSelection_existingId_removesFromSelectedSet() {
        let vm = ViewModel()
        vm.toggleSelection(errorId: 1)
        vm.toggleSelection(errorId: 1)
        #expect(!vm.selectedErrors.contains(1))
        #expect(vm.selectedErrors.isEmpty)
    }

    @Test func toggleSelection_nilId_doesNothing() {
        let vm = ViewModel()
        vm.toggleSelection(errorId: nil)
        #expect(vm.selectedErrors.isEmpty)
    }

    @Test func toggleSelection_multipleDistinctIds_allAdded() {
        let vm = ViewModel()
        vm.toggleSelection(errorId: 1)
        vm.toggleSelection(errorId: 2)
        vm.toggleSelection(errorId: 3)
        #expect(vm.selectedErrors.count == 3)
        #expect(vm.selectedErrors.contains(1))
        #expect(vm.selectedErrors.contains(2))
        #expect(vm.selectedErrors.contains(3))
    }

    @Test func toggleSelection_removesOnlyTargetedId() {
        let vm = ViewModel()
        vm.toggleSelection(errorId: 1)
        vm.toggleSelection(errorId: 2)
        vm.toggleSelection(errorId: 3)
        vm.toggleSelection(errorId: 2) // remove 2
        #expect(vm.selectedErrors.count == 2)
        #expect(!vm.selectedErrors.contains(2))
        #expect(vm.selectedErrors.contains(1))
        #expect(vm.selectedErrors.contains(3))
    }

    @Test func toggleSelection_nilMixedWithValidIds_onlyValidAdded() {
        let vm = ViewModel()
        vm.toggleSelection(errorId: 10)
        vm.toggleSelection(errorId: nil)
        vm.toggleSelection(errorId: 20)
        #expect(vm.selectedErrors.count == 2)
        #expect(vm.selectedErrors.contains(10))
        #expect(vm.selectedErrors.contains(20))
    }

    // MARK: - selectAll

    @Test func selectAll_populatesSetFromErrorItems() {
        let vm = ViewModel()
        vm.errorItems = [
            ErrorCloudItem(id: 10),
            ErrorCloudItem(id: 20),
            ErrorCloudItem(id: 30)
        ]
        vm.selectAll()
        #expect(vm.selectedErrors == [10, 20, 30])
    }

    @Test func selectAll_emptyErrorItems_createsEmptySet() {
        let vm = ViewModel()
        vm.errorItems = []
        vm.selectAll()
        #expect(vm.selectedErrors.isEmpty)
    }

    @Test func selectAll_itemsWithNilId_nilsAreExcluded() {
        let vm = ViewModel()
        vm.errorItems = [
            ErrorCloudItem(id: 10),
            ErrorCloudItem(id: nil),
            ErrorCloudItem(id: 30)
        ]
        vm.selectAll()
        #expect(vm.selectedErrors.count == 2)
        #expect(vm.selectedErrors.contains(10))
        #expect(vm.selectedErrors.contains(30))
    }

    @Test func selectAll_replacesExistingSelection() {
        let vm = ViewModel()
        vm.toggleSelection(errorId: 99) // pre-select something unrelated
        vm.errorItems = [ErrorCloudItem(id: 1), ErrorCloudItem(id: 2)]
        vm.selectAll()
        // 99 is no longer in errorItems, so it should not appear
        #expect(!vm.selectedErrors.contains(99))
        #expect(vm.selectedErrors.contains(1))
        #expect(vm.selectedErrors.contains(2))
    }

    @Test func selectAll_allItemsHaveNilId_resultIsEmpty() {
        let vm = ViewModel()
        vm.errorItems = [
            ErrorCloudItem(id: nil),
            ErrorCloudItem(id: nil)
        ]
        vm.selectAll()
        #expect(vm.selectedErrors.isEmpty)
    }

    // MARK: - deselectAll

    @Test func deselectAll_clearsAllSelectedErrors() {
        let vm = ViewModel()
        vm.toggleSelection(errorId: 1)
        vm.toggleSelection(errorId: 2)
        vm.toggleSelection(errorId: 3)
        vm.deselectAll()
        #expect(vm.selectedErrors.isEmpty)
    }

    @Test func deselectAll_onEmptySet_remainsEmpty() {
        let vm = ViewModel()
        vm.deselectAll()
        #expect(vm.selectedErrors.isEmpty)
    }

    @Test func deselectAll_afterSelectAll_clearsAll() {
        let vm = ViewModel()
        vm.errorItems = [ErrorCloudItem(id: 1), ErrorCloudItem(id: 2)]
        vm.selectAll()
        vm.deselectAll()
        #expect(vm.selectedErrors.isEmpty)
    }

    // MARK: - selectedCount

    @Test func selectedCount_startsAtZero() {
        let vm = ViewModel()
        #expect(vm.selectedCount == 0)
    }

    @Test func selectedCount_incrementsWithEachToggle() {
        let vm = ViewModel()
        vm.toggleSelection(errorId: 1)
        #expect(vm.selectedCount == 1)
        vm.toggleSelection(errorId: 2)
        #expect(vm.selectedCount == 2)
        vm.toggleSelection(errorId: 3)
        #expect(vm.selectedCount == 3)
    }

    @Test func selectedCount_decrementsWhenDeselected() {
        let vm = ViewModel()
        vm.toggleSelection(errorId: 1)
        vm.toggleSelection(errorId: 2)
        vm.toggleSelection(errorId: 1) // deselect
        #expect(vm.selectedCount == 1)
    }

    @Test func selectedCount_returnsZeroAfterDeselectAll() {
        let vm = ViewModel()
        vm.toggleSelection(errorId: 1)
        vm.toggleSelection(errorId: 2)
        vm.deselectAll()
        #expect(vm.selectedCount == 0)
    }

    @Test func selectedCount_matchesSelectAll() {
        let vm = ViewModel()
        vm.errorItems = [
            ErrorCloudItem(id: 1),
            ErrorCloudItem(id: 2),
            ErrorCloudItem(id: 3)
        ]
        vm.selectAll()
        #expect(vm.selectedCount == 3)
    }

    // MARK: - canDeleteMultiple

    @Test func canDeleteMultiple_falseWhenSelectionEmpty() {
        let vm = ViewModel()
        #expect(vm.canDeleteMultiple == false)
    }

    @Test func canDeleteMultiple_trueWhenOneItemSelected() {
        let vm = ViewModel()
        vm.toggleSelection(errorId: 42)
        #expect(vm.canDeleteMultiple == true)
    }

    @Test func canDeleteMultiple_trueWhenMultipleItemsSelected() {
        let vm = ViewModel()
        vm.toggleSelection(errorId: 1)
        vm.toggleSelection(errorId: 2)
        #expect(vm.canDeleteMultiple == true)
    }

    @Test func canDeleteMultiple_falseAfterDeselectingLastItem() {
        let vm = ViewModel()
        vm.toggleSelection(errorId: 42)
        vm.toggleSelection(errorId: 42)
        #expect(vm.canDeleteMultiple == false)
    }

    @Test func canDeleteMultiple_falseAfterDeselectAll() {
        let vm = ViewModel()
        vm.toggleSelection(errorId: 1)
        vm.toggleSelection(errorId: 2)
        vm.deselectAll()
        #expect(vm.canDeleteMultiple == false)
    }

    @Test func canDeleteMultiple_trueAfterSelectAll() {
        let vm = ViewModel()
        vm.errorItems = [ErrorCloudItem(id: 1), ErrorCloudItem(id: 2)]
        vm.selectAll()
        #expect(vm.canDeleteMultiple == true)
    }
}
