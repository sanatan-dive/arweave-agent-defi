# 🤖 AO DeFi Portfolio Manager Agent

[![AO](https://img.shields.io/badge/Built%20on-AO-blue)](https://ao.arweave.dev)
[![Lua](https://img.shields.io/badge/Language-Lua-purple)](https://www.lua.org/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen)](https://github.com/sanatan-dive/arweave-agent-defi)

An autonomous DeFi portfolio manager running natively on AO that automatically rebalances portfolios, optimizes yields, and manages risk across multiple protocols using advanced ML-based algorithms.

## 🌟 Key Features

- **🤖 Autonomous Operation**: Runs 24/7 on AO with cron-based scheduling
- **📊 Advanced Risk Management**: ML-powered VaR calculations and protocol scoring
- **💰 Yield Optimization**: Multi-protocol yield farming across AstroUSD, Permaswap
- **⚖️ Smart Rebalancing**: Automated portfolio rebalancing with slippage protection
- **🔮 Real Price Feeds**: Integration with 0rbit oracle network
- **🛡️ Emergency Controls**: Pause/resume functionality with risk thresholds
- **📈 Performance Tracking**: Comprehensive metrics and historical analysis

## 🚀 Live Deployment

**Agent Process ID**: `3cn7HC83zWIzBnnHJlloZaLONq4uerfGRM-3OSR7gBs`

Monitor live at: https://www.ao.link/#/entity/3cn7HC83zWIzBnnHJlloZaLONq4uerfGRM-3OSR7gBs

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   agent.lua     │    │  portfolio.lua  │    │    risk.lua     │
│  (Orchestrator) │◄──►│ (Tracking &     │◄──►│ (ML Risk        │
│                 │    │  Performance)   │    │  Assessment)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   yield.lua     │    │ rebalance.lua   │    │ protocols.lua   │
│ (Multi-Protocol │    │ (Smart Trading  │    │ (External       │
│  Optimization)  │    │  Engine)        │    │  Integrations)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 ▼
                    ┌─────────────────────────┐
                    │       config.lua        │
                    │   (Configuration &      │
                    │    Real Process IDs)    │
                    └─────────────────────────┘
```

## 🔗 Protocol Integrations

| Protocol | Process ID | Purpose |
|----------|------------|---------|
| **0rbit Oracle** | `BaMK1dfayo75s3q1ow6AO64UDpD9SEFbeE8xYrY2fyQ` | Real-time price feeds |
| **Permaswap DEX** | `aGF7BWB_9B924sBXoirHy4KOceoCX72B77yh1nllMPA` | Automated trading |
| **AstroUSD** | `GcFxqTQnKHcr304qnOcq00ZqbaYGDn4Wbb0DHAM-wvU` | Stable asset management |

## 🚀 Quick Start

### Prerequisites

```bash
# Install AO CLI
npm install -g https://get_ao.g8way.io

# Clone repository
git clone https://github.com/sanatan-dive/arweave-agent-defi
cd arweave-agent-defi
```

### Deploy Your Agent

```bash
# Start AOS and deploy modules
aos 3cn7HC83zWIzBnnHJlloZaLONq4uerfGRM-3OSR7gBs

# In AOS terminal, load all modules:
.load config.lua
.load portfolio.lua
.load risk.lua  
.load yield.lua
.load rebalance.lua
.load protocols.lua
.load agent.lua

# Initialize the agent
initialize_agent()
```

## 📋 Module Overview

### Core Modules (2,024 lines of production code)

| Module | Lines | Description |
|--------|-------|-------------|
| `agent.lua` | 175 | Main orchestrator with message handlers |
| `config.lua` | 180 | Configuration with real process IDs |
| `portfolio.lua` | 187 | Real-time portfolio tracking |
| `risk.lua` | 309 | ML-based risk assessment |
| `yield.lua` | 400 | Multi-protocol yield optimization |
| `rebalance.lua` | 273 | Automated trading engine |
| `protocols.lua` | 500 | External protocol interfaces |

### Key Algorithms

- **Value at Risk (VaR)**: 95% confidence interval calculations
- **Portfolio Optimization**: Mean-variance optimization with constraints
- **Risk Scoring**: Multi-factor protocol assessment
- **Yield Farming**: Risk-adjusted APY optimization
- **Rebalancing**: Drift-based automatic rebalancing

## 🎮 Usage Examples

### Send Commands to Your Agent

```lua
-- Check portfolio status
Send({
  Target = "3cn7HC83zWIzBnnHJlloZaLONq4uerfGRM-3OSR7gBs",
  Action = "Portfolio-Status"
})

-- Trigger manual rebalancing
Send({
  Target = "3cn7HC83zWIzBnnHJlloZaLONq4uerfGRM-3OSR7gBs", 
  Action = "Rebalance-Portfolio"
})

-- Get risk assessment
Send({
  Target = "3cn7HC83zWIzBnnHJlloZaLONq4uerfGRM-3OSR7gBs",
  Action = "Risk-Assessment"
})
```

### Monitor Performance

```bash
# Check agent status in AOS
aos 3cn7HC83zWIzBnnHJlloZaLONq4uerfGRM-3OSR7gBs

# In AOS terminal:
print("Agent Status: " .. tostring(agent_state.initialized))
Portfolio.get_allocation_percentages()
Risk.assess()
```

## 🛡️ Security & Risk Management

### Built-in Safeguards

- **Emergency Stop**: Immediate agent shutdown capability
- **Risk Limits**: Automatic position sizing based on VaR
- **Slippage Protection**: MEV-resistant trade execution
- **Concentration Limits**: Maximum allocation per asset
- **Audit Trail**: Complete transaction logging

### Risk Parameters

```lua
risk_tolerance = 0.7,           -- 70% risk tolerance
max_position_size = 0.3,        -- Max 30% in any asset
emergency_threshold = 0.9,      -- Emergency stop trigger
var_confidence_level = 0.95,    -- 95% VaR confidence
```

## 📊 Performance Metrics

The agent tracks comprehensive performance metrics:

- **Portfolio Value**: Real-time USD value calculation
- **Returns**: Daily, weekly, monthly performance
- **Risk Metrics**: VaR, volatility, Sharpe ratio
- **Yield Performance**: APY tracking across protocols
- **Rebalancing Activity**: Trade frequency and slippage
- **Protocol Health**: Risk scores and TVL monitoring

## 🔧 Configuration

### Portfolio Allocation

```lua
target_allocations = {
  stablecoins = 0.25,      -- 25% USDA via AstroUSD
  bluechip = 0.35,         -- 35% AR, ETH, BTC
  defi = 0.25,             -- 25% DeFi protocol tokens
  yield_farming = 0.15     -- 15% active yield positions
}
```

### Timing Configuration

```lua
rebalance_interval = 3600,      -- 1 hour
price_update_interval = 300,    -- 5 minutes  
yield_scan_interval = 1800,     -- 30 minutes
health_check_interval = 600     -- 10 minutes
```

## 🧪 Testing

### Run Test Suite

```bash
# Load test module in AOS
aos 3cn7HC83zWIzBnnHJlloZaLONq4uerfGRM-3OSR7gBs

# In AOS terminal:
.load test.lua
test_agent()
```

### Test Coverage

- ✅ Agent initialization and state management
- ✅ Portfolio tracking and metric calculations  
- ✅ Risk assessment and VaR calculations
- ✅ Yield optimization algorithms
- ✅ Rebalancing logic and trade execution
- ✅ Protocol integration and error handling
- ✅ Emergency procedures and recovery

## 📚 Documentation

- **[Deployment Guide](DEPLOYMENT-STEPS.md)**: Complete deployment instructions
- **[Technical Writeup](TECHNICAL-WRITEUP.md)**: Comprehensive technical analysis
- **[Test Suite](test.lua)**: Agent validation and testing

## 🌐 Links & Resources

- **AO Platform**: https://ao.arweave.dev
- **0rbit Oracle**: https://0rbit.co  
- **Permaswap DEX**: https://permaswap.network
- **AstroUSD**: https://www.astrousd.com

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏆 Hackathon Submission

This project was built for the AO Hackathon, showcasing:

- **Advanced DeFi Integration**: Real protocol connections with AstroUSD, 0rbit, Permaswap
- **ML-Powered Risk Management**: Sophisticated algorithms for portfolio optimization
- **Autonomous Operation**: True set-and-forget portfolio management
- **Production Ready**: Deployed and running on AO mainnet

## 📞 Support

- **GitHub Issues**: [Submit an issue](https://github.com/sanatan-dive/arweave-agent-defi/issues)
- **AO Discord**: https://discord.gg/arweave
- **Documentation**: Check the repository files

---

**Built with ❤️ on AO - Autonomous DeFi Portfolio Management Made Simple** 🚀
