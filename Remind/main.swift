//
//  main.swift
//  Remind
//
//  Created by Brandon Evans on 2014-08-18.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

import Foundation
import EventKit
import Argue

let listArgument = Argument(fullName: "list", shortName: "l", description: "Prints only the reminders in the given list or creates a new reminder there", isFlag: false)
let newArgument = Argument(fullName: "new", shortName: "n", description: "Creates a new reminder", isFlag: false)
let usage = "A little app to quickly deal with reminders."
let argue = Argue(usage: usage, arguments: [newArgument, listArgument])
let error = argue.parse()
if error != nil {
    println("Error parsing arguments: \(error?.localizedDescription)")
    exit(1)
}

if argue.helpArgument.value != nil {
    exit(0)
}

let store = EKEventStore()

func calendarNamed(requestedCalendar: String?) -> [EKCalendar] {
    var calendars = store.calendarsForEntityType(EKEntityTypeReminder) as [EKCalendar]
    if requestedCalendar? == nil {
        return calendars
    }
    calendars = calendars.filter({ (calendar) -> Bool in
        return calendar.title == requestedCalendar
    })
    return calendars
}

func printReminders(reminders: [EKReminder]) {
    for (index, reminder) in enumerate(reminders) {
        print("#\(index + 1)\t\(reminder.calendar.title): \(reminder.title)")
        if let components = reminder.dueDateComponents {
            let date = NSCalendar.currentCalendar().dateFromComponents(components)
            let formatter = NSDateFormatter()
            formatter.dateStyle = .ShortStyle
            formatter.timeStyle = .ShortStyle
            formatter.doesRelativeDateFormatting = true
            if date != nil {
                print(" (due \(formatter.stringFromDate(date!)))")
            }
        }
        print("\n")
    }
}

store.requestAccessToEntityType(EKEntityTypeReminder, completion: { (granted, error) -> Void in
    if granted && error == nil {
        let calendars = calendarNamed(listArgument.value as? String)

        // Create new reminder
        if let title = newArgument.value as? String {
            let reminder = EKReminder(eventStore: store)
            reminder.title = title
            reminder.calendar = calendars.first
            store.saveReminder(reminder, commit: true, error: nil)
            exit(0)
        }
        // Print reminders
        else {
            let reminderPredicate = store.predicateForIncompleteRemindersWithDueDateStarting(nil, ending: nil, calendars: calendars)
            store.fetchRemindersMatchingPredicate(reminderPredicate, completion: { r in
                var reminders = r as [EKReminder]
                reminders.sort({ (reminder1, reminder2) -> Bool in
                    return reminder1.calendar.title > reminder2.calendar.title
                })
                printReminders(reminders)
                exit(0)
            })
        }
    }
    else {
        println("Error fetching reminders: \(error.localizedDescription)")
        exit(1)
    }
})

NSRunLoop.currentRunLoop().run()