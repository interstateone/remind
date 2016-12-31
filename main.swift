//
//  main.swift
//  Remind
//
//  Created by Brandon Evans on 2014-08-18.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
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
    if let calendarName = listArgument.value as? String, allArgument.value == nil {
        specifiedCalendar = calendar(named: calendarName, in: calendars)
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
    // Complete a reminder
    else if let indexString = completeArgument.value as? String, let userIndex = Int(indexString) {
        let reminderPredicate = store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: specifiedCalendars)
        store.fetchReminders(matching: reminderPredicate, completion: { reminders in
            let sortedReminders = reminders?.sorted { $0.calendar.title > $1.calendar.title } ?? []
            let index = userIndex - 1
            guard index >= 0, index < sortedReminders.count else {
                print("Index \(userIndex) doesn't correspond to a reminder in \(specifiedCalendars.map { $0.title }.joined(separator: ", "))")
                exit(1)
            }

            let reminder = sortedReminders[index]
            reminder.isCompleted = true

            do {
                try store.save(reminder, commit: true)
            }
            catch {
                print(error)
                exit(1)
            }

            print("Completed: \(reminder.title)")
            exit(0)
        })
    }
    // Delete a reminder
    else if let indexString = deleteArgument.value as? String, let userIndex = Int(indexString) {
        let reminderPredicate = store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: specifiedCalendars)
        store.fetchReminders(matching: reminderPredicate, completion: { reminders in
            let sortedReminders = reminders?.sorted { $0.calendar.title > $1.calendar.title } ?? []
            let index = userIndex - 1
            guard index >= 0, index < sortedReminders.count else {
                print("Index \(userIndex) doesn't correspond to a reminder in \(specifiedCalendars.map { $0.title }.joined(separator: ", "))")
                exit(1)
            }

            let reminder = sortedReminders[index]

            print("Are you sure you want to delete \(reminder.title)? (y/N)")
            guard readLine()?.contains("y") ?? false else {
                exit(0)
            }

            do {
                try store.remove(reminder, commit: true)
            }
            catch {
                print(error)
                exit(1)
            }

            print("Deleted: \(reminder.title)")
            exit(0)
        })
    }
    // Print reminders
    else {
        let reminderPredicate = store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: specifiedCalendars)
        store.fetchReminders(matching: reminderPredicate, completion: { reminders in
            let sortedReminders = reminders?.sorted { $0.calendar.title > $1.calendar.title } ?? []
            print(description(for: sortedReminders))
            exit(0)
        })
    }
})

RunLoop.current.run()
