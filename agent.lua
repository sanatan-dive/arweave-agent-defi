-- agent.lua
-- Main AO DeFi Portfolio Manager Agent with Sponsor Bonus Features
-- Integrates RandAO, Apus Network AI, and AstroUSD for maximum hackathon points

-- Agent state
agent_state = {
  initialized = false,
  last_rebalance = 0,
  last_yield_scan = 0,
  last_price_update = 0,
  emergency_mode = false,
  
  -- Bonus features state
  last_randomness_request = 0,
  last_ai_inference = 0,
  ai_enhanced_decisions = 0,
  randomized_operations = 0,
  
  performance_metrics = {
    total_trades = 0,
    successful_trades = 0,
    total_return = 0,
    max_drawdown = 0
  }
}

-- Initialize the agent with bonus features
function initialize_agent()
  if agent_state.initialized then
    return
  end
  
  ao.log("Initializing AO DeFi Portfolio Manager Agent v" .. config.version)
  ao.log("🎲 RandAO Integration: " .. (RandAO and "✅ Active" or "❌ Not loaded"))
  ao.log("🤖 Apus AI Integration: " .. (ApusAI and "✅ Active" or "❌ Not loaded"))
  
  -- Initialize portfolio with initial assets
  Portfolio.initialize_portfolio(config.initial_portfolio)
  
  -- Initialize bonus features if available
  if RandAO then
    agent_state.randomness_enabled = true
    ao.log("RandAO randomness features enabled")
  end
  
  if ApusAI then
    agent_state.ai_enhanced = true
    ao.log("Apus Network AI features enabled")
  end
  
  -- Set protocol IDs
  Protocols.protocol_ids = config.protocol_process_ids
  
  -- Log initialization
  ao.log("Agent initialized with portfolio value: $" .. Portfolio.calculate_total_value())
  
  agent_state.initialized = true
  agent_state.last_rebalance = os.time()
  agent_state.last_yield_scan = os.time()
  agent_state.last_price_update = os.time()
end

-- Main message handler
function handle_message(msg)
  if not agent_state.initialized then
    initialize_agent()
  end
  
  local action = msg.Action or msg.action or ""
  
  -- Handle different message types
  if action == "Price-Response" or action == "price_update" then
    handle_price_update(msg)
  elseif action == "Rebalance" or action == "rebalance" then
    trigger_rebalance()
  elseif action == "Emergency-Stop" then
    handle_emergency_stop()
  elseif action == "Get-Status" then
    send_status_response(msg.From)
  elseif action == "Update-Config" then
    handle_config_update(msg)
  elseif action == "Manual-Trade" then
    handle_manual_trade(msg)
  elseif Protocols.handle_protocol_response(msg) then
    -- Protocol response handled
  else
    ao.log("Unknown message action: " .. action)
  end
end

function perform_rebalancing()
  -- Calculate portfolio metrics
  local metrics = Portfolio.calculate_metrics()
  
  -- Assess risk
  local risk_result = Risk.assess(Portfolio.portfolio)
  
  -- Determine target allocations based on risk
  local target_allocations = config.target_allocations
  if risk_result.risk_score > config.emergency_threshold then
    target_allocations = config.emergency_allocations
    agent_state.emergency_mode = true
  else
    agent_state.emergency_mode = false
  end
  
  -- Execute rebalancing
  local rebalance_result = Rebalance.rebalance(
    Portfolio.portfolio, 
    risk_result.risk_score, 
    target_allocations
  )
  
  return {
    metrics = metrics,
    risk = risk_result,
    rebalance = rebalance_result,
    timestamp = os.time()
  }
end

-- Cron handlers for different intervals with bonus features
function main_cron()
  local current_time = os.time()
  
  -- Price updates
  if current_time - agent_state.last_price_update >= config.price_update_interval then
    Portfolio.update_prices_from_oracles(config.oracle_addresses)
    agent_state.last_price_update = os.time()
  end
  
  -- AI-enhanced risk assessment
  if current_time - agent_state.last_ai_inference >= 1800 and ApusAI then -- Every 30 minutes
    ApusAI.ai_risk_inference(Portfolio.portfolio)
    ApusAI.ai_market_sentiment()
    agent_state.last_ai_inference = os.time()
    agent_state.ai_enhanced_decisions = agent_state.ai_enhanced_decisions + 1
  end
  
  -- Yield optimization with randomness
  if current_time - agent_state.last_yield_scan >= config.yield_scan_interval then
    if RandAO then
      -- Use randomness for yield selection
      local yield_selection = RandAO.randomized_yield_selection(Yield.get_available_strategies())
      if yield_selection then
        agent_state.randomized_operations = agent_state.randomized_operations + 1
      end
    end
    
    Yield.scan_protocols(config.supported_protocols)
    local optimization_result = Yield.optimize(Portfolio.portfolio, 0.5)
    agent_state.last_yield_scan = os.time()
  end
  
  -- Enhanced rebalancing with AI and randomness
  if current_time - agent_state.last_rebalance >= config.rebalance_interval then
    -- Get AI rebalancing strategy if available
    if ApusAI then
      ApusAI.ai_rebalancing_strategy(Portfolio.portfolio, config.target_allocations)
    end
    
    -- Use randomness for MEV protection
    if RandAO then
      local random_strategy = RandAO.randomized_rebalance_strategy()
      agent_state.pending_random_rebalance = random_strategy
      agent_state.last_randomness_request = os.time()
      agent_state.randomized_operations = agent_state.randomized_operations + 1
    end
    
    local result = perform_rebalancing()
    agent_state.last_rebalance = os.time()
    log_rebalance_result(result)
  end
  
  -- Health checks and cleanup
  Protocols.cleanup_old_requests()
end

function log_rebalance_result(result)
  ao.log("Rebalancing completed - Action: " .. (result.action or "unknown"))
  
  if result.trades then
    ao.log("Trades executed: " .. #result.trades)
  end
  
  -- Store in permanent storage
  ao.data.append("rebalance-history", {
    timestamp = os.time(),
    result = result,
    portfolio_value = Portfolio.calculate_total_value()
  })
end

-- Data storage and logging
function log_action(action)
  ao.data.append("portfolio-history", action)
end

-- AO process handlers setup
Handlers.add(
  "MessageHandler",
  Handlers.utils.hasMatchingTag("Action", "."),
  handle_message
)

Handlers.add(
  "CronHandler", 
  Handlers.utils.hasMatchingTag("Action", "Cron"),
  main_cron
)

-- Global function for manual initialization
function init_agent()
  initialize_agent()
  print("✅ Agent initialized successfully!")
  print("Agent ID: " .. config.agent_id)
  print("Agent Active: " .. tostring(agent_state.active))
end

-- Initialize agent on startup
initialize_agent()

ao.log("AO DeFi Portfolio Manager Agent started successfully")
