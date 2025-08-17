-- yield.lua
-- Scans protocols for best APYs and automates yield farming
Yield = {}

Yield.protocol_yields = {}
Yield.active_positions = {}
Yield.yield_history = {}

-- Yield optimization configuration
Yield.config = {
  min_apy = 0.05, -- Minimum 5% APY to consider
  max_risk_score = 0.7, -- Maximum protocol risk score
  min_liquidity = 1000000, -- Minimum $1M liquidity
  gas_threshold = 50, -- Maximum gas cost in USD
  rebalance_threshold = 0.02 -- 2% APY difference to trigger rebalance
}

-- Known AO protocol process IDs (to be configured)
Yield.protocol_addresses = {
  lending = {
    "ao_aave_process_id",
    "ao_compound_process_id"
  },
  dex = {
    "ao_uniswap_process_id",
    "ao_sushiswap_process_id"
  },
  yield_farms = {
    "ao_yearn_process_id",
    "ao_curve_process_id"
  },
  staking = {
    "astro_usd_staking_id"
  }
}

function Yield.scan_protocols(protocols)
  Yield.protocol_yields = {}
  
  for category, protocol_list in pairs(Yield.protocol_addresses) do
    for _, protocol_id in ipairs(protocol_list) do
      Yield.query_protocol_yield(protocol_id, category)
    end
  end
  
  -- Also scan any custom protocols passed in
  if protocols then
    for _, protocol_name in ipairs(protocols) do
      if Yield.protocol_addresses[protocol_name] then
        for _, protocol_id in ipairs(Yield.protocol_addresses[protocol_name]) do
          Yield.query_protocol_yield(protocol_id, protocol_name)
        end
      end
    end
  end
end

function Yield.query_protocol_yield(protocol_id, category)
  -- Send message to protocol to get current yields
  ao.send({
    Target = protocol_id,
    Action = "Get-Yield-Info",
    Data = {
      Requester = ao.id,
      Category = category,
      Timestamp = os.time()
    }
  })
end

function Yield.handle_yield_response(msg)
  if msg.Action == "Yield-Info-Response" and msg.Data then
    local protocol_id = msg.From
    local yield_data = msg.Data
    
    Yield.protocol_yields[protocol_id] = {
      apy = tonumber(yield_data.APY) or 0,
      liquidity = tonumber(yield_data.Liquidity) or 0,
      risk_score = tonumber(yield_data.RiskScore) or 1,
      category = yield_data.Category or "unknown",
      supported_assets = yield_data.SupportedAssets or {},
      fees = tonumber(yield_data.Fees) or 0,
      lock_period = tonumber(yield_data.LockPeriod) or 0,
      last_updated = os.time()
    }
  end
end

function Yield.optimize(portfolio, portfolio_risk_score)
  if not portfolio or not portfolio.assets then
    return {}
  end
  
  local optimization_results = {
    recommendations = {},
    current_yield = Yield.calculate_current_yield(portfolio),
    potential_yield = 0,
    risk_adjusted_yield = 0
  }
  
  -- Get best yields for each asset
  for asset_symbol, asset_data in pairs(portfolio.assets) do
    local best_opportunities = Yield.find_best_yields_for_asset(asset_symbol, portfolio_risk_score)
    
    if #best_opportunities > 0 then
      local recommendation = {
        asset = asset_symbol,
        current_amount = asset_data.amount,
        opportunities = best_opportunities,
        recommended_action = Yield.get_recommended_action(asset_symbol, best_opportunities)
      }
      
      table.insert(optimization_results.recommendations, recommendation)
    end
  end
  
  -- Calculate potential yields
  optimization_results.potential_yield = Yield.calculate_potential_yield(optimization_results.recommendations)
  optimization_results.risk_adjusted_yield = Yield.calculate_risk_adjusted_yield(optimization_results.recommendations)
  
  return optimization_results
end

function Yield.find_best_yields_for_asset(asset_symbol, max_risk_score)
  local opportunities = {}
  
  for protocol_id, yield_data in pairs(Yield.protocol_yields) do
    -- Check if protocol supports this asset
    local supports_asset = false
    for _, supported_asset in ipairs(yield_data.supported_assets) do
      if supported_asset == asset_symbol then
        supports_asset = true
        break
      end
    end
    
    if supports_asset and Yield.meets_criteria(yield_data, max_risk_score) then
      table.insert(opportunities, {
        protocol_id = protocol_id,
        apy = yield_data.apy,
        risk_score = yield_data.risk_score,
        liquidity = yield_data.liquidity,
        category = yield_data.category,
        fees = yield_data.fees,
        lock_period = yield_data.lock_period,
        risk_adjusted_apy = yield_data.apy * (1 - yield_data.risk_score)
      })
    end
  end
  
  -- Sort by risk-adjusted APY
  table.sort(opportunities, function(a, b)
    return a.risk_adjusted_apy > b.risk_adjusted_apy
  end)
  
  return opportunities
end

function Yield.meets_criteria(yield_data, max_risk_score)
  return yield_data.apy >= Yield.config.min_apy and
         yield_data.risk_score <= math.min(max_risk_score, Yield.config.max_risk_score) and
         yield_data.liquidity >= Yield.config.min_liquidity
end

