# Contributing

Thanks for your interest in contributing to Mist Blog! This document provides guidelines for contributing to the project.

## Development Setup

1. Fork the repository
2. Clone your fork: `git clone <your-fork-url>`
3. Install dependencies: `gleam deps download`

## Running Tests

```bash
# Run all tests
gleam test

# Run tests with verbose output
gleam test --verbose
```

## Code Style

This project uses `gleam format` for code formatting. Run it before committing:

```bash
gleam format src test
```

## Adding Features

1. Create a new branch: `git checkout -b feature/your-feature-name`
2. Make your changes
3. Add tests if applicable
4. Run the test suite
5. Format your code: `gleam format src test`
6. Commit your changes
7. Push to your fork and create a pull request

## Reporting Issues

When reporting bugs, please include:

- The version of Mist Blog you're using
- Steps to reproduce the issue
- Expected vs actual behavior
- Any error messages or logs

## License

By contributing, you agree that your contributions will be licensed under the MIT License.