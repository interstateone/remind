//
//  main.swift
//  Remind
//
//  Created by Brandon Evans on 2014-08-18.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

import Foundation
import EventKit

let defaults = NSUserDefaults.standardUserDefaults()
let list = defaults.stringForKey("list")
let reminder = defaults.stringForKey("reminder")
let completeReminder = defaults.integerForKey("complete")

let store = EKEventStore()

store.requestAccessToEntityType(EKEntityTypeReminder, completion: { (granted, error) -> Void in
    if granted && error == nil {
        // Filter calendars if necessary
        var calendars = store.calendarsForEntityType(EKEntityTypeReminder) as [EKCalendar]
        if list != nil {
            calendars = calendars.filter({ (calendar) -> Bool in
                return calendar.title == list!
            })
        }

        let predicate = store.predicateForIncompleteRemindersWithDueDateStarting(nil, ending: nil, calendars: calendars)
        store.fetchRemindersMatchingPredicate(predicate, completion: { r in
            var reminders = r as [EKReminder]
            reminders.sort({ (reminder1, reminder2) -> Bool in
                return reminder1.calendar.title > reminder2.calendar.title
            })
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
        })
    }
    else {
        println("Error fetching reminders: \(error.localizedDescription)")
    }
})

NSRunLoop.currentRunLoop().run()