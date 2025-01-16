# CHANGELOG

## vNext (2024-01-20)

This is the initial release of the project.

It contains the following features for win-x64 dev enlistment:
- Initial setup for `zilch.devenv`:
  - [ ] `zilch.devenv` entry to download and install it without github clone
  - [x] Pre-installation of of `scoop` & `wsl2` as one-time setup
  - [x] Create shortcut in Desktop and run in admin mode
- Launch `zilch.devenv` with refreshing dev environment: 
  - Fundamentals
    - [x] Log files for 'launch.sh' running in `zilch.devenv`
    - [x] Support ANSI color and utf-8 encoding by default
    - [x] Allow `launch.conf` for customizing the launch behavior.
  - Welcome Screen
    - [x] Say hi with machine name, user name and bash version
    - [x] ASCII art
    - [x] Prompt of the day (with locale support)
    - [x] Countdown
  - Scoop Apps
    - [x] Add customized buckets if need
    - [x] List required scoop apps and install
    - [x] Update scoop apps if need
  - Entry
    - [x] Set up working directory to project home
    - [x] Launch terminal console or vscode as starter
  - VSCode
    - [x] Set default vscode forks with binpath
    - [x] List and install required vscode extensions
    - [x] Update vscode extensions from Visual Studio Marketplace if need
  - Git
    - [ ] Setup `git` with customized configuration.
  - Cmder
    - [ ] Setup `cmder` with better defaults.
- Workloads configuration in `zilch.devenv`:
  - [ ] `markdown`: Markdown authoring and publish as github pages.
  - [ ] `rust`: Rust toolchain and development.
  - [ ] `python`: Python toolchain and development.
  - [ ] `typescript`: Typescript/Javascript toolchain and development under `nodejs`.
  - [ ] `go`: Go toolchain and development.
  - [ ] `dotnet`: .NET Core SDK and C# development.
  - [ ] `java`: Java toolchain and development.
  - [ ] `c`: ANSI C toolchain and development.
  - [ ] `cpp`: C++ toolchain and development.

And more infrastructure improvement and shared components are listed below:
- [x] Reentry protection for bash script.
- [x] Logging friendly: trace, warn/error & usage.
- [ ] CI/Gated pipeline for initial setup and launch.
