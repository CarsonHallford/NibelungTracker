local frame = CreateFrame("Frame")
local iconPath = "Interface\\AddOns\\NibelungTracker\\Textures\\VALKYR.blp"
local summonSpellID = 71844 -- Spell ID for Nibelung's Val'kyr Guardian summoning
local activeValkyrs = 0
local valkyrGUIDs = {} -- This table holds all the currently tracked Val'kyr entities, using their GUIDs as keys.

-- Val'kyr Icon
local iconFrame = CreateFrame("Frame", "ValkyrIconFrame", UIParent) -- Create new frame as a child of UIParent.
iconFrame:SetFrameStrata("HIGH")
iconFrame:SetWidth(64)
iconFrame:SetHeight(64)
iconFrame:SetPoint("CENTER")
iconFrame:EnableMouse(true) -- Allows frame to receive mouse events (clicks and drags).
iconFrame:SetMovable(true) -- Allows frame to be movable.
iconFrame:SetClampedToScreen(true) -- Ensures frame cannot be dragged off screen.

local cooldown = CreateFrame("Cooldown", nil, iconFrame, "CooldownFrameTemplate") -- Frame for displaying cooldown spiral.
cooldown:SetAllPoints(iconFrame) -- Sets cooldown frame to occupy all of the space inside its parent frame (iconFrame), making it the same size and position.
cooldown:SetDrawEdge(false) -- Disables drawing of cooldown edge. The edge is a bright light that shows on the border of the spiral.
cooldown:SetDrawSwipe(true) -- Enables the drawing of the cooldown swipe.
cooldown:SetSwipeColor(0, 0, 0, 0.8) -- Sets color and transparency of the cooldown swipe to black with 80% opacity.

-- Controls the visibility of the iconFrame based on the number of active Val'kyrs.
local function UpdateIconVisibility()
    if activeValkyrs > 0 then -- Checks if the current number of active Val'kyrs is greater than zero.
        iconFrame:Show() -- If there are active Val'kyrs, then the icon will be displayed.
    else -- If there are not active Val'kyrs.
        iconFrame:Hide() -- The icon will not be displayed.
    end
end

-- Initializing the cooldown effect on the iconFrame.
local function StartCooldown()
    cooldown:SetCooldown(GetTime(), 30) -- Calls SetCooldown method on the 'cooldown' frame with the current time and a duration of 30 sec.
end

local function ShowIcon()
    iconFrame:Show() -- Calls Show method on iconFrame, making the frame visible on the UI.
    StartCooldown() -- Calls StartCooldown from above to begin the cooldown animation on the iconFrame.
end

-- Script handler for "OnMouseDown" event on iconFrame
iconFrame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then -- Checks if the left mouse button was pressed.
        self:StartMoving() -- Calls StartMoving on the frame, allowing it to be moved.
        self.isMoving = true -- Sets an isMoving flag to true, indicating the frame is in the process of moving.
    end
end)

-- Script handler for "OnMouseUp" event on iconFrame
iconFrame:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" then -- Checks if the left mouse button was pressed.
        self:StopMovingOrSizing() -- Stops any moving or sizing action that was taking place.
        self.isMoving = false -- Resets the isMoving flag to false.
    end
end)

-- Script handler for "OnHide" event on iconFrame
iconFrame:SetScript("OnHide", function(self)
    if self.isMoving then -- Checks if the frame is currently flagged as moving.
        self:StopMovingOrSizing() -- Ensures that moving or sizing stops if the frame is hidden mid-move.
        self.isMoving = false -- Resets the isMoving flag to false.
    end
end)

-- Resize iconFrame based on a given scale factor
local function ResizeIcon(scale)
    iconFrame:SetWidth(64 * scale)
    iconFrame:SetHeight(64 * scale)
end

-- Assigns custom slash command '/valkyr' to SLASH_VALKYR1
SLASH_VALKYR1 = '/valkyr'

-- Function to handle different possible command inputs after '/valkyr'
local function SlashCmd(cmd)
    if cmd:lower() == 'lock' then -- Converts command to lowercase and checks if it's 'lock'
        iconFrame:EnableMouse(false) -- Disables mouse commands with the iconFrame
        iconFrame:Hide() -- Hides the iconFrame
        print("Val'kyr icon locked.") -- Outputs a message to the chat confirming the icon is locked

    elseif cmd:lower() == 'unlock' then -- Converts command to lowercase and checks if its 'unlock'
        iconFrame:EnableMouse(true) -- Enables mouse commands with the iconFrame
        iconFrame:Show() -- Show the icon when it's unlocked for moving
        print("Val'kyr icon unlocked. You can move it now.") -- Outputs a message to the chat confirming the icon can be moved


    elseif cmd:lower() == 'scale' then -- Converts command to lowercase and checks if it's 'scale'
        iconFrame:Show() -- Shows the icon
        iconFrame:EnableMouse(true) -- Enables mouse commands with the iconFrame
        iconFrame:EnableMouseWheel(true) -- Enables the mouse wheel input
        -- Sets a script to handle mouse wheel scrolling for resizing
        iconFrame:SetScript("OnMouseWheel", function(self, delta)
            local newSize = self:GetWidth() + (delta * 5) -- Calculates the new size based on scroll input
            ResizeIcon(newSize / 64) -- Calls the ResizeIcon function with the new scale
        end)
        print("Scroll to resize the Val'kyr icon.") -- Outputs a message informing player how to resize the icon
    
    elseif cmd:lower() == 'show' then -- Converts command to lowercase and checks if it's 'show'
        iconFrame:Show() -- Shows the icon

    else -- If none of the above commands match, it prints usage instructions and available commands to the player.
        print("Commands:\n")
        print("/valkyr unlock: Shows valkyr icon and allows for manuverability of the icon.\n")
        print("/valkyr lock: Locks the valkyr icon in position.\n")
        print("/valkyr show: Displays the valkyr icon.\n")
        print("Valkyr scale: Adjusts scale of the valkyr icon with your scrollwheel.\n")
    end
