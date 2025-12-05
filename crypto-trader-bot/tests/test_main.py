"""
Tests for the main entry point.
"""

import pytest
from unittest.mock import patch, AsyncMock
import argparse

import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from main import parse_arguments, main, __version__


class TestParseArguments:
    """Tests for command line argument parsing."""
    
    def test_default_arguments(self):
        """Test parsing with default arguments."""
        with patch('sys.argv', ['main.py']):
            args = parse_arguments()
        
        assert args.mode == "paper"
        assert args.config == "config/config.yaml"
        assert args.log_level == "INFO"
        assert args.backtest is False
        assert args.strategy is None
        assert args.start is None
        assert args.end is None
    
    def test_live_mode(self):
        """Test parsing with live mode."""
        with patch('sys.argv', ['main.py', '--mode', 'live']):
            args = parse_arguments()
        
        assert args.mode == "live"
    
    def test_paper_mode(self):
        """Test parsing with paper mode."""
        with patch('sys.argv', ['main.py', '--mode', 'paper']):
            args = parse_arguments()
        
        assert args.mode == "paper"
    
    def test_custom_config(self):
        """Test parsing with custom config path."""
        with patch('sys.argv', ['main.py', '--config', '/path/to/config.yaml']):
            args = parse_arguments()
        
        assert args.config == "/path/to/config.yaml"
    
    def test_log_level_debug(self):
        """Test parsing with DEBUG log level."""
        with patch('sys.argv', ['main.py', '--log-level', 'DEBUG']):
            args = parse_arguments()
        
        assert args.log_level == "DEBUG"
    
    def test_log_level_error(self):
        """Test parsing with ERROR log level."""
        with patch('sys.argv', ['main.py', '--log-level', 'ERROR']):
            args = parse_arguments()
        
        assert args.log_level == "ERROR"
    
    def test_backtest_flag(self):
        """Test parsing with backtest flag."""
        with patch('sys.argv', ['main.py', '--backtest']):
            args = parse_arguments()
        
        assert args.backtest is True
    
    def test_strategy_argument(self):
        """Test parsing with strategy argument."""
        with patch('sys.argv', ['main.py', '--strategy', 'momentum']):
            args = parse_arguments()
        
        assert args.strategy == "momentum"
    
    def test_date_arguments(self):
        """Test parsing with start and end dates."""
        with patch('sys.argv', ['main.py', '--start', '2023-01-01', '--end', '2023-12-31']):
            args = parse_arguments()
        
        assert args.start == "2023-01-01"
        assert args.end == "2023-12-31"
    
    def test_combined_arguments(self):
        """Test parsing with multiple arguments."""
        with patch('sys.argv', [
            'main.py', 
            '--mode', 'live',
            '--config', 'custom.yaml',
            '--log-level', 'WARNING',
            '--backtest',
            '--strategy', 'rsi',
            '--start', '2023-06-01',
            '--end', '2023-06-30'
        ]):
            args = parse_arguments()
        
        assert args.mode == "live"
        assert args.config == "custom.yaml"
        assert args.log_level == "WARNING"
        assert args.backtest is True
        assert args.strategy == "rsi"
        assert args.start == "2023-06-01"
        assert args.end == "2023-06-30"


class TestVersion:
    """Tests for version information."""
    
    def test_version_is_defined(self):
        """Test that version is defined."""
        assert __version__ is not None
    
    def test_version_format(self):
        """Test that version follows semantic versioning format."""
        parts = __version__.split('.')
        assert len(parts) == 3
        # Each part should be a valid integer
        for part in parts:
            int(part)


@pytest.mark.asyncio
class TestMain:
    """Tests for the main function."""
    
    async def test_main_paper_mode(self, capsys):
        """Test main function in paper mode."""
        args = argparse.Namespace(
            mode="paper",
            config="config/config.yaml",
            log_level="INFO",
            backtest=False,
            strategy=None,
            start=None,
            end=None
        )
        
        await main(args)
        
        captured = capsys.readouterr()
        assert f"Crypto Trading Bot v{__version__}" in captured.out
        assert "Mode: paper" in captured.out
        assert "Trading mode: paper" in captured.out
    
    async def test_main_live_mode(self, capsys):
        """Test main function in live mode."""
        args = argparse.Namespace(
            mode="live",
            config="config/config.yaml",
            log_level="INFO",
            backtest=False,
            strategy=None,
            start=None,
            end=None
        )
        
        await main(args)
        
        captured = capsys.readouterr()
        assert "Mode: live" in captured.out
        assert "Trading mode: live" in captured.out
    
    async def test_main_backtest_mode(self, capsys):
        """Test main function in backtest mode."""
        args = argparse.Namespace(
            mode="paper",
            config="config/config.yaml",
            log_level="INFO",
            backtest=True,
            strategy="momentum",
            start="2023-01-01",
            end="2023-12-31"
        )
        
        await main(args)
        
        captured = capsys.readouterr()
        assert "Backtesting mode" in captured.out
