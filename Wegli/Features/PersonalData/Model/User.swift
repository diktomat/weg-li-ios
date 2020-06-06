//
//  User.swift
//  Wegli
//
//  Created by Malte Bünz on 05.06.20.
//  Copyright © 2020 Stefan Trauth. All rights reserved.
//

import Foundation

struct User {
    struct Address {
        let street: String
        let zipCode: String
        let town: String
    }
    let firstName: String
    let name: String
    let address: Address
    let phone: String
}
