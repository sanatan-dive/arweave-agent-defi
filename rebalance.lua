-- rebalance.lua
-- Executes trades with slippage protection and allocation drift correction
Rebalance = {}

Rebalance.trade_history = {}
Rebalance.pending_trades = {}

-- Rebalancing configuration
Rebalance.config = {
  max_slippage = 0.01, -- 1% maximum slippage
  drift_threshold = 0.05, -- 5% allocation drift triggers rebalance
  min_trade_value = 100, -- Minimum $100 trade to avoid dust
  gas_limit = 200, -- Maximum gas cost in USD
  batch_delay = 5, -- Seconds between batched trades
  emergency_threshold = 0.15 -- 15% drift triggers emergency rebalance
}

function Rebalance.calculate_drift(portfolio, target_allocations)
  if not portfolio.assets or not target_allocations then
    return {}
  end
  
  local total_value = 0
  local current_allocations = {}
  
  -- Calculate total portfolio value
  for symbol, asset in pairs(portfolio.assets) do
    total_value = total_value + (asset.value or 0)
  end
  
  if total_value <= 0 then
    return {}
  end
  
  -- Calculate current allocations as percentages
  for symbol, asset in pairs(portfolio.assets) do
    current_allocations[symbol] = (asset.value or 0) / total_value
  end
  
  -- Calculate drift for each target allocation
  local drift = {}
  for target_symbol, target_percentage in pairs(target_allocations) do
    local current_percentage = current_allocations[target_symbol] or 0
    drift[target_symbol] = {
      current = current_percentage,
      target = target_percentage,
      drift = current_percentage - target_percentage,
      drift_abs = math.abs(current_percentage - target_percentage),
      value_diff = (current_percentage - target_percentage) * total_value
    }
  end
  
  return drift
end

function Rebalance.needs_rebalancing(drift, risk_score)
  -- Check if any allocation drift exceeds threshold
  for symbol, drift_data in pairs(drift) do
    if drift_data.drift_abs > Rebalance.config.drift_threshold then
      return true, "allocation_drift", symbol
    end
  end
  
  -- Check for emergency rebalancing due to high risk
  if risk_score and risk_score > 0.9 then
    for symbol, drift_data in pairs(drift) do
      if drift_data.drift_abs > Rebalance.config.emergency_threshold then
        return true, "emergency_risk", symbol
      end
    end
  end
  
  return false, "within_tolerance", nil
end

function Rebalance.rebalance(portfolio, risk_score, target_allocations)
  local drift = Rebalance.calculate_drift(portfolio, target_allocations)
  local needs_rebalance, reason, trigger_symbol = Rebalance.needs_rebalancing(drift, risk_score)
  
  if not needs_rebalance then
    return {
      action = "no_rebalance",
      reason = reason,
      drift = drift
    }
  end
  
  -- Adjust target allocations based on risk score
  local adjusted_targets = Rebalance.adjust_targets_for_risk(target_allocations, risk_score)
  
  -- Calculate required trades
  local trades = Rebalance.calculate_trades(portfolio, drift, adjusted_targets)
  
  -- Optimize trade execution order
  trades = Rebalance.optimize_trade_order(trades)
  
  -- Execute trades
  local execution_results = Rebalance.execute_trades(trades)
  
  return {
    action = "rebalanced",
    reason = reason,
    trigger_symbol = trigger_symbol,
    risk_score = risk_score,
    original_targets = target_allocations,
    adjusted_targets = adjusted_targets,
    trades = trades,
    execution_results = execution_results,
    timestamp = os.time()
  }
end

function Rebalance.adjust_targets_for_risk(target_allocations, risk_score)
  local adjusted = {}
  
  -- Copy original targets
  for symbol, percentage in pairs(target_allocations) do
    adjusted[symbol] = percentage
  end
  
  -- Adjust for high risk - increase stablecoin allocation
  if risk_score > 0.8 then
    local risk_adjustment = (risk_score - 0.8) * 0.5 -- Up to 10% shift to stables
    
    -- Increase stablecoin allocation
    if adjusted.stablecoins then
      adjusted.stablecoins = math.min(0.7, adjusted.stablecoins + risk_adjustment)
    else
      adjusted.USDA = math.min(0.7, (adjusted.USDA or 0) + risk_adjustment)
    end
    
    -- Proportionally reduce other allocations
    local reduction_per_asset = risk_adjustment / (table.getn(adjusted) - 1)
    for symbol, percentage in pairs(adjusted) do
      if symbol ~= "stablecoins" and symbol ~= "USDA" then
        adjusted[symbol] = math.max(0.05, percentage - reduction_per_asset)
      end
    end
  end
  
  return adjusted
