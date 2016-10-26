//
//  ShootTests.swift
//  ShootTests
//
//  Created by Joey Van Gundy on 4/19/16.
//  Copyright © 2016 Joe Van Gundy. All rights reserved.
//

import XCTest
@testable import Shoot

class ShootTests: XCTestCase {
    var NewPostVC: NewPostViewController!
    var MapVC: MapViewController!

    override func setUp() {
        super.setUp()
//        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
//        MapVC = storyboard.instantiateInitialViewController() as! MapViewController
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testGetCurrentDate(){
        let dateDecimal = NewPostVC.getCurrentDate()
        let date = NSDate(timeIntervalSince1970: dateDecimal)
        let unitFlags: NSCalendarUnit = [.Hour, .Day, .Month, .Year]
        let components = NSCalendar.currentCalendar().components(unitFlags, fromDate: date)
        XCTAssert(components.validDate)
        
    }
    
}
