wrk.headers["Content-Type"] = "application/json"

-- possible values for WRK_TEST_NAME: ["mix", "request-id", "metrics", "health"]
wrk_test_name = os.getenv("WRK_TEST_NAME") or 'mix'


-- The main request function
function request()
  local method, endpoint = choose_endpoint(wrk_test_name)
  local payload = generate_payload(endpoint, next_player_id)
  --io.stderr:write(string.format("method: %s, endpoint: %s, payload: %s\n", method, endpoint, payload))
  return wrk.format(method, endpoint, nil, payload)
end

-- Function to randomly select an endpoint + method
function choose_endpoint(test_name)
  local weighted_endpoints = {}
  weighted_endpoints["request-id"] = {50, "POST", "/v1/request-id"}
  weighted_endpoints["metrics"] = {5, "GET", "/_status/metrics"}
  weighted_endpoints["health"] = {10, "GET", "/v1/health"}


  if (test_name == "request-id") or  
     (test_name == "metrics") or
     (test_name == "health")
  then
    _, method, url = unpack(weighted_endpoints[test_name])
    return method, url
  elseif test_name == "mix" then
    local total_weight = 0
    local weight_hash = {}
    for key, test_info in pairs(weighted_endpoints) do
        local curr_weight = test_info[1]
        weight_hash[key] = {total_weight + 1, total_weight + curr_weight}
        total_weight = total_weight + curr_weight
    end
    -- generate random number to use it for choosing method by 
    -- weight later
    random_num = math.random(1, total_weight)
    for key, weight_info in pairs(weight_hash) do
        min_num, max_num = unpack(weight_info)
        if (random_num >= min_num) and (random_num <= max_num) then
            _, method, url = unpack(weighted_endpoints[key])
            return method, url
        end
    end
    error("Logic error with weight, check the code above!")
  else
    error("Wrong wrk_test_name: " .. wrk_test_name)
  end
end

-- Function to generate a payload based on the selected endpoint
function generate_payload(endpoint, player_id)
   if endpoint == "/v1/request-id" then
      return "{}"
   else
      return ""
   end
end
