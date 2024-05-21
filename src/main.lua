---@meta _
---@diagnostic disable

-- grabbing our dependencies,
-- these funky (---@) comments are just there
--	 to help VS Code find the definitions of things

---@diagnostic disable-next-line: undefined-global
local mods = rom.mods

---@module 'SGG_Modding-ENVY-auto'
mods['SGG_Modding-ENVY'].auto()
-- ^ this gives us `public` and `import`, among others
--	and makes all globals we define private to this plugin.
---@diagnostic disable: lowercase-global

---@diagnostic disable-next-line: undefined-global
rom = rom
---@diagnostic disable-next-line: undefined-global
_PLUGIN = PLUGIN

---@module 'SGG_Modding-Hades2GameDef-Globals'
game = rom.game

---@module 'SGG_Modding-ModUtil'
modutil = mods['SGG_Modding-ModUtil']

---@module 'SGG_Modding-Chalk'
chalk = mods["SGG_Modding-Chalk"]
---@module 'SGG_Modding-ReLoad'
reload = mods['SGG_Modding-ReLoad']

---@module 'config'
config = chalk.auto()
-- ^ this updates our config.toml in the config folder!
public.config = config -- so other mods can access our config

local function on_ready()
    -- what to do when we are ready, but not re-do on reload.
    if config.enabled == false then return end

    function public.DeactivateAllArcana(screen)
        local components = game.ScreenAnchors.MetaUpgradeScreen.Components or {}
        for k, v in pairs(components) do
            if string.match(k, 'MetaUpgrade$') then
                -- generate a fake "button" to appease functions that want one
                local button = { Id = v.Id, CardName = v.CardName, CardState = "UNLOCKED" }
                local cardState = game.GameState.MetaUpgradeState[v.CardName]

                -- if cost not 0 and card was equipped
                if game.MetaUpgradeCardData[v.CardName].Cost ~= 0 and cardState.Equipped ~= nil and cardState.Equipped == true then
                    game.MetaUpgradeCardAction(screen, button)
                    cardState.Equipped = nil
                    game.UnequipMetaUpgradeCardPresentation(screen, button)
                    game.UpdateMetaUpgradeCardAnimation(button)
                end
                game.SessionState["MetaUpgradeChanges"] = { HasChanged = true }
                game.RecordMetaUpgradeChanges(screen)
            end
        end
    end

    local ResetAllButton =
    {
        Graphic = "ContextualActionButton",
        GroupName = "Combat_Menu_Overlay",
        Data =
        {
            OnMouseOverFunctionName = "MouseOverContextualAction",
            OnMouseOffFunctionName = "MouseOffContextualAction",
            OnPressedFunctionName = public.DeactivateAllArcana,
            ControlHotkeys = { "Reroll", },
        },
        Text = "{RR} DEACTIVATE ALL",
        TextArgs = game.UIData.ContextualButtonFormatRight,
    }

    table.insert(game.ScreenData.MetaUpgradeCardLayout.ComponentData.ActionBar.ChildrenOrder, "ResetAllButton")
    game.ScreenData.MetaUpgradeCardLayout.ComponentData.ActionBar.Children["ResetAllButton"] = ResetAllButton
end

local function on_reload()

end

-- this allows us to limit certain functions to not be reloaded.
local loader = reload.auto_single()

-- this runs only when modutil and the game's lua is ready
modutil.on_ready_final(function()
    loader.load(on_ready, on_reload)
end)
