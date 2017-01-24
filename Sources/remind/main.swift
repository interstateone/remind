//
//  main.swift
//  Remind
//
//  Created by Brandon Evans on 2014-08-18.
//  Copyright (c) 2017 Brandon Evans. All rights reserved.
//

import Foundation
import Argue
import EventKit

let listArgument = Argument(type: .value, fullName: "list", shortName: "l", description: "Prints only the reminders in the given list or creates a new reminder there")
let allArgument = Argument(type: .flag, fullName: "all", shortName: "a", description: "Prints the reminders in all of the lists")
let completeArgument = Argument(type: .value, fullName: "complete", shortName: "c", description: "Completes a reminder at the given index")
let deleteArgument = Argument(type: .value, fullName: "delete", shortName: "d", description: "Deletes a reminder at the given index")
let newArgument = Argument(type: .value, fullName: "new", shortName: "n", description: "Creates a new reminder")
let usage = "A little app to quickly deal with reminders."
let argue = Argue(usage: usage, arguments: [newArgument, allArgument, completeArgument, deleteArgument, listArgument])

do {
    try argue.parseArguments(Array(CommandLine.arguments.dropFirst()))
}
catch {
    print("Error parsing arguments: \(error.localizedDescription)")
    exit(1)
}

if argue.helpArgument.value != nil {
    print(argue.description)
    exit(0)
}

let store = EKEventStore()

store.withAccessToReminders {
    let calendars = store.calendars(for: .reminder)
    guard let firstCalendar = calendars.first else {
        print("Error: didn't find at least one reminder list.")
        exit(1)
    }

    let specifiedCalendar: EKCalendar?
    if let calendarName = listArgument.value as? String, allArgument.value == nil {
        specifiedCalendar = calendars.filter { $0.title == calendarName }.first
    }
    else {
        specifiedCalendar = nil
    }

    let specifiedCalendars: [EKCalendar]
    if let specifiedCalendar = specifiedCalendar {
        specifiedCalendars = [specifiedCalendar]
    }
    else {
        specifiedCalendars = calendars
    }

    if let title = newArgument.value as? String {
        store.createReminder(named: title, in: specifiedCalendar ?? firstCalendar)
    }
    else if let indexString = completeArgument.value as? String, let userIndex = Int(indexString) {
        store.completeReminder(at: userIndex, in: specifiedCalendars)
    }
    else if let indexString = deleteArgument.value as? String, let userIndex = Int(indexString) {
        store.deleteReminder(at: userIndex, in: specifiedCalendars)
    }
    else {
        store.printReminders(in: specifiedCalendars)
    }
}

RunLoop.current.run()

