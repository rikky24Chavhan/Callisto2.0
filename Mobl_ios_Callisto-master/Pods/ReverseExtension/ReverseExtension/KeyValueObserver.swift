//
//  KeyValueObserver.swift
//  Pods
//
//  Created by marty-suzuki on 2017/04/03.
//
//

import Foundation

final class KeyValueObserver: NSObject {
    private weak var target: NSObject?
    private let keyPath: String
    
    var didChange: ((Any?, [NSKeyValueChangeKey : Any]?) -> ())?
    
    init(target: NSObject, forKeyPath keyPath: String) {
        self.keyPath = keyPath
        self.target = target
        super.init()
        target.addObserver(self, forKeyPath: keyPath, options: [.new, .old], context: nil)
    }
    
    deinit {
        try? ExceptionHandler.catchException {
            target?.removeObserver(self, forKeyPath: keyPath)
        }
        didChange = nil
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let didChange = didChange else { return }
        switch keyPath {
        case (self.keyPath)?:
            DispatchQueue.global().async {
                didChange(object, change)
            }
        default:
            break
        }
    }
}
