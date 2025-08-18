-- randao.lua
-- RandAO Integration for Randomized Portfolio Management
-- Process ID: SjvsFtgngd6PyOJDzmZ3a4wbkP5LGFGAZ6hqOkYoSPo

RandAO = {}

-- RandAO process ID (real mainnet address)
RandAO.process_id = "SjvsFtgngd6PyOJDzmZ3a4wbkP5LGFGAZ6hqOkYoSPo"

-- Randomness state
RandAO.state = {
  last_random_value = nil,
  last_request_time = 0,
  pending_requests = {},
  randomness_history = {}
}

-- Request randomness from RandAO
function RandAO.request_random(purpose, min_val, max_val)
  min_val = min_val or 1
  max_val = max_val or 100
  
  local request_id = "rand_" .. purpose .. "_" .. tostring(os.time())
  
  -- Send randomness request to RandAO
  ao.log("RandAO: Sending request to " .. RandAO.process_id)
  Send({
    Target = RandAO.process_id,
    Action = "Get-Random",
    Data = {
      request_id = request_id,
      purpose = purpose,
      min = min_val,
      max = max_val,
      requester = ao.id,
      timestamp = os.time()
    }
  })
  
  -- Track pending request
  RandAO.state.pending_requests[request_id] = {
    purpose = purpose,
    min = min_val,
    max = max_val,
    timestamp = os.time()
  }
  
  -- For demo purposes, also generate local fallback randomness
  -- This ensures the demo works even if RandAO service has delays
  local fallback_random = math.random(min_val, max_val)
  
  -- Immediately simulate response for demo (remove this in production)
  RandAO.simulate_response(request_id, fallback_random)
  
  ao.log("RandAO: Requested randomness for " .. purpose .. " (fallback: " .. fallback_random .. ")")
  return request_id
end

-- Enhanced rebalancing with randomness to prevent MEV attacks
function RandAO.randomized_rebalance_strategy()
  -- Request randomness for rebalancing
  local rand_delay = RandAO.request_random("rebalance_delay", 1, 60) -- 1-60 minute delay
  local rand_order = RandAO.request_random("execution_order", 1, 1000) -- Order randomization
  
  -- Create randomized execution strategy
  local strategy = {
    purpose = "anti_mev_rebalancing",
    delay_request = rand_delay,
    order_request = rand_order,
    created_at = os.time(),
    
    -- Default values (will be updated when randomness arrives)
    random_delay = 30, -- Default 30 minutes
    execution_order = {},
    anti_mev_enabled = true
  }
  
  return strategy
end

-- Randomized yield strategy selection
function RandAO.randomized_yield_selection(available_strategies)
  if not available_strategies or #available_strategies == 0 then
    return nil
  end
  
  -- Request randomness for yield strategy selection
  local max_index = #available_strategies
  local request_id = RandAO.request_random("yield_selection", 1, max_index)
  
  local selection = {
    purpose = "yield_strategy_diversification",
    available_count = max_index,
    request_id = request_id,
    strategies = available_strategies,
    randomness_factor = "pending",
    
    -- Default fallback selection
    default_selection = available_strategies[1]
  }
  
  return selection
end

-- Randomized portfolio rebalancing intervals
function RandAO.randomized_rebalance_interval()
  -- Add randomness to rebalancing timing to prevent predictable patterns
  local base_interval = config.rebalance_interval or 3600 -- 1 hour default
  local variance_request = RandAO.request_random("interval_variance", -600, 600) -- ±10 minutes
  
  return {
    base_interval = base_interval,
    variance_request = variance_request,
    purpose = "unpredictable_timing",
    next_rebalance = "calculated_on_randomness_arrival"
  }
end

-- Randomized asset allocation within target ranges
function RandAO.randomized_allocation_adjustment(target_allocations)
  local randomized_allocations = {}
  
  for asset, target_percentage in pairs(target_allocations) do
    -- Add small random variance to target allocations (±2%)
    local variance_request = RandAO.request_random("allocation_" .. asset, -2, 2)
    
    randomized_allocations[asset] = {
      target = target_percentage,
      variance_request = variance_request,
      min_allocation = math.max(0.05, target_percentage - 0.02),
      max_allocation = math.min(0.95, target_percentage + 0.02)
    }
  end
  
  return randomized_allocations
end

-- Simulate RandAO response for demo purposes
function RandAO.simulate_response(request_id, random_value)
  -- This simulates what would happen when RandAO responds
  local fake_msg = {
    From = RandAO.process_id,
    Data = {
      request_id = request_id,
      random_value = tostring(random_value)
    }
  }
  
  RandAO.handle_randomness_response(fake_msg)
  ao.log("RandAO: Simulated response for demo - value: " .. random_value)
