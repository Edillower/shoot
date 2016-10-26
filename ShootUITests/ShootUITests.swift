//
//  ShootUITests.swift
//  ShootUITests
//
//  Created by Joey Van Gundy on 4/19/16.
//  Copyright © 2016 Joe Van Gundy. All rights reserved.
//

import XCTest

class ShootUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testClickSearch(){
        XCUIApplication().buttons["Search"].tap()
        
    }
    
    func testSearch(){
        
        let app = XCUIApplication()
        app.buttons["Search"].tap()
        app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element(boundBy: 2).children(matching: .other).element.children(matching: .searchField).element.tap()
        app.searchFields.containing(.button, identifier:"Clear text").element
        app.buttons["Search"].tap()
        app.searchFields.containing(.button, identifier:"Clear text").element
    }
    
    
    func testSearchClose(){
        
        let app = XCUIApplication()
        app.buttons["Search"].tap()
        app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element(boundBy: 2).children(matching: .other).element.children(matching: .searchField).element.tap()
        app.searchFields.containing(.button, identifier:"Clear text").element
        app.buttons["Cancel"].tap()
        
    }
    
    func testBruteForceSearch(){
        
        let app = XCUIApplication()
        let searchButton = app.buttons["Search"]
        searchButton.tap()
        
        let cancelButton = app.buttons["Cancel"]
        cancelButton.tap()
        searchButton.tap()
        cancelButton.tap()
        searchButton.tap()
        cancelButton.tap()
        searchButton.tap()
        cancelButton.tap()
        searchButton.tap()
        cancelButton.tap()
        searchButton.tap()
        cancelButton.tap()
        searchButton.tap()
        cancelButton.tap()
        searchButton.tap()
        cancelButton.tap()
        searchButton.tap()
        cancelButton.tap()
        searchButton.tap()
        cancelButton.tap()
        
    }
    
    func testScanAcrossView(){
        
        let element = XCUIApplication().children(matching: .window).element(boundBy: 0).children(matching: .other).element
        element.tap()
        element.tap()
        element.tap()
        element.tap()
        element.tap()
        element.tap()
        element.children(matching: .other).element(boundBy: 2).tap()
        element.tap()
        
    }
    
    func testButtonValidations(){
        
        let app = XCUIApplication()
        let element = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element
        element.tap()
        element.tap()
        element.tap()
        element.tap()
        element.tap()
        
        let tablesQuery = app.tables
        tablesQuery.staticTexts["it may be done"].tap()
        app.buttons["Go Back"].tap()
        tablesQuery.navigationBars["The Ohio State University"].buttons["Done"].tap()
        
        
    }
    
    func testSearchForAValidPlace(){
        
        
        
        let app = XCUIApplication()
        app.buttons["Search"].tap()
        app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element(boundBy: 2).children(matching: .other).element.children(matching: .searchField).element.tap()
        app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element(boundBy: 2).children(matching: .other).element.children(matching: .searchField).element.typeText("White House")

        app.searchFields.containing(.button, identifier:"Clear text").element
        app.buttons["Search"].tap()
        app.searchFields.containing(.button, identifier:"Clear text").element
        app.buttons["Cancel"].tap()
        
        
        
    }
    
    func testSearchForAnInvalidPlace(){
        
        
        let app = XCUIApplication()
        app.buttons["Search"].tap()
        app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element(boundBy: 2).children(matching: .other).element.children(matching: .searchField).element.tap()
        app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element(boundBy: 2).children(matching: .other).element.children(matching: .searchField).element.typeText("jdkadhakjdhajsdhajdhasjkdhaskdja")

        app.searchFields.containing(.button, identifier:"Clear text").element
        app.buttons["Search"].tap()
        app.searchFields.containing(.button, identifier:"Clear text").element
        app.alerts.collectionViews.buttons["Dismiss"].tap()
        app.buttons["Cancel"].tap()
    }
    
    func testClickOnMarker(){
        
        let element = XCUIApplication().children(matching: .window).element(boundBy: 0).children(matching: .other).element
        element.tap()
        element.tap()
        element.tap()
        element.tap()
        element.tap()
        
    }
}
