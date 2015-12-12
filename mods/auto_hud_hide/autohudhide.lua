--[[
Copyright (c) 2015, Robert 'Bobby' Zenz
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]



--- A system which automatically hides hud items if there are no changes.
autohudhide = {
	--- If the healthbar should be automatically hidde.
	healthbar_autohide = settings.get_bool("autohudhide_healthbar_autohide", true),
	
	--- The delay after which the healthbar is hidden.
	healthbar_delay = settings.get_number("autohudhide_healthbar_delay", 5),
	
	--- If the hotbar should be automatically hidden.
	hotbar_autohide = settings.get_bool("autohudhide_hotbar_autohide", true),
	
	--- The delay after which the hotbar is hidden.
	hotbar_delay = settings.get_number("autohudhide_hotbar_delay", 3),
	
	--- The infos of players used for determining when to hide elements.
	infos = {}
}


--- Activates the system, if it has not been deactivated in the configuration
-- by settings autohudhide_activate to false.
function autohudhide.activate()
	if settings.get_bool("autohudhide_activate", true) then
		minetest.register_on_leaveplayer(autohudhide.remove_info)
		scheduler.schedule(
			"autohudhide",
			settings.get_number("autohudhide_interval", 0.1),
			autohudhide.run,
			scheduler.OVERSHOOT_POLICY_RUN_ONCE)
	end
end

--- Gets the info for the given player. If there is none, one will be created.
--
-- @param player The player for which to get the info.
-- @return The info object for the given player.
function autohudhide.get_info(player)
	local info = autohudhide.infos[player:get_player_name()]
	
	if info == nil then
		info = {
			hotbar_visible = true,
			last_hotbar_change = os.time()
		}
		autohudhide.infos[player:get_player_name()] = info
	end
	
	return info
end

--- Removes the info for the given player.
--
-- @param player The player for whom to remove the info.
function autohudhide.remove_info(player)
	autohudhide.infos[player:get_player_name()] = nil
end

--- Runs the update on all players.
function autohudhide.run()
	for key, player in pairs(minetest.get_connected_players()) do
		autohudhide.run_on_player(player)
	end
end

--- Runs the update on the given player.
--
-- @param player The player on which to run.
function autohudhide.run_on_player(player)
	local info = autohudhide.get_info(player)
	
	autohudhide.update_healthbar(player, info)
	autohudhide.update_hotbar(player, info)
end

--- Updates the status of the healthbar for the given player.
--
-- @param player The player which to update.
-- @param info The info for the player.
function autohudhide.update_healthbar(player, info)
	if autohudhide.healthbar_autohide then
		local current_health = player:get_hp()
		
		if info.health ~= current_health then
			info.health = current_health
			info.healthbar_visible = true
			info.last_health_change = os.time()
			
			player:hud_set_flags({ healthbar = true })
		elseif info.healthbar_visible and (os.time() - info.last_health_change) >= autohudhide.healthbar_delay then
			info.healthbar_visible = false
			
			player:hud_set_flags({ healthbar = false })
		end
	end
end

--- Updates the status of the hotbar for the given player.
--
-- @param player The player which to update.
-- @param info The info for the player.
function autohudhide.update_hotbar(player, info)
	if autohudhide.hotbar_autohide then
		local current_wield_item = player:get_wielded_item():to_string()
		local current_wield_item_index = player:get_wield_index()
		
		if info.wield_item ~= current_wield_item
			or info.wield_item_index ~= current_wield_item_index then
			
			info.hotbar_visible = true
			info.last_wield_item_change = os.time()
			info.wield_item = current_wield_item
			info.wield_item_index = current_wield_item_index
			
			player:hud_set_flags({ hotbar = true })
		elseif info.hotbar_visible and (os.time() - info.last_wield_item_change) >= autohudhide.hotbar_delay then
			info.hotbar_visible = false
			
			player:hud_set_flags({ hotbar = false })
		end
	end
end

