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

let listArgument = Argument(fullName: "list", shortName: "l", description: "Prints only the reminders in this list", isFlag: false)
let usage = "A little app to quickly deal with reminders."
let argue = Argue(usage: usage, arguments: [listArgument])
argue.parse()

let store = EKEventStore()

func filteredCalendars(requestedCalendar: String?) -> [EKCalendar] {
    var calendars = store.calendarsForEntityType(EKEntityTypeReminder) as [EKCalendar]
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
        let calendars = filteredCalendars(argue["list"])

        let reminderPredicate = store.predicateForIncompleteRemindersWithDueDateStarting(nil, ending: nil, calendars: calendars)
        store.fetchRemindersMatchingPredicate(reminderPredicate, completion: { r in
            var reminders = r as [EKReminder]
            reminders.sort({ (reminder1, reminder2) -> Bool in
                return reminder1.calendar.title > reminder2.calendar.title
            })
            printReminders(reminders)
        })
    }
    else {
        println("Error fetching reminders: \(error.localizedDescription)")
    }
})

NSRunLoop.currentRunLoop().run()