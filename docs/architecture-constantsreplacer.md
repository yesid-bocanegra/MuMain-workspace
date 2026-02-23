# Architecture: ConstantsReplacer Code Generation Tool

## Executive Summary

ConstantsReplacer is a .NET 8 WinForms desktop application that synchronizes game constant values between the OpenMU server database and the MuMain C++ client codebase. It reads SQL files containing server-side item/monster definitions and replaces corresponding constant values in C++ source files, ensuring client-server data consistency.

## Technology Stack

| Category | Technology | Version | Notes |
|----------|-----------|---------|-------|
| Runtime | .NET | 8.0 | Windows Forms |
| Language | C# | Latest | |
| UI Framework | WinForms | — | Single-form GUI |
| Encoding | UDE.CSharp | 1.1.0 | NuGet: universal charset detection |

## Architecture Pattern

**Pipeline/Transform Pattern** — Reads SQL constants, matches patterns in C++ files, replaces values.

```
SQL Files (OpenMU constants)
        │
        ▼
┌─────────────────────┐
│  ConstantsReplacer   │
│                      │
│  1. Parse SQL files  │
│  2. Extract constants│
│  3. Scan C++ files   │
│  4. Pattern match    │
│  5. Replace values   │
│  6. Detect encoding  │
│  7. Write back       │
└─────────────────────┘
        │
        ▼
C++ Source Files (updated constants)
```

## Core Components

### Program.cs
- **Role:** Application entry point
- **Responsibility:** WinForms bootstrap, launches `MainForm`

### MainForm.cs
- **Role:** GUI interface
- **Responsibility:** File selection, replacement preview, execution trigger

### Replacer.cs
- **Role:** Core replacement engine
- **Responsibility:** SQL parsing, C++ pattern matching, constant value substitution

### FileEncoding.cs
- **Role:** Encoding detection and preservation
- **Responsibility:** Uses UDE.CSharp to detect source file encodings, ensures write-back preserves original encoding (critical for multi-language C++ files with non-ASCII identifiers)

## Data Flow

```
*.sql (item definitions, monster tables)
    │
    ├── Extract: constant names + values
    │
    ▼
C++ source files (src/source/*.h, *.cpp)
    │
    ├── Find: #define CONSTANT_NAME or enum values
    ├── Match: constant name from SQL
    ├── Replace: old value → new value
    │
    ▼
Updated C++ files (encoding preserved)
```

## SQL Sources

The tool processes SQL files that define server-side game data:
- Item constants (IDs, attributes, categories)
- Monster constants (IDs, stats, spawn data)
- Mapped from OpenMU server database schema

## Build & Usage

```bash
# Build
dotnet build ConstantsReplacer/ConstantsReplacer.csproj

# Run (GUI)
dotnet run --project ConstantsReplacer/ConstantsReplacer.csproj
```

Also built as a CMake custom command target during the full MuMain build process.

## Key Files Reference

| File | Role |
|------|------|
| `ConstantsReplacer.csproj` | Project config (.NET 8, WinForms) |
| `Program.cs` | Entry point |
| `MainForm.cs` | GUI form |
| `Replacer.cs` | Replacement logic engine |
| `FileEncoding.cs` | Charset detection (UDE.CSharp) |
| `*.sql` | OpenMU constant SQL definitions |
