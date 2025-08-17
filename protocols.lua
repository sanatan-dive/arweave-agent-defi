-- protocols.lua
-- Interfaces for AO DeFi protocols and AstroUSD integration
Protocols = {}

-- Protocol process IDs (to be configured with actual AO process IDs)
Protocols.protocol_ids = {
  astro_usd = {
    main = "astro_usd_main_process_id",
    staking = "astro_usd_staking_process_id",
    bridge = "quantum_bridge_process_id"
  },
  lending = {
    aave = "ao_aave_process_id",
    compound = "ao_compound_process_id"
  },
  dex = {
    uniswap = "ao_uniswap_process_id",
    sushiswap = "ao_sushiswap_process_id",
    curve = "ao_curve_process_id"
  },
  yield_farms = {
    yearn = "ao_yearn_process_id",
    convex = "ao_convex_process_id"
  },
  oracles = {
    price_feed = "ao_oracle_price_feed_id",
    chainlink = "ao_chainlink_oracle_id"
  }
}

-- Track protocol interactions and responses
Protocols.pending_requests = {}
Protocols.protocol_responses = {}
Protocols.connection_status = {}

function Protocols.query_protocol(protocol, action, params)
  local protocol_id = Protocols.get_protocol_id(protocol)
  if not protocol_id then
    return false, "Protocol not found: " .. protocol
  end
  
  local request_id = Protocols.generate_request_id()
  local message_data = {
    RequestId = request_id,
    Action = action,
    Timestamp = os.time(),
    Requester = ao.id
  }
  
  -- Add parameters to message data
  if params then
    for key, value in pairs(params) do
      message_data[key] = value
    end
  end
  
  -- Send message to protocol
  ao.send({
    Target = protocol_id,
    Action = action,
    Data = message_data
  })
  
  -- Track pending request
  Protocols.pending_requests[request_id] = {
    protocol = protocol,
    action = action,
    params = params,
    timestamp = os.time(),
    protocol_id = protocol_id
  }
  
  return true, request_id
end

function Protocols.get_protocol_id(protocol_name)
  -- Navigate nested protocol_ids structure
  for category, protocols in pairs(Protocols.protocol_ids) do
    if type(protocols) == "table" then
      if protocols[protocol_name] then
        return protocols[protocol_name]
      end
    elseif category == protocol_name then
      return protocols
    end
  end
  return nil
end

function Protocols.generate_request_id()
  return "req_" .. os.time() .. "_" .. math.random(1000, 9999)
end

-- AstroUSD Integration Functions
function Protocols.mint_usda(amount, collateral_type)
  collateral_type = collateral_type or "AR"
  
  local success, request_id = Protocols.query_protocol("astro_usd", "Mint-USDA", {
    Amount = tostring(amount),
    CollateralType = collateral_type,
    SlippageTolerance = "0.01"
  })
  
  if success then
    ao.log("USDA mint request sent: " .. request_id .. " for " .. amount .. " " .. collateral_type)
  end
  
  return success, request_id
end

function Protocols.stake_usda(amount)
  local success, request_id = Protocols.query_protocol("astro_usd", "Stake-USDA", {
    Amount = tostring(amount),
    StakingPool = "main"
  })
  
  if success then
    ao.log("USDA staking request sent: " .. request_id .. " for " .. amount .. " USDA")
  end
  
  return success, request_id
end

function Protocols.get_usda_yield()
  local success, request_id = Protocols.query_protocol("astro_usd", "Get-Staking-APY", {})
  return success, request_id
end

function Protocols.bridge_assets(asset, amount, destination_chain)
  local success, request_id = Protocols.query_protocol("astro_usd", "Bridge-Assets", {
    Asset = asset,
    Amount = tostring(amount),
    DestinationChain = destination_chain,
    BridgeType = "quantum"
  })
  
  if success then
    ao.log("Bridge request sent: " .. request_id .. " for " .. amount .. " " .. asset .. " to " .. destination_chain)
  end
  
  return success, request_id
end

-- Lending Protocol Functions
function Protocols.lend_asset(protocol, asset, amount)
  local success, request_id = Protocols.query_protocol(protocol, "Lend-Asset", {
    Asset = asset,
    Amount = tostring(amount),
    InterestMode = "variable"
  })
  
  return success, request_id
end

function Protocols.borrow_asset(protocol, asset, amount, collateral)
  local success, request_id = Protocols.query_protocol(protocol, "Borrow-Asset", {
    Asset = asset,
    Amount = tostring(amount),
    Collateral = collateral,
    CollateralizationRatio = "150" -- 150% collateralization
  })
  
  return success, request_id
