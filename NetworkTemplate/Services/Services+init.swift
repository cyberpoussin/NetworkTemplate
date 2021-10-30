//
//  Services+init.swift
//  Services+init
//
//  Created by Admin on 01/09/2021.
//

import Foundation

public struct Services {
    public init(networkService: NetworkService, keyValueService: KeyValueService) {
        self.networkService = networkService
        self.keyValueService = keyValueService
    }
    
    let networkService: NetworkService
    let keyValueService: KeyValueService
}

extension Services {
    public init() {
        self.init(
            networkService: APISession(),
            keyValueService: UserDefaults.standard)
    }
}

public protocol KeyValueService: AnyObject {
    subscript<C: Codable>(key key: String, type type: C.Type) -> C? { get set }
}
