# Quick Start Guide

This guide will help you get the Crypto Trader Bot up and running quickly.

## Prerequisites

- Python 3.10 or higher
- Docker and Docker Compose (recommended)
- Git
- 8GB RAM minimum
- 20GB free disk space

## Installation Methods

### Method 1: Docker (Recommended)

This is the easiest way to get started with all dependencies pre-configured.

```bash
# 1. Clone the repository
git clone https://github.com/meltonjoshua/Windows-upgrade-2.0.git
cd Windows-upgrade-2.0/crypto-trader-bot

# 2. Create environment file
cp .env.example .env
# Edit .env with your settings

# 3. Start all services
docker-compose up -d

# 4. Check service status
docker-compose ps

# 5. View logs
docker-compose logs -f crypto-bot-app
```

**Access Points**:
- Web Dashboard: http://localhost:8000
- Grafana: http://localhost:3000 (admin/admin)
- Prometheus: http://localhost:9090

### Method 2: Manual Setup

For development or customization:

```bash
# 1. Clone the repository
git clone https://github.com/meltonjoshua/Windows-upgrade-2.0.git
cd Windows-upgrade-2.0/crypto-trader-bot

# 2. Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Set up databases (requires Docker)
docker-compose up -d postgres redis influxdb mongodb

# 5. Create configuration
cp config/config.example.yaml config/config.yaml
# Edit config/config.yaml with your settings

# 6. Set environment variables
export POSTGRES_USER=crypto_bot
export POSTGRES_PASSWORD=changeme
export REDIS_PASSWORD=changeme
export BINANCE_API_KEY=your_api_key
export BINANCE_API_SECRET=your_api_secret

# 7. Initialize database
python scripts/init_db.py

# 8. Run the bot (paper trading mode)
python src/main.py --mode paper
```

## Configuration

### Exchange API Keys

1. **Binance** (Primary Exchange):
   - Sign up at https://www.binance.com
   - Go to API Management
   - Create new API key with trading permissions
   - **Important**: Enable IP whitelist for security
   - Add keys to `config/config.yaml` or environment variables

2. **Testnet** (Recommended for beginners):
   - Use Binance Testnet: https://testnet.binance.vision/
   - Get free test funds
   - No risk of losing real money

### Basic Configuration

Edit `config/config.yaml`:

```yaml
bot:
  mode: "paper"  # Start with paper trading
  
exchanges:
  binance:
    enabled: true
    testnet: true  # Use testnet first
    api_key: "${BINANCE_API_KEY}"
    api_secret: "${BINANCE_API_SECRET}"

trading_pairs:
  - symbol: "BTC/USDT"
    exchange: "binance"
    enabled: true

strategies:
  - name: "MA Crossover"
    type: "trend_following"
    enabled: true
    allocation: 0.3  # Use 30% of capital
```

## First Run

### Paper Trading (Simulated)

Safe way to test without risking real money:

```bash
# Run in paper trading mode
python src/main.py --mode paper

# You should see:
# - Crypto Trading Bot v0.1.0
# - Mode: paper
# - Connection to exchanges
# - Strategy initialization
# - Real-time price updates
```

### Backtesting

Test strategies on historical data:

```bash
# Backtest MA Crossover strategy
python src/main.py --backtest \
  --strategy "MA Crossover" \
  --start 2023-01-01 \
  --end 2023-12-31

# View results in reports/ directory
```

## Monitoring

### Web Dashboard

Access at http://localhost:8000

Features:
- Real-time portfolio value
- Open positions
- Recent trades
- Performance charts
- Strategy status

### Command Line

```bash
# Check bot status
python src/cli.py status

# View positions
python src/cli.py positions

# View recent trades
python src/cli.py trades --limit 10

# Start/stop strategies
python src/cli.py start-strategy "MA Crossover"
python src/cli.py stop-strategy "MA Crossover"
```

### Logs

```bash
# View live logs
tail -f logs/bot.log

# Search logs
grep "ERROR" logs/bot.log

# Docker logs
docker-compose logs -f crypto-bot-app
```

## Safety Checklist

Before going live with real money:

- [ ] Successfully run paper trading for at least 2 weeks
- [ ] Backtest strategies on 1+ year of historical data
- [ ] Verify positive risk-adjusted returns (Sharpe > 1.0)
- [ ] Test all risk management features
- [ ] Set up alerts and monitoring
- [ ] Configure stop-loss and position limits
- [ ] Enable IP whitelist on exchange APIs
- [ ] Start with small capital (<1% of portfolio)
- [ ] Monitor first week closely
- [ ] Have emergency shutdown plan

## Common Issues

### Issue: "Cannot connect to exchange"
**Solution**: 
- Check internet connection
- Verify API keys are correct
- Check if IP is whitelisted on exchange
- Ensure testnet/mainnet setting is correct

### Issue: "Database connection failed"
**Solution**:
- Ensure Docker containers are running: `docker-compose ps`
- Check database credentials in config
- Restart database: `docker-compose restart postgres`

### Issue: "No trading signals generated"
**Solution**:
- Check if strategy is enabled in config
- Verify market data is being received
- Review strategy logs for errors
- Ensure trading pair has sufficient liquidity

### Issue: "ImportError" or "ModuleNotFoundError"
**Solution**:
- Ensure virtual environment is activated
- Reinstall dependencies: `pip install -r requirements.txt`
- Check Python version: `python --version` (should be 3.10+)

## Next Steps

1. **Read Documentation**:
   - [Architecture Overview](docs/architecture/README.md)
   - [Complete Project Plan](../CRYPTO_BOT_PROJECT_PLAN.md)
   - [Development Roadmap](ROADMAP.md)

2. **Explore Strategies**:
   - Review existing strategies in `src/strategies/`
   - Read strategy configuration in `config/strategies/`
   - Create custom strategies following base class

3. **Customize Configuration**:
   - Adjust risk parameters
   - Add more trading pairs
   - Configure notifications
   - Set up additional exchanges

4. **Join Community**:
   - Report issues on GitHub
   - Share strategies and insights
   - Request features
   - Contribute to development

## Support

- **Documentation**: Check docs/ folder
- **Issues**: https://github.com/meltonjoshua/Windows-upgrade-2.0/issues
- **Discussions**: https://github.com/meltonjoshua/Windows-upgrade-2.0/discussions

## Important Reminders

⚠️ **Risk Warning**: Cryptocurrency trading carries substantial risk. Only trade with capital you can afford to lose.

⚠️ **Security**: Never commit API keys to version control. Use environment variables or secure vaults.

⚠️ **Testing**: Always start with paper trading and testnet before using real money.

⚠️ **Monitoring**: Actively monitor bot performance, especially in the first weeks.

---

**Ready to Start?** 

Run `docker-compose up -d` and access the dashboard at http://localhost:8000

**Questions?** Check the [Complete Project Plan](../CRYPTO_BOT_PROJECT_PLAN.md) for comprehensive details.