end

function Protocols.get_lending_rates(protocol)
  local success, request_id = Protocols.query_protocol(protocol, "Get-Lending-Rates", {})
  return success, request_id
end

-- DEX Functions
function Protocols.swap_tokens(dex, from_token, to_token, amount, min_output)
  local success, request_id = Protocols.query_protocol(dex, "Swap-Tokens", {
    FromToken = from_token,
    ToToken = to_token,
    Amount = tostring(amount),
    MinOutput = tostring(min_output or 0),
    Deadline = tostring(os.time() + 300) -- 5 minute deadline
  })
  
  return success, request_id
end

function Protocols.add_liquidity(dex, token_a, token_b, amount_a, amount_b)
  local success, request_id = Protocols.query_protocol(dex, "Add-Liquidity", {
    TokenA = token_a,
    TokenB = token_b,
    AmountA = tostring(amount_a),
    AmountB = tostring(amount_b),
    SlippageTolerance = "0.01"
  })
  
  return success, request_id
end

function Protocols.remove_liquidity(dex, lp_token, amount)
  local success, request_id = Protocols.query_protocol(dex, "Remove-Liquidity", {
    LPToken = lp_token,
    Amount = tostring(amount)
  })
  
  return success, request_id
end

function Protocols.get_pool_info(dex, token_a, token_b)
  local success, request_id = Protocols.query_protocol(dex, "Get-Pool-Info", {
    TokenA = token_a,
    TokenB = token_b
  })
  
  return success, request_id
end

-- Yield Farming Functions
function Protocols.enter_farm(protocol, farm_id, asset, amount)
  local success, request_id = Protocols.query_protocol(protocol, "Enter-Farm", {
    FarmId = farm_id,
    Asset = asset,
    Amount = tostring(amount)
  })
  
  return success, request_id
end

function Protocols.exit_farm(protocol, farm_id, amount)
  local success, request_id = Protocols.query_protocol(protocol, "Exit-Farm", {
    FarmId = farm_id,
    Amount = tostring(amount or "all")
  })
  
  return success, request_id
end

function Protocols.claim_rewards(protocol, farm_id)
  local success, request_id = Protocols.query_protocol(protocol, "Claim-Rewards", {
    FarmId = farm_id
  })
  
  return success, request_id
end

function Protocols.get_farm_info(protocol)
  local success, request_id = Protocols.query_protocol(protocol, "Get-Farm-Info", {})
  return success, request_id
end

-- Oracle Functions (REAL 0rbit Integration)
function Protocols.get_price(asset)
  -- Use real 0rbit oracle message format
  local success, request_id = Protocols.query_protocol("price_feed", "Get-Token-Price", {
    Token = asset
  })
  
  return success, request_id
end

function Protocols.get_multiple_prices(assets)
  -- Get prices for multiple assets from 0rbit
  local requests = {}
  for _, asset in ipairs(assets) do
    local success, request_id = Protocols.get_price(asset)
    if success then
      table.insert(requests, {asset = asset, request_id = request_id})
    end
  end
  
  return requests
end

-- Response Handlers
function Protocols.handle_protocol_response(msg)
  if not msg.Data or not msg.Data.RequestId then
    return false
  end
  
  local request_id = msg.Data.RequestId
  local pending_request = Protocols.pending_requests[request_id]
  
  if not pending_request then
    return false
  end
  
  -- Store response
  Protocols.protocol_responses[request_id] = {
    request = pending_request,
    response = msg.Data,
    timestamp = os.time(),
    success = msg.Data.Success ~= "false"
  }
  
  -- Remove from pending
  Protocols.pending_requests[request_id] = nil
  
  -- Handle specific response types
  Protocols.process_specific_response(pending_request, msg.Data)
  
  return true
end

function Protocols.process_specific_response(request, response_data)
  local action = request.action
  local protocol = request.protocol
  
  if action == "Get-Price" then
    Protocols.handle_price_response(response_data)
  elseif action == "Get-Staking-APY" then
    Protocols.handle_yield_response(response_data)
  elseif action == "Mint-USDA" then
    Protocols.handle_mint_response(response_data)
  elseif action == "Swap-Tokens" then
    Protocols.handle_swap_response(response_data)
  elseif action == "Get-Lending-Rates" then
    Protocols.handle_lending_rates_response(response_data)
  elseif action == "Get-Farm-Info" then
    Protocols.handle_farm_info_response(response_data)
  end