end

SlashCmdList["VALKYR"] = SlashCmd -- Registers the function SlashCmd to the '/valkyr' slash command

-- New texture created for iconFrame, which is the container the icon
local iconTexture = iconFrame:CreateTexture(nil, "ARTWORK")
iconTexture:SetAllPoints(iconFrame) -- Sets newly created texture to cover the entire area of its parent frame (iconFrame)
iconTexture:SetTexture(iconPath) -- Applies texture image to the iconTexture. 
iconFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0) -- Default placement will be center of player's screen until it has been moved.
iconFrame:Hide() -- Hides the icon until it is triggered by an event or command.

-- Updates the counting element of the Val'kyr icon displayed in game.
local function UpdateCounterDisplay()
    if not iconFrame.counter then -- Checks if the iconFrame does not already have a counter element.
        iconFrame.counter = iconFrame:CreateFontString(nil, "OVERLAY") -- If not, a FontString (UI Element that can display text) is created. 
        iconFrame.counter:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE") -- Sets font to standard WoW font and outlined for better readability.
        iconFrame.counter:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -5, 5) -- Anchors the counter to the bottom right of the icon.
    end
    iconFrame.counter:SetText(activeValkyrs) -- Sets the text of the counter to the value of the global variable 'activeValkyrs' which is expected to hold the current number of active Valks.
end

-- Function to remove a Val'kyr from the current counter on the icon.
local function RemoveValkyr(guid) -- Takes a single parameter 'guid' which is expected to be a unique identifier for each Val'kyr entity being tracked.
    if valkyrGUIDs[guid] then -- Checks if 'guid' is present in the 'valkyrGUIDs' table declared at the beginning.
        valkyrGUIDs[guid] = nil -- If Val'kyr 'guid' is found, it's removed from the table. Setting it to 'nil', removing it.
        activeValkyrs = math.max(activeValkyrs - 1, 0) -- Decrements the count of 'activeValkyrs', ensuring it does not go below 0.
        UpdateIconVisibility() -- Calls function responsible for showing/hiding the icon based on if activeValkyr > 0.
        UpdateCounterDisplay() -- Function is called to update the numerical display that indicated number of Valkys alive.
    end
end

-- Function is called when a new Val'kyr entity appears and needs to be tracked.
local function SummonValkyr(guid) -- Accepts a single parameter 'guid', representing the unique identifier for a Val'kyr
    if not valkyrGUIDs[guid] then -- Checks if 'guid' provided is not already present in the 'valkyrGUIDs' table. If 'guid' is NOT present, it proceeds.
        valkyrGUIDs[guid] = true -- Adds the 'guid' to the 'valkyrGUIDs' table and sets its value to 'true', indicating that the valkyr is now being tracked.
        activeValkyrs = activeValkyrs + 1 -- Increments the amount of active Valks by 1 since a new Valk has appeared.
        UpdateIconVisibility() -- Calls function responsible for showing/hiding the icon based on if activeValkyr > 0.
        UpdateCounterDisplay() -- Function is called to update the numerical display that indicated number of Valkys alive.
        ShowIcon() -- Ensures that the icon is shown
        C_Timer.After(30, function() -- Schedules a function to be called after 30 seconds (duration of a Valk)
            if valkyrGUIDs[guid] then -- Checks if the Valk with this 'guid' is still being tracked
                print("A Val'kyr Guardian has despawned.") -- Outputs a message to the chat confirming that a valk has been despawned
                RemoveValkyr(guid) -- Calls the RemoveValkyr function to remove this Valk from tracking.
            end
        end)
    end
end

frame:RegisterEvent("PLAYER_LOGIN") -- Registers frame to listen for the "PLAYER_LOGIN" event, when the player logs in.
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED") -- Registers frame to listen for any combat-related action.
frame:SetScript("OnEvent", function(self, event, ...) -- Anonymous function to handle events whenever they occur.
    if event == "PLAYER_LOGIN" then -- If player logs in then
        UpdateCounterDisplay() -- Call function to intialize current number of active valks
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then -- If combat-related action triggers this event then
        local timestamp, subevent, _, sourceGUID, _, _, _, destGUID, _, _, _, spellId = CombatLogGetCurrentEventInfo() -- Extracted variables contain detailed info about the combant event that occured.
        if subevent == "SPELL_SUMMON" and spellId == summonSpellID then -- Checks if subevent was a "SPELL_SUMMON" and if the spellID matches the ID of a valk summoning spell.
            local playerGUID = UnitGUID("player") -- Retrieves GUID for the player's character. Ensures addon only reacts to Valk guardians summoned by the player and not by other players.
            if sourceGUID == playerGUID then -- Checks whether the entity that cast the summon spell is the player themselves.
                print("Your Nibelung staff has summoned a Val'kyr Guardian!") -- Outputs a message to the chat that a Valk has spawned
                SummonValkyr(destGUID) -- Calls the 'SummonValkyr' function with the GUID of the summoned Val'kyr
            end
        elseif (subevent == "UNIT_DIED" or subevent == "SPELL_AURA_REMOVED") and valkyrGUIDs[destGUID] then -- Checks if the subevent is a unit death or a spell aura removal that invovles a Val'kyr being tracked
            RemoveValkyr(destGUID) -- If a tracked Valk has died or its aura has been removed, 'RemoveValkyr' is called to remove it from tracking.
        end
    end
end)
