//
//  ArgueTests.swift
//  ArgueTests
//
//  Created by Brandon Evans on 2014-08-19.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

import Cocoa
import XCTest
import Argue

class ArgueTests: XCTestCase {
    var argue: Argue?

    override func setUp() {
        let argument1 = Argument(fullName: "test1", shortName: "t1", description: "A string", isFlag: false)
        let argument2 = Argument(fullName: "test2", shortName: "t2", description: "A test flag", isFlag: true)

        let usage = "How to use this program..."
        argue = Argue(usage: usage, arguments:[argument1, argument2])
    }

    func testMatchesArgumentName() {
        let argument = Argument(fullName: "test", shortName: "t", description: "A test flag", isFlag: true)
        XCTAssert(argument.matchesArgumentName("") == false)
        XCTAssert(argument.matchesArgumentName("a") == false)
        XCTAssert(argument.matchesArgumentName("apple") == false)
        XCTAssert(argument.matchesArgumentName("-t") == true)
        XCTAssert(argument.matchesArgumentName("--test") == true)
    }

    func testParseArguments() {
        argue!.parseArguments(["--test1", "TEST", "--test2"])
        XCTAssert(countElements(argue!.parsedArguments) == 2, "Incorrect number of arguments parsed")
        XCTAssert(argue!.parsedArguments["test1"]? == "TEST", "Error parsing value")
        XCTAssert(argue!["test2"]? == nil, "Error accessing value with subscript")

        argue!.parseArguments([])
        XCTAssert(countElements(argue!.parsedArguments) == 0, "Incorrect number of arguments parsed")

        argue!.parseArguments(["--wrongName"])
        XCTAssert(argue!.error? != nil, "Failed to report error")
        XCTAssert(countElements(argue!.error!.localizedDescription) > 0, "Failed to provide localized error description")
    }

    func testHelpArgument() {
        argue!.parseArguments(["--help"])
        XCTAssert(countElements(argue!.parsedArguments) == 1, "Failed to parse help argument")
    }

    func testUsageString() {
        let lineBreaks = argue!.usageString().componentsSeparatedByString("\n").count - 1
        XCTAssertEqual(lineBreaks, 6, "Failed to print the correct number of lines for usage instructions")
    }
}
