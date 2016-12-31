//
//  main.swift
//  Remind
//
//  Created by Brandon Evans on 2014-08-18.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

import Foundation
import EventKit

let listArgument = Argument(type: .value, fullName: "list", shortName: "l", description: "Prints only the reminders in the given list or creates a new reminder there")
let newArgument = Argument(type: .value, fullName: "new", shortName: "n", description: "Creates a new reminder")
let usage = "A little app to quickly deal with reminders."
let argue = Argue(usage: usage, arguments: [newArgument, listArgument])

do {
    try argue.parse()
}
catch {
    print("Error parsing arguments: \(error.localizedDescription)")
    exit(1)
}

if argue.helpArgument.value != nil {
    print(argue.description)
    exit(0)
}

func calendar(named requestedCalendarName: String, in calendars: [EKCalendar]) -> EKCalendar? {
    return calendars.filter { $0.title == requestedCalendarName }.first
}

let ShortDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    formatter.doesRelativeDateFormatting = true
    return formatter
}()

func description(for reminders: [EKReminder]) -> String {
    return reminders.enumerated().reduce("") { result, reminder in
        var description = "#\(reminder.offset + 1)\t\(reminder.element.calendar.title): \(reminder.element.title)"

        if let components = reminder.element.dueDateComponents, let date = Calendar.current.date(from: components) {
            description += " (due \(ShortDateFormatter.string(from: date)))"
        }

        return result + description + "\n"
    }
}

let store = EKEventStore()

store.requestAccess(to: .reminder, completion: { (granted, error) -> Void in
    guard granted, error == nil else {
        if let error = error {
            print("Error fetching reminders: \(error.localizedDescription).")
        }
        else if !granted {
            print("remind doesn't have permission to access your reminders.")
        }
        exit(1)
    }

    let calendars = store.calendars(for: .reminder)
    guard let firstCalendar = calendars.first else {
        print("Error: didn't find at least one reminder list.")
        exit(1)
    }

    let specifiedCalendar: EKCalendar?
    if let calendarName = listArgument.value as? String {
        specifiedCalendar = calendar(named: calendarName, in: calendars)
    }
    else {
        specifiedCalendar = nil
    }

    // Create new reminder
    if let title = newArgument.value as? String {
        let reminder = EKReminder(eventStore: store)
        reminder.title = title
        reminder.calendar = specifiedCalendar ?? firstCalendar

        do {
            try store.save(reminder, commit: true)
        }
        catch {
            print(error)
            exit(1)
        }

        exit(0)
    }
    // Print reminders
    else {
        let specifiedCalendars: [EKCalendar]
        if let specifiedCalendar = specifiedCalendar {
            specifiedCalendars = [specifiedCalendar]
        }
        else {
            specifiedCalendars = calendars
        }
        let reminderPredicate = store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: specifiedCalendars)
        store.fetchReminders(matching: reminderPredicate, completion: { reminders in
            let sortedReminders = reminders?.sorted { $0.calendar.title > $1.calendar.title } ?? []
            print(description(for: sortedReminders))
            exit(0)
        })
    }
})

RunLoop.current.run()
