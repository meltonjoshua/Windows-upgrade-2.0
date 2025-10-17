# Contributing to Crypto Trader Bot

Thank you for your interest in contributing to the Crypto Trader Bot! This document provides guidelines and instructions for contributing.

## Code of Conduct

- Be respectful and professional
- Welcome newcomers and help them get started
- Focus on constructive feedback
- Respect differing viewpoints and experiences

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in [Issues](https://github.com/meltonjoshua/Windows-upgrade-2.0/issues)
2. If not, create a new issue with:
   - Clear, descriptive title
   - Steps to reproduce
   - Expected vs. actual behavior
   - Environment details (OS, Python version, etc.)
   - Log excerpts if applicable

### Suggesting Features

1. Check [Issues](https://github.com/meltonjoshua/Windows-upgrade-2.0/issues) and [Discussions](https://github.com/meltonjoshua/Windows-upgrade-2.0/discussions)
2. Create a new discussion or issue with:
   - Clear description of the feature
   - Use case and motivation
   - Potential implementation approach
   - Any relevant examples

### Pull Requests

1. **Fork the repository**
2. **Create a feature branch** from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**:
   - Follow the code style guidelines
   - Add tests for new functionality
   - Update documentation
   - Keep commits atomic and well-described

4. **Test your changes**:
   ```bash
   # Run tests
   pytest
   
   # Check code style
   black src/
   flake8 src/
   
   # Type checking
   mypy src/
   ```

5. **Commit your changes**:
   ```bash
   git commit -m "feat: add awesome new feature"
   ```
   
   Use conventional commit format:
   - `feat:` - New feature
   - `fix:` - Bug fix
   - `docs:` - Documentation changes
   - `style:` - Code style changes (formatting)
   - `refactor:` - Code refactoring
   - `test:` - Adding or updating tests
   - `chore:` - Maintenance tasks

6. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Create a Pull Request**:
   - Provide clear description of changes
   - Reference any related issues
   - Include screenshots for UI changes
   - Ensure CI checks pass

## Development Setup

### Prerequisites

- Python 3.10+
- Docker and Docker Compose
- Git
- Virtual environment tool

### Setup Steps

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/Windows-upgrade-2.0.git
cd Windows-upgrade-2.0/crypto-trader-bot

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install development dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt  # If exists

# Install pre-commit hooks
pre-commit install

# Start development databases
docker-compose up -d postgres redis influxdb

# Run tests
pytest
```

## Code Style

### Python

- Follow [PEP 8](https://pep8.org/)
- Use [Black](https://black.readthedocs.io/) for formatting
- Use [flake8](https://flake8.pycqa.org/) for linting
- Use [mypy](http://mypy-lang.org/) for type checking
- Maximum line length: 100 characters

```bash
# Format code
black src/

# Lint code
flake8 src/

# Type check
mypy src/
```

### Documentation

- Use docstrings for all public modules, classes, and functions
- Follow [Google Style](https://google.github.io/styleguide/pyguide.html#38-comments-and-docstrings) for docstrings
- Keep documentation up-to-date with code changes
- Include examples in docstrings when helpful

Example:
```python
def calculate_position_size(
    capital: float,
    risk_percent: float,
    stop_loss_percent: float
) -> float:
    """
    Calculate position size based on risk parameters.
    
    Args:
        capital: Total available capital in base currency
        risk_percent: Percentage of capital to risk (0-1)
        stop_loss_percent: Stop loss distance as percentage (0-1)
        
    Returns:
        Position size in base currency
        
    Raises:
        ValueError: If any parameter is negative or out of valid range
        
    Example:
        >>> calculate_position_size(10000, 0.02, 0.05)
        4000.0
    """
    if capital < 0 or risk_percent < 0 or stop_loss_percent < 0:
        raise ValueError("Parameters must be non-negative")
    
    return (capital * risk_percent) / stop_loss_percent
```

## Testing

### Writing Tests

- Write tests for all new functionality
- Aim for 80%+ code coverage
- Use pytest for testing
- Mock external dependencies (exchanges, databases)
- Test edge cases and error conditions

### Test Structure

```python
# tests/test_strategies/test_ma_crossover.py

import pytest
from src.strategies.ma_crossover import MACrossoverStrategy

class TestMACrossoverStrategy:
    """Test suite for MA Crossover strategy."""
    
    @pytest.fixture
    def strategy(self):
        """Create strategy instance for testing."""
        config = {
            'fast_period': 10,
            'slow_period': 20,
            'enabled': True
        }
        return MACrossoverStrategy('MA_Test', config)
    
    def test_initialization(self, strategy):
        """Test strategy initialization."""
        assert strategy.name == 'MA_Test'
        assert strategy.config['fast_period'] == 10
        
    def test_signal_generation(self, strategy):
        """Test signal generation logic."""
        # Test implementation
        pass
```

### Running Tests

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=src --cov-report=html

# Run specific test file
pytest tests/test_strategies/test_ma_crossover.py

# Run specific test
pytest tests/test_strategies/test_ma_crossover.py::TestMACrossoverStrategy::test_initialization

# Run with verbose output
pytest -v

# Stop on first failure
pytest -x
```

## Project Structure

```
crypto-trader-bot/
├── src/                    # Source code
│   ├── core/              # Core engine components
│   ├── strategies/        # Trading strategies
│   ├── exchanges/         # Exchange integrations
│   ├── data/              # Data pipeline
│   ├── risk/              # Risk management
│   ├── monitoring/        # Monitoring and alerts
│   ├── backtesting/       # Backtesting engine
│   └── utils/             # Utility functions
├── tests/                 # Test files (mirror src/ structure)
├── docs/                  # Documentation
├── config/                # Configuration files
├── scripts/               # Utility scripts
└── docker/                # Docker configurations
```

## Areas for Contribution

### High Priority

- Exchange integrations (Coinbase Pro, Kraken, etc.)
- Additional trading strategies
- Risk management improvements
- Backtesting engine optimization
- Documentation and tutorials
- Test coverage improvements

### Medium Priority

- Web dashboard development
- Mobile app development
- Advanced ML models
- Performance optimizations
- Additional notification channels

### Good First Issues

Look for issues labeled `good-first-issue` for beginner-friendly tasks:
- Documentation improvements
- Simple bug fixes
- Adding tests
- Code cleanup and refactoring

## Review Process

1. **Automated Checks**: CI/CD pipeline runs tests and linting
2. **Code Review**: Maintainers review code for:
   - Correctness
   - Code quality
   - Test coverage
   - Documentation
   - Performance
3. **Feedback**: Address review comments
4. **Approval**: At least one maintainer approval required
5. **Merge**: Squash and merge to main branch

## Questions?

- Check the [documentation](docs/)
- Search [existing issues](https://github.com/meltonjoshua/Windows-upgrade-2.0/issues)
- Ask in [discussions](https://github.com/meltonjoshua/Windows-upgrade-2.0/discussions)
- Contact maintainers

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (MIT License).

---

Thank you for contributing to Crypto Trader Bot! 🚀
