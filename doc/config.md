# Configuration Files

The .cfg file contains a configuration list for various items based on the use case.

Basically, each line is a listed item but it may contains ignored lines or comments.

## Comments

The syntax of comments are: `# <comment>`.
- Comment line: The comment line is started with the `#` character. The entire line is ignored.
- Inline comments: All characters after the `#` character in a line are ignored.
- Any empty lines or extra spaces are ignored like comments as well.

## Listed Items

There are various items in `zilch.devenv` configuration files. All items should share same type of format within one single file.

### Scoop App

The format of each `scoop app` line is `[<bucket>/]<app>[<suffix>]`:
- `<bucket>`: an optional scoop bucket where the scoop app is located, followed by a '/' character
- `<app>`: scoop app name to be installed
- `<suffix>`: an optional suffix to identify the check-for-update policy as follows:
  - `<no suffix>` (default): install the latest version and check for updates in future
  - `@<version>`: install the specific version and skip future updates
  - `!`: install the latest version but skip future updates

### VSCode Extension

The format of each `vscode extension` line is `<publisher>.<extension>[<suffix>]`:
- `<publisher>`: The publisher of the extension.
- `<extension>`: The name of the extension.
- `<suffix>`: an optional suffix to identify the check-for-update policy as follows:
  - `<no suffix>` (default): install the latest version and check for updates in future
  - `@<version>`: install the specific version and skip future updates
  - `!`: install the latest version but skip future updates

> **NOTE**:
> - Suggest to add suffix "!" to forbid auto-updating of international language packs.
> - Preview version of extension installation is not supported due to limitation of VSCode CLI.

### 