function Yield.get_recommended_action(asset_symbol, opportunities)
  if #opportunities == 0 then
    return {
      action = "hold",
      reason = "No suitable yield opportunities found"
    }
  end
  
  local best_opportunity = opportunities[1]
  local current_position = Yield.active_positions[asset_symbol]
  
  if not current_position then
    return {
      action = "enter",
      protocol_id = best_opportunity.protocol_id,
      expected_apy = best_opportunity.apy,
      reason = "New yield farming opportunity"
    }
  end
  
  -- Check if should switch protocols
  local current_apy = current_position.apy or 0
  local apy_difference = best_opportunity.apy - current_apy
  
  if apy_difference > Yield.config.rebalance_threshold then
    return {
      action = "switch",
      from_protocol = current_position.protocol_id,
      to_protocol = best_opportunity.protocol_id,
      apy_improvement = apy_difference,
      reason = "Better yield opportunity available"
    }
  end
  
  return {
    action = "hold",
    reason = "Current position is optimal"
  }
end

function Yield.calculate_current_yield(portfolio)
  local total_yield = 0
  local total_value = 0
  
  for asset_symbol, position in pairs(Yield.active_positions) do
    local asset_data = portfolio.assets[asset_symbol]
    if asset_data then
      local asset_value = asset_data.value or 0
      total_yield = total_yield + (asset_value * (position.apy or 0))
      total_value = total_value + asset_value
    end
  end
  
  return total_value > 0 and (total_yield / total_value) or 0
end

function Yield.calculate_potential_yield(recommendations)
  local total_potential = 0
  
  for _, rec in ipairs(recommendations) do
    if #rec.opportunities > 0 then
      total_potential = total_potential + rec.opportunities[1].apy
    end
  end
  
  return #recommendations > 0 and (total_potential / #recommendations) or 0
end

function Yield.calculate_risk_adjusted_yield(recommendations)
  local total_risk_adjusted = 0
  
  for _, rec in ipairs(recommendations) do
    if #rec.opportunities > 0 then
      total_risk_adjusted = total_risk_adjusted + rec.opportunities[1].risk_adjusted_apy
    end
  end
  
  return #recommendations > 0 and (total_risk_adjusted / #recommendations) or 0
end

function Yield.execute_yield_strategy(asset_symbol, action_data)
  local success = false
  
  if action_data.action == "enter" then
    success = Yield.enter_yield_position(asset_symbol, action_data.protocol_id)
  elseif action_data.action == "switch" then
    success = Yield.switch_yield_position(asset_symbol, action_data.from_protocol, action_data.to_protocol)
  elseif action_data.action == "exit" then
    success = Yield.exit_yield_position(asset_symbol, action_data.protocol_id)
  end
  
  if success then
    Yield.log_yield_action(asset_symbol, action_data)
  end
  
  return success
end

function Yield.enter_yield_position(asset_symbol, protocol_id)
  -- Send message to protocol to enter yield farming
  ao.send({
    Target = protocol_id,
    Action = "Enter-Yield",
    Data = {
      Asset = asset_symbol,
      Amount = "all", -- Use all available balance
      Timestamp = os.time()
    }
  })
  
  -- Update active positions (simplified)
  Yield.active_positions[asset_symbol] = {
    protocol_id = protocol_id,
    entry_time = os.time(),
    apy = Yield.protocol_yields[protocol_id].apy
  }
  
  return true
end

function Yield.switch_yield_position(asset_symbol, from_protocol, to_protocol)
  -- Exit current position
  ao.send({
    Target = from_protocol,
    Action = "Exit-Yield",
    Data = {
      Asset = asset_symbol,
      Timestamp = os.time()
    }
  })
  
  -- Enter new position
  ao.send({
    Target = to_protocol,
    Action = "Enter-Yield",
    Data = {
      Asset = asset_symbol,
      Amount = "all",
      Timestamp = os.time()
    }
  })
  
  -- Update active positions
  Yield.active_positions[asset_symbol] = {
    protocol_id = to_protocol,
    entry_time = os.time(),
    apy = Yield.protocol_yields[to_protocol].apy
  }
  
  return true
end

function Yield.exit_yield_position(asset_symbol, protocol_id)
  ao.send({
    Target = protocol_id,
    Action = "Exit-Yield",
    Data = {
      Asset = asset_symbol,
      Timestamp = os.time()
    }
  })
  
  -- Remove from active positions
  Yield.active_positions[asset_symbol] = nil
  
  return true
end

function Yield.log_yield_action(asset_symbol, action_data)
  table.insert(Yield.yield_history, {
    timestamp = os.time(),
    asset = asset_symbol,
    action = action_data.action,
    details = action_data
  })
  
  -- Keep only last 50 actions
  if #Yield.yield_history > 50 then
    table.remove(Yield.yield_history, 1)
  end
end

function Yield.get_yield_report()
  local current_yield = 0
  local total_positions = 0
  
  for asset, position in pairs(Yield.active_positions) do
    current_yield = current_yield + (position.apy or 0)
    total_positions = total_positions + 1
  end
  
  return {
    average_yield = total_positions > 0 and (current_yield / total_positions) or 0,
    active_positions = total_positions,
    protocols_used = Yield.get_unique_protocols(),
    last_optimization = Yield.get_last_optimization_time()
  }
end

function Yield.get_unique_protocols()
  local protocols = {}
  for _, position in pairs(Yield.active_positions) do
    protocols[position.protocol_id] = true
  end
  
  local count = 0
  for _ in pairs(protocols) do
    count = count + 1
  end
  
  return count
end

function Yield.get_last_optimization_time()
  if #Yield.yield_history > 0 then
    return Yield.yield_history[#Yield.yield_history].timestamp
  end
  return 0
end

-- Yield module loaded globally
