"""
Tests for the BaseStrategy class and Signal dataclass.
"""

import pytest
from datetime import datetime
from typing import Dict, Any

import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from strategies.base import Signal, BaseStrategy


class TestSignal:
    """Tests for the Signal dataclass."""
    
    def test_signal_creation_with_required_fields(self):
        """Test creating a Signal with required fields only."""
        signal = Signal(
            action="BUY",
            symbol="BTC/USDT",
            timestamp=datetime(2023, 1, 1, 12, 0, 0),
            price=50000.0
        )
        
        assert signal.action == "BUY"
        assert signal.symbol == "BTC/USDT"
        assert signal.timestamp == datetime(2023, 1, 1, 12, 0, 0)
        assert signal.price == 50000.0
        assert signal.confidence == 1.0  # default value
        assert signal.metadata is None  # default value
    
    def test_signal_creation_with_all_fields(self):
        """Test creating a Signal with all fields."""
        metadata = {"indicator": "RSI", "value": 30}
        signal = Signal(
            action="SELL",
            symbol="ETH/USDT",
            timestamp=datetime(2023, 6, 15, 10, 30, 0),
            price=2000.0,
            confidence=0.85,
            metadata=metadata
        )
        
        assert signal.action == "SELL"
        assert signal.symbol == "ETH/USDT"
        assert signal.timestamp == datetime(2023, 6, 15, 10, 30, 0)
        assert signal.price == 2000.0
        assert signal.confidence == 0.85
        assert signal.metadata == {"indicator": "RSI", "value": 30}
    
    def test_signal_hold_action(self):
        """Test creating a HOLD signal."""
        signal = Signal(
            action="HOLD",
            symbol="BTC/USDT",
            timestamp=datetime.now(),
            price=55000.0,
            confidence=0.5
        )
        
        assert signal.action == "HOLD"
        assert signal.confidence == 0.5


class ConcreteStrategy(BaseStrategy):
    """Concrete implementation of BaseStrategy for testing."""
    
    def initialize(self) -> None:
        """Initialize the strategy."""
        self.initialized = True
    
    def calculate_signals(self, data: Dict[str, Any]) -> Signal:
        """Calculate trading signals."""
        return Signal(
            action="HOLD",
            symbol=data.get("symbol", "BTC/USDT"),
            timestamp=datetime.now(),
            price=data.get("price", 0.0)
        )


class TestBaseStrategy:
    """Tests for the BaseStrategy class."""
    
    def test_strategy_initialization(self):
        """Test strategy initialization with default config."""
        config = {"enabled": True, "allocation": 0.15}
        strategy = ConcreteStrategy("TestStrategy", config)
        
        assert strategy.name == "TestStrategy"
        assert strategy.config == config
        assert strategy.enabled is True
        assert strategy.allocation == 0.15
        assert strategy.positions == {}
        assert strategy.initialized is False
    
    def test_strategy_default_values(self):
        """Test strategy with empty config uses defaults."""
        strategy = ConcreteStrategy("DefaultStrategy", {})
        
        assert strategy.enabled is True  # default
        assert strategy.allocation == 0.1  # default
    
    def test_strategy_initialize_method(self):
        """Test that initialize method can be called."""
        strategy = ConcreteStrategy("TestStrategy", {})
        strategy.initialize()
        
        assert strategy.initialized is True
    
    def test_calculate_signals(self):
        """Test calculate_signals returns proper Signal."""
        strategy = ConcreteStrategy("TestStrategy", {})
        data = {"symbol": "ETH/USDT", "price": 3000.0}
        
        signal = strategy.calculate_signals(data)
        
        assert isinstance(signal, Signal)
        assert signal.symbol == "ETH/USDT"
        assert signal.price == 3000.0
        assert signal.action == "HOLD"
    
    def test_get_position_size(self):
        """Test position size calculation."""
        config = {"allocation": 0.2}
        strategy = ConcreteStrategy("TestStrategy", config)
        signal = Signal(
            action="BUY",
            symbol="BTC/USDT",
            timestamp=datetime.now(),
            price=50000.0
        )
        
        position_size = strategy.get_position_size(signal, capital=10000.0)
        
        assert position_size == 2000.0  # 10000 * 0.2
    
    def test_validate_signal_valid_buy(self):
        """Test validate_signal with valid BUY signal."""
        strategy = ConcreteStrategy("TestStrategy", {})
        signal = Signal(
            action="BUY",
            symbol="BTC/USDT",
            timestamp=datetime.now(),
            price=50000.0,
            confidence=0.8
        )
        
        assert strategy.validate_signal(signal) is True
    
    def test_validate_signal_valid_sell(self):
        """Test validate_signal with valid SELL signal."""
        strategy = ConcreteStrategy("TestStrategy", {})
        signal = Signal(
            action="SELL",
            symbol="BTC/USDT",
            timestamp=datetime.now(),
            price=50000.0,
            confidence=0.9
        )
        
        assert strategy.validate_signal(signal) is True
    
    def test_validate_signal_valid_hold(self):
        """Test validate_signal with valid HOLD signal."""
        strategy = ConcreteStrategy("TestStrategy", {})
        signal = Signal(
            action="HOLD",
            symbol="BTC/USDT",
            timestamp=datetime.now(),
            price=50000.0,
            confidence=0.5
        )
        
        assert strategy.validate_signal(signal) is True
    
    def test_validate_signal_invalid_action(self):
        """Test validate_signal with invalid action."""
        strategy = ConcreteStrategy("TestStrategy", {})
        signal = Signal(
            action="INVALID",
            symbol="BTC/USDT",
            timestamp=datetime.now(),
            price=50000.0
        )
        
        assert strategy.validate_signal(signal) is False
    
    def test_validate_signal_confidence_too_high(self):
        """Test validate_signal with confidence > 1."""
        strategy = ConcreteStrategy("TestStrategy", {})
        signal = Signal(
            action="BUY",
            symbol="BTC/USDT",
            timestamp=datetime.now(),
            price=50000.0,
            confidence=1.5
        )
        
        assert strategy.validate_signal(signal) is False
    
    def test_validate_signal_confidence_negative(self):
        """Test validate_signal with negative confidence."""
        strategy = ConcreteStrategy("TestStrategy", {})
        signal = Signal(
            action="BUY",
            symbol="BTC/USDT",
            timestamp=datetime.now(),
            price=50000.0,
            confidence=-0.1
        )
        
        assert strategy.validate_signal(signal) is False
    
    def test_strategy_str_representation(self):
        """Test string representation of strategy."""
        strategy = ConcreteStrategy("MyStrategy", {"enabled": True})
        
        assert str(strategy) == "Strategy(MyStrategy, enabled=True)"
    
    def test_strategy_repr(self):
        """Test repr of strategy."""
        strategy = ConcreteStrategy("MyStrategy", {"enabled": False})
        
        assert repr(strategy) == "Strategy(MyStrategy, enabled=False)"
    
    def test_on_tick_returns_none_by_default(self):
        """Test that on_tick returns None by default."""
        strategy = ConcreteStrategy("TestStrategy", {})
        result = strategy.on_tick({"price": 50000.0})
        
        assert result is None
    
    def test_on_bar_returns_none_by_default(self):
        """Test that on_bar returns None by default."""
        strategy = ConcreteStrategy("TestStrategy", {})
        result = strategy.on_bar({"open": 50000.0, "close": 50100.0})
        
        assert result is None
