-- risk.lua
-- ML-based risk scoring and VaR calculations using aolearn
Risk = {}

Risk.risk_score = 0
Risk.var = 0
Risk.protocol_scores = {}

-- Risk thresholds and configurations
Risk.config = {
  var_confidence = 0.95,
  lookback_period = 30,
  high_risk_threshold = 0.8,
  medium_risk_threshold = 0.5,
  max_position_size = 0.3, -- Max 30% in any single asset
  correlation_threshold = 0.7 -- High correlation warning
}

function Risk.assess(portfolio)
  local risk_metrics = {}
  
  -- Calculate VaR
  risk_metrics.var = Risk.calculate_var(portfolio)
  
  -- Calculate portfolio concentration risk
  risk_metrics.concentration_risk = Risk.calculate_concentration_risk(portfolio)
  
  -- Calculate correlation risk
  risk_metrics.correlation_risk = Risk.calculate_correlation_risk(portfolio)
  
  -- Calculate overall risk score (weighted combination)
  risk_metrics.risk_score = Risk.calculate_overall_risk(risk_metrics)
  
  -- Store results
  Risk.risk_score = risk_metrics.risk_score
  Risk.var = risk_metrics.var
  
  return risk_metrics
end

function Risk.calculate_var(portfolio)
  if not portfolio.history or #portfolio.history < Risk.config.lookback_period then
    return 0
  end
  
  local returns = {}
  local history = portfolio.history
  
  -- Calculate daily returns from portfolio history
  for i = 2, math.min(#history, Risk.config.lookback_period + 1) do
    local current_value = history[i].total_value or 0
    local previous_value = history[i-1].total_value or 1
    
    if previous_value > 0 then
      local daily_return = (current_value - previous_value) / previous_value
      table.insert(returns, daily_return)
    end
  end
  
  if #returns < 5 then
    return 0
  end
  
  -- Sort returns for VaR calculation
  table.sort(returns)
  
  -- Calculate VaR at specified confidence level
  local var_index = math.floor((1 - Risk.config.var_confidence) * #returns)
  var_index = math.max(1, var_index)
  
  Risk.var = math.abs(returns[var_index])
  return Risk.var
end

function Risk.calculate_concentration_risk(portfolio)
  if not portfolio.assets then
    return 0
  end
  
  local total_value = 0
  local asset_values = {}
  
  -- Calculate total portfolio value and individual asset values
  for symbol, asset in pairs(portfolio.assets) do
    local value = (asset.value or 0)
    total_value = total_value + value
    asset_values[symbol] = value
  end
  
  if total_value <= 0 then
    return 0
  end
  
  -- Calculate concentration risk (Herfindahl index)
  local herfindahl = 0
  local max_concentration = 0
  
  for symbol, value in pairs(asset_values) do
    local weight = value / total_value
    herfindahl = herfindahl + (weight * weight)
    max_concentration = math.max(max_concentration, weight)
  end
  
  -- Risk score based on concentration (0-1 scale)
  local concentration_risk = 0
  if max_concentration > Risk.config.max_position_size then
    concentration_risk = concentration_risk + 0.5
  end
  
  -- Add Herfindahl-based risk (higher concentration = higher risk)
  concentration_risk = concentration_risk + (herfindahl - (1 / table.getn(asset_values))) * 2
  
  return math.min(1, concentration_risk)
end

function Risk.calculate_correlation_risk(portfolio)
  -- Simplified correlation risk - would need price correlation data in practice
  -- For now, return low risk if portfolio is diversified across asset classes
  if not portfolio.assets then
    return 0
  end
  
  local asset_classes = {}
  for symbol, _ in pairs(portfolio.assets) do
    if string.find(symbol, "USD") or string.find(symbol, "DAI") then
      asset_classes.stablecoin = true
    elseif symbol == "AR" or symbol == "ETH" or symbol == "BTC" then
      asset_classes.crypto = true
    else
      asset_classes.defi = true
    end
  end
  
  local class_count = 0
  for _, _ in pairs(asset_classes) do
    class_count = class_count + 1
  end
  
  -- Lower risk with more asset class diversification
  return math.max(0, 1 - (class_count / 3))
end

function Risk.calculate_overall_risk(risk_metrics)
  -- Weighted combination of risk factors
  local weights = {
    var = 0.4,
    concentration = 0.3,
    correlation = 0.3
  }
  
  local overall_risk = 
    (risk_metrics.var or 0) * weights.var +
    (risk_metrics.concentration_risk or 0) * weights.concentration +
    (risk_metrics.correlation_risk or 0) * weights.correlation
  
  return math.min(1, overall_risk)
end

function Risk.assess_protocol_risk(protocol_id, protocol_data)
  local risk_factors = {
    tvl_score = Risk.calculate_tvl_score(protocol_data.tvl),
    audit_score = Risk.calculate_audit_score(protocol_data.audits),
    community_score = Risk.calculate_community_score(protocol_data.community),
    technical_score = Risk.calculate_technical_score(protocol_data.technical)
  }
  
  -- Weighted protocol risk score
  local protocol_risk = 
    risk_factors.tvl_score * 0.3 +
    risk_factors.audit_score * 0.4 +
    risk_factors.community_score * 0.15 +
    risk_factors.technical_score * 0.15
  
  Risk.protocol_scores[protocol_id] = {
    overall_score = protocol_risk,
    factors = risk_factors,
    last_updated = os.time()
  }
  
  return protocol_risk
end

function Risk.calculate_tvl_score(tvl)
  -- Higher TVL = lower risk (up to a point)
  if not tvl or tvl <= 0 then return 0 end
  
  if tvl > 1000000000 then -- > $1B
    return 0.9
  elseif tvl > 100000000 then -- > $100M
    return 0.7
  elseif tvl > 10000000 then -- > $10M
    return 0.5
  else
    return 0.2
  end
end

function Risk.calculate_audit_score(audits)
  if not audits then return 0.1 end
  
  local score = 0
  if audits.major_firms and audits.major_firms > 0 then
    score = score + 0.5
  end
  if audits.bug_bounty then
    score = score + 0.2
  end
  if audits.time_since_last and audits.time_since_last < 365 then
    score = score + 0.3
  end
  
  return math.min(1, score)
end

function Risk.calculate_community_score(community)
  if not community then return 0.3 end
  
  local score = 0
  if community.github_stars and community.github_stars > 1000 then
    score = score + 0.3
  end
  if community.discord_members and community.discord_members > 10000 then
    score = score + 0.3
  end
  if community.active_developers and community.active_developers > 10 then
    score = score + 0.4
  end
  
  return math.min(1, score)
end

function Risk.calculate_technical_score(technical)
  if not technical then return 0.3 end
  
  local score = 0
  if technical.uptime and technical.uptime > 0.99 then
    score = score + 0.4
  end
  if technical.response_time and technical.response_time < 1000 then
    score = score + 0.3
  end
  if technical.security_incidents == 0 then
    score = score + 0.3
  end
  
  return math.min(1, score)
end

function Risk.get_risk_recommendation(risk_score)
  if risk_score > Risk.config.high_risk_threshold then
    return {
      action = "reduce_risk",
      message = "High risk detected. Consider rebalancing to safer assets.",
      suggested_allocation = {
        stablecoins = 0.5,
        bluechip = 0.3,
        defi = 0.2
      }
    }
  elseif risk_score > Risk.config.medium_risk_threshold then
    return {
      action = "moderate_risk",
      message = "Moderate risk. Monitor closely.",
      suggested_allocation = {
        stablecoins = 0.3,
        bluechip = 0.4,
        defi = 0.3
      }
    }
  else
    return {
      action = "low_risk",
      message = "Low risk. Portfolio allocation is appropriate.",
      suggested_allocation = nil
    }
  end
end

-- Integration with aolearn (placeholder for ML models)
function Risk.ml_risk_prediction(portfolio, market_data)
  -- Placeholder for aolearn integration
  -- This would use machine learning models to predict risk
  -- based on portfolio composition and market conditions
  
  -- Example structure:
  -- local model = aolearn.load_model("risk_assessment_v1")
  -- local features = Risk.extract_features(portfolio, market_data)
  -- local prediction = model:predict(features)
  -- return prediction
  
  return Risk.risk_score -- Return current risk score as fallback
end

function Risk.extract_features(portfolio, market_data)
  -- Extract features for ML model
  local features = {
    portfolio_size = portfolio.metrics.total_value or 0,
    diversification = table.getn(portfolio.assets or {}),
    volatility = portfolio.metrics.volatility or 0,
    returns = portfolio.metrics.returns or 0,
    market_volatility = market_data.volatility or 0,
    market_trend = market_data.trend or 0
  }
  
  return features
end

-- Risk module loaded globally
