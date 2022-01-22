//
//  PostLikeTests.swift
//  PostLikeTests
//
//  Created by taichi on 2022/01/22.
//  Copyright © 2022 taichi. All rights reserved.
//

import XCTest
@testable import PostLike_Dev

class PostLikeTests: XCTestCase {

    override func setUpWithError() throws {
        
    }

    override func tearDownWithError() throws {
        
    }
    
    func diff(timeInterval: TimeInterval) -> String {
        let now = Date()
        let date = Date(timeInterval: timeInterval, since: now)
        let text = UILabel().dateString(dateValue: date)
        return text
    }
    
    func testASecondAgo() throws {
        XCTAssertEqual(diff(timeInterval: -1), "1秒前")
    }
    
    func testAMinuteAgo() {
        XCTAssertEqual(diff(timeInterval: -60), "1分前")
    }
    
    func testAnHourAgo() {
        XCTAssertEqual(diff(timeInterval: -60*60), "1時間前")
    }
    
    func testADayAgo() {
        XCTAssertEqual(diff(timeInterval: -60*60*24), "1日前")
    }
    
    func testAMonthAgo() {
        XCTAssertEqual(diff(timeInterval: -60*60*24*31), "1ヶ月前")
    }
    
    func testAYearAgo() {
        XCTAssertEqual(diff(timeInterval: -60*60*24*365), "1年前")
    }
    
}
