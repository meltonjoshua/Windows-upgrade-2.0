"""
Base Strategy Class

All trading strategies must inherit from this base class.
"""

from abc import ABC, abstractmethod
from typing import Dict, Any, Optional
from dataclasses import dataclass
from datetime import datetime


@dataclass
class Signal:
    """Trading signal representation."""
    action: str  # BUY, SELL, HOLD
    symbol: str
    timestamp: datetime
    price: float
    confidence: float = 1.0
    metadata: Optional[Dict[str, Any]] = None


class BaseStrategy(ABC):
    """
    Base class for all trading strategies.
    
    All custom strategies must inherit from this class and implement
    the required abstract methods.
    """
    
    def __init__(self, name: str, config: Dict[str, Any]):
        """
        Initialize the strategy.
        
        Args:
            name: Strategy name
            config: Strategy configuration dictionary
        """
        self.name = name
        self.config = config
        self.enabled = config.get('enabled', True)
        self.allocation = config.get('allocation', 0.1)
        self.positions = {}
        self.initialized = False
    
    @abstractmethod
    def initialize(self) -> None:
        """
        Initialize strategy-specific parameters.
        
        This method is called once when the strategy is first loaded.
        Use it to set up indicators, load models, etc.
        """
        pass
    
    @abstractmethod
    def calculate_signals(self, data: Dict[str, Any]) -> Signal:
        """
        Calculate trading signals based on market data.
        
        Args:
            data: Market data dictionary containing OHLCV and other data
            
        Returns:
            Signal object with trading decision
        """
        pass
    
    def on_tick(self, tick: Dict[str, Any]) -> Optional[Signal]:
        """
        Process real-time tick data.
        
        Args:
            tick: Real-time tick data
            
        Returns:
            Optional Signal object
        """
        return None
    
    def on_bar(self, bar: Dict[str, Any]) -> Optional[Signal]:
        """
        Process bar/candle data.
        
        Args:
            bar: OHLCV bar data
            
        Returns:
            Optional Signal object
        """
        return None
    
    def on_order_update(self, order: Dict[str, Any]) -> None:
        """
        Handle order status updates.
        
        Args:
            order: Order update information
        """
        pass
    
    def on_fill(self, trade: Dict[str, Any]) -> None:
        """
        Handle trade execution notification.
        
        Args:
            trade: Trade execution details
        """
        pass
    
    def on_shutdown(self) -> None:
        """
        Cleanup when strategy is stopped.
        
        Use this to close positions, save state, etc.
        """
        pass
    
    def get_position_size(self, signal: Signal, capital: float) -> float:
        """
        Calculate position size for a signal.
        
        Args:
            signal: Trading signal
            capital: Available capital
            
        Returns:
            Position size in base currency
        """
        # Default implementation: use allocation percentage
        return capital * self.allocation
    
    def validate_signal(self, signal: Signal) -> bool:
        """
        Validate a trading signal before execution.
        
        Args:
            signal: Signal to validate
            
        Returns:
            True if signal is valid, False otherwise
        """
        if signal.action not in ['BUY', 'SELL', 'HOLD']:
            return False
        
        if signal.confidence < 0 or signal.confidence > 1:
            return False
        
        return True
    
    def __str__(self) -> str:
        return f"Strategy({self.name}, enabled={self.enabled})"
    
    def __repr__(self) -> str:
        return self.__str__()