end

function Protocols.handle_price_response(data)
  if data.Asset and data.Price then
    ao.log("Price update: " .. data.Asset .. " = $" .. data.Price)
    -- This would typically update the portfolio module
    -- portfolio.handle_price_update({Data = data})
  end
end

function Protocols.handle_yield_response(data)
  if data.APY then
    ao.log("USDA staking APY: " .. data.APY .. "%")
  end
end

function Protocols.handle_mint_response(data)
  if data.Success == "true" and data.Amount then
    ao.log("Successfully minted " .. data.Amount .. " USDA")
  else
    ao.log("USDA mint failed: " .. (data.Error or "Unknown error"))
  end
end

function Protocols.handle_swap_response(data)
  if data.Success == "true" then
    ao.log("Swap completed: " .. (data.AmountOut or "unknown") .. " tokens received")
  else
    ao.log("Swap failed: " .. (data.Error or "Unknown error"))
  end
end

function Protocols.handle_lending_rates_response(data)
  if data.LendingRates then
    ao.log("Lending rates received for " .. (data.Protocol or "unknown protocol"))
  end
end

function Protocols.handle_farm_info_response(data)
  if data.Farms then
    ao.log("Farm info received: " .. (data.FarmCount or "0") .. " farms available")
  end
end

-- Protocol Health Monitoring
function Protocols.check_protocol_health(protocol)
  local protocol_id = Protocols.get_protocol_id(protocol)
  if not protocol_id then
    return false, "Protocol not found"
  end
  
  local success, request_id = Protocols.query_protocol(protocol, "Health-Check", {})
  return success, request_id
end

function Protocols.get_protocol_status()
  local status = {}
  
  for category, protocols in pairs(Protocols.protocol_ids) do
    status[category] = {}
    
    if type(protocols) == "table" then
      for protocol_name, protocol_id in pairs(protocols) do
        status[category][protocol_name] = {
          id = protocol_id,
          connected = Protocols.connection_status[protocol_id] or false,
          last_response = Protocols.get_last_response_time(protocol_id)
        }
      end
    end
  end
  
  return status
end

function Protocols.get_last_response_time(protocol_id)
  local last_time = 0
  
  for request_id, response in pairs(Protocols.protocol_responses) do
    if response.request.protocol_id == protocol_id and response.timestamp > last_time then
      last_time = response.timestamp
    end
  end
  
  return last_time
end

-- Utility Functions
function Protocols.cleanup_old_requests()
  local current_time = os.time()
  local cleanup_threshold = 3600 -- 1 hour
  
  -- Clean up old pending requests
  for request_id, request in pairs(Protocols.pending_requests) do
    if current_time - request.timestamp > cleanup_threshold then
      Protocols.pending_requests[request_id] = nil
    end
  end
  
  -- Clean up old responses (keep last 100)
  local response_count = 0
  for _ in pairs(Protocols.protocol_responses) do
    response_count = response_count + 1
  end
  
  if response_count > 100 then
    -- Remove oldest responses
    local responses_by_time = {}
    for request_id, response in pairs(Protocols.protocol_responses) do
      table.insert(responses_by_time, {id = request_id, time = response.timestamp})
    end
    
    table.sort(responses_by_time, function(a, b) return a.time < b.time end)
    
    -- Remove oldest 20
    for i = 1, 20 do
      if responses_by_time[i] then
        Protocols.protocol_responses[responses_by_time[i].id] = nil
      end
    end
  end
end

function Protocols.get_interaction_summary()
  local summary = {
    pending_requests = 0,
    completed_responses = 0,
    successful_responses = 0,
    recent_activity = {}
  }
  
  -- Count pending requests
  for _ in pairs(Protocols.pending_requests) do
    summary.pending_requests = summary.pending_requests + 1
  end
  
  -- Count responses
  for request_id, response in pairs(Protocols.protocol_responses) do
    summary.completed_responses = summary.completed_responses + 1
    if response.success then
      summary.successful_responses = summary.successful_responses + 1
    end
    
    -- Add to recent activity if within last hour
    if os.time() - response.timestamp < 3600 then
      table.insert(summary.recent_activity, {
        protocol = response.request.protocol,
        action = response.request.action,
        success = response.success,
        timestamp = response.timestamp
      })
    end
  end
  
  summary.success_rate = summary.completed_responses > 0 and 
    (summary.successful_responses / summary.completed_responses) or 0
  
  return summary
end

-- Protocols module loaded globally