end

function Rebalance.calculate_trades(portfolio, drift, target_allocations)
  local trades = {}
  local total_value = 0
  
  -- Calculate total portfolio value
  for symbol, asset in pairs(portfolio.assets) do
    total_value = total_value + (asset.value or 0)
  end
  
  if total_value <= 0 then
    return trades
  end
  
  -- Calculate required trades
  for symbol, target_percentage in pairs(target_allocations) do
    local current_asset = portfolio.assets[symbol] or { value = 0, amount = 0 }
    local current_value = current_asset.value or 0
    local target_value = total_value * target_percentage
    local value_difference = target_value - current_value
    
    -- Only create trade if difference is significant
    if math.abs(value_difference) > Rebalance.config.min_trade_value then
      local trade = {
        symbol = symbol,
        action = value_difference > 0 and "buy" or "sell",
        current_value = current_value,
        target_value = target_value,
        value_difference = math.abs(value_difference),
        percentage_change = value_difference / total_value,
        priority = Rebalance.calculate_trade_priority(symbol, value_difference, target_percentage),
        estimated_gas = Rebalance.estimate_gas_cost(symbol, math.abs(value_difference))
      }
      
      table.insert(trades, trade)
    end
  end
  
  return trades
end

function Rebalance.calculate_trade_priority(symbol, value_difference, target_percentage)
  -- Higher priority for:
  -- 1. Larger value differences
  -- 2. Stablecoins (safer)
  -- 3. Major assets
  
  local priority = math.abs(value_difference) / 1000 -- Base priority on trade size
  
  -- Boost priority for stablecoins
  if string.find(symbol, "USD") or string.find(symbol, "DAI") then
    priority = priority * 1.5
  end
  
  -- Boost priority for major assets
  if symbol == "AR" or symbol == "ETH" or symbol == "BTC" then
    priority = priority * 1.2
  end
  
  return priority
end

function Rebalance.estimate_gas_cost(symbol, trade_value)
  -- Simplified gas estimation
  local base_gas = 50 -- Base $50 gas cost
  local variable_gas = trade_value * 0.001 -- 0.1% of trade value
  
  return base_gas + variable_gas
end

function Rebalance.optimize_trade_order(trades)
  -- Sort trades by priority (highest first)
  table.sort(trades, function(a, b)
    return a.priority > b.priority
  end)
  
  -- Group sells before buys to have liquidity
  local sells = {}
  local buys = {}
  
  for _, trade in ipairs(trades) do
    if trade.action == "sell" then
      table.insert(sells, trade)
    else
      table.insert(buys, trade)
    end
  end
  
  -- Combine sells first, then buys
  local optimized_trades = {}
  for _, trade in ipairs(sells) do
    table.insert(optimized_trades, trade)
  end
  for _, trade in ipairs(buys) do
    table.insert(optimized_trades, trade)
  end
  
  return optimized_trades
end

function Rebalance.execute_trades(trades)
  local results = {}
  
  for i, trade in ipairs(trades) do
    -- Add delay between trades to avoid overwhelming the network
    if i > 1 then
      -- In real implementation, this would be a proper delay
      -- For now, just log the intended delay
      ao.log("Delaying " .. Rebalance.config.batch_delay .. " seconds before next trade")
    end
    
    local result = Rebalance.execute_single_trade(trade)
    table.insert(results, result)
    
    -- Add to pending trades for monitoring
    Rebalance.pending_trades[trade.symbol .. "_" .. os.time()] = {
      trade = trade,
      result = result,
      timestamp = os.time()
    }
  end
  
  return results
end

function Rebalance.execute_single_trade(trade)
  -- Check gas cost limit
  if trade.estimated_gas > Rebalance.config.gas_limit then
    return {
      success = false,
      error = "Gas cost too high",
      trade = trade
    }
  end
  
  local result = {
    success = false,
    trade = trade,
    transaction_id = nil,
    actual_amount = 0,
    slippage = 0,
    gas_used = 0,
    timestamp = os.time()
  }
  
  if trade.action == "buy" then
    result = Rebalance.execute_buy_order(trade)
  elseif trade.action == "sell" then
    result = Rebalance.execute_sell_order(trade)
  end
  
  -- Log trade execution
  Rebalance.log_trade(result)
  
  return result
end

function Rebalance.execute_buy_order(trade)
  -- Send buy order to appropriate DEX
  local dex_process_id = Rebalance.get_best_dex_for_asset(trade.symbol)
  
  ao.send({
    Target = dex_process_id,
    Action = "Buy-Order",
    Data = {
      Symbol = trade.symbol,
      Value = trade.value_difference,
      MaxSlippage = Rebalance.config.max_slippage,
      Deadline = os.time() + 300, -- 5 minute deadline
      Timestamp = os.time()
    }
  })
  
  return {
    success = true,
    trade = trade,
    transaction_id = "pending_" .. os.time(),
    estimated_slippage = 0.005, -- Estimated 0.5% slippage
    dex_used = dex_process_id
  }
