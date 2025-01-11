# CHANGELOG

## vNext (2024-01-20)

This is the initial release of the project.

It contains the following features for win-x64 dev enlistment:
- Initial setup for `zilch.devenv`:
  - [ ] `zilch.devenv` entry to download and install it without github clone.
  - [x] Pre-installation of of `scoop` & `wsl2` as one-time setup.
  - [x] Create shortcut in Desktop and run in admin mode.
- Launch `zilch.devenv` with refreshing dev environment: 
  - [x] Log files for 'launch.sh' running in `zilch.devenv`.
  - [x] Support ANSI color and utf-8 encoding by default.
  - [x] Welcome screen with locale selection, ASCII art and prompt of the day.
  - [x] Scoop installation with customized buckets and apps (basic).
  - [x] Entry for home directory with launching of `cmder` or `vscode` as starter.
  - [ ] Setup `git` with customized configuration.
  - [ ] Setup `vscode` with cusomized extensions.
  - [ ] Setup `cmder` with better defaults.
  - [ ] Allow `launch.conf` for customizing the launch behavior.
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
- [x] Trace output for bash functions.
- [ ] CI/Gated pipeline for initial setup and launch.
