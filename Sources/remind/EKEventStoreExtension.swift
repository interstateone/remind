//
//  EKEventStoreExtension.swift
//  Remind
//
//  Created by Brandon Evans on 2017-01-23.
//  Copyright (c) 2017 Brandon Evans. All rights reserved.
//

import EventKit

extension EKEventStore {
    func withAccessToReminders(task: @escaping () -> Void) {
        requestAccess(to: .reminder) { (granted, error) -> Void in
            guard granted, error == nil else {
                if let error = error {
                    print("Error fetching reminders: \(error.localizedDescription).")
                }
                else if !granted {
                    print("remind doesn't have permission to access your reminders.")
                }
                exit(1)
            }

            task()
        }
    }

    func createReminder(named title: String, in calendar: EKCalendar) {
        let reminder = EKReminder(eventStore: self)
        reminder.title = title
        reminder.calendar = calendar

        do {
            try save(reminder, commit: true)
        }
        catch {
            print(error)
            exit(1)
        }
    }

    func completeReminder(at userIndex: Int, in calendars: [EKCalendar]) {
        let reminderPredicate = predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: calendars)
        fetchReminders(matching: reminderPredicate, completion: { [weak self] reminders in
            let sortedReminders = reminders?.sorted { $0.calendar.title > $1.calendar.title } ?? []
            let index = userIndex - 1
            guard index >= 0, index < sortedReminders.count else {
                print("Index \(userIndex) doesn't correspond to a reminder in \(calendars.map { $0.title }.joined(separator: ", "))")
                exit(1)
            }

            let reminder = sortedReminders[index]
            reminder.isCompleted = true

            do {
                try self?.save(reminder, commit: true)
            }
            catch {
                print(error)
                exit(1)
            }

            print("Completed: \(reminder.title)")
        })
    }

    func deleteReminder(at userIndex: Int, in calendars: [EKCalendar]) {
        let reminderPredicate = predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: calendars)
        fetchReminders(matching: reminderPredicate, completion: { [weak self] reminders in
            let sortedReminders = reminders?.sorted { $0.calendar.title > $1.calendar.title } ?? []
            let index = userIndex - 1
            guard index >= 0, index < sortedReminders.count else {
                print("Index \(userIndex) doesn't correspond to a reminder in \(calendars.map { $0.title }.joined(separator: ", "))")
                exit(1)
            }

            let reminder = sortedReminders[index]

            print("Are you sure you want to delete \(reminder.title)? (y/N)")
            guard readLine()?.contains("y") ?? false else {
                exit(0)
            }

            do {
                try self?.remove(reminder, commit: true)
            }
            catch {
                print(error)
                exit(1)
            }

            print("Deleted: \(reminder.title)")
            exit(0)
        })
    }

    func printReminders(in calendars: [EKCalendar]) {
        let reminderPredicate = predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: calendars)
        fetchReminders(matching: reminderPredicate, completion: { reminders in
            let sortedReminders = reminders?.sorted { $0.calendar.title > $1.calendar.title } ?? []
            print(listOutput(for: sortedReminders))
            exit(0)
        })
    }
}

func listOutput(for reminders: [EKReminder]) -> String {
    return reminders.enumerated().reduce("") { result, reminder in
        var description = "#\(reminder.offset + 1)\t\(reminder.element.calendar.title): \(reminder.element.title)"

        if let components = reminder.element.dueDateComponents, let date = Calendar.current.date(from: components) {
            // ANSI color codes
            // \u{001B}[\(style);\(color)m
            let normalCode = "0"
            let boldCode = "1"
            let redCode = "31"
            let whiteCode = "37"
            let styleCode = Calendar.current.isDateInToday(date) || Date().compare(date) == .orderedDescending ? boldCode : normalCode
            description += " \u{001B}[\(styleCode);\(redCode)m(due \(ShortDateFormatter.string(from: date)))\u{001B}[\(normalCode);\(whiteCode)m"
        }

        return result + description + "\n"
    }
}

let ShortDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    formatter.doesRelativeDateFormatting = true
    return formatter
}()

