# [Ky Coding Test 2026-04 for SRAM](https://github.com/KyNorthstar/Coding-Test-2026-04-SRAM)

A coding test I performed on 2026-04 for SRAM.



## Building & running

First, clone this entire repository to your local machine.


### Prerequisites

This is a standard Xcode project. To build it, you only need the following installed with standard configurations:
- Xcode 26.4 or compatible
- iOS 26 SDK

This is also a Strava project. The secret and client ID aren't stored in this public repo, so you'll need to provide your own or ask Ky for theirs. Once you have those:
- Copy the file `Config.xcconfig TEMPLATE.txt` and rename the new copy to `Config.xcconfig`
- Open the config in a text editor
- Replace `YOUR_CLIENT_ID_HERE` with a valid Strava Client ID
- Replace `YOUR_CLIENT_SECRET_HERE` with a valid Strava Client Secret

That new config file will be ignored by Git. Ensure that remains so, and that those values remain secret to your local machine andor trusted parties.


### Build & run

After that, the steps to build are standard:
- Open the Xcode project in this folder
- There's only one scheme, so just make sure you've selected a device (or simulator) you can run it on
- You may need to edit the project file to set your Apple Developer account as the current team in the Signing & Capabilities section of the only target
- Ensure you're online and Xcode can reach GitHub for package resolution
- Reset package caches
- Build & run (press the play button at the top of the Xcode window, or ⌘R, or select Product › Run)



## Features

The concept behind this app is that it displays your Strava activity like a GitHub activity chart.

Here's a **mockup**:

![A screenshot of an iPhone app showing a dot matrix 7-wide, like a vertical version of GitHub's activity chart with different colors.](./Cadence%20main%20screen%20mockup.png)



## If I had more time

In a production app, I would do the following differently:
- The client secret wouldn't be in the binary at all, instead stored in a backend proxy and fetched using a public key at runtime
