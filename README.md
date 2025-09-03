# TempStickMonitor

SwiftUI app + Apple Watch app for monitoring TempStick sensors.  
This repository only contains the **source files** and assets — not the Xcode project itself.
---

## Contents
---

## Rebuilding the Project in Xcode

### 1. Create the iOS app project
1. Create a new project from a WatchOs template.
2. Leave "Watch App with New Companion iOS App" selected (default option)
3. Fill in Product Name, Organization Identifier
4. Leave "Testing System" to "None"

### 2. Add the iOS sources
1. In Finder, open this repo.
2. Delete the pre-existing folders in Xcode (they will be named [your product name] and [your product name] Watch App)
3. In finder, copy the folder "TempStickMonitor" from the project into Xcode, and when prompted check the box for the target with [your product name]. Leave other options default.
4. In finder, copy the folder "TempStickMonitor Watch App" into Xcode, and when prompted check the box for the target with [your product name Watch App]. Leave other options default.

> **Important Note:
> When copying the folders, make sure to copy to the top level directory in the project structure
> (e.g. do not copy the Watch App folder into the folder with the TempStickMonitor iOS app files copied in step 3 under this section)


### 3. Build and Run (in simulator)
1. If you don't have a simulator paired with a simulated iOS device, create one in Product - Destination - Manage Run Destinations (Create a new iOS simulator and select "Paired With Apple Watch" and go through the dialogs)
2. Select the target named "[your product name] Watch App" from the menu on the top of the main window in Xcode, and under iOS simulators select the device "Apple Watch Series...via [your simulator name]"
3. Click Run (the main arrow in the side panel in Xcode).

### 4. Enter API key on iOS, sync settings to Watch App
1. With the app built and installed in both the watch and iOS simulators, open the app in the iOS simulator
2. Click on "Settings" and enter your TempStick API key (found in the company's TempStick App under the "Developers" tab)
3. Click "Save Settings"