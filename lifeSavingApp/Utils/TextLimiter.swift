//
//  TextLimiter.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 12/10/2021.
//

import Foundation


class TextLimiter: ObservableObject {
    private let limit: Int
    
    init(limit: Int) {
        self.limit = limit
    }
    
    @Published var value = "" {
        didSet {
            if value.count > self.limit {
                value = String(value.prefix(self.limit))
                self.hasReachedLimit = true
            } else {
                self.hasReachedLimit = false
            }
        }
    }
    
    @Published var hasReachedLimit = false
}