end

function Rebalance.execute_sell_order(trade)
  -- Send sell order to appropriate DEX
  local dex_process_id = Rebalance.get_best_dex_for_asset(trade.symbol)
  
  ao.send({
    Target = dex_process_id,
    Action = "Sell-Order",
    Data = {
      Symbol = trade.symbol,
      Value = trade.value_difference,
      MaxSlippage = Rebalance.config.max_slippage,
      Deadline = os.time() + 300, -- 5 minute deadline
      Timestamp = os.time()
    }
  })
  
  return {
    success = true,
    trade = trade,
    transaction_id = "pending_" .. os.time(),
    estimated_slippage = 0.005, -- Estimated 0.5% slippage
    dex_used = dex_process_id
  }
end

function Rebalance.get_best_dex_for_asset(symbol)
  -- Simple DEX selection logic
  -- In practice, this would query multiple DEXs for best price
  local dex_options = {
    "ao_uniswap_process_id",
    "ao_sushiswap_process_id",
    "ao_curve_process_id"
  }
  
  -- For stablecoins, prefer Curve
  if string.find(symbol, "USD") or string.find(symbol, "DAI") then
    return "ao_curve_process_id"
  end
  
  -- Default to Uniswap
  return dex_options[1]
end

function Rebalance.log_trade(result)
  table.insert(Rebalance.trade_history, {
    timestamp = os.time(),
    symbol = result.trade.symbol,
    action = result.trade.action,
    value = result.trade.value_difference,
    success = result.success,
    slippage = result.slippage,
    gas_used = result.gas_used,
    transaction_id = result.transaction_id
  })
  
  -- Keep only last 100 trades
  if #Rebalance.trade_history > 100 then
    table.remove(Rebalance.trade_history, 1)
  end
end

function Rebalance.handle_trade_confirmation(msg)
  -- Handle trade confirmation from DEX
  if msg.Action == "Trade-Confirmed" and msg.Data then
    local trade_id = msg.Data.TradeId
    local actual_amount = tonumber(msg.Data.ActualAmount) or 0
    local slippage = tonumber(msg.Data.Slippage) or 0
    local gas_used = tonumber(msg.Data.GasUsed) or 0
    
    -- Update pending trade
    for pending_id, pending_trade in pairs(Rebalance.pending_trades) do
      if pending_trade.result.transaction_id == trade_id then
        pending_trade.result.actual_amount = actual_amount
        pending_trade.result.slippage = slippage
        pending_trade.result.gas_used = gas_used
        pending_trade.result.confirmed = true
        break
      end
    end
  end
end

function Rebalance.get_rebalance_report()
  local recent_trades = {}
  local total_gas_spent = 0
  local average_slippage = 0
  local successful_trades = 0
  
  -- Analyze recent trade history (last 10 trades)
  local start_index = math.max(1, #Rebalance.trade_history - 9)
  for i = start_index, #Rebalance.trade_history do
    local trade = Rebalance.trade_history[i]
    table.insert(recent_trades, trade)
    
    if trade.success then
      successful_trades = successful_trades + 1
      total_gas_spent = total_gas_spent + (trade.gas_used or 0)
      average_slippage = average_slippage + (trade.slippage or 0)
    end
  end
  
  if successful_trades > 0 then
    average_slippage = average_slippage / successful_trades
  end
  
  return {
    recent_trades = recent_trades,
    success_rate = successful_trades / math.max(1, #recent_trades),
    total_gas_spent = total_gas_spent,
    average_slippage = average_slippage,
    pending_trades = table.getn(Rebalance.pending_trades)
  }
end

function Rebalance.emergency_rebalance(portfolio, target_allocations)
  -- Emergency rebalancing with relaxed constraints
  local emergency_config = {
    max_slippage = 0.03, -- Allow 3% slippage in emergency
    drift_threshold = 0.01, -- 1% threshold for emergency
    min_trade_value = 50, -- Lower minimum trade value
    gas_limit = 500 -- Higher gas limit
  }
  
  -- Temporarily override config
  local original_config = Rebalance.config
  Rebalance.config = emergency_config
  
  local result = Rebalance.rebalance(portfolio, 1.0, target_allocations) -- Max risk score
  
  -- Restore original config
  Rebalance.config = original_config
  
  result.emergency = true
  return result
end

-- Rebalance module loaded globally
