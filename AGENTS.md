# AGENT Instructions

This repository contains Swift, Python, and TypeScript code.

## Code Style
- Use two spaces for indentation in `.swift` and `.ts` files.
- Use four spaces for indentation in `.py` files.
- Swift variables and properties should use `camelCase`.
- Python variables should use `snake_case`.
- Keep lines under 120 characters.

## Pull Requests
- Provide a concise summary of your changes.
- Include a **Testing** section summarizing the commands run to verify your work.
- If tests or formatting commands fail because of missing dependencies or network
  restrictions, mention this in the **Testing** section.

## Programmatic Checks
For any change that touches Python files, run the following before committing:

```bash
python -m py_compile $(git ls-files '*.py')
```

