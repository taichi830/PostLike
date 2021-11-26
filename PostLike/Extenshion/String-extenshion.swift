//
//  String-Extenshion.swift
//  PostLike
//
//  Created by taichi on 2021/11/25.
//  Copyright © 2021 taichi. All rights reserved.
//

import Foundation

extension String {
    var urlsFromRegexs: [String] {
        let pattern = "(http://|https://){1}[0-9a-zA-Z\\.\\-/:!#$%&@=?_]+"
        let regex = try! NSRegularExpression(pattern:pattern, options:[])
        guard let range = self.range(of:self) else { return [] }
        return regex.matches(in:self, range:NSRange(range, in: self)).map { String(self[Range($0.range, in:self)!]) }
    }
}
