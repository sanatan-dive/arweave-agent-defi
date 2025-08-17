-- portfolio.lua
-- Tracks portfolio composition, returns, volatility, and history
Portfolio = {}

Portfolio.portfolio = {
  assets = {},
  history = {},
  metrics = {
    returns = 0,
    volatility = 0,
    sharpe_ratio = 0,
    total_value = 0
  }
}

-- Oracle addresses for price feeds (to be configured)
Portfolio.oracle_addresses = {
  AR = "oracle_ar_process_id",
  USDA = "oracle_usda_process_id",
  ETH = "oracle_eth_process_id",
  BTC = "oracle_btc_process_id"
}

function Portfolio.update_asset(symbol, amount, price)
  if not Portfolio.portfolio.assets[symbol] then
    Portfolio.portfolio.assets[symbol] = {}
  end
  Portfolio.portfolio.assets[symbol].amount = amount or Portfolio.portfolio.assets[symbol].amount or 0
  Portfolio.portfolio.assets[symbol].price = price or Portfolio.portfolio.assets[symbol].price or 0
  Portfolio.portfolio.assets[symbol].value = Portfolio.portfolio.assets[symbol].amount * Portfolio.portfolio.assets[symbol].price
  Portfolio.portfolio.assets[symbol].last_updated = os.time()
end

function Portfolio.update_prices_from_oracles(oracle_addresses)
  for symbol, oracle_id in pairs(oracle_addresses or Portfolio.oracle_addresses) do
    if Portfolio.portfolio.assets[symbol] then
      -- Send message to oracle for current price
      ao.send({
        Target = oracle_id,
        Action = "Get-Price",
        Data = { Symbol = symbol }
      })
    end
  end
end

function Portfolio.record_history()
  local snapshot = {
    timestamp = os.time(),
    assets = {},
    total_value = Portfolio.calculate_total_value()
  }
  
  -- Deep copy current assets
  for symbol, asset in pairs(Portfolio.portfolio.assets) do
    snapshot.assets[symbol] = {
      amount = asset.amount,
      price = asset.price,
      value = asset.value
    }
  end
  
  table.insert(Portfolio.portfolio.history, snapshot)
  
  -- Keep only last 100 records to manage memory
  if #Portfolio.portfolio.history > 100 then
    table.remove(Portfolio.portfolio.history, 1)
  end
end

function Portfolio.calculate_total_value()
  local total = 0
  for symbol, asset in pairs(Portfolio.portfolio.assets) do
    total = total + (asset.value or 0)
  end
  Portfolio.portfolio.metrics.total_value = total
  return total
end

function Portfolio.calculate_returns()
  if #Portfolio.portfolio.history < 2 then
    return 0
  end
  
  local current_value = Portfolio.calculate_total_value()
  local previous_value = Portfolio.portfolio.history[#Portfolio.portfolio.history - 1].total_value
  
  if previous_value > 0 then
    Portfolio.portfolio.metrics.returns = (current_value - previous_value) / previous_value
  end
  
  return Portfolio.portfolio.metrics.returns
end

function Portfolio.calculate_volatility()
  if #Portfolio.portfolio.history < 10 then
    return 0
  end
  
  local returns = {}
  for i = 2, #Portfolio.portfolio.history do
    local current = Portfolio.portfolio.history[i].total_value
    local previous = Portfolio.portfolio.history[i-1].total_value
    if previous > 0 then
      table.insert(returns, (current - previous) / previous)
    end
  end
  
  if #returns < 2 then
    return 0
  end
  
  -- Calculate mean
  local mean = 0
  for _, ret in ipairs(returns) do
    mean = mean + ret
  end
  mean = mean / #returns
  
  -- Calculate variance
  local variance = 0
  for _, ret in ipairs(returns) do
    variance = variance + (ret - mean)^2
  end
  variance = variance / (#returns - 1)
  
  Portfolio.portfolio.metrics.volatility = math.sqrt(variance)
  return Portfolio.portfolio.metrics.volatility
end

function Portfolio.calculate_sharpe_ratio(risk_free_rate)
  risk_free_rate = risk_free_rate or 0.02 -- Default 2% annual risk-free rate
  local returns = Portfolio.portfolio.metrics.returns
  local volatility = Portfolio.portfolio.metrics.volatility
  
  if volatility > 0 then
    Portfolio.portfolio.metrics.sharpe_ratio = (returns - risk_free_rate) / volatility
  else
    Portfolio.portfolio.metrics.sharpe_ratio = 0
  end
  
  return Portfolio.portfolio.metrics.sharpe_ratio
end

function Portfolio.calculate_metrics()
  Portfolio.calculate_total_value()
  Portfolio.calculate_returns()
  Portfolio.calculate_volatility()
  Portfolio.calculate_sharpe_ratio()
  
  return Portfolio.portfolio.metrics
end

function Portfolio.get_allocation_percentages()
  local total_value = Portfolio.calculate_total_value()
  local allocations = {}
  
  if total_value > 0 then
    for symbol, asset in pairs(Portfolio.portfolio.assets) do
      allocations[symbol] = (asset.value or 0) / total_value
    end
  end
  
  return allocations
end

function Portfolio.initialize_portfolio(initial_assets)
  for symbol, data in pairs(initial_assets or {}) do
    Portfolio.update_asset(symbol, data.amount, data.price)
  end
  Portfolio.record_history()
end

-- Handle oracle price responses
function Portfolio.handle_price_update(msg)
  if msg.Action == "Price-Response" and msg.Data.Symbol and msg.Data.Price then
    local symbol = msg.Data.Symbol
    local price = tonumber(msg.Data.Price)
    
    if Portfolio.portfolio.assets[symbol] then
      Portfolio.update_asset(symbol, Portfolio.portfolio.assets[symbol].amount, price)
    end
  end
end
