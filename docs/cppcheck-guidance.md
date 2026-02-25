# cppcheck Suppression Policy

## Overview

The `make lint` target runs cppcheck with a two-tier suppression policy:

- **Globally suppressed** — style-only checks that never indicate bugs
- **Enforced via inline baseline** — checks that catch real bugs; legacy violations are suppressed with `// cppcheck-suppress` comments in-source, but new code must pass clean

## Enforced Checks

These checks are active. Existing legacy violations have inline `// cppcheck-suppress` comments. **Do not add new inline suppressions for these — fix the issue instead.**

### `uninitMemberVar` / `uninitMemberVarPrivate`

**What it catches:** Class members not initialized in the constructor, leading to undefined behavior when read before assignment.

**How to fix:** Initialize all members in the constructor member initializer list:

```cpp
// BAD — m_nCount has indeterminate value
CMyClass::CMyClass() { }

// GOOD
CMyClass::CMyClass() : m_nCount(0), m_pData(nullptr) { }
```

For classes with many members, use in-class default initializers (C++11):

```cpp
class CMyClass {
    int m_nCount = 0;
    float m_fScale = 1.0f;
    CWidget* m_pWidget = nullptr;
};
```

### `dangerousTypeCast`

**What it catches:** Unsafe C-style casts that may truncate data or violate type safety.

**How to fix:** Replace C-style casts with the appropriate C++ cast:

```cpp
// BAD
int value = (int)floatVar;
CBase* p = (CBase*)voidPtr;

// GOOD
int value = static_cast<int>(floatVar);
auto* p = static_cast<CBase*>(voidPtr);
```

Use `static_cast` for numeric conversions, `reinterpret_cast` for pointer reinterpretation (rare), and `const_cast` only when removing const from APIs you don't control.

### `noOperatorEq` / `noCopyConstructor`

**What it catches:** Rule of Three violations — classes with a destructor but no copy constructor or assignment operator, risking double-free or shallow copy bugs.

**How to fix (preferred):** If the class doesn't need copying, delete the operations:

```cpp
class CResourceHolder {
public:
    ~CResourceHolder();
    CResourceHolder(const CResourceHolder&) = delete;
    CResourceHolder& operator=(const CResourceHolder&) = delete;
};
```

If copying is needed, implement all three (or use the Rule of Five with move operations).

### `duplInheritedMember`

**What it catches:** A derived class defines a member function or variable with the same name as one in a base class, which shadows the base version and can cause subtle bugs.

**How to fix:** Rename the derived member, or if the shadowing is intentional, add an explicit `using` declaration or document the intent.

## Globally Suppressed (Style-Only)

These are suppressed project-wide because they are style preferences, not correctness issues:

| Check | Reason |
|-------|--------|
| `missingInclude` | cppcheck can't resolve Win32/DirectX/third-party include paths |
| `unmatchedSuppression` | Avoids noise when inline suppressions don't match across cppcheck versions |
| `unusedFunction` | Too many false positives without whole-program analysis (callbacks, macros, conditional compilation) |
| `useInitializationList` | Style preference for initializer lists vs assignment in constructor body |
| `passedByValue` | Suggests pass-by-const-ref; performance style, not a bug |
| `postfixOperator` | Suggests `++i` over `i++`; trivial performance difference |
| `returnByReference` | Suggests returning by reference; performance style |
| `*:*/ThirdParty/*` | Third-party code is not our responsibility |

## Reducing Legacy Suppressions

When you touch a file that has inline `// cppcheck-suppress` comments for enforced checks, consider fixing the underlying issue and removing the suppression. Priority order:

1. `uninitMemberVar` — most likely to cause real runtime bugs
2. `dangerousTypeCast` — data truncation and type safety
3. `noOperatorEq` / `noCopyConstructor` — resource management bugs
4. `duplInheritedMember` — shadowing confusion
