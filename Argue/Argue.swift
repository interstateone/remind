//
//  Argue.swift
//  Remind
//
//  Created by Brandon Evans on 2014-08-19.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

import Cocoa

extension String {
    subscript (r: Range<Int>) -> String {
        get {
            let startIndex = advance(self.startIndex, r.startIndex)
            let endIndex = advance(startIndex, r.endIndex - r.startIndex)

            return self[Range(start: startIndex, end: endIndex)]
        }
    }
}

public struct Argument {
    let fullName: String
    let shortName: String
    let description: String
    let isFlag: Bool

    public init(fullName: String, shortName: String, description: String, isFlag: Bool) {
        self.fullName = fullName
        self.shortName = shortName
        self.description = description
        self.isFlag = isFlag
    }

    public func matchesArgumentName(argumentName: String) -> Bool {
        if argumentName.hasPrefix("---") {
            return false
        }
        else if argumentName.hasPrefix("--") {
            return fullName == argumentName[2..<countElements(argumentName)]
        }
        else if argumentName.hasPrefix("-") {
            let start = argumentName.startIndex
            return shortName == argumentName[1..<countElements(argumentName)]
        }
        return false
    }

    public func usageString() -> String {
        return "--\(fullName)\t(-\(shortName))\t\(description)"
    }
}

extension Argument: Equatable {}

public func ==(lhs: Argument, rhs: Argument) -> Bool {
        return lhs.fullName == rhs.fullName
}

extension Argument: Hashable {
    public var hashValue: Int {
        get {
            return fullName.hashValue
        }
    }
}

public class Argue: NSObject {
    let usage: String
    let arguments: [Argument]
    public var parsedArguments: [String: String?] = Dictionary()
    public var error: NSError? = nil

    public init(usage: String, arguments: [Argument]) {
        let helpArgument = Argument(fullName: "help", shortName: "h", description: "Show usage instructions", isFlag: true)

        self.usage = usage
        var args = arguments
        args.append(helpArgument)
        self.arguments = args
        super.init()
    }

    public func usageString() -> String {
        var usageString = "\(usage)\n\n"
        usageString += "Arguments:\n"
        for argument in arguments {
            usageString += argument.usageString() + "\n"
        }
        return usageString
    }

    public func usageStringForArgumentName(argumentName: String) -> String? {
        return argumentForArgumentString(argumentName)?.usageString()
    }

    public func parseArguments(argumentStrings: [String]) {
        parsedArguments = Dictionary()

        var generator = argumentStrings.generate()
        while let argumentString = generator.next() {
            if let argument = argumentForArgumentString(argumentString) {
                if !argument.isFlag {
                    if let value = generator.next() {
                        parsedArguments[argument.fullName] = value
                    }
                    else {
                        parsedArguments[argument.fullName] = Optional(nil)
                    }
                }
                else {
                    parsedArguments[argument.fullName] = Optional(nil)
                }
            }
            else {
                parsedArguments = Dictionary()
                error = NSError(domain: "ca.brandonevans.Argue", code: 1, userInfo: [NSLocalizedDescriptionKey: "Error parsing argument \"\(argumentString)\""])
                return
            }
        }
        error = nil
    }

    private func argumentForArgumentString(argumentString: String) -> Argument? {
        for argument in arguments {
            if argument.matchesArgumentName(argumentString) {
                return argument
            }
        }
        return nil
    }
}

extension Argue {
   public subscript(index: String) -> String? {
        return parsedArguments[index]!
    }
}