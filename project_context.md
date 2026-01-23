# Project Architecture & Guidelines

## Overview
This project is a high-frequency trading platform component. Performance and thread safety are paramount.

## Coding Standards
- **Language:** C# / .NET 8 or PowerShell for automation.
- **Async/Await:** Must be used for all I/O bound operations. Avoid `.Result` or `.Wait()`.
- **Logging:** Use structured logging (Serilog). Do not use `Console.WriteLine`.
- **Error Handling:** Catch specific exceptions, not generic `Exception`.

## Security
- No secrets in code. Use KeyVault.
- Input validation is mandatory for all public methods.

## Architecture
- Layered architecture: API -> Service -> Repo.
- Dependency Injection for all services.
