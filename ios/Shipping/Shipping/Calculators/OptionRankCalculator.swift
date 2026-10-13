//
//  OptionRankCalculator.swift
//  Shipping
//
//  Marks the cheapest and the fastest option. The API doesn't send these
//  labels, so the app works them out.
//

import Foundation

struct OptionRank: Equatable {
    var isCheapest = false
    var isFastest = false
}

struct OptionRankCalculator {
    // Keyed by option id. With fewer than two options there's nothing to compare.
    func calcRanks(for options: [ShippingOption]) -> [String: OptionRank] {
        guard options.count > 1,
              let minPrice = options.map(\.price).min(),
              let minArrival = options.map(\.estimatedArrival).min() else { return [:] }

        return Dictionary(uniqueKeysWithValues: options.map { option in
            (option.id, OptionRank(isCheapest: option.price == minPrice,
                                   isFastest: option.estimatedArrival == minArrival))
        })
    }
}
