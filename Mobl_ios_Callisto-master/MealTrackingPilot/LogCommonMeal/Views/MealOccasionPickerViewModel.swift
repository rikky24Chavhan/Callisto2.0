//
//  MealOccasionPickerViewModel.swift
//  MealTrackingPilot
//
//  Created by Andrew Dolce on 3/21/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import RxSwift

class MealOccasionPickerViewModel: OccasionPickerDataSource, OccasionPickerDelegate {
    let occasions: [MealOccasion]
    private(set) var selectedIndex: Variable<Int>

    private var itemViewModels = [MealOccasionPickerItemViewModel]()

    var selectedOccasion: Observable<MealOccasion?> {
        return selectedIndex.asObservable().map { [weak self] index in
            return self?.occasion(at: index)
        }
    }

    private struct Constants {
        static let itemPadding: CGFloat = 16.0
    }

    init(occasions: [MealOccasion] = MealOccasion.orderedValues) {
        self.occasions = occasions
        self.selectedIndex = Variable(0)
        self.itemViewModels = createItemViewModels(from: occasions)
    }

    // MARK: Item View Models

    private func createItemViewModels(from occasions: [MealOccasion]) -> [MealOccasionPickerItemViewModel] {
        var viewModels = occasions.map { MealOccasionPickerItemViewModel(occasion: $0, highlighted: false) }
        viewModels.insert(MealOccasionPickerItemViewModel(occasion: nil, highlighted: false), at: 0)
        return viewModels
    }

    private func occasion(at index: Int) -> MealOccasion? {
        if index <= 0 {
            return nil
        }
        return occasions[index - 1]
    }

    // MARK: - OccasionPickerDataSource

    func occasionPickerNumberOfItems(_ occasionPicker: OccasionPicker) -> Int {
        return itemViewModels.count
    }

    func occasionPickerSpanForItems(_ _occasionPicker: OccasionPicker) -> CGFloat {
        return MealOccasionPickerItemView.preferredWidth + Constants.itemPadding
    }

    func occasionPicker(_ occasionPicker: OccasionPicker, viewForItem item: Int, index: Int, highlighted: Bool, reusingView view: UIView?) -> UIView? {
        let itemView = (view as? MealOccasionPickerItemView) ?? MealOccasionPickerItemView.fromNib()
        let viewModel = itemViewModels[index]
        viewModel.highlighted = highlighted
        itemView.configureWithViewModel(viewModel)
        return itemView
    }

    func occasionPicker(_ _occasionPicker: OccasionPicker, titleForItem item: Int, index: Int) -> String {
        return ""
    }

    // MARK: - OccasionPickerDelegate

    func occasionPicker(_ _occasionPicker: OccasionPicker, didSelectItem item: Int, index: Int) {
        selectedIndex.value = index
    }
}