end

-- Handle RandAO responses
function RandAO.handle_randomness_response(msg)
  if msg.From == RandAO.process_id and msg.Data then
    local request_id = msg.Data.request_id
    local random_value = tonumber(msg.Data.random_value)
    
    if request_id and random_value then
      -- Store randomness
      RandAO.state.last_random_value = random_value
      RandAO.state.last_request_time = os.time()
      
      -- Add to history
      table.insert(RandAO.state.randomness_history, {
        request_id = request_id,
        value = random_value,
        timestamp = os.time()
      })
      
      -- Process based on purpose
      local pending = RandAO.state.pending_requests[request_id]
      if pending then
        RandAO.process_randomness_for_purpose(pending.purpose, random_value, pending)
        RandAO.state.pending_requests[request_id] = nil
      end
      
      ao.log("RandAO: Received randomness: " .. tostring(random_value) .. " for " .. tostring(request_id))
    end
  end
end

-- Process randomness based on its intended purpose
function RandAO.process_randomness_for_purpose(purpose, random_value, request_info)
  if string.find(purpose, "rebalance_delay") then
    -- Use randomness for rebalancing delay
    local delay_minutes = math.floor(random_value % 60) + 1
    agent_state.next_rebalance_delay = delay_minutes
    ao.log("RandAO: Next rebalance delayed by " .. delay_minutes .. " minutes")
    
  elseif string.find(purpose, "execution_order") then
    -- Use randomness for trade execution order
    agent_state.trade_execution_seed = random_value
    ao.log("RandAO: Trade execution order randomized with seed " .. random_value)
    
  elseif string.find(purpose, "yield_selection") then
    -- Use randomness for yield strategy selection
    if Yield and Yield.available_strategies then
      local strategy_count = #Yield.available_strategies
      local selected_index = (random_value % strategy_count) + 1
      agent_state.selected_yield_strategy = Yield.available_strategies[selected_index]
      ao.log("RandAO: Selected yield strategy " .. selected_index .. " via randomness")
    end
    
  elseif string.find(purpose, "interval_variance") then
    -- Use randomness for interval variance
    local variance_seconds = (random_value % 1200) - 600 -- ±10 minutes
    agent_state.rebalance_interval_variance = variance_seconds
    ao.log("RandAO: Rebalance interval variance: " .. variance_seconds .. " seconds")
    
  elseif string.find(purpose, "allocation_") then
    -- Use randomness for allocation adjustments
    local asset = string.gsub(purpose, "allocation_", "")
    local variance_percentage = ((random_value % 4) - 2) / 100 -- ±2%
    
    if not agent_state.randomized_allocations then
      agent_state.randomized_allocations = {}
    end
    agent_state.randomized_allocations[asset] = variance_percentage
    ao.log("RandAO: " .. asset .. " allocation variance: " .. (variance_percentage * 100) .. "%")
  end
end

-- Generate immediate randomness for demo purposes
function RandAO.generate_demo_randomness()
  ao.log("RandAO: Generating demo randomness...")
  
  -- Generate some sample random requests
  local demo_requests = {
    {purpose = "rebalance_delay", min = 1, max = 60},
    {purpose = "execution_order", min = 1, max = 1000},
    {purpose = "yield_selection", min = 1, max = 5},
    {purpose = "allocation_AR", min = -2, max = 2},
    {purpose = "interval_variance", min = -600, max = 600}
  }
  
  for _, req in ipairs(demo_requests) do
    RandAO.request_random(req.purpose, req.min, req.max)
  end
  
  ao.log("RandAO: Demo randomness generation complete")
end

-- Get randomness statistics
function RandAO.get_randomness_stats()
  local pending_count = 0
  for _ in pairs(RandAO.state.pending_requests) do
    pending_count = pending_count + 1
  end
  
  return {
    total_requests = #RandAO.state.randomness_history,
    last_random_value = RandAO.state.last_random_value,
    last_request_time = RandAO.state.last_request_time,
    pending_requests = pending_count,
    randomness_enabled = true,
    process_id = RandAO.process_id
  }
end

-- Initialize RandAO message handler
Handlers.add(
  "RandAOResponse",
  Handlers.utils.hasMatchingTag("Action", "Random-Response"),
  RandAO.handle_randomness_response
)

-- Also handle direct responses from RandAO process
Handlers.add(
  "RandAODirectResponse", 
  function(msg)
    return msg.From == RandAO.process_id
  end,
  RandAO.handle_randomness_response
)

ao.log("RandAO integration loaded - Process: " .. RandAO.process_id)
