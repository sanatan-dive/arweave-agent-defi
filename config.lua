-- config.lua
-- Configuration for AO DeFi Portfolio Manager Agent
-- Includes real process IDs and sponsor bonus feature settings

config = {
  version = "1.0.0",
  agent_id = "3cn7HC83zWIzBnnHJlloZaLONq4uerfGRM-3OSR7gBs",
  
  -- Sponsor Integration Process IDs (REAL MAINNET ADDRESSES)
  sponsor_integrations = {
    randao = "SjvsFtgngd6PyOJDzmZ3a4wbkP5LGFGAZ6hqOkYoSPo",      -- RandAO for randomness
    apus_ai = "mqBYxpDsolZmJyBdTK8TJp_ftOuIUXVYcSQ8MYZdJg0",    -- Apus Network for AI
    astrousd = "GcFxqTQnKHcr304qnOcq00ZqbaYGDn4Wbb0DHAM-wvU"    -- AstroUSD for stable assets
  },
  
  -- Bonus Features Configuration
  bonus_features = {
    randao_enabled = true,
    apus_ai_enabled = true,
    astrousd_deep_integration = true,
    
    -- RandAO settings
    randomness_interval = 3600,              -- Request randomness every hour
    random_rebalance_threshold = 0.1,        -- 10% threshold for random rebalancing
    mev_protection_enabled = true,           -- Enable MEV-resistant trading
    
    -- Apus Network AI settings
    ai_inference_interval = 1800,            -- AI analysis every 30 minutes
    ai_confidence_threshold = 0.8,           -- Minimum confidence for AI decisions
    ai_risk_enhancement = true,              -- Enhanced risk assessment
    ai_yield_optimization = true,            -- AI-powered yield selection
    
    -- AstroUSD integration settings
    usda_portfolio_percentage = 0.25,        -- 25% USDA allocation target
    usda_staking_enabled = true,             -- Enable USDA staking
    cross_chain_bridge_enabled = true       -- Enable cross-chain operations
  },
  
  -- Oracle Configuration (REAL 0rbit Oracle Process IDs)
  oracle_addresses = {
    AR = "BaMK1dfayo75s3q1ow6AO64UDpD9SEFbeE8xYrY2fyQ",   -- 0rbit Oracle
    ETH = "BaMK1dfayo75s3q1ow6AO64UDpD9SEFbeE8xYrY2fyQ",  -- 0rbit Oracle  
    BTC = "BaMK1dfayo75s3q1ow6AO64UDpD9SEFbeE8xYrY2fyQ",  -- 0rbit Oracle
    USDA = "BaMK1dfayo75s3q1ow6AO64UDpD9SEFbeE8xYrY2fyQ", -- 0rbit Oracle (if supported)
    USDC = "BaMK1dfayo75s3q1ow6AO64UDpD9SEFbeE8xYrY2fyQ", -- 0rbit Oracle
    UNI = "BaMK1dfayo75s3q1ow6AO64UDpD9SEFbeE8xYrY2fyQ",  -- 0rbit Oracle
    SUSHI = "BaMK1dfayo75s3q1ow6AO64UDpD9SEFbeE8xYrY2fyQ" -- 0rbit Oracle
  },
  
  -- Timing Configuration
  rebalance_interval = 3600, -- seconds (1 hour)
  price_update_interval = 300, -- seconds (5 minutes)
  yield_scan_interval = 1800, -- seconds (30 minutes)
  health_check_interval = 600, -- seconds (10 minutes)
  
  -- Risk Management
  risk_tolerance = 0.7, -- 0-1 scale (0.7 = moderate risk)
  max_position_size = 0.3, -- Maximum 30% in any single asset
  emergency_threshold = 0.9, -- Risk score triggering emergency action
  var_confidence_level = 0.95, -- 95% confidence for VaR calculations
  
  -- Target Allocations (must sum to 1.0)
  target_allocations = {
    stablecoins = 0.25, -- 25% in stablecoins (USDA, USDC, DAI)
    bluechip = 0.35,    -- 35% in blue chip crypto (AR, ETH, BTC)
    defi = 0.25,        -- 25% in DeFi tokens
    yield_farming = 0.15 -- 15% in active yield farming positions
  },
  
  -- Emergency allocation (used when risk > emergency_threshold)
  emergency_allocations = {
    stablecoins = 0.6,  -- 60% in stablecoins during high risk
    bluechip = 0.3,     -- 30% in blue chips
    defi = 0.1,         -- 10% in DeFi
    yield_farming = 0.0 -- 0% in yield farming during emergencies
  },
  
  -- Trading Configuration
  max_slippage = 0.02, -- 2% maximum slippage tolerance
  gas_price_multiplier = 1.1, -- 10% gas price buffer
  min_trade_amount = 1, -- Minimum trade amount in base currency
  
  -- Rebalancing Configuration  
  drift_threshold = 0.05, -- 5% drift triggers rebalancing
  rebalance_cooldown = 1800, -- 30 minutes between rebalances
  emergency_drift_threshold = 0.15, -- 15% drift triggers emergency rebalancing
  
  -- Yield Farming Configuration
  min_apy_threshold = 0.05, -- 5% minimum APY to consider
  yield_risk_adjustment = 0.8, -- Risk adjustment factor for yield calculations
  max_yield_allocation = 0.4, -- Maximum 40% in any single yield strategy
  
  -- Risk Categories
  asset_categories = {
    stablecoins = {"USDA", "USDC", "DAI", "USDT"},
    bluechip = {"AR", "ETH", "BTC", "SOL"},
    defi = {"UNI", "SUSHI", "COMP", "AAVE"},
    altcoins = {"LINK", "DOT", "ADA", "MATIC"}
  },
  
  -- Protocol process IDs (REAL VALUES)
  protocol_process_ids = {
    permaswap = "aGF7BWB_9B924sBXoirHy4KOceoCX72B77yh1nllMPA",
    permaswap_router = "DM3FoZUq_yebASPhgd8pEIRIzDW6muXEhxz5-JwbZwo",
    astrousd = "GcFxqTQnKHcr304qnOcq00ZqbaYGDn4Wbb0DHAM-wvU", -- AstroUSD (USDA)
    astro_lending = "GcFxqTQnKHcr304qnOcq00ZqbaYGDn4Wbb0DHAM-wvU" -- Using same process for now
  },
  
  -- Initial Portfolio (YOUR REAL HOLDINGS - Update with actual amounts)
  initial_portfolio = {
    AR = {
      amount = 100,        -- 100 AR tokens
      price = 28.50        -- Current AR price
    },
    USDA = {
      amount = 0,          -- Will mint USDA from AR
      price = 1.00         -- USDA should be ~$1
    }
  },
  
  -- Performance tracking
  benchmark = "AR", -- Benchmark asset for performance comparison
  performance_window = 30, -- Days to track for performance calculations
  
  -- Security settings
  max_daily_trades = 20, -- Maximum trades per day
  position_size_limits = {
    single_asset = 0.3,    -- 30% max in any single asset
    single_protocol = 0.5, -- 50% max in any single protocol
    single_category = 0.6  -- 60% max in any category
  },
  
  -- Logging configuration
  log_level = "INFO", -- DEBUG, INFO, WARN, ERROR
  max_log_entries = 1000, -- Maximum log entries to keep
  log_retention_days = 30 -- Days to keep logs
}
