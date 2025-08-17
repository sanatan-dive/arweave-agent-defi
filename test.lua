-- test.lua
-- Quick test to verify agent initialization

function test_agent()
  print("=== AO DeFi Portfolio Manager Agent Test ===")
  
  -- Check if config loaded
  if config then
    print("✓ Config loaded: " .. config.version)
  else
    print("✗ Config not loaded")
    return false
  end
  
  -- Check if modules loaded
  local modules = {"Portfolio", "Risk", "Yield", "Rebalance", "Protocols"}
  for _, module_name in ipairs(modules) do
    if _G[module_name] then
      print("✓ " .. module_name .. " module loaded")
    else
      print("✗ " .. module_name .. " module not loaded")
      return false
    end
  end
  
  -- Test agent initialization
  if initialize_agent then
    print("✓ Agent initialization function found")
    initialize_agent()
    if agent_state.initialized then
      print("✓ Agent successfully initialized")
    else
      print("✗ Agent initialization failed")
      return false
    end
  else
    print("✗ Agent initialization function not found")
    return false
  end
  
  print("=== All tests passed! Agent is ready ===")
  return true
end
