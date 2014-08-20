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

public class Argue: NSObject {
    let usage: String
    let arguments: [Argument]
    let helpArgument = Argument(fullName: "help", shortName: "h", description: "Show usage instructions", isFlag: true)

    public var parsedArguments: [String: String?] = Dictionary()
    public var error: NSError? = nil
    public var exitOnHelp = true

    public init(usage: String, arguments: [Argument]) {
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
                if argument == helpArgument && exitOnHelp {
                    println(usageString())
                    exit(0)
                }

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

    public func parse() {
        // Ignore the application path
        var args = Process.arguments
        if countElements(args) > 0 {
            args.removeAtIndex(0)
        }
        parseArguments(args)
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
        return parsedArguments[index]?
    }
}