-- agent.lua
-- Main AO DeFi Portfolio Manager Agent
-- Note: All modules are loaded globally in the same AOS process

-- Agent state
agent_state = {
  initialized = false,
  last_rebalance = 0,
  last_yield_scan = 0,
  last_price_update = 0,
  emergency_mode = false,
  performance_metrics = {
    total_trades = 0,
    successful_trades = 0,
    total_return = 0,
    max_drawdown = 0
  }
}

-- Initialize the agent
function initialize_agent()
  if agent_state.initialized then
    return
  end
  
  ao.log("Initializing AO DeFi Portfolio Manager Agent v" .. config.version)
  
  -- Initialize portfolio with initial assets
  Portfolio.initialize_portfolio(config.initial_portfolio)
  
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

-- Cron handlers for different intervals
function main_cron()
  local current_time = os.time()
  
  -- Price updates
  if current_time - agent_state.last_price_update >= config.price_update_interval then
    Portfolio.update_prices_from_oracles(config.oracle_addresses)
    agent_state.last_price_update = os.time()
  end
  
  -- Yield optimization
  if current_time - agent_state.last_yield_scan >= config.yield_scan_interval then
    Yield.scan_protocols(config.supported_protocols)
    local optimization_result = Yield.optimize(Portfolio.portfolio, 0.5)
    agent_state.last_yield_scan = os.time()
  end
  
  -- Rebalancing
  if current_time - agent_state.last_rebalance >= config.rebalance_interval then
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
