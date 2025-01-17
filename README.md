# zilch.devenv

`zilch.devenv` is a simple yet powerful tool designed to help developers quickly set up and manage their development environments. By leveraging easy-to-follow configuration and automation, `zilch.devenv` ensures a smooth and efficient start for any project, saving you time and effort.

Ideally, enrolling a development environment should be done with a single command. Please refer to the detailed instructions for various operating systems below:

- [Windows (win-x64)](src/win-x64/README.md)
    - Setup WSL2, scoop, git, cmder and vscode
    - Support markdown, rust, c#, typescript and python
    - Embrace LLM-driven development
- [Linux (linux-x64)](src/linux-x64/README.md) – under construction
- [macOS (osx-arm64)](src/osx-arm64/README.md) – under construction

## About the Project

This is an experimental project exploring collaboration between AI and human developers.
- All code is written and reviewed by large language models (LLMs), with human developers providing feedback, insights, and prompts. This is not running in "Copilot mode," as human developers act as supervisors rather than directly writing code. They are responsible for reviewing, testing, and providing feedback.
- The project is not currently operated by automated LLM-driven development agents. However, the insights gained from building this project will help us understand how LLMs and developers can collaborate in future agentic world, as well as the potential and limitations of such collaboration.
- Among all available open-source, free-to-use, or affordable commercial LLMs, Deepseek v3 has shown the best performance in AI-assisted coding for this project. Remarkably, it outperforms some high-cost models, including ChatGPT (4o/4o-mini) models, in certain complex scenarios.
