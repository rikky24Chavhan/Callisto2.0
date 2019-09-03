# Eli Lilly - Meal Tracking Pilot

[![Build Status](https://ci.intrepid.io/buildStatus/icon?job=meal-tracking-pilot-ios)](https://ci.intrepid.io/job/meal-tracking-pilot-ios/)
[![Coverage](http://ci.intrepid.io:9913/jenkins/cobertura/meal-tracking-pilot-ios/)](https://ci.intrepid.io/job/meal-tracking-pilot-ios/cobertura/)

This app will be used by a group of diabetes patients in a research study aiming to gain insight into the relationships between food intake, insulin dosing and the resulting blood glucose levels.
___
# Table of Contents

1. [Building](#building)
	1. [Onboarding](#onboarding)
	2. [Running](#running)
2. [Testing](#testing)
3. [Release](#release)
	1. [Quirks](#quirks)
	2. [Known Bugs](#known-bugs)
4. [Architecture](#architecture)
	1. [Data Flow](#data-flow)
	2. [Synchronization](#synchronization)
	3. [Error Handling](#error-handling)
	4. [Third Party Libraries](#third-party-libraries)
5. [History](#history)

___

# Building
## Onboarding
Install dependencies using `pod install` and open the `xcworkspace` project.
This project doesn't require any other special configuration to run.

## Running
Run the app in either the simulator or on a device.
___

# Testing
Run unit tests.
The project also has a UI test target that has been disabled in the MealTrackingPilot scheme.

# Release
Releases are not currently formalized. The client has access to the primary OTA web page, and will download end-of-sprint builds from there.

## Quirks
None to mention... yet.

## Known Bugs
No bugs. **QA Rules**
___

# Architecture
## Data Flow
The data model in the app consists primarily of `Meal`s and `MealEvent`s. `Meal` represents the definition of a meal, while `MealEvent`s are instances of when the user ate that particular meal.

Realm is used for local persistent storage, and represents the single source of truth from which state is determined. The local data store is made accessible to the view controller and view model layers through a data controller object. All meal/food-related data is handled by the `RealmMealDataController`, which exposes various observable fields after fetching, filtering and sorting appropriately.

## Synchronization
In order to provide a functional offline mode, and to improve error handling from the user's perspective, data is primarily read from and written to the local store, then synchronized with the server when available. Whenever a write call to the server fails for a reason other than invalid data (i.e. HTTP 422 status code), the object's `isDirty` property is set, marking it as something that must be synced with the server at a later date.

The `OfflineMealSyncController` class defines the logic for attempting to synchronize dirty `MealEvent` objects that have been created/updated in the local data store. The sync logic is executed when the application launches. `Meal` objects can also be created and subsequently logged offline, as `RealmMealDataController` will make the successful synchronization of the `Meal` a prerequisite of the `MealEvent`.

## Error Handling
Network errors are handled as follows for the various API calls in the app:
#### Dashboard - Get Logged Meal Events
Display an alert that meal events may be missing from the meal journal. Populate the table view with `MealEvent` objects fetched from the Realm.
#### Log Meal Event - Get Common/Test Meals
`Meal` objects are fetched from Realm, API call errors are not surfaced to the user.
#### Log Meal Event - Create/Update Meal Event
For most error responses, the created/updated `MealEvent` is saved locally and no error is surfaced to the user. The only exception is HTTP 422 errors, a result of the application sending invalid data to the server, which are handled by displaying an alert to the user.
#### Create Meal
Similar to Log Meal Event: for most error responses, the created/updated `Meal` is saved locally and no error is surfaced to the user. For specific errors that preclude us from saving locally and syncing later (i.e. meal already exists) an appropriate message will be displayed to the user in an alert dialog.
#### Report Meal Event
No offline support for reporting meal events, user will see an alert immediately.

## Third Party Libraries
[Intrepid](https://github.com/IntrepidPursuits/swift-wisdom)

[Intrepid APIClient](https://github.com/IntrepidPursuits/prefab-api-client)

[RxSwift](https://github.com/ReactiveX/RxSwift)

[Genome](https://github.com/LoganWright/Genome)

[RealmSwift](https://github.com/realm/realm-cocoa)

Google Sign-In
___

# History
App is currently in development.

# Swift 4 Transition Checklist
Is the project going to remain active or under maintenance contract beyond launch of Swift 4 (Sept/Oct 2017)  - [x] Yes  - [ ] No

 - [x] Swift 4 transition story in the backlog
 - [ ] Podfile being inventoried by Jenkins
 - [ ] Manual Pod audit to identify unmaintained/Intrepid maintained Pods
 - [ ] Stories for removing unmaintained/Intrepid Pods, if needed (Not including Swift Wisdom)
 - [ ] Stories for updating unmaintained/Intrepid Pods, if needed (Not including Swift Wisdom)
