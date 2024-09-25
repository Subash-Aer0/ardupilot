-- Simple Lua script to control a rover in ArduPilot SITL


local MAV_SEVERITY = {EMERGENCY=0, ALERT=1, CRITICAL=2, ERROR=3, WARNING=4, NOTICE=5, INFO=6, DEBUG=7}

-- Check if the script is running on a rover
local vehicle_type = assert(param:get("SYSID_THISMAV"))
if not (vehicle_type == 17) then -- 2 is the vehicle type for rover
    local text = "Error: This script is for rovers only!" .. tostring(vehicle_type)
    gcs:send_text(6, text)
    return
else
    gcs:send_text(MAV_SEVERITY.INFO, "Executing ship lua script!")
end

-- Set target speed (m/s) and steering
local target_speed = 2 -- 2 m/s forward
local target_steering = 0 -- Straight line

-- Function to send velocity commands
function update()
    -- Create a movement command
    local cmd = {
        speed = target_speed,
        turn = target_steering,
        throttle = target_speed > 0 and 100 or -100
    }

    local vel = Vector3f()
    vel:x(5.0)
    vel:y(0)
    vel:z(0)

    -- Send the movement command to the rover
    vehicle:set_target_velocity_NED(vel)

    -- Send feedback to GCS
    gcs:send_text(6, string.format("Speed: %.2f m/s, Steering: %.2f", target_speed, target_steering))
end

-- Schedule the function to run at 10Hz
-- return update:register(move_rover, 100)
-- wrapper around update(). This calls update() at 20Hz,
-- and if update faults then an error is displayed, but the script is not
-- stopped
function protected_wrapper()
    local success, err = pcall(update)
    if not success then
       gcs:send_text(MAV_SEVERITY.ERROR, "Internal Error: " .. err)
       -- when we fault we run the update function again after 1s, slowing it
       -- down a bit so we don't flood the console with errors
       return protected_wrapper, 1000
    end
    return protected_wrapper, 50
  end
  
  -- start running update loop
  return protected_wrapper()
