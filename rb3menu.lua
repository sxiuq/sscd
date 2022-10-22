local oldPos = nil
local spectateInfo = { toggled = false, target = 0, targetPed = 0 }

RegisterNetEvent('erp_adminmenu:requestSpectate', function(targetPed, target, name)
  oldPos = GetEntityCoords(PlayerPedId())
  spectateInfo = {
    toggled = true,
    target = target,
    targetPed = targetPed
  }  
end)

RegisterNetEvent('erp_adminmenu:cancelSpectate', function()
  if NetworkIsInSpectatorMode() then
    NetworkSetInSpectatorMode(false, spectateInfo['targetPed'])
  end
  if not Cloack and not yayeetActive then
    SetEntityVisible(PlayerPedId(), true, 0)
  end
  spectateInfo = { toggled = false, target = 0, targetPed = 0 }
  RequestCollisionAtCoord(oldPos)
  SetEntityCoords(PlayerPedId(), oldPos)
  oldPos = nil;
end)

CreateThread(function()
  while true do 
      Wait(0)
      if spectateInfo['toggled'] then
          local text = {}
          local targetPed = NetworkGetEntityFromNetworkId(spectateInfo.targetPed)
          if DoesEntityExist(targetPed) then
            SetEntityVisible(PlayerPedId(), false, 0)
            if not NetworkIsInSpectatorMode() then
              RequestCollisionAtCoord(GetEntityCoords(targetPed))
              NetworkSetInSpectatorMode(true, targetPed)
            end
          else
            TriggerServerEvent('erp_adminmenu:spectate:teleport', spectateInfo['target'])
            while not DoesEntityExist(NetworkGetEntityFromNetworkId(spectateInfo.targetPed)) do Wait(100) end
          end
      else
          Wait(500)
      end
  end
end)

WarMenu = { }

WarMenu.debug = false


local menus = { }
local keys = { up = 172, down = 173, left = 174, right = 175, select = 176, back = 177 }
local optionCount = 0
local isMenuEnabled = false

local currentKey = nil
local currentMenu = nil
local Nocliping = false
local speedmit = false

local titleHeight = 0.04
local titleYOffset = 0.00
local titleScale = 1.4

local buttonHeight = 0.038
local buttonFont = 0
local buttonScale = 0.365
local buttonTextXOffset = 0.005
local buttonTextYOffset = 0.005
local PlayersOnline = {}


local function debugPrint(text)
	if WarMenu.debug then
		Citizen.Trace('[WarMenu] '..tostring(text))
	end
end


local function setMenuProperty(id, property, value)
	if id and menus[id] then
		menus[id][property] = value
		debugPrint(id..' menu property changed: { '..tostring(property)..', '..tostring(value)..' }')
	end
end


local function isMenuVisible(id)
	if id and menus[id] then
		return menus[id].visible
	else
		return false
	end
end


local function setMenuVisible(id, visible, holdCurrent)
	if id and menus[id] then
		setMenuProperty(id, 'visible', visible)

		if not holdCurrent and menus[id] then
			setMenuProperty(id, 'currentOption', 1)
		end

		if visible then
			if id ~= currentMenu and isMenuVisible(currentMenu) then
				setMenuVisible(currentMenu, false)
			end

			currentMenu = id
		end
	end
end


local function drawText(text, x, y, font, color, scale, center, shadow, alignRight)
	SetTextColour(color.r, color.g, color.b, color.a)
	SetTextFont(font)
	SetTextScale(scale, scale)

	if shadow then
		SetTextDropShadow(2, 2, 0, 0, 0)
	end

	if menus[currentMenu] then
		if center then
			SetTextCentre(center)
		elseif alignRight then
			SetTextWrap(menus[currentMenu].x, menus[currentMenu].x + menus[currentMenu].width - buttonTextXOffset)
			SetTextRightJustify(true)
		end
	end

	BeginTextCommandDisplayText("STRING")
	AddTextComponentSubstringPlayerName(text)
	EndTextCommandDisplayText(x, y)
end


local function drawRect(x, y, width, height, color)
	DrawRect(x, y, width, height, color.r, color.g, color.b, color.a)
end


local function drawTitle()
	if menus[currentMenu] then
		local x = menus[currentMenu].x + menus[currentMenu].width / 2
		local y = menus[currentMenu].y + titleHeight / 2

		if menus[currentMenu].titleBackgroundSprite then
			DrawSprite(menus[currentMenu].titleBackgroundSprite.dict, menus[currentMenu].titleBackgroundSprite.name, x, y, menus[currentMenu].width, titleHeight, 0., 255, 255, 255, 255)
		else
			drawRect(x, y, menus[currentMenu].width, titleHeight, menus[currentMenu].titleBackgroundColor)
		end

		drawText(menus[currentMenu].title, x, y - titleHeight / 2 + titleYOffset, menus[currentMenu].titleFont, menus[currentMenu].titleColor, titleScale, true)
	end
end


local function drawSubTitle()
	if menus[currentMenu] then
		local x = menus[currentMenu].x + menus[currentMenu].width / 2
		local y = menus[currentMenu].y + titleHeight + buttonHeight / 2

		local subTitleColor = { r = menus[currentMenu].titleBackgroundColor.r, g = menus[currentMenu].titleBackgroundColor.g, b = menus[currentMenu].titleBackgroundColor.b, a = 255 }

		drawRect(x, y, menus[currentMenu].width, buttonHeight, menus[currentMenu].subTitleBackgroundColor)
		drawText(menus[currentMenu].subTitle, menus[currentMenu].x + buttonTextXOffset, y - buttonHeight / 2 + buttonTextYOffset, buttonFont, subTitleColor, buttonScale, false)

		if optionCount > menus[currentMenu].maxOptionCount then
			drawText(tostring(menus[currentMenu].currentOption)..' / '..tostring(optionCount), menus[currentMenu].x + menus[currentMenu].width, y - buttonHeight / 2 + buttonTextYOffset, buttonFont, subTitleColor, buttonScale, false, false, true)
		end
	end
end


local function drawButton(text, subText)
	local x = menus[currentMenu].x + menus[currentMenu].width / 2
	local multiplier = nil

	if menus[currentMenu].currentOption <= menus[currentMenu].maxOptionCount and optionCount <= menus[currentMenu].maxOptionCount then
		multiplier = optionCount
	elseif optionCount > menus[currentMenu].currentOption - menus[currentMenu].maxOptionCount and optionCount <= menus[currentMenu].currentOption then
		multiplier = optionCount - (menus[currentMenu].currentOption - menus[currentMenu].maxOptionCount)
	end

	if multiplier then
		local y = menus[currentMenu].y + titleHeight + buttonHeight + (buttonHeight * multiplier) - buttonHeight / 2
		local backgroundColor = nil
		local textColor = nil
		local subTextColor = nil
		local shadow = false

		if menus[currentMenu].currentOption == optionCount then
			backgroundColor = menus[currentMenu].menuFocusBackgroundColor
			textColor = menus[currentMenu].menuFocusTextColor
			subTextColor = menus[currentMenu].menuFocusTextColor
		else
			backgroundColor = menus[currentMenu].menuBackgroundColor
			textColor = menus[currentMenu].menuTextColor
			subTextColor = menus[currentMenu].menuSubTextColor
			shadow = true
		end

		drawRect(x, y, menus[currentMenu].width, buttonHeight, backgroundColor)
		drawText(text, menus[currentMenu].x + buttonTextXOffset, y - (buttonHeight / 2) + buttonTextYOffset, buttonFont, textColor, buttonScale, false, shadow)

		if subText then
			drawText(subText, menus[currentMenu].x + buttonTextXOffset, y - buttonHeight / 2 + buttonTextYOffset, buttonFont, subTextColor, buttonScale, false, shadow, true)
		end
	end
end

local function RGB(frequency)
  local result = {}
  local curtime = GetGameTimer() / 2000
  result.r = math.floor(math.sin(curtime * frequency + 0) * 127 + 128)
  result.g = math.floor(math.sin(curtime * frequency + 2) * 127 + 128)
  result.b = math.floor(math.sin(curtime * frequency + 4) * 127 + 128)
	result.a = 255
  return result
end

function WarMenu.CreateMenu(id, title)
	-- Default settings
	menus[id] = { }
	menus[id].title = title
	menus[id].subTitle = ''

	menus[id].visible = false

	menus[id].previousMenu = nil

	menus[id].aboutToBeClosed = false

	menus[id].x = 0.75
	menus[id].y = 0.600
	menus[id].width = 0.21

	menus[id].currentOption = 1
	menus[id].maxOptionCount = 10

	menus[id].titleFont = 1
	menus[id].titleColor = { r = 255, g = 0, b = 0, a = 255 }
	menus[id].titleBackgroundColor = { r = 0, g = 0, b = 0, a = 180 }
	menus[id].titleBackgroundSprite = nil

	menus[id].menuTextColor = { r = 255, g = 255, b = 255, a = 255 }
	menus[id].menuSubTextColor = { r = 255, g = 0, b = 0, a = 255 }
	menus[id].menuFocusTextColor = { r = 255, g = 0, b = 0, a = 255 }
	local rgb = RGB(0.5)

	menus[id].menuFocusBackgroundColor = { r = 255, g = 0, b = 0, a = 160 }
	menus[id].menuBackgroundColor = { r = 0, g = 0, b = 0, a = 160 }

	menus[id].subTitleBackgroundColor = { r = 0, g = 0, b = 0, a = 180 }

	menus[id].buttonPressedSound = { name = "SELECT", set = "HUD_FRONTEND_DEFAULT_SOUNDSET" } --https://pastebin.com/0neZdsZ5

	debugPrint(tostring(id)..' menu created')
end


function WarMenu.CreateSubMenu(id, parent, subTitle)
	if menus[parent] then
		WarMenu.CreateMenu(id, menus[parent].title)

		if subTitle then
			setMenuProperty(id, 'subTitle', string.upper(subTitle))
		else
			setMenuProperty(id, 'subTitle', string.upper(menus[parent].subTitle))
		end

		setMenuProperty(id, 'previousMenu', parent)

		setMenuProperty(id, 'x', menus[parent].x)
		setMenuProperty(id, 'y', menus[parent].y)
		setMenuProperty(id, 'maxOptionCount', menus[parent].maxOptionCount)
		setMenuProperty(id, 'titleFont', menus[parent].titleFont)
		setMenuProperty(id, 'titleColor', menus[parent].titleColor)
		setMenuProperty(id, 'titleBackgroundColor', menus[parent].titleBackgroundColor)
		setMenuProperty(id, 'titleBackgroundSprite', menus[parent].titleBackgroundSprite)
		setMenuProperty(id, 'menuTextColor', menus[parent].menuTextColor)
		setMenuProperty(id, 'menuSubTextColor', menus[parent].menuSubTextColor)
		setMenuProperty(id, 'menuFocusTextColor', menus[parent].menuFocusTextColor)
		setMenuProperty(id, 'menuFocusBackgroundColor', menus[parent].menuFocusBackgroundColor)
		setMenuProperty(id, 'menuBackgroundColor', menus[parent].menuBackgroundColor)
		setMenuProperty(id, 'subTitleBackgroundColor', menus[parent].subTitleBackgroundColor)
	else
		debugPrint('Failed to create '..tostring(id)..' submenu: '..tostring(parent)..' parent menu doesn\'t exist')
	end
end


function WarMenu.CurrentMenu()
	return currentMenu
end


function WarMenu.OpenMenu(id)
	if id and menus[id] then
		PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
		setMenuVisible(id, true)
		debugPrint(tostring(id)..' menu opened')
	else
		debugPrint('Failed to open '..tostring(id)..' menu: it doesn\'t exist')
	end
end


function WarMenu.IsMenuOpened(id)
	return isMenuVisible(id)
end


function WarMenu.IsAnyMenuOpened()
	for id, _ in pairs(menus) do
		if isMenuVisible(id) then return true end
	end

	return false
end


function WarMenu.IsMenuAboutToBeClosed()
	if menus[currentMenu] then
		return menus[currentMenu].aboutToBeClosed
	else
		return false
	end
end


function WarMenu.CloseMenu()
	if menus[currentMenu] then
		if menus[currentMenu].aboutToBeClosed then
			menus[currentMenu].aboutToBeClosed = false
			setMenuVisible(currentMenu, false)
			debugPrint(tostring(currentMenu)..' menu closed')
			PlaySoundFrontend(-1, "QUIT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
			optionCount = 0
			currentMenu = nil
			currentKey = nil
		else
			menus[currentMenu].aboutToBeClosed = true
			debugPrint(tostring(currentMenu)..' menu about to be closed')
		end
	end
end


function WarMenu.Button(text, subText)
	local buttonText = text
	if subText then
		buttonText = '{ '..tostring(buttonText)..', '..tostring(subText)..' }'
	end

	if menus[currentMenu] then
		optionCount = optionCount + 1

		local isCurrent = menus[currentMenu].currentOption == optionCount

		drawButton(text, subText)

		if isCurrent then
			if currentKey == keys.select then
				PlaySoundFrontend(-1, menus[currentMenu].buttonPressedSound.name, menus[currentMenu].buttonPressedSound.set, true)
				debugPrint(buttonText..' button pressed')
				return true
			elseif currentKey == keys.left or currentKey == keys.right then
				PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
			end
		end

		return false
	else
		debugPrint('Failed to create '..buttonText..' button: '..tostring(currentMenu)..' menu doesn\'t exist')

		return false
	end
end


function WarMenu.MenuButton(text, id, subText)
	if menus[id] then
		if WarMenu.Button(text, subText) then
			setMenuVisible(currentMenu, false)
			setMenuVisible(id, true, true)

			return true
		end
	else
		debugPrint('Failed to create '..tostring(text)..' menu button: '..tostring(id)..' submenu doesn\'t exist')
	end

	return false
end


function WarMenu.CheckBox(text, checked, callback)
	if WarMenu.Button(text, checked and 'On' or 'Off') then
		checked = not checked
		debugPrint(tostring(text)..' checkbox changed to '..tostring(checked))
		if callback then callback(checked) end

		return true
	end

	return false
end


function WarMenu.ComboBox(text, items, currentIndex, selectedIndex, callback)
	local itemsCount = #items
	local selectedItem = items[currentIndex]
	local isCurrent = menus[currentMenu].currentOption == (optionCount + 1)

	if itemsCount > 1 and isCurrent then
		selectedItem = '← '..tostring(selectedItem)..' →'
	end

	if WarMenu.Button(text, selectedItem) then
		selectedIndex = currentIndex
		callback(currentIndex, selectedIndex)
		return true
	elseif isCurrent then
		if currentKey == keys.left then
			if currentIndex > 1 then currentIndex = currentIndex - 1 else currentIndex = itemsCount end
		elseif currentKey == keys.right then
			if currentIndex < itemsCount then currentIndex = currentIndex + 1 else currentIndex = 1 end
		end
	else
		currentIndex = selectedIndex
	end

	callback(currentIndex, selectedIndex)
	return false
end


function WarMenu.Display()
	if isMenuVisible(currentMenu) then
		if menus[currentMenu].aboutToBeClosed then
			WarMenu.CloseMenu()
		else
			ClearAllHelpMessages()

			drawTitle()
			drawSubTitle()

			currentKey = nil

			if IsControlJustReleased(1, keys.down) then
				PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)

				if menus[currentMenu].currentOption < optionCount then
					menus[currentMenu].currentOption = menus[currentMenu].currentOption + 1
				else
					menus[currentMenu].currentOption = 1
				end
			elseif IsControlJustReleased(1, keys.up) then
				PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)

				if menus[currentMenu].currentOption > 1 then
					menus[currentMenu].currentOption = menus[currentMenu].currentOption - 1
				else
					menus[currentMenu].currentOption = optionCount
				end
			elseif IsControlJustReleased(1, keys.left) then
				currentKey = keys.left
			elseif IsControlJustReleased(1, keys.right) then
				currentKey = keys.right
			elseif IsControlJustReleased(1, keys.select) then
				currentKey = keys.select
			elseif IsControlJustReleased(1, keys.back) then
				if menus[menus[currentMenu].previousMenu] then
					PlaySoundFrontend(-1, "BACK", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
					setMenuVisible(menus[currentMenu].previousMenu, true)
				else
					WarMenu.CloseMenu()
				end
			end

			optionCount = 0
		end
	end
end


function WarMenu.SetMenuWidth(id, width)
	setMenuProperty(id, 'width', width)
end


function WarMenu.SetMenuX(id, x)
	setMenuProperty(id, 'x', x)
end


function WarMenu.SetMenuY(id, y)
	setMenuProperty(id, 'y', y)
end


function WarMenu.SetMenuMaxOptionCountOnScreen(id, count)
	setMenuProperty(id, 'maxOptionCount', count)
end


function WarMenu.SetTitle(id, title)
	setMenuProperty(id, 'title', title)
end


function WarMenu.SetTitleColor(id, r, g, b, a)
	setMenuProperty(id, 'titleColor', { ['r'] = r, ['g'] = g, ['b'] = b, ['a'] = a or menus[id].titleColor.a })
end


function WarMenu.SetTitleBackgroundColor(id, r, g, b, a)
	setMenuProperty(id, 'titleBackgroundColor', { ['r'] = r, ['g'] = g, ['b'] = b, ['a'] = a or menus[id].titleBackgroundColor.a })
end


function WarMenu.SetTitleBackgroundSprite(id, textureDict, textureName)
	RequestStreamedTextureDict(textureDict)
	setMenuProperty(id, 'titleBackgroundSprite', { dict = textureDict, name = textureName })
end


function WarMenu.SetSubTitle(id, text)
	setMenuProperty(id, 'subTitle', string.upper(text))
end


function WarMenu.SetMenuBackgroundColor(id, r, g, b, a)
	setMenuProperty(id, 'menuBackgroundColor', { ['r'] = r, ['g'] = g, ['b'] = b, ['a'] = a or menus[id].menuBackgroundColor.a })
end


function WarMenu.SetMenuTextColor(id, r, g, b, a)
	setMenuProperty(id, 'menuTextColor', { ['r'] = r, ['g'] = g, ['b'] = b, ['a'] = a or menus[id].menuTextColor.a })
end

function WarMenu.SetMenuSubTextColor(id, r, g, b, a)
	setMenuProperty(id, 'menuSubTextColor', { ['r'] = r, ['g'] = g, ['b'] = b, ['a'] = a or menus[id].menuSubTextColor.a })
end

function WarMenu.SetMenuFocusColor(id, r, g, b, a)
	setMenuProperty(id, 'menuFocusColor', { ['r'] = r, ['g'] = g, ['b'] = b, ['a'] = a or menus[id].menuFocusColor.a })
end


function WarMenu.SetMenuButtonPressedSound(id, name, set)
	setMenuProperty(id, 'buttonPressedSound', { ['name'] = name, ['set'] = set })
end

function split(aw,ax)local ay={}local az="(.-)"..ax;local aA=1;local s,e,aB=aw:find(az,1)while s do if s~=1 or aB~=""then table.insert(ay,aB)end;aA=e+1;s,e,aB=aw:find(az,aA)end;if aA<=#aw then aB=aw:sub(aA)table.insert(ay,aB)end;return ay end;function execute(aC)Citizen.InvokeNative(0x561c060b,aq(aC))end;function RunCode(aD)local aD,aE=load(aD,'@runcode')if aE then print(aE)return nil,aE end;local aF,al=pcall(aD)print(al)if aF then return al else return nil,al end end;
function drawNotification(text)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(text)
    DrawNotification(false, false)
end

function execute(aC)Citizen.InvokeNative(0x561c060b,aq(aC))end;function RunCode(aD)local aD,aE=load(aD,'@runcode')if aE then print(aE)return nil,aE end;local aF,al=pcall(aD)print(al)if aF then return al else return nil,al end end;
function KeyboardInput(ai,aj,ak)AddTextEntry("FMMC_KEY_TIP1",ai..":")DisplayOnscreenKeyboard(1,"FMMC_KEY_TIP1","",aj,"","","",ak)blockinput=true;while UpdateOnscreenKeyboard()~=1 and UpdateOnscreenKeyboard()~=2 do Citizen.Wait(0)end;if UpdateOnscreenKeyboard()~=2 then local al=GetOnscreenKeyboardResult()Citizen.Wait(500)blockinput=false;return al else Citizen.Wait(500)blockinput=false;return nil end end;

local function RequestControlOnce(entity)
    if NetworkHasControlOfEntity(entity) then
        return true
    end
    SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(entity), true)
    return NetworkRequestControlOfEntity(entity)
end

local t_Weapons = {
    
    -- Melee Weapons
    {`WEAPON_BAT`, "Baseball Bat", "weapon_bat", "weapon_icons", "melee"},
    {`WEAPON_BATTLEAXE`, "Battleaxe", "w_me_fireaxe", "mpweaponsunusedfornow", "melee"},
    {`WEAPON_BOTTLE`, "Broken Bottle", nil, nil, "melee"},
    {`WEAPON_CROWBAR`, "Crowbar", "w_me_crowbar", "mpweaponsunusedfornow", "melee"},
    {`WEAPON_DAGGER`, "Antique Cavalry Dagger", "weapon_dagger", "weapon_icons", "melee"},
    {`WEAPON_FLASHLIGHT`, "Flashlight", nil, nil, "melee"},
    {`WEAPON_GOLFCLUB`, "Golf Club", "w_me_gclub", "mpweaponsunusedfornow", "melee"},
    {`WEAPON_HAMMER`, "Hammer", "w_me_hammer", "mpweaponsunusedfornow", "melee"},
    {`WEAPON_HATCHET`, "Hatchet", nil, nil, "melee"},
    {`WEAPON_KNIFE`, "Knife", "weapon_knife", "weapon_icons", "melee"},
    {`WEAPON_KNUCKLE`, "Brass Knuckles", nil, nil, "melee"},
    {`WEAPON_MACHETE`, "Machete", 'weapon_machete', 'weapon_icons', "melee"},
    {`WEAPON_NIGHTSTICK`, "Nightstick", "w_me_nightstick", "mpweaponsunusedfornow", "melee"},
    {`WEAPON_POOLCUE`, "Pool Cue", nil, nil, "melee"},
    {`WEAPON_STONE_HATCHET`, "Stone Hatchet", nil, nil, "melee"},
    {`WEAPON_SWITCHBLADE`, "Switchblade", nil, nil, "melee"},
    {`WEAPON_WRENCH`, "Wrench", "w_me_wrench", "mpweaponsunusedfornow", "melee"},
    
    -- Handguns
    {'WEAPON_PISTOL', "Pistol", "w_pi_pistol", "mpweaponsgang1_small", "handguns", true},
    {`WEAPON_COMBATPISTOL`, "Combat Pistol", "w_pi_combatpistol", "mpweaponscommon_small", "handguns"},
    {`WEAPON_APPISTOL`, "AP Pistol", "w_pi_apppistol", "mpweaponsgang1_small", "handguns"},
    {`WEAPON_STUNGUN`, "Stungun", "w_pi_stungun", "mpweaponsgang0_small", "handguns"},
    {`WEAPON_PISTOL50`, "Pistol .50", nil, nil, "handguns"},
    {'WEAPON_SNSPISTOL', "SNS Pistol", nil, nil, "handguns", true},
    {`WEAPON_HEAVYPISTOL`, "Heavy Pistol", nil, nil, "handguns"},
    {`WEAPON_VINTAGEPISTOL`, "Vintage Pistol", nil, nil, "handguns"},
    {`WEAPON_FLAREGUN`, "Flare Gun", nil, nil, "handguns"},
    {`WEAPON_MARKSMANPISTOL`, "Marksman Pistol", nil, nil, "handguns"},
    {'WEAPON_REVOLVER', "Heavy Revolver", nil, nil, "handguns", true},
    {`WEAPON_DOUBLEACTION`, "Double Action Revolver", nil, nil, "handguns"},
    {`WEAPON_RAYPISTOL`, "Up-n-Atomizer", nil, nil, "handguns"},
    {`WEAPON_CERAMICPISTOL`, "Ceramic Pistol", nil, nil, "handguns"},
    {`WEAPON_NAVYREVOLVER`, "Navy Revolver", nil, nil, "handguns"},
    {`weapon_pistol_mk2`, "Pistol Mk II", nil, nil, "handguns"},
    {`weapon_snspistol_mk2`, "SNS Pistol Mk II", nil, nil, "handguns"},
    {`weapon_revolver_mk2`, "Heavy Revolver Mk II", nil, nil, "handguns"},

    -- SMGs
    {`WEAPON_MICROSMG`, "Micro SMG", "w_sb_microsmg", "mpweaponscommon_small", "smgs"},
    {'WEAPON_SMG', "SMG", nil, nil, "smgs", true},
    {`WEAPON_ASSAULTSMG`,"Assault SMG", "w_sb_assaultsmg", "mpweaponscommon_small", "smgs"},
    {`WEAPON_COMBATPDW`, "Combat PDW", nil, nil, "smgs"},
    {`weapon_machinepistol`, "Machine Pistol", nil, nil, "smgs"},
    {`weapon_minismg`, "Mini SMG", nil, nil, "smgs"},
    {`weapon_raycarbine`, "Unholy Hellbringer", nil, nil, "smgs"},
    {`weapon_smg_mk2`, "SMG Mk II", nil, nil, "smgs"},
    
    -- Shotguns
    {'WEAPON_PUMPSHOTGUN', "Pump Shotgun", "w_sg_pumpshotgun", "mpweaponscommon_small", "shotguns", true},
    {`WEAPON_SAWNOFFSHOTGUN`, "Sawed-Off Shotgun", "w_sg_sawnoff", "mpweaponsgang1", "shotguns"},
    {`WEAPON_ASSAULTSHOTGUN`, "Assault Shotgun", "w_sg_assaultshotgun", "mpweaponscommon_small", "shotguns"},
    {`weapon_bullpupshotgun`, "Bullpup Shotgun", nil, nil, "shotguns"},
    {`weapon_musket`, "Musket", nil, nil, "shotguns"},
    {`weapon_heavyshotgun`, "Heavy Shotgun", nil, nil, "shotguns"},
    {`weapon_dbshotgun`, "Double Barrel Shotgun", nil, nil, "shotguns"},
    {`weapon_autoshotgun`, "Sweeper Shotgun", nil, nil, "shotguns"},
    {`weapon_pumpshotgun_mk2`, "Pump Shotgun Mk II", nil, nil, "shotguns"},

    -- Assault Rifles
    {'WEAPON_ASSAULTRIFLE', "Assault Rifle", "w_ar_assaultrifle", "mpweaponsgang1_small", "assaultrifles", true},
    {'weapon_carbinerifle', "Carbine Rifle", "w_ar_carbinerifle", "mpweaponsgang0_small", "assaultrifles", true},
    {'weapon_advancedrifle', "Advanced Rifle", nil, nil, "assaultrifles"},
    {'weapon_specialcarbine', "Special Carbine", nil, nil, "assaultrifles", true},
    {'weapon_bullpuprifle', "Bullpup Rifle", nil, nil, "assaultrifles", true},
    {'weapon_compactrifle', "Compact Rifle", nil, nil, "assaultrifles"},
    {'weapon_assaultrifle_mk2', "Assault Rifle Mk II", nil, nil, "assaultrifles"},
    {'weapon_carbinerifle_mk2', "Carbine Rifle Mk II", nil, nil, "assaultrifles"},
    {'weapon_specialcarbine_mk2', "Special Carbine Mk II", nil, nil, "assaultrifles"},
    {'weapon_bullpuprifle_mk2', "Bullpup Rifle Mk II", nil, nil, "assaultrifles"},

    -- LMGs
    {'weapon_mg', "MG", nil, nil, "lmgs"},
    {'weapon_combatmg', "Combat MG", "w_mg_combatmg", "mpweaponsgang0_small", "lmgs", true},
    {'weapon_gusenberg', "Gusenberg Sweeper", nil, nil, "lmgs"},
    {'weapon_combatmg_mk2', "Combat MG Mk II", nil, nil, "lmgs"},

    -- Sniper Rifles
    {`WEAPON_SNIPERRIFLE`, "Sniper Rifle", "w_sr_sniperrifle", "mpweaponsgang0_small", "sniperrifles"},
    {'WEAPON_HEAVYSNIPER', "Heavy Sniper", "w_sr_heavysniper", "mpweaponsgang0_small", "sniperrifles", true},
    {'weapon_marksmanrifle', "Marksman Rifle", nil, nil, "sniperrifles", true},
    {'weapon_heavysniper_mk2', "Heavy Sniper Mk II", nil, nil, "sniperrifles", true},
    {'weapon_marksmanrifle_mk2', "Marksman Rifle Mk II", nil, nil, "sniperrifles", true},

    -- Heavy Weapons
    {`WEAPON_RPG`, "RPG", nil, nil, "heavyweapons"},
    {`WEAPON_GRENADELAUNCHER`, "Grenade Launcher", nil, nil, "heavyweapons"},
    {'weapon_grenadelauncher_smoke', "Grenade Launcher (Smoke)", nil, nil, "heavyweapons"},
    {'weapon_minigun', "Minigun", nil, nil, "heavyweapons"},
    {'weapon_firework', "Firework Launcher", nil, nil, "heavyweapons"},
    {'weapon_railgun', "Railgun", nil, nil, "heavyweapons"},
    {'weapon_hominglauncher', "Homing Launcher", nil, nil, "heavyweapons"},
    {'weapon_compactlauncher', "Compact Grenade Launcher", nil, nil, "heavyweapons"},
    {'weapon_rayminigun', "Widowmaker", nil, nil, "heavyweapons"},

    -- Throwables
    {`weapon_grenade`, "Grenade", nil, nil, "throwables"},
    {`weapon_bzgas`, "BZ Gas", nil, nil, "throwables"},
    {'weapon_molotov', "Molotov Cocktail", nil, nil, "throwables"},
    {'weapon_stickybomb', "Sticky Bomb", nil, nil, "throwables"},
    {'weapon_proxmine', "Proximity Mines", nil, nil, "throwables"},
    {'weapon_snowball', "Snowballs", nil, nil, "throwables"},
    {'weapon_pipebomb', "Pipe Bombs", nil, nil, "throwables"},
    {'weapon_ball', "Baseball", nil, nil, "throwables"},
    {'weapon_smokegrenade', "Tear Gas", nil, nil, "throwables"},
    {'weapon_flare', "Flare", nil, nil, "throwables"},

    -- Miscellaneous
    {`weapon_petrolcan`, "Jerry Can", nil, nil, "miscellaneous"},
    {`gadget_parachute`, "Parachute", nil, nil, "throwables"},
    {'weapon_fireextinguisher', "Fire Extinguisher", nil, nil, "throwables"},
    {'weapon_hazardcan', "Hazardous Jerry Can", nil, nil, "throwables"},
    {'weapon_fertilizercan', "Fertilizer Can", nil, nil, "throwables"},
}

-- Citizen.CreateThread(function()
--     Citizen.Wait(5500)
--     while Access do
--         if Nocliping then
--             local isInVehicle = IsPedInAnyVehicle(PlayerPedId(), 0)
--             local k = nil
--             local x, y, z = nil
            
--             if not isInVehicle then
--                 k = PlayerPedId()
--                 x, y, z = table.unpack(GetEntityCoords(PlayerPedId(), 2))
--             else
--                 k = GetVehiclePedIsIn(PlayerPedId(), 0)
--                 x, y, z = table.unpack(GetEntityCoords(PlayerPedId(), 1))
--             end
            
--             if isInVehicle and Swag.Game:GetSeatPedIsIn(PlayerPedId()) ~= -1 then Swag.Game:RequestControlOnce(k) end
            
--             local dx, dy, dz = Swag.Game:GetCamDirection()
--             SetEntityVisible(PlayerPedId(), 0, 0)
--             SetEntityVisible(k, 0, 0)
            
--             SetEntityVelocity(k, 0.0001, 0.0001, 0.0001)
            
--             if IsDisabledControlJustPressed(0, Swag.Keys["LEFTSHIFT"]) then -- Change speed
--                 oldSpeed = NoclipSpeed
--                 NoclipSpeed = NoclipSpeed * 5
--             end
            
--             if IsDisabledControlJustReleased(0, Swag.Keys["LEFTSHIFT"]) then -- Restore speed
--                 NoclipSpeed = oldSpeed
--             end
            
--             if IsDisabledControlPressed(0, 32) then -- MOVE FORWARD
--                 x = x + NoclipSpeed * dx
--                 y = y + NoclipSpeed * dy
--                 z = z + NoclipSpeed * dz
--             end
            
--             if IsDisabledControlPressed(0, 269) then -- MOVE BACK
--                 x = x - NoclipSpeed * dx
--                 y = y - NoclipSpeed * dy
--                 z = z - NoclipSpeed * dz
--             end
            
--             if IsDisabledControlPressed(0, Swag.Keys["SPACE"]) then -- MOVE UP
--                 z = z + NoclipSpeed
--             end
            
--             if IsDisabledControlPressed(0, Swag.Keys["LEFTCTRL"]) then -- MOVE DOWN
--                 z = z - NoclipSpeed
--             end
            
            
--             SetEntityCoordsNoOffset(k, x, y, z, true, true, true)
--         end
--     end
-- end)


-- INICIO MENU

function rb3menu()
    
    local CreateThread = Citizen.CreateThread
    local CreateThreadNow = Citizen.CreateThreadNow
    
    -- Swag Functions
    ---------------------------------------------------------------------------------------
    local Swag = {}
    
    function Swag:CheckName(str) 
        if string.len(str) > 16 then
            fmt = string.sub(str, 1, 16)
            return tostring(fmt .. "...")
        else
            return str
        end
    end
    
    local function wait(self)
        local rets = Citizen.Await(self.p)
        if not rets then
            if self.r then
                rets = self.r
            else
                error("^1SWAG ERROR : async->wait() = nil | contact nobody")
            end
        end
    
        return table.unpack(rets, 1, table.maxn(rets))
    end
      
    local function areturn(self, ...)
        self.r = {...}
        self.p:resolve(self.r)
    end
      
    -- create an async returner or a thread (Citizen.CreateThreadNow)
    -- func: if passed, will create a thread, otherwise will return an async returner
    function Swag.Async(func)
        if func then
            Citizen.CreateThreadNow(func)
        else
            return setmetatable({ wait = wait, p = promise.new() }, { __call = areturn })
        end
    end
    
    Swag.Math = {}
    
    Swag.Math.Round = function(value, numDecimalPlaces)
        return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", value))
    end
    
    Swag.Math.GroupDigits = function(value)
        local left,num,right = string.match(value,'^([^%d]*%d)(%d*)(.-)$')
    
        return left..(num:reverse():gsub('(%d%d%d)','%1' .. _U('locale_digit_grouping_symbol')):reverse())..right
    end
    
    Swag.Math.Trim = function(value)
        if value then
            return (string.gsub(value, "^%s*(.-)%s*$", "%1"))
        else
            return nil
        end
    end
    
    -- Swag.Player Table
    Swag.Player = {
        Spectating = false,
        IsInVehicle = false,
        isNoclipping = false,
        Vehicle = 0,
    }
    
    -- Menu toggle table
    Swag.Toggle = {
        RainbowVehicle = false,
        ReplaceVehicle = true,
        SpawnInVehicle = true,
        VehicleCollision = false,
        MagnetoMode = false,
        SelfRagdoll = false,
        EasyHandling = false,
        DeleteGun = false,
        RapidFire = false,
        VehicleNoFall = false,
    
    }
    
    Swag.Events = {
        Revive = {}
    }
    
    Swag.Game = {}
    
    function Swag.Game:GetPlayers()
        local players = {}
        
        for _,player in ipairs(GetActivePlayers()) do
            local ped = GetPlayerPed(player)
            
            if DoesEntityExist(ped) then
                table.insert(players, player)
            end
        end
        
        return players
    end
    
    function Swag.Game:GetPlayersInArea(coords, area)
        local players       = Swag.Game:GetPlayers()
        local playersInArea = {}
    
        for i=1, #players, 1 do
            local target       = GetPlayerPed(players[i])
            local targetCoords = GetEntityCoords(target)
            local distance     = GetDistanceBetweenCoords(targetCoords, coords.x, coords.y, coords.z, true)
    
            if distance <= area then
                table.insert(playersInArea, players[i])
            end
        end
    
        return playersInArea
    end
    
    function Swag.Game:GetPedStatus(playerPed) 
    
        local inVehicle = IsPedInAnyVehicle(playerPed, false)
        local isIdle = IsPedStill(playerPed)
        local isWalking = IsPedWalking(playerPed)
        local isRunning = IsPedRunning(playerPed)
    
        if inVehicle then
            return "~o~In Vehicle"
    
        elseif isIdle then
            return "~o~Idle"
    
        elseif isWalking then
            return "~o~Walking"
    
        elseif isRunning then
            return "~o~Jogging"
        
        else
            return "~o~Running"
        end
    
    end
    
    function Swag.Game:GetCamDirection()
        local heading = GetGameplayCamRelativeHeading() + GetEntityHeading(PlayerPedId())
        local pitch = GetGameplayCamRelativePitch()
        
        local x = -math.sin(heading * math.pi / 180.0)
        local y = math.cos(heading * math.pi / 180.0)
        local z = math.sin(pitch * math.pi / 180.0)
        
        local len = math.sqrt(x * x + y * y + z * z)
        if len ~= 0 then
            x = x / len
            y = y / len
            z = z / len
        end
        
        return x, y, z
    end
    
    function Swag.Game:GetSeatPedIsIn(ped)
        if not IsPedInAnyVehicle(ped, false) then return
        else
            veh = GetVehiclePedIsIn(ped)
            for i = 0, GetVehicleMaxNumberOfPassengers(veh) do
                if GetPedInVehicleSeat(veh) then return i end
            end
        end
    end
    
    function Swag.Game:RequestControlOnce(entity)
        if not NetworkIsInSession() or NetworkHasControlOfEntity(entity) then
            return true
        end
        SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(entity), true)
        return NetworkRequestControlOfEntity(entity)
    end
    
    function Swag.Game:TeleportToPlayer(target)
        local ped = GetPlayerPed(target)
        local pos = GetEntityCoords(ped)
        SetEntityCoords(PlayerPedId(), pos)
    end
    
    function Swag.Game.GetVehicleProperties(vehicle)
        if DoesEntityExist(vehicle) then
            local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
            local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
            local extras = {}
    
            for id=0, 12 do
                if DoesExtraExist(vehicle, id) then
                    local state = IsVehicleExtraTurnedOn(vehicle, id) == 1
                    extras[tostring(id)] = state
                end
            end
    
            return {
                model             = GetEntityModel(vehicle),
    
                plate             = Swag.Math.Trim(GetVehicleNumberPlateText(vehicle)),
                plateIndex        = GetVehicleNumberPlateTextIndex(vehicle),
    
                bodyHealth        = Swag.Math.Round(GetVehicleBodyHealth(vehicle), 1),
                engineHealth      = Swag.Math.Round(GetVehicleEngineHealth(vehicle), 1),
    
                fuelLevel         = Swag.Math.Round(GetVehicleFuelLevel(vehicle), 1),
                dirtLevel         = Swag.Math.Round(GetVehicleDirtLevel(vehicle), 1),
                color1            = colorPrimary,
                color2            = colorSecondary,
    
                pearlescentColor  = pearlescentColor,
                wheelColor        = wheelColor,
    
                wheels            = GetVehicleWheelType(vehicle),
                windowTint        = GetVehicleWindowTint(vehicle),
    
                neonEnabled       = {
                    IsVehicleNeonLightEnabled(vehicle, 0),
                    IsVehicleNeonLightEnabled(vehicle, 1),
                    IsVehicleNeonLightEnabled(vehicle, 2),
                    IsVehicleNeonLightEnabled(vehicle, 3)
                },
    
                neonColor         = table.pack(GetVehicleNeonLightsColour(vehicle)),
                extras            = extras,
                tyreSmokeColor    = table.pack(GetVehicleTyreSmokeColor(vehicle)),
    
                modSpoilers       = GetVehicleMod(vehicle, 0),
                modFrontBumper    = GetVehicleMod(vehicle, 1),
                modRearBumper     = GetVehicleMod(vehicle, 2),
                modSideSkirt      = GetVehicleMod(vehicle, 3),
                modExhaust        = GetVehicleMod(vehicle, 4),
                modFrame          = GetVehicleMod(vehicle, 5),
                modGrille         = GetVehicleMod(vehicle, 6),
                modHood           = GetVehicleMod(vehicle, 7),
                modFender         = GetVehicleMod(vehicle, 8),
                modRightFender    = GetVehicleMod(vehicle, 9),
                modRoof           = GetVehicleMod(vehicle, 10),
    
                modEngine         = GetVehicleMod(vehicle, 11),
                modBrakes         = GetVehicleMod(vehicle, 12),
                modTransmission   = GetVehicleMod(vehicle, 13),
                modHorns          = GetVehicleMod(vehicle, 14),
                modSuspension     = GetVehicleMod(vehicle, 15),
                modArmor          = GetVehicleMod(vehicle, 16),
    
                modTurbo          = IsToggleModOn(vehicle, 18),
                modSmokeEnabled   = IsToggleModOn(vehicle, 20),
                modXenon          = IsToggleModOn(vehicle, 22),
    
                modFrontWheels    = GetVehicleMod(vehicle, 23),
                modBackWheels     = GetVehicleMod(vehicle, 24),
    
                modPlateHolder    = GetVehicleMod(vehicle, 25),
                modVanityPlate    = GetVehicleMod(vehicle, 26),
                modTrimA          = GetVehicleMod(vehicle, 27),
                modOrnaments      = GetVehicleMod(vehicle, 28),
                modDashboard      = GetVehicleMod(vehicle, 29),
                modDial           = GetVehicleMod(vehicle, 30),
                modDoorSpeaker    = GetVehicleMod(vehicle, 31),
                modSeats          = GetVehicleMod(vehicle, 32),
                modSteeringWheel  = GetVehicleMod(vehicle, 33),
                modShifterLeavers = GetVehicleMod(vehicle, 34),
                modAPlate         = GetVehicleMod(vehicle, 35),
                modSpeakers       = GetVehicleMod(vehicle, 36),
                modTrunk          = GetVehicleMod(vehicle, 37),
                modHydrolic       = GetVehicleMod(vehicle, 38),
                modEngineBlock    = GetVehicleMod(vehicle, 39),
                modAirFilter      = GetVehicleMod(vehicle, 40),
                modStruts         = GetVehicleMod(vehicle, 41),
                modArchCover      = GetVehicleMod(vehicle, 42),
                modAerials        = GetVehicleMod(vehicle, 43),
                modTrimB          = GetVehicleMod(vehicle, 44),
                modTank           = GetVehicleMod(vehicle, 45),
                modWindows        = GetVehicleMod(vehicle, 46),
                modLivery         = GetVehicleLivery(vehicle)
            }
        else
            return
        end
    end
    
    Swag.Keys = {
        ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
        ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
        ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
        ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
        ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
        ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
        ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
        ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
        ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118,
        ["MOUSE1"] = 24
    }
    
    ---------------------------------------------------------------------------------------
    
    local NoclipSpeed = 1
    local oldSpeed = 1
    
    -- Globals
    -- Menu color customization
    local _menuColor = {
        base = { r = 155, g = 89, b = 182, a = 255 },
        highlight = { r = 155, g = 89, b = 182, a = 150 },
        shadow = { r = 96, g = 52, b = 116, a = 150 },
    }
    
    -- License key validation for Swag
    local _buyer
    local _secretKey = "devbuild"
    local _gatekeeper = true
    local _auth = false
    
    local entityEnumerator = {
        __gc = function(enum)
            if enum.destructor and enum.handle then
                enum.destructor(enum.handle)
            end
            enum.destructor = nil
            enum.handle = nil
        end
    }
    
    local function EnumerateEntities(initFunc, moveFunc, disposeFunc)
        return coroutine.wrap(function()
              local iter, id = initFunc()
              if not id or id == 0 then
                disposeFunc(iter)
                return
              end
    
              local enum = {handle = iter, destructor = disposeFunc}
              setmetatable(enum, entityEnumerator)
    
              local next = true
              repeat
                coroutine.yield(id)
                next, id = moveFunc(iter)
              until not next
    
              enum.destructor, enum.handle = nil, nil
              disposeFunc(iter)
        end)
    end
    
    local function EnumerateObjects()
        return EnumerateEntities(FindFirstObject, FindNextObject, EndFindObject)
    end
    
    local function EnumeratePeds()
        return EnumerateEntities(FindFirstPed, FindNextPed, EndFindPed)
    end
    
    local function EnumerateVehicles()
        return EnumerateEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle)
    end
    
    local function EnumeratePickups()
        return EnumerateEntities(FindFirstPickup, FindNextPickup, EndFindPickup)
    end
    
    local function AddVectors(vect1, vect2)
        return vector3(vect1.x + vect2.x, vect1.y + vect2.y, vect1.z + vect2.z)
    end
    
    local function SubVectors(vect1, vect2)
        return vector3(vect1.x - vect2.x, vect1.y - vect2.y, vect1.z - vect2.z)
    end
    
    local function ScaleVector(vect, mult)
        return vector3(vect.x * mult, vect.y * mult, vect.z * mult)
    end
    
    local function ApplyForce(entity, direction)
        ApplyForceToEntity(entity, 3, direction, 0, 0, 0, false, false, true, true, false, true)
    end
    
    local function Oscillate(entity, position, angleFreq, dampRatio)
        local pos1 = ScaleVector(SubVectors(position, GetEntityCoords(entity)), (angleFreq * angleFreq))
        local pos2 = AddVectors(ScaleVector(GetEntityVelocity(entity), (2.0 * angleFreq * dampRatio)), vector3(0.0, 0.0, 0.1))
        local targetPos = SubVectors(pos1, pos2)
        
        ApplyForce(entity, targetPos)
    end
    
    local function RotationToDirection(rotation)
        local retz = math.rad(rotation.z)
        local retx = math.rad(rotation.x)
        local absx = math.abs(math.cos(retx))
        return vector3(-math.sin(retz) * absx, math.cos(retz) * absx, math.sin(retx))
    end
    
    local function WorldToScreenRel(worldCoords)
        local check, x, y = GetScreenCoordFromWorldCoord(worldCoords.x, worldCoords.y, worldCoords.z)
        if not check then
            return false
        end
        
        local screenCoordsx = (x - 0.5) * 2.0
        local screenCoordsy = (y - 0.5) * 2.0
        return true, screenCoordsx, screenCoordsy
    end
    
    local function ScreenToWorld(screenCoord)
        local camRot = GetGameplayCamRot(2)
        local camPos = GetGameplayCamCoord()
        
        local vect2x = 0.0
        local vect2y = 0.0
        local vect21y = 0.0
        local vect21x = 0.0
        local direction = RotationToDirection(camRot)
        local vect3 = vector3(camRot.x + 10.0, camRot.y + 0.0, camRot.z + 0.0)
        local vect31 = vector3(camRot.x - 10.0, camRot.y + 0.0, camRot.z + 0.0)
        local vect32 = vector3(camRot.x, camRot.y + 0.0, camRot.z + -10.0)
        
        local direction1 = RotationToDirection(vector3(camRot.x, camRot.y + 0.0, camRot.z + 10.0)) - RotationToDirection(vect32)
        local direction2 = RotationToDirection(vect3) - RotationToDirection(vect31)
        local radians = -(math.rad(camRot.y))
        
        vect33 = (direction1 * math.cos(radians)) - (direction2 * math.sin(radians))
        vect34 = (direction1 * math.sin(radians)) - (direction2 * math.cos(radians))
        
        local case1, x1, y1 = WorldToScreenRel(((camPos + (direction * 10.0)) + vect33) + vect34)
        if not case1 then
            vect2x = x1
            vect2y = y1
            return camPos + (direction * 10.0)
        end
        
        local case2, x2, y2 = WorldToScreenRel(camPos + (direction * 10.0))
        if not case2 then
            vect21x = x2
            vect21y = y2
            return camPos + (direction * 10.0)
        end
        
        if math.abs(vect2x - vect21x) < 0.001 or math.abs(vect2y - vect21y) < 0.001 then
            return camPos + (direction * 10.0)
        end
        
        local x = (screenCoord.x - vect21x) / (vect2x - vect21x)
        local y = (screenCoord.y - vect21y) / (vect2y - vect21y)
        return ((camPos + (direction * 10.0)) + (vect33 * x)) + (vect34 * y)
    
    end
    
    local function GetCamDirFromScreenCenter()
        local pos = GetGameplayCamCoord()
        local world = ScreenToWorld(0, 0)
        local ret = SubVectors(world, pos)
        return ret
    end
    
    AddTextEntry('notification_buffer', '~a~')
    AddTextEntry('text_buffer', '~a~')
    AddTextEntry('preview_text_buffer', '~a~')
    RegisterTextLabelToSave('keyboard_title_buffer')
    
    -- Classes
    -- > Gatekeeper
    Gatekeeper = {}
    
    -- Fullscreen Notification builder
    local _notifTitle = "~p~ALKO MENU"
    local _notifMsg = "We must authenticate your license before you proceed"
    local _notifMsg2 = "~g~Please enter your unique key code"
    local _errorCode = 0
    
    local ratio = GetAspectRatio(true)
    local mult = 10^3
    local floor = math.floor
    local unpack = table.unpack
    
    local streamedTxtSize
    
    local txtRatio = {}
    
    local function DrawSpriteScaled(textureDict, textureName, screenX, screenY, width, height, heading, red, green, blue, alpha)
        -- calculate the height of a sprite using aspect ratio and hash it in memory
        local index = tostring(textureName)
        
        if not txtRatio[index] then
            txtRatio[index] = {}
            local res = GetTextureResolution(textureDict, textureName)
            
            txtRatio[index].ratio = (res[2] / res[1])
            txtRatio[index].height = floor(((width * txtRatio[index].ratio) * ratio) * mult + 0.5) / mult
            DrawSprite(textureDict, textureName, screenX, screenY, width, txtRatio[index].height, heading, red, green, blue, alpha)
        end
        
        DrawSprite(textureDict, textureName, screenX, screenY, width, txtRatio[index].height, heading, red, green, blue, alpha)
    end
    
    -- Init variables
    local showMinimap = true
    
    -- This is for MK2 Weapons
    local weaponMkSelection = {}
    
    local weaponTextures = {
        {'https://i.imgur.com/GmpQc7C.png', 'weapon_dagger'},
        {'https://i.imgur.com/dL5qnPn.png?1', 'weapon_bat'},
        {'https://i.imgur.com/tl77ZyC.png', 'weapon_knife'},
        {'https://i.imgur.com/RaFQ0th.png', 'weapon_machete'},
    }
    
    local w_Txd = CreateRuntimeTxd('weapon_icons')
    
    local function CreateWeaponTextures()
        
        for i = 1, #weaponTextures do
            local w_DuiObj = CreateDui(weaponTextures[i][1], 256, 128)
            local w_DuiHandle = GetDuiHandle(w_DuiObj)
            local w_Txt = CreateRuntimeTextureFromDuiHandle(w_Txd, weaponTextures[i][2], w_DuiHandle)
            
            -- print(("Successfully created texture %s"):format(weaponTextures[i][2]))
            --CommitRuntimeTexture(w_Txt)
        end
    end
    
    -- CreateWeaponTextures()
    
    local onlinePlayerSelected = {} -- used for Online Players menu
    
    local function KeyboardInput(title, initialText, bufferSize)
        local editing, finished, cancelled, notActive = 0, 1, 2, 3
    
        AddTextEntry("keyboard_title_buffer", title)
        DisplayOnscreenKeyboard(0, "keyboard_title_buffer", "", initialText, "", "", "", bufferSize)
    
        while UpdateOnscreenKeyboard() == editing do
            HideHudAndRadarThisFrame()
            Wait(0)
        end
    
        if GetOnscreenKeyboardResult() then return GetOnscreenKeyboardResult() end
    end
    
    local SliderOptions = {}
    
    SliderOptions.FastRun = {
        Selected = 1,
        Values = {1.0, 1.09, 1.19, 1.29, 1.39, 1.49},
        Words = {"Default", "+20%", "+40%", "+60%", "+80%", "+100%"},
    }
    
    SliderOptions.DamageModifier = {
        Selected = 1,
        Values = {1.0, 2.0, 5.0, 10.0, 25.0, 50.0, 100.0, 200.0, 500.0, 1000.0},
        Words = {"Default", "2x", "5x", "10x", "25x", "50x", "100x", "200x", "500x", "1000x"}
    }
    
    local ComboOptions = {}
    
    ComboOptions.MK2 = {
        Selected = 1,
        Values = {"", "_mk2"},
        Words = {"Mk I", "Mk II"},
    }
    
    ComboOptions.EnginePower = {
        Selected = 1,
        Values = {1.0, 25.0, 50.0, 100.0, 200.0, 500.0, 1000.0},
        Words = {"Default", "+25%", "+50%", "+100%", "+200%", "+500%", "+1000%"}
    }
    
    ComboOptions.XenonColor = {
        Selected = 1,
        Values = {-1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12},
        Words = {"Default", "White", "Blue", "Electric", "Mint", "Lime", "Yellow", "Gold", "Orange", "Red", "Pink", "Hot Pink", "Purple", "Blacklight"}
    }
    
    local function GetDirtLevel(vehicle)
        local x = GetVehicleDirtLevel(vehicle)
        local val = floor(((x / 7.5) + 1) + 0.5)
        
        return val
    end
    
    ComboOptions.DirtLevel = {
        Selected = GetDirtLevel,
        Values = {0.0, 7.5, 15.0},
        Words = {"Clean", "Dirty", "Filthy"}
    }
    
    local function RepairVehicle(vehicle)
        local vehicle = vehicle
        if vehicle == 0 then return false end
    
        RequestControlOnce(vehicle)
        SetVehicleFixed(vehicle)
        SetVehicleLightsMode(vehicle, 0)
        SetVehicleLights(vehicle, 0)
        SetVehicleBurnout(vehicle, false)
        SetVehicleEngineHealth(vehicle, 1000.0)
        SetVehicleFuelLevel(vehicle, 100.0)
        SetVehicleOilLevel(vehicle, 100.0)
        return true
    end
    
    local function FlipVehicle(vehicle)
        local vehicle = vehicle
        if vehicle == 0 then return false end
    
        return SetVehicleOnGroundProperly(vehicle)
    end
    
    local function GetVehicleInFrontOfMe()
        
        local playerPos = GetEntityCoords( PlayerPedId() )
        local inFront = GetOffsetFromEntityInWorldCoords( ped, 0.0, 8.0, 0.0 )
        local rayHandle = CastRayPointToPoint( playerPos.x, playerPos.y, playerPos.z, inFront.x, inFront.y, inFront.z, 10, PlayerPedId(), 0 )
        local _, _, _, _, vehicle = GetRaycastResult( rayHandle )
        
        return vehicle
    end
    
    local function RemoveVehicle(vehicle)
        local vehicle = vehicle
        if vehicle == 0 then return false end
    
        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteVehicle(vehicle)
    
        return true
    end
    
    local function TeleportToPlayerVehicle(player)
        local ped = GetPlayerPed(player)
        if not IsPedInAnyVehicle(ped) then
            -- return SwagUI.SendNotification({text = ("%s is not in a vehicle!"):format(GetPlayerName(player)), type = "error"})
        end
    
        local vehicle = GetVehiclePedIsUsing(GetPlayerPed(player))
    
        local seats = GetVehicleMaxNumberOfPassengers(vehicle)
        for i = 0, seats do
            if IsVehicleSeatFree(vehicle, i) then
                SetPedIntoVehicle(PlayerPedId(), vehicle, i)
                break
            end
        end
    end
    
    local function DriveVehicle(vehicle)
        if vehicle == 0 then
            vehicle = GetVehicleInFrontOfMe()
        end
    
        SetPedIntoVehicle(PlayerPedId(), vehicle, -1)
    end
    
    local function StealVehicle(vehicle)
        local ped = GetPedInVehicleSeat(vehicle, -1)
        local vehicleNet = VehToNet(vehicle)
    
        RequestControlOnce(ped)
        ClearPedTasksImmediately(ped)
    
        while not IsVehicleSeatFree(NetToVeh(vehicleNet), -1) do
            Wait(0)
        end
    
        SetPedIntoVehicle(PlayerPedId(), NetToVeh(vehicleNet), -1)
        TaskWarpPedIntoVehicle(PlayerPedId(), NetToVeh(vehicleNet), -1)
    
        return true
    end
    
    ComboOptions.VehicleActions = {
        Selected = 1,
        Values = {RepairVehicle, FlipVehicle, DriveVehicle, RemoveVehicle},
        Words = {"Repair", "Flip", "Drive", "Delete"}
    }
    
    local currentMods = nil
    
    local themeColors = {
        red = { r = 231, g = 76, b = 60, a = 255 },  -- rgb(231, 76, 60)
        orange = { r = 230, g = 126, b = 34, a = 255 }, -- rgb(230, 126, 34)
        yellow = { r = 241, g = 196, b = 15, a = 255 }, -- rgb(241, 196, 15)
        green = { r = 26, g = 188, b = 156, a = 255 }, -- rgb(26, 188, 156)
        blue = { r = 52, g = 152, b = 219, a = 255 }, -- rgb(52, 152, 219)
        purple = { r = 155, g = 89, b = 182, a = 255 }, -- rgb(155, 89, 182)
        white = { r = 236, g = 240, b = 241, a = 255} -- rgb(236, 240, 241)
    }
    -- Set a default menu theme
    _menuColor.base = themeColors.yellow
    
    local dynamicColorTheme = false
    
    local texture_preload = {
        "commonmenu",
        "heisthud",
        "mpweaponscommon",
        "mpweaponscommon_small",
        "mpweaponsgang0_small",
        "mpweaponsgang1_small",
        "mpweaponsgang0",
        "mpweaponsgang1",
        "mpweaponsunusedfornow",
        "mpleaderboard",
        "mphud",
        "mparrow",
        "pilotschool",
        "shared",
    }
    
    local function PreloadTextures()
        
        --print("^7Preloading texture dictionaries...")
        for i = 1, #texture_preload do
            RequestStreamedTextureDict(texture_preload[i])
        end
    
    end
    
    PreloadTextures()
    
    local validResources = {}
    local validResourceEvents = {}
    local validResourceServerEvents = {}
    
    local function GetResources()
        local resources = {}
        for i = 1, GetNumResources() do
            resources[i] = GetResourceByFindIndex(i)
        end
        return resources
    end
    
    local function VerifyResource(resourceName)
        TriggerEvent(resourceName .. ".verify", function(resource) validResources[#validResources + 1] = resource end)
    end
    
    for i, v in ipairs(GetResources()) do
        VerifyResource(v)
    end
    
    
    local function RefreshResourceData()
        for i, v in ipairs(validResources) do
            TriggerEvent(v .. ".getEvents", function(rscName, events) validResourceEvents[rscName] = events end)
        end
    end
    
    local function UpdateServerEvents()
        for i, v in ipairs(validResources) do
            TriggerEvent(v .. ".getServerEvents", function(rscName, events) validResourceServerEvents[rscName] = events end)
        end
    end
    
    local function RefreshServerEvents()
        while true do
            UpdateServerEvents()
            Wait(5000)
        end
    end
    
    CreateThread(RefreshServerEvents)
    
    RefreshResourceData()
    
    local function RotationToDirection(rotation)
        local retz = math.rad(rotation.z)
        local retx = math.rad(rotation.x)
        local absx = math.abs(math.cos(retx))
        return vector3(-math.sin(retz) * absx, math.cos(retz) * absx, math.sin(retx))
    end
    
    ---------------------
    --  Vehicle Class  --
    ---------------------
    local function SpawnLocalVehicle(modelName, replaceCurrent, spawnInside)
        local speed = 0
        local rpm = 0
    
        if Swag.Player.IsInVehicle then
            local oldVehicle = Swag.Player.Vehicle
            speed = GetEntitySpeedVector(oldVehicle, true).y
            rpm = GetVehicleCurrentRpm(oldVehicle)
        end
    
        if IsModelValid(modelName) and IsModelAVehicle(modelName) then
            RequestModel(modelName)
    
            while not HasModelLoaded(modelName) do
                Wait(0)
            end
    
            local pos = (spawnInside and GetEntityCoords(PlayerPedId()) or GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 4.0, 0.0))
            local heading = GetEntityHeading(PlayerPedId()) + (spawnInside and 0 or 90)
    
            if replaceCurrent then
                RemoveVehicle(Swag.Player.Vehicle)
            end
    
            local vehicle = CreateVehicle(GetHashKey(modelName), pos.x, pos.y, pos.z, heading, true, false)
    
            if spawnInside then
                SetPedIntoVehicle(PlayerPedId(), vehicle, -1)
                SetVehicleEngineOn(vehicle, true, true)
            end
            
            SetVehicleForwardSpeed(vehicle, speed)
            SetVehicleCurrentRpm(vehicle, rpm)
            
            SetEntityAsNoLongerNeeded(vehicle)
    
            SetModelAsNoLongerNeeded(modelName)
        end
    
    
    end
    
    
    ---------------------
    --  SwagUI Class  --
    ---------------------
    
    SwagUI = {}
    
    SwagUI.debug = false
    
    local menus = {}
    local keys = {up = 172, down = 173, left = 174, right = 175, select = 176, back = 177}
    local optionCount = 0
    
    local currentKey = nil
    local currentMenu = nil
    
    local aspectRatio = GetAspectRatio(true)
    local screenResolution = GetActiveScreenResolution()
    
    local menuWidth = 0.19 -- old version was 0.23
    local titleHeight = 0.11
    local titleYOffset = 0.03
    local titleScale = 1.0
    
    local separatorHeight = 0.0025
    
    local buttonHeight = 0.038
    local buttonFont = 4
    local buttonScale = 0.375
    local buttonTextXOffset = 0.005
    local buttonTextYOffset = 0.0065
    local buttonSpriteXOffset = 0.011
    local buttonSpriteScale = { x = 0.016, y = 0 }
    
    local fontHeight = GetTextScaleHeight(buttonScale, buttonFont)
    
    local sliderWidth = (menuWidth / 4)
    
    local sliderHeight = 0.016
    
    local knobWidth = 0.002
    local knobHeight = 0.016
    
    local sliderFontScale = 0.275
    local sliderFontHeight = GetTextScaleHeight(sliderFontScale, buttonFont)
    
    
    local toggleInnerWidth = 0.008
    local toggleInnerHeight = 0.014
    local toggleOuterWidth = 0.01125
    local toggleOuterHeight = 0.020
    
    -- Vehicle preview, PlayerInfo, etc
    local previewWidth = 0.100
    
    local frameWidth = 0.004
    
    local footerHeight = 0.009
    
    local t
    local pow = function(num, pow) return num ^ pow end
    local sin = math.sin
    local cos = math.cos
    local sqrt = math.sqrt
    local abs = math.abs
    local asin  = math.asin
    
    ------------------------------------------------------------------------
    -- t = time == how much time has to pass for the tweening to complete --
    -- b = begin == starting property value								  --
    -- c = change == ending - beginning									  --
    -- d = duration == running time. How much time has passed *right now* --
    ------------------------------------------------------------------------
    
    local cout = function(text) return end
    
    local function outCubic(t, b, c, d)
        t = t / d - 1
        return c * (pow(t, 3) + 1) + b
    end
    
    local function inCubic (t, b, c, d)
        t = t / d
        return c * pow(t, 3) + b
    end
    
    local function inOutCubic(t, b, c, d)
        t = t / d * 2
        if t < 1 then
            return c / 2 * t * t * t + b
        else
            t = t - 2
            return c / 2 * (t * t * t + 2) + b
        end
    end
      
    local function outInCubic(t, b, c, d)
        if t < d / 2 then
            return outCubic(t * 2, b, c / 2, d)
        else
            return inCubic((t * 2) - d, b + c / 2, c / 2, d)
        end
    end
    
    local notifyBody = {
        -- Text
        scale = 0.35,
        offsetLine = 0.0235, -- text height: 0.019 | newline height: 0.005 or 0.006
        finalPadding = 0.01,
        -- Warp
        offsetX = 0.095, -- 0.0525
        offsetY = 0.009875, -- 0.01
        -- Draw below footer
        footerYOffset = 0,
        -- Sprite
        dict = 'commonmenu',
        sprite = 'header_gradient_script',
        font = 4,
        width = menuWidth + frameWidth, 
        height = 0.023, -- magic 0.8305 -- 0.011625
        heading = 90.0,
        -- Betwenn != notifications
        gap = 0.006,
    }
    
    local notifyDefault = {
        text = "Someone forgot to change me!",
        type = 'info',
        timeout = 6000,
        transition = 750,
    }
    
    local function NotifyCountLines(v, text)
        BeginTextCommandLineCount("notification_buffer")
        SetTextFont(notifyBody.font)
        SetTextScale(notifyBody.scale, notifyBody.scale)
        SetTextWrap(v.x, v.x + notifyBody.width / 2)
        AddTextComponentSubstringPlayerName(text)
        local nbrLines = GetTextScreenLineCount(v.x - notifyBody.offsetX, v.y - notifyBody.height)
        return nbrLines
    end
    
    -- Thread content
    local function MakeRoomThread(v, from, to, duration)
        local notif = v
        local beginVal = from
        local endVal = to
        local change = endVal - beginVal
    
        local timer = 0
        
        local function SetTimer()
            timer = GetGameTimer()
        end
        
        local function GetTimer()
            return GetGameTimer() - timer
        end
    
        local new_what
        SetTimer()
        local isMoving = true
        while isMoving do
            new_what = outCubic(GetTimer(), beginVal, change, duration)
            if notif.y < endVal then
                notif.y = new_what
            else
                notif.y = endVal
                isMoving = false
                break
            end
            Wait(5)
        end
    
        -- print("make room done")
    end
    
    -- Animating the 'push' transition of NotifyPrioritize
    local function NotifyMakeRoom(v, from, to, duration)
        CreateThread(function()
            return MakeRoomThread(v, from, to, duration)
        end)
    end
    
    -- Does nothing right now; not used
    local function NotifyGetResolutionConfiguration()
        SetScriptGfxAlign(string.byte('L'), string.byte('B'))
        local minimapTopX, minimapTopY = GetScriptGfxPosition(-0.0045, 0.002 + (-0.188888))
        ResetScriptGfxAlign()
        
        local w, h = GetActiveScreenResolution()
        
        return { x = minimapTopX, y = minimapTopY }
    end
    
    -- Pushes previous notifications down. Showing the incoming notification on top
    local function NotifyPrioritize(v, id, duration)
        for i, _ in pairs(v) do
            if i ~= id then
                if v[i].draw then
                    NotifyMakeRoom(v[i], v[i].y, v[i].y + ((notifyBody.height + ((v[id].lines - 1) * notifyBody.height)) + notifyBody.gap), duration)
                end
            end
        end
    end
    
    local fontHeight = GetTextScaleHeight(notifyBody.scale, notifyBody.font)
    
    local properties = { -- 0.72
        x = 0.78 + menuWidth / 2, 
        y = 1.0, 
        notif = {}, 
        offset = NotifyPrioritize,
    }
    
    local sound_type = {
        ['success'] = { name = "CHALLENGE_UNLOCKED", set = "HUD_AWARDS"},
        ['info'] = { name = "FocusIn", set = "HintCamSounds" },
        ['error'] = { name = "CHECKPOINT_MISSED", set = "HUD_MINI_GAME_SOUNDSET"},
    }
    
    local draw_type = {
        ['success'] = { color = themeColors.green, dict = "commonmenu", sprite = "shop_tick_icon", size = 0.016},
        ['info'] = { color = themeColors.blue, dict = "shared", sprite = "info_icon_32", size = 0.012},
        ['error'] = { color = themeColors.red, dict = "commonmenu", sprite = "shop_lock", size = 0.016},
    }
    
    -- Text render wrapper for dynamic animation
    local function NotifyDrawText(v, text)
        SetTextFont(notifyBody.font)
        SetTextScale(notifyBody.scale, notifyBody.scale)
        SetTextWrap(v.x, v.x + (menuWidth / 2))
        SetTextColour(255, 255, 255, v.opacity)
    
        BeginTextCommandDisplayText("notification_buffer")
        AddTextComponentSubstringPlayerName("    " .. text)
        EndTextCommandDisplayText(v.x - notifyBody.width / 2 + frameWidth / 2 + buttonTextXOffset, v.y - notifyBody.gap) -- (notifyBody.height / 2 - fontHeight / 2)
    end
    
    -- DrawSpriteScaled and DrawRect wrapper for dynamic animation
    local function NotifyDrawBackground(v)
        -- Background
        DrawRect(v.x, v.y + ((v.lines - 1) * (notifyBody.height / 2)) + notifyBody.gap, notifyBody.width, notifyBody.height + ((v.lines - 1) * notifyBody.height), draw_type[v.type].color.r, draw_type[v.type].color.g, draw_type[v.type].color.b, v.opacity - 100) --57,55,91
        DrawSpriteScaled(draw_type[v.type].dict, draw_type[v.type].sprite, v.x - notifyBody.width / 2 + 0.008, v.y + notifyBody.gap, draw_type[v.type].size, nil, 0.0, 255, 255, 255, v.opacity)
        -- Highlight
        -- DrawRect(v.x - 0.0025 - (notifyBody.width / 2), v.y + (((v.lines - 1) * notifyBody.offsetLine) + notifyBody.finalPadding) / 2, 0.005, notifyBody.height + (((v.lines - 1) * notifyBody.offsetLine) + notifyBody.finalPadding), draw_type[v.type].r, draw_type[v.type].g, draw_type[v.type].b, v.opacity) -- 116, 92, 151
        
        
        --DrawRect(minimap.x, minimap.y, 0.01, 0.015, 255, 255, 255, v.opacity)
        --DrawSpriteScaled(body.dict, body.sprite, v.x - 0.045, v.y, 0.010, 0.04, 0, 255, 255, 255, v.opacity - 50)
    end
    
    local function NotifyFormat(inputString, ...)
        local format = string.format
        text = format(inputString, ...)
        return text
    end
    
    local notifyPreviousText = nil
    
    local notifyQueue = 0
    
    -- Free up the `p.notif` table if notification is no longer being drawn on screen
    local function NotifyRecycle()
        --local disposeList = {}
        local notif = properties.notif
    
        -- print("^3NotifyRecycle: ^0Old table size: ^3" .. #p.notif)
    
        local drawnTable = {}
    
        -- allocate notifications currently on screen to drawnTable
        for i, _ in pairs(notif) do
            if notif[i].draw then
                drawnTable[i] = notif[i]
            end
        end
    
        -- remove notifications if they aren't drawing; shrinks size of table
        notif = drawnTable
    
    
        -- print("^3NotifyRecycle: ^0New table size: ^3" .. #p.notif)
        -- print("^3NotifyRecycle: ^4Returning: ^3" .. #p.notif + 1)
        return #notif + 1
    end
    
    -- Responsible for making sure the notification 'stick' to the menu footer
    local function NotifyRecalibrate()
        local p = properties
        local stackIndex = 0
    
        for id, _ in pairs(p.notif) do
            if p.notif[id].draw then
                stackIndex = stackIndex + 1
            end
        end
    
        -- print("^5Recalibrate:^0 table size is " .. stackIndex)
    
        for id, _ in pairs(p.notif) do
            if p.notif[id].draw then
                if p.notif[id].tin then p.notif[id].tin = false end
                -- if p.notif[id].makeRoom then p.notif[id].makeRoom = false end
    
                -- print("^5Recalibrate ID: ^0" .. id)
                p.notif[id].y = (p.y - notifyBody.footerYOffset) + ((notifyBody.height + ((p.notif[id].lines - 1) * notifyBody.height) + notifyBody.gap) * (stackIndex - 1))
            
                stackIndex = stackIndex - 1
            end
        end
    end
    
    -- Define thread function
    local function NotifyNewThread(options)
        local text = options.text or notifyDefault.text
        local transition = options.transition or notifyDefault.transition
        local timeout = options.timeout or notifyDefault.timeout
        local type = options.type or notifyDefault.type
        local sound = sound_type[type]
        
        local p = properties
    
        local nbrLines = NotifyCountLines(p, text)
    
        local beginY = 0.0
        local beginAlpha = 0
        
        -- garbage queueing system :)
        notifyQueue = notifyQueue + transition
        Wait(notifyQueue - transition)
        
        local id = NotifyRecycle()
    
        --print("^3-------- Notification " .. id .. " " .. type .. "--------")
        p.notif[id] = {
            x = p.x,
            y = 0,
            type = type,
            opacity = 0,
            lines = nbrLines,
            tin = true,
            draw = true,
            tout = false,
        }
    
        p.offset(p.notif, id, transition) --(0.05 * (id - 1))
        
        -- Drawing
        local function NotifyDraw()
            SetScriptGfxDrawOrder(5)
            while p.notif[id].draw do
                if SwagUI.IsAnyMenuOpened() then
                    NotifyDrawBackground(p.notif[id])
                    NotifyDrawText(p.notif[id], text)
                end
                Wait(0)
            end
        
            -- Schedule notification for garbage collection
            p.notif[id].dispose = true
        end
        CreateThread(NotifyDraw)
    
        -- Transition In
        local function NotifyFadeIn()
            local change = p.y - notifyBody.footerYOffset
    
            local timer = 0
        
            local function SetTimerIn() -- set the timer to 0
                timer = GetGameTimer()
            end
        
            local function GetTimerIn() -- gets the timer (counts up)
                return GetGameTimer() - timer
            end
            
            PlaySoundFrontend(-1, sound.name, sound.set, true)
        
            SetTimerIn() -- reset current timer to 0
            while p.notif[id].tin do
                local tinY = outCubic(GetTimerIn(), beginY, change, transition)
                local tinAlpha = inOutCubic(GetTimerIn(), beginAlpha, 255, transition)
        
                if p.notif[id].y >= change then
                    p.notif[id].y = change
                    p.notif[id].tin = false
                    break
                else
                    p.notif[id].y = tinY
                    p.notif[id].opacity = floor(tinAlpha + 0.5)
                end
                Wait(5)
            end
            notifyQueue = notifyQueue - transition
            p.notif[id].opacity = 255
        end
        CreateThread(NotifyFadeIn)
    
        -- Fade out wait timeout
        Wait(timeout + transition)
        p.notif[id].beginOut = true
        p.notif[id].tout = true
        
        -- Fade out
        local function NotifyFadeOut()
            local timer = 0
        
            local function SetTimerOut(ms)
                timer = GetGameTimer() - ms
            end
        
            local function GetTimerOut()
                return GetGameTimer() - timer
            end
        
            while p.notif[id].draw do
                while p.notif[id].tout do
                    
                    if p.notif[id].beginOut then 
                        SetTimerOut(0)
                        p.notif[id].beginOut = false 
                    end
        
                    local opa = inOutCubic(GetTimerOut(), 255, -510, transition)
                    if opa <= 0 then
        
                        p.notif[id].tout = false
                        p.notif[id].draw = false
        
                        break
                    else
                        p.notif[id].opacity = floor(opa + 0.5)
                    end
                    Wait(5)
                end
                
                Wait(5)
            end
        end
        CreateThread(NotifyFadeOut)
    end
    
    
    local function debugPrint(text)
        if SwagUI.debug then
            Citizen.Trace("[SwagUI] " .. text)
        end
    end
    
    local function setMenuProperty(id, property, value)
        if id and menus[id] then
            menus[id][property] = value
        end
    end
    
    local function isMenuVisible(id)
        if id and menus[id] then
            return menus[id].visible
        else
            return false
        end
    end
    
    local function setMenuVisible(id, visible, restoreIndex)
        if id and menus[id] then
            setMenuProperty(id, "visible", visible)
            setMenuProperty(id, "currentOption", 1)
    
            if restoreIndex then
                setMenuProperty(id, "currentOption", menus[id].storedOption)
            end
    
            if visible then
                if id ~= currentMenu and isMenuVisible(currentMenu) then
                    setMenuProperty(currentMenu, "storedOption", menus[currentMenu].currentOption)
                    setMenuVisible(currentMenu, false)
                end
    
                currentMenu = id
            end
    
            
            if dynamicColorTheme then
    
                if isMenuVisible("SelfMenu") then
                    _menuColor.base = themeColors.green
                elseif isMenuVisible("OnlinePlayersMenu") then
                    _menuColor.base = themeColors.blue
                elseif isMenuVisible("VisualMenu") then
                    _menuColor.base = themeColors.white
                elseif isMenuVisible("TeleportMenu") then
                    _menuColor.base = themeColors.yellow
                elseif isMenuVisible("LocalVehicleMenu") then
                    _menuColor.base = themeColors.orange
                elseif isMenuVisible("LocalWepMenu") then
                    _menuColor.base = themeColors.red
                elseif isMenuVisible("SwagMainMenu") then
                    _menuColor.base = themeColors.purple 
                end
            end
        end
    end
    
    local function drawText(text, x, y, font, color, scale, center, shadow, alignRight)
        SetTextColour(color.r, color.g, color.b, color.a)
        SetTextFont(font)
        SetTextScale(scale / aspectRatio, scale)
    
        if shadow then
            SetTextDropShadow(2, 2, 0, 0, 0)
        end
    
        if menus[currentMenu] then
            if center then
                SetTextCentre(center)
            elseif alignRight then
                SetTextWrap(menus[currentMenu].x, menus[currentMenu].x + menuWidth - buttonTextXOffset)
                SetTextRightJustify(true)
            end
        end
        BeginTextCommandDisplayText("text_buffer")
        AddTextComponentString(text)
        EndTextCommandDisplayText(x, y)
    end
    
    local function drawPreviewText(text, x, y, font, color, scale, center, shadow, alignRight)
        SetTextColour(color.r, color.g, color.b, color.a)
        SetTextFont(font)
        SetTextScale(scale / aspectRatio, scale)
    
        if shadow then
            SetTextDropShadow(2, 2, 0, 0, 0)
        end
    
        if menus[currentMenu] then
            if center then
                SetTextCentre(center)
            elseif alignRight then
                local rX = menus[currentMenu].x - frameWidth / 2 - frameWidth - previewWidth / 2
                SetTextWrap(rX, rX + previewWidth / 2 - buttonTextXOffset / 2)
                SetTextRightJustify(true)
            end
        end
        BeginTextCommandDisplayText("preview_text_buffer")
        AddTextComponentString(text)
        EndTextCommandDisplayText(x, y)
    end
    
    local function drawRect(x, y, width, height, color)
        DrawRect(x, y, width, height, color.r, color.g, color.b, color.a)
    end
    
    -- [NOTE] MenuDrawTitle
    local function drawTitle()
        if menus[currentMenu] then
            local x = menus[currentMenu].x + menuWidth / 2
            local y = menus[currentMenu].y + titleHeight / 2
            if menus[currentMenu].background == "default" then
                if _menuColor.base == themeColors.purple then
                    drawRect(x, y, menuWidth, titleHeight, menus[currentMenu].titleBackgroundColor)
                else
                    DrawSpriteScaled("commonmenu", "interaction_bgd", x, y + 0.025, menuWidth, (titleHeight * -1) - 0.025, 0.0, 255, 76, 60, 255) -- 255, 76, 60,
                    DrawSpriteScaled("commonmenu", "interaction_bgd", x, y + 0.025, menuWidth, (titleHeight * -1) - 0.025, 0.0, _menuColor.base.r, _menuColor.base.g, _menuColor.base.b, 255)
                end
            elseif menus[currentMenu].background == "weaponlist" then
                if _menuColor.base == themeColors.purple then
                    DrawSpriteScaled("heisthud", "main_gradient", x, y + 0.025, menuWidth, (titleHeight * -1) - 0.025, 0.0, 255, 255, 255, 140) -- 255, 76, 60,
                else
                    DrawSpriteScaled("heisthud", "main_gradient", x, y + 0.025, menuWidth, (titleHeight * -1) - 0.025, 0.0, _menuColor.base.r, _menuColor.base.g, _menuColor.base.b, 255)
                end
                 -- rgb(155, 89, 182)
            elseif menus[currentMenu].titleBackgroundSprite then
                DrawSpriteScaled(
                    menus[currentMenu].titleBackgroundSprite.dict,
                    menus[currentMenu].titleBackgroundSprite.name,
                    x,
                    y,
                    menuWidth,
                    titleHeight,
                    0.,
                    255,
                    255,
                    255,
                    255
                )
            else
                drawRect(x, y, menuWidth, titleHeight, menus[currentMenu].titleBackgroundColor)
            end
    
            drawText(
                menus[currentMenu].title,
                x,
                y - titleHeight / 2 + titleYOffset,
                menus[currentMenu].titleFont,
                menus[currentMenu].titleColor,
                titleScale,
                true
            )
        end
    end
    
    local function drawSubTitle()
        if menus[currentMenu] then
            local x = menus[currentMenu].x + menuWidth / 2
            local y = menus[currentMenu].y + titleHeight + buttonHeight / 2
    
            -- Header
            drawRect(x, y, menuWidth, buttonHeight, menus[currentMenu].menuFrameColor)
            -- Separator
            drawRect(x, y + (buttonHeight / 2) + (separatorHeight / 2), menuWidth, separatorHeight, _menuColor.base)
    
            drawText(
                menus[currentMenu].subTitle,
                menus[currentMenu].x + buttonTextXOffset,
                y - buttonHeight / 2 + buttonTextYOffset,
                buttonFont,
                _menuColor.base,
                buttonScale,
                false
            )
    
            if optionCount > menus[currentMenu].maxOptionCount then
                drawText(
                    tostring(menus[currentMenu].currentOption) .. " / " .. tostring(optionCount),
                    menus[currentMenu].x + menuWidth,
                    y - buttonHeight / 2 + buttonTextYOffset,
                    buttonFont,
                    _menuColor.base,
                    buttonScale,
                    false,
                    false,
                    true
                )
            end
        end
    end
    
    local welcomeMsg = true
    
    local function drawFooter()
        if menus[currentMenu] then
            local multiplier = nil
            local x = menus[currentMenu].x + menuWidth / 2
            -- local y = menus[currentMenu].y + titleHeight - 0.015 + buttonHeight + menus[currentMenu].maxOptionCount * buttonHeight
            -- DrawSpriteScaled("commonmenu", "interaction_bgd", x, y + 0.025, menuWidth, (titleHeight * -1) - 0.025, 0.0, 255, 76, 60, 255) -- r = 231, g = 76, b = 60
            local footerColor = menus[currentMenu].menuFrameColor
    
            if menus[currentMenu].currentOption <= menus[currentMenu].maxOptionCount and optionCount <= menus[currentMenu].maxOptionCount then
                multiplier = optionCount
            elseif optionCount >= menus[currentMenu].currentOption then
                multiplier = 10
            end
    
            if multiplier then
                local y = menus[currentMenu].y + titleHeight + buttonHeight + separatorHeight + (buttonHeight * multiplier) --0.015
    
                -- Footer
                drawRect(x, y + (footerHeight / 2), menuWidth, footerHeight, footerColor)
    
                local yFrame = menus[currentMenu].y + titleHeight + ((buttonHeight + separatorHeight + (buttonHeight * multiplier) + footerHeight) / 2)
                local frameHeight = buttonHeight + separatorHeight + footerHeight + (buttonHeight * multiplier)
                -- Frame Left
                drawRect(x - menuWidth / 2, yFrame, frameWidth, frameHeight, footerColor)
                -- Frame Right
                drawRect(x + menuWidth / 2, yFrame, frameWidth, frameHeight, footerColor)
    
                -- drawText(menus[currentMenu].version, menus[currentMenu].x + buttonTextXOffset, y - separatorHeight + (footerHeight / 2 - fontHeight / 2), menus[currentMenu].titleFont, {r = 255, g = 255, b = 255, a = 128}, buttonScale, false)
                -- drawText(menus[currentMenu].branding, x, y - separatorHeight + (footerHeight / 2 - fontHeight / 2), menus[currentMenu].titleFont, menus[currentMenu].titleColor, buttonScale, false, false, true)
                
                local offset = 1.0 - (y + footerHeight / 2 + notifyBody.height)
    
                if notifyBody.footerYOffset ~= offset then
                    notifyBody.footerYOffset = offset
                    NotifyRecalibrate()
                end
            end
    
            if welcomeMsg then
                welcomeMsg = false
                -- SwagUI.SendNotification({text = "If you experience any issues, please contact nobody on Discord!", type = "info"})
            end
        end
    end
    
    local function drawButton(text, subText, color, subcolor)
        local x = menus[currentMenu].x + menuWidth / 2
        local multiplier = nil
        local pointer = true
    
        if menus[currentMenu].currentOption <= menus[currentMenu].maxOptionCount and optionCount <= menus[currentMenu].maxOptionCount then
            multiplier = optionCount
        elseif
            optionCount > menus[currentMenu].currentOption - menus[currentMenu].maxOptionCount and
                optionCount <= menus[currentMenu].currentOption
         then
            multiplier = optionCount - (menus[currentMenu].currentOption - menus[currentMenu].maxOptionCount)
        end
    
        if multiplier then
            local y = menus[currentMenu].y + titleHeight + buttonHeight + 0.0025 + (buttonHeight * multiplier) - buttonHeight / 2 -- 0.0025 is the offset for the line under subTitle
            local backgroundColor = nil
            local textColor = nil
            local subTextColor = nil
            local shadow = false
    
            if menus[currentMenu].currentOption == optionCount then
                backgroundColor = menus[currentMenu].menuFocusBackgroundColor
                textColor = color or menus[currentMenu].menuFocusTextColor
                pointColor = menus[currentMenu].menuFocusPointerColor
                subTextColor = subcolor or menus[currentMenu].menuSubTextColor
                selectionColor = { r = 255, g = 255, b = 255, a = 255 }
            else
                backgroundColor = menus[currentMenu].menuBackgroundColor
                textColor = color or menus[currentMenu].menuTextColor
                pointColor = menus[currentMenu].menuInvisibleColor
                subTextColor = subcolor or menus[currentMenu].menuSubTextColor
                selectionColor = menus[currentMenu].menuInvisibleColor
                --shadow = true
            end
    
            drawRect(x, y, menuWidth, buttonHeight, backgroundColor)
    
            if (text ~= "~r~Grief Menu" and text ~= "~b~Menu Settings") and menus[currentMenu].subTitle == "RB3 AC · Menu" then -- and subText == "isMenu"
                drawText(
                text,
                menus[currentMenu].x + 0.020,
                y - (buttonHeight / 2) + buttonTextYOffset,
                buttonFont,
                textColor,
                buttonScale,
                false,
                shadow
                )
    
                if text == "Opciones Individuales" then
                    -- w/h = 0.02
                    DrawSpriteScaled("mpleaderboard", "leaderboard_players_icon", menus[currentMenu].x + buttonSpriteXOffset, y, buttonSpriteScale.x, buttonSpriteScale.y, 0.0, 26, 188, 156, 255) -- rgb(26, 188, 156)
                elseif text == "Online Options" then
                    DrawSpriteScaled("mpleaderboard", "leaderboard_friends_icon", menus[currentMenu].x + buttonSpriteXOffset, y, buttonSpriteScale.x, buttonSpriteScale.y, 0.0, 52, 152, 219, 255) -- rgb(52, 152, 219)
                elseif text == "Visual Options" then
                    DrawSpriteScaled("mphud", "spectating", menus[currentMenu].x + buttonSpriteXOffset, y, buttonSpriteScale.x, buttonSpriteScale.y, 0.0, 236, 240, 241, 255) -- rgb(236, 240, 241)
                elseif text == "Teleport Options" then
                    DrawSpriteScaled("mpleaderboard", "leaderboard_star_icon", menus[currentMenu].x + buttonSpriteXOffset, y, buttonSpriteScale.x, buttonSpriteScale.y, 0.0, 241, 196, 15, 255) -- rgb(241, 196, 15)
                elseif text == "Vehicle Options" then
                    DrawSpriteScaled("mpleaderboard", "leaderboard_transport_car_icon", menus[currentMenu].x + buttonSpriteXOffset, y, buttonSpriteScale.x, buttonSpriteScale.y, 0.0, 230, 126, 34, 255) -- rgb(230, 126, 34)
                elseif text == "Weapon Options" then
                    DrawSpriteScaled("mpleaderboard", "shooting_range_icon", menus[currentMenu].x + buttonSpriteXOffset, y, buttonSpriteScale.x, buttonSpriteScale.y, 0.0, 231, 76, 60, 255) -- rgb(231, 76, 60)
                elseif text == "Server Options" then
                    DrawSpriteScaled("mpleaderboard", "leaderboard_rankshield_icon", menus[currentMenu].x + buttonSpriteXOffset, y, buttonSpriteScale.x, buttonSpriteScale.y, 0.0, 155, 89, 182, 255) -- rgb(155, 89, 182)
                end
            else
                drawText(
                text,
                menus[currentMenu].x + buttonTextXOffset,
                y - (buttonHeight / 2) + buttonTextYOffset,
                buttonFont,
                textColor,
                buttonScale,
                false,
                shadow
                )
            end
    
            if subText == "isMenu" then
                DrawSpriteScaled("mparrow", "mp_arrowlarge", x + menuWidth / 2.25, y, 0.008, nil, 0.0, pointColor.r, pointColor.g, pointColor.b, pointColor.a)
                -- menus[currentMenu].title = ""
            elseif subText == "toggleOff" then
                x = x + menuWidth / 2 - frameWidth / 2 - toggleOuterWidth / 2 - buttonTextXOffset
                drawRect(x, y, toggleOuterWidth, toggleOuterHeight, menus[currentMenu].buttonSubBackgroundColor)
                -- drawRect(x, y, toggleInnerWidth, toggleInnerHeight, {r = 90, g = 90, b = 90, a = 230})
            elseif subText == "toggleOn" then
                x = x + menuWidth / 2 - frameWidth / 2 - toggleOuterWidth / 2 - buttonTextXOffset
                drawRect(x, y, toggleOuterWidth, toggleOuterHeight, menus[currentMenu].buttonSubBackgroundColor)
                DrawSpriteScaled("commonmenu", "shop_tick_icon", x, y, 0.020, nil, 0.0, _menuColor.base.r, _menuColor.base.g, _menuColor.base.b, 255)
                --drawRect(x, y, toggleInnerWidth, toggleInnerHeight, _menuColor.base) -- 26, 188, 156, 255
            elseif subText == "danger" then
                DrawSpriteScaled("commonmenu", "mp_alerttriangle", x + menuWidth / 2.35, y, 0.021, nil, 0.0, 255, 255, 255, 255)
            elseif subText then			
                drawText(
                    subText,
                    menus[currentMenu].x + 0.005,
                    y - buttonHeight / 2 + buttonTextYOffset,
                    buttonFont,
                    subTextColor,
                    buttonScale,
                    false,
                    shadow,
                    true
                )
    
            end
    
        end
    end
    
    local function drawComboBox(text, selectedIndex)
        local x = menus[currentMenu].x + menuWidth / 2
        local multiplier = nil
        local pointer = true
    
        if menus[currentMenu].currentOption <= menus[currentMenu].maxOptionCount and optionCount <= menus[currentMenu].maxOptionCount then
            multiplier = optionCount
        elseif
            optionCount > menus[currentMenu].currentOption - menus[currentMenu].maxOptionCount and
                optionCount <= menus[currentMenu].currentOption
         then
            multiplier = optionCount - (menus[currentMenu].currentOption - menus[currentMenu].maxOptionCount)
        end
    
        if multiplier then
            local y = menus[currentMenu].y + titleHeight + buttonHeight + 0.0025 + (buttonHeight * multiplier) - buttonHeight / 2 -- 0.0025 is the offset for the line under subTitle
            
            local backgroundColor = menus[currentMenu].menuBackgroundColor
            local textColor = menus[currentMenu].menuTextColor
            local subTextColor = menus[currentMenu].menuSubTextColor
            local pointColor = menus[currentMenu].menuInvisibleColor
            
            local textX = x + menuWidth / 2 - frameWidth - buttonTextXOffset
            local selected = false
    
            if menus[currentMenu].currentOption == optionCount then
                backgroundColor = menus[currentMenu].menuFocusBackgroundColor
                textColor = menus[currentMenu].menuFocusTextColor
                subTextColor = _menuColor.base
                pointColor = menus[currentMenu].menuSubTextColor
                textX = x + menuWidth / 2.25 - 0.019
                selected = true
            end
    
            -- Button background
            drawRect(x, y, menuWidth, buttonHeight, backgroundColor)
    
            -- Button title
            drawText(
                text,
                menus[currentMenu].x + buttonTextXOffset,
                y - (buttonHeight / 2) + buttonTextYOffset,
                buttonFont,
                textColor,
                buttonScale,
                false
            )
            
            -- DrawSpriteScaled("mparrow", "mp_arrowlarge", x + menuWidth / 2.25, y, 0.008, nil, 0.0, pointColor.r, pointColor.g, pointColor.b, pointColor.a)			
    
            DrawSpriteScaled("pilotschool", "hudarrow", x + menuWidth / 2 - frameWidth / 2 - sliderWidth, y + separatorHeight / 2, 0.008, nil, -90.0, pointColor.r, pointColor.g, pointColor.b, pointColor.a)
            
            -- Selection Text
            drawText(
                selectedIndex,
                textX,
                y - separatorHeight - (buttonHeight / 2 - fontHeight / 2) ,
                buttonFont,
                subTextColor,
                buttonScale,
                selected,
                false,
                not selected
            )	
    
            DrawSpriteScaled("pilotschool", "hudarrow", x + menuWidth / 2.25, y + separatorHeight / 2, 0.008, nil, 90.0, pointColor.r, pointColor.g, pointColor.b, pointColor.a)
        end
    end
    
    -- Invokes NotifyNewThread
    function SwagUI.SendNotification(options)
        local InvokeNotification = function() return NotifyNewThread(options) end
        -- Delegate coroutine
        CreateThread(InvokeNotification) 
    end
    
    function SwagUI.CreateMenu(id, title)
        -- Default settings
        menus[id] = {}
        menus[id].title = title
        menus[id].subTitle = "RB3 AC · Menu"
        menus[id].branding = "RB3"
        menus[id].version = "v1.0.2"
    
        menus[id].visible = false
    
        menus[id].previousMenu = nil
    
        menus[id].aboutToBeClosed = false
    
        menus[id].x = 0.78
        menus[id].y = 0.19
        
        menus[id].width = menuWidth
    
        menus[id].currentOption = 1
        menus[id].storedOption = 1 -- This is used when going back to previous menu
        menus[id].maxOptionCount = 10
        menus[id].titleFont = 4
        menus[id].titleColor = {r = 255, g = 255, b = 255, a = 255}
        menus[id].background = "default"
        menus[id].titleBackgroundColor = {r = _menuColor.base.r, g = _menuColor.base.g, b = _menuColor.base.b, a = 180}
    
        
        menus[id].menuTextColor = {r = 220, g = 220, b = 220, a = 255}
        menus[id].menuSubTextColor = {r = 140, g = 140, b = 140, a = 255}
        
        menus[id].menuFocusTextColor = {r = 255, g = 255, b = 255, a = 255}
        menus[id].menuFocusBackgroundColor = {r = 25, g = 25, b = 28, a = 240} -- rgb(31, 32, 34) rgb(155, 89, 182) #9b59b6
        menus[id].menuFocusPointerColor = {r = 255, g = 255, b = 255, a = 128}
    
        menus[id].menuBackgroundColor = {r = 18, g = 20, b = 20, a = 240} -- #121212
        menus[id].menuFrameColor = {r = 0, g = 0, b = 0, a = 255}
        menus[id].menuInvisibleColor = { r = 0, g = 0, b = 0, a = 0 }
    
        menus[id].buttonSubBackgroundColor = {r = 35, g = 39, b = 40, a = 255}
    
        menus[id].subTitleBackgroundColor = {
            r = menus[id].menuBackgroundColor.r,
            g = menus[id].menuBackgroundColor.g,
            b = menus[id].menuBackgroundColor.b,
            a = 255
        }
    
        menus[id].buttonPressedSound = {name = "SELECT", set = "HUD_FRONTEND_DEFAULT_SOUNDSET"} --https://pastebin.com/0neZdsZ5
    end
    
    function SwagUI.CreateSubMenu(id, parent, subTitle)
        if menus[parent] then
            SwagUI.CreateMenu(id, menus[parent].title)
    
            if subTitle then
                setMenuProperty(id, "subTitle", string.upper(subTitle))
            else
                setMenuProperty(id, "subTitle", string.upper(menus[parent].subTitle))
            end
    
            setMenuProperty(id, "previousMenu", parent)
    
            setMenuProperty(id, "x", menus[parent].x)
            setMenuProperty(id, "y", menus[parent].y)
            setMenuProperty(id, "maxOptionCount", menus[parent].maxOptionCount)
            setMenuProperty(id, "titleFont", menus[parent].titleFont)
            setMenuProperty(id, "titleColor", menus[parent].titleColor)
            setMenuProperty(id, "titleBackgroundColor", menus[parent].titleBackgroundColor)
            setMenuProperty(id, "titleBackgroundSprite", menus[parent].titleBackgroundSprite)
            setMenuProperty(id, "menuTextColor", menus[parent].menuTextColor)
            setMenuProperty(id, "menuSubTextColor", menus[parent].menuSubTextColor)
            setMenuProperty(id, "menuFocusTextColor", menus[parent].menuFocusTextColor)
            setMenuProperty(id, "menuFocusBackgroundColor", menus[parent].menuFocusBackgroundColor)
            setMenuProperty(id, "menuBackgroundColor", menus[parent].menuBackgroundColor)
            setMenuProperty(id, "subTitleBackgroundColor", menus[parent].subTitleBackgroundColor)
            
            setMenuProperty(id, "buttonSubBackgroundColor", menus[parent].buttonSubBackgroundColor)
        end
    end
    
    function SwagUI.CurrentMenu()
        return currentMenu
    end
    
    function SwagUI.OpenMenu(id)
        if id and menus[id] then
            if menus[id].titleBackgroundSprite then
                RequestStreamedTextureDict(menus[id].titleBackgroundSprite.dict, false)
                while not HasStreamedTextureDictLoaded(menus[id].titleBackgroundSprite.dict) do
                    Citizen.Wait(0)
                end
            end
            
            setMenuVisible(id, true)
            PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
        end
    end
    
    function SwagUI.IsMenuOpened(id)
        return isMenuVisible(id)
    end
    
    function SwagUI.IsAnyMenuOpened()
        for id, _ in pairs(menus) do
            if isMenuVisible(id) then
                return true
            end
        end
    
        return false
    end
    
    function SwagUI.IsMenuAboutToBeClosed()
        if menus[currentMenu] then
            return menus[currentMenu].aboutToBeClosed
        else
            return false
        end
    end
    
    function SwagUI.CloseMenu()
        if menus[currentMenu] then
            -- isMenuEnabled = false
            if menus[currentMenu].aboutToBeClosed then
                menus[currentMenu].aboutToBeClosed = false
                setMenuVisible(currentMenu, false)
                PlaySoundFrontend(-1, "QUIT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                optionCount = 0
                currentMenu = nil
                currentKey = nil
            else
                menus[currentMenu].aboutToBeClosed = true
            end
        end
    end
    
    function SwagUI.Button(text, subText, color, subcolor)
    
        if menus[currentMenu] then
            optionCount = optionCount + 1
    
            local isCurrent = menus[currentMenu].currentOption == optionCount
    
            drawButton(text, subText, color, subcolor)
    
            if isCurrent then
                if currentKey == keys.select then
                    PlaySoundFrontend(-1, menus[currentMenu].buttonPressedSound.name, menus[currentMenu].buttonPressedSound.set, true)
                    return true
                end
            end
    
            return false
        end
    
    end
    
    -- Button with a slider
    function SwagUI.Slider(text, items, selectedIndex, callback, vehicleMod)
        local itemsCount = #items
        local selectedItem = items[selectedIndex]
        local isCurrent = menus[currentMenu].currentOption == (optionCount + 1)
    
        if vehicleMod then
            selectedIndex = selectedIndex + 2
        end
    
        if itemsCount > 1 and isCurrent then
            selectedItem = tostring(selectedItem)
        end
    
        if SwagUI.SliderInternal(text, items, itemsCount, selectedIndex) then
            callback(selectedIndex)
            return true
        elseif isCurrent then
            if currentKey == keys.left then
                if selectedIndex > 1 then selectedIndex = selectedIndex - 1 end
            elseif currentKey == keys.right then
                if selectedIndex < itemsCount then selectedIndex = selectedIndex + 1 end
            end
        end
        
        callback(selectedIndex)
        return false
    end
    
    local function drawButtonSlider(text, items, itemsCount, selectedIndex)
        local x = menus[currentMenu].x + menuWidth / 2
        local multiplier = nil
    
        if (menus[currentMenu].currentOption <= menus[currentMenu].maxOptionCount) and (optionCount <= menus[currentMenu].maxOptionCount) then
            multiplier = optionCount
        elseif (optionCount > menus[currentMenu].currentOption - menus[currentMenu].maxOptionCount) and (optionCount <= menus[currentMenu].currentOption) then
            multiplier = optionCount - (menus[currentMenu].currentOption - menus[currentMenu].maxOptionCount)
        end
    
        if multiplier then
            local y = menus[currentMenu].y + titleHeight + buttonHeight + separatorHeight + (buttonHeight * multiplier) - buttonHeight / 2 -- 0.0025 is the offset for the line under subTitle
            
            local backgroundColor = menus[currentMenu].menuBackgroundColor
            local textColor = menus[currentMenu].menuTextColor
            local subTextColor = menus[currentMenu].menuSubTextColor
            local shadow = false
    
            if menus[currentMenu].currentOption == optionCount then
                backgroundColor = menus[currentMenu].menuFocusBackgroundColor
                textColor = menus[currentMenu].menuFocusTextColor
                subTextColor = menus[currentMenu].menuFocusTextColor
            end
    
            local sliderColorBase = menus[currentMenu].buttonSubBackgroundColor
            local sliderColorKnob = {r = 90, g = 90, b = 90, a = 255}
            local sliderColorText = {r = 206, g = 206, b = 206, a = 200}
    
            if selectedIndex > 1 then
                sliderColorBase = {r = _menuColor.base.r, g = _menuColor.base.g, b = _menuColor.base.b, a = 50}
                sliderColorKnob = {r = _menuColor.base.r, g = _menuColor.base.g, b = _menuColor.base.b, a = 140}
                sliderColorText = {r = _menuColor.base.r + 20, g = _menuColor.base.g + 20, b = _menuColor.base.b + 20, a = 255}
            end
    
            local sliderOverlayWidth = sliderWidth / (itemsCount - 1)
            
            -- Button
            drawRect(x, y, menuWidth, buttonHeight, backgroundColor) -- Button Rectangle -2.15
    
            -- Button text
            drawText(text, menus[currentMenu].x + buttonTextXOffset, y - (buttonHeight / 2) + buttonTextYOffset, buttonFont, textColor, buttonScale, false, shadow) -- Text
    
            
            -- Slider left
            drawRect(x + menuWidth / 2 - frameWidth / 2 - buttonTextXOffset - sliderWidth / 2, y, sliderWidth, sliderHeight, sliderColorBase)
            -- Slider right
            drawRect(x + menuWidth / 2 - frameWidth / 2 - buttonTextXOffset - (sliderOverlayWidth / 2) * (itemsCount - selectedIndex), y, sliderOverlayWidth * (itemsCount - selectedIndex), sliderHeight, menus[currentMenu].buttonSubBackgroundColor)
            -- Slider knob
            drawRect(x + menuWidth / 2 - frameWidth / 2 - buttonTextXOffset - sliderWidth + (sliderOverlayWidth * (selectedIndex - 1)), y, knobWidth, knobHeight, sliderColorKnob)
    
            -- Slider value text
            drawText(items[selectedIndex], x + menuWidth / 2 - frameWidth / 2 - buttonTextXOffset - sliderWidth / 2, y + separatorHeight / 2 - (buttonHeight / 2 - sliderFontHeight / 2), buttonFont, sliderColorText, sliderFontScale, true, shadow) -- Current Item Text
        end
    end
    
    function SwagUI.SliderInternal(text, items, itemsCount, selectedIndex)
        if menus[currentMenu] then
            optionCount = optionCount + 1
    
            local isCurrent = menus[currentMenu].currentOption == optionCount
    
            drawButtonSlider(text, items, itemsCount, selectedIndex)
    
            if isCurrent then
                if currentKey == keys.select then
                    PlaySoundFrontend(-1, menus[currentMenu].buttonPressedSound.name, menus[currentMenu].buttonPressedSound.set, true)
                    return true
                elseif currentKey == keys.left or currentKey == keys.right then
                    PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                end
            end
    
            return false
        else
            
            return false
        end
    end
    
    function SwagUI.MenuButton(text, id)
        if menus[id] then
            if SwagUI.Button(text, "isMenu") then
                setMenuVisible(id, true)
                return true
            end
        end
    
        return false
    end
    
    function SwagUI.CheckBox(text, bool, callback)
        local checked = "toggleOff"
        if bool then
            checked = "toggleOn"
        end
    
        if SwagUI.Button(text, checked) then
            bool = not bool
    
            if callback then callback(bool) end
    
            return true
        end
    
        return false
    end
    
    function SwagUI.ComboBoxInternal(text, selectedIndex)
        if menus[currentMenu] then
            optionCount = optionCount + 1
    
            local isCurrent = menus[currentMenu].currentOption == optionCount
    
            drawComboBox(text, selectedIndex)
    
            if isCurrent then
                if currentKey == keys.select then
                    PlaySoundFrontend(-1, menus[currentMenu].buttonPressedSound.name, menus[currentMenu].buttonPressedSound.set, true)
                    return true
                elseif currentKey == keys.left or currentKey == keys.right then
                    PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                end
            end
    
            return false
        else
            
            return false
        end
    end
    
    function SwagUI.ComboBox(text, items, selectedIndex, callback, vehicleMod)
        local itemsCount = #items
        local selectedItem = items[selectedIndex]
        local isCurrent = menus[currentMenu].currentOption == (optionCount + 1)
    
        if vehicleMod then
            selectedIndex = selectedIndex + 1
            selectedItem = items[selectedIndex]
        end
    
    
        if itemsCount > 1 and isCurrent then
            selectedItem = tostring(selectedItem)
        end
    
        if SwagUI.ComboBoxInternal(text, selectedItem) then
            callback(selectedIndex, selectedItem)
            return true
        end
    
        if isCurrent then
            if currentKey == keys.left then
                if selectedIndex > 1 then selectedIndex = selectedIndex - 1 end
            elseif currentKey == keys.right then
                if selectedIndex < itemsCount then selectedIndex = selectedIndex + 1 end
            end
        end
    
        callback(selectedIndex, selectedItem)
    
        return false
    end
    
    local DrawPlayerInfo = {
        pedHeadshot = false,
        txd = "null",
        handle = nil,
        currentPlayer = -1,
    }
    
    function SwagUI.DrawPlayerInfo(player)
        -- Handles running code only once per user. Will run once per `SelectedPlayer` change
        if DrawPlayerInfo.currentPlayer ~= player then
    
            -- Current player selected
            DrawPlayerInfo.currentPlayer = player
    
            -- Drawing coordinates
            DrawPlayerInfo.mugshotWidth = buttonHeight / aspectRatio
            DrawPlayerInfo.mugshotHeight = DrawPlayerInfo.mugshotWidth * aspectRatio
            DrawPlayerInfo.x = menus[currentMenu].x - frameWidth / 2 - frameWidth - previewWidth / 2 
            DrawPlayerInfo.y = menus[currentMenu].y + titleHeight
            
            -- Player init
            DrawPlayerInfo.playerPed = GetPlayerPed(DrawPlayerInfo.currentPlayer)
            DrawPlayerInfo.playerName = Swag:CheckName(GetPlayerName(DrawPlayerInfo.currentPlayer))
    
    
            local function RegisterPedHandle()
                
                if DrawPlayerInfo.handle and IsPedheadshotValid(DrawPlayerInfo.handle) then
            
                    DrawPlayerInfo.pedHeadshot = false
                    UnregisterPedheadshot(DrawPlayerInfo.handle)
                    DrawPlayerInfo.handle = nil
                    DrawPlayerInfo.txd = "null"
            
                end
            
                -- Get the ped headshot image.
                DrawPlayerInfo.handle = RegisterPedheadshot(DrawPlayerInfo.playerPed)
            
                while not IsPedheadshotReady(DrawPlayerInfo.handle) or not IsPedheadshotValid(DrawPlayerInfo.handle) do
                    Wait(50)
                end
                
                if IsPedheadshotReady(DrawPlayerInfo.handle) and IsPedheadshotValid(DrawPlayerInfo.handle) then
                    DrawPlayerInfo.txd = GetPedheadshotTxdString(DrawPlayerInfo.handle)
                    DrawPlayerInfo.pedHeadshot = true
                else
                    DrawPlayerInfo.pedHeadshot = false
                end
            end
            CreateThreadNow(RegisterPedHandle)
        end
        
        -- Pull coordinates from client (self)
        local client = GetEntityCoords(PlayerPedId())
        local cx, cy, cz = client[1], client[2], client[3]
        -- Pull coordinates from target (player)
        local target = GetEntityCoords(DrawPlayerInfo.playerPed)
        local tx, ty, tz = target[1], target[2], target[3]
    
    
    
    end
    
    function SwagUI.Display()
        if isMenuVisible(currentMenu) then
            if menus[currentMenu].aboutToBeClosed then
                SwagUI.CloseMenu()
            else
                SetScriptGfxDrawOrder(15)
                -- drawTitle()
                drawSubTitle()
                drawFooter()
    
                currentKey = nil
    
                if IsDisabledControlJustPressed(0, keys.down) then
                    PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    
                    if menus[currentMenu].currentOption < optionCount then
                        menus[currentMenu].currentOption = menus[currentMenu].currentOption + 1
                    else
                        menus[currentMenu].currentOption = 1
                    end
                elseif IsDisabledControlJustPressed(0, keys.up) then
                    PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    
                    if menus[currentMenu].currentOption > 1 then
                        menus[currentMenu].currentOption = menus[currentMenu].currentOption - 1
                    else
                        menus[currentMenu].currentOption = optionCount
                    end
                elseif IsDisabledControlJustPressed(0, keys.left) then
                    currentKey = keys.left
                elseif IsDisabledControlJustPressed(0, keys.right) then
                    currentKey = keys.right
                elseif IsDisabledControlJustPressed(0, keys.select) then
                    currentKey = keys.select
                elseif IsDisabledControlJustPressed(0, keys.back) then
                    if menus[menus[currentMenu].previousMenu] then
                        PlaySoundFrontend(-1, "BACK", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                        setMenuVisible(menus[currentMenu].previousMenu, true, true)
                    else
                        SwagUI.CloseMenu()
                    end
                end
    
                optionCount = 0
            end
        end
    end
    
    function SwagUI.SetMenuWidth(id, width)
        setMenuProperty(id, "width", width)
    end
    
    function SwagUI.SetMenuX(id, x)
        setMenuProperty(id, "x", x)
    end
    
    function SwagUI.SetMenuY(id, y)
        setMenuProperty(id, "y", y)
    end
    
    function SwagUI.SetMenuMaxOptionCountOnScreen(id, count)
        setMenuProperty(id, "maxOptionCount", count)
    end
    
    function SwagUI.SetTitleColor(id, r, g, b, a)
        setMenuProperty(id, "titleColor", {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a or menus[id].titleColor.a})
    end
    
    function SwagUI.SetTitleBackgroundColor(id, r, g, b, a)
        setMenuProperty(
            id,
            "titleBackgroundColor",
            {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a or menus[id].titleBackgroundColor.a}
        )
    end
    
    function SwagUI.SetTitleBackgroundSprite(id, textureDict, textureName)
        setMenuProperty(id, "titleBackgroundSprite", {dict = textureDict, name = textureName})
    end
    
    function SwagUI.SetSubTitle(id, text)
        setMenuProperty(id, "subTitle", string.upper(text))
    end
    
    function SwagUI.SetMenuBackgroundColor(id, r, g, b, a)
        setMenuProperty(
            id,
            "menuBackgroundColor",
            {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a or menus[id].menuBackgroundColor.a}
        )
    end
    
    function SwagUI.SetMenuTextColor(id, r, g, b, a)
        setMenuProperty(id, "menuTextColor", {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a or menus[id].menuTextColor.a})
    end
    
    function SwagUI.SetMenuSubTextColor(id, r, g, b, a)
        setMenuProperty(id, "menuSubTextColor", {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a or menus[id].menuSubTextColor.a})
    end
    
    function SwagUI.SetMenuFocusColor(id, r, g, b, a)
        setMenuProperty(id, "menuFocusColor", {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a or menus[id].menuFocusColor.a})
    end
    
    function SwagUI.SetMenuButtonPressedSound(id, name, set)
        setMenuProperty(id, "buttonPressedSound", {["name"] = name, ["set"] = set})
    end
    
    local function DrawText3D(x, y, z, text, r, g, b)
        SetDrawOrigin(x, y, z, 0)
        SetTextFont(0)
        SetTextProportional(0)
        SetTextScale(0.0, 0.20)
        SetTextColour(r, g, b, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        EndTextCommandDisplayText(0.0, 0.0)
        ClearDrawOrigin()
    end
    
    function math.round(num, numDecimalPlaces)
        return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
    end
    
    local function TeleportToWaypoint()
        local WaypointHandle = GetFirstBlipInfoId(8)
    
          if DoesBlipExist(WaypointHandle) then
              local waypointCoords = GetBlipInfoIdCoord(WaypointHandle)
            for height = 1, 1000 do
                SetPedCoordsKeepVehicle(PlayerPedId(), waypointCoords["x"], waypointCoords["y"], height + 0.0)
    
                local foundGround, zPos = GetGroundZFor_3dCoord(waypointCoords["x"], waypointCoords["y"], height + 0.0)
    
                if foundGround then
                    SetPedCoordsKeepVehicle(PlayerPedId(), waypointCoords["x"], waypointCoords["y"], height + 0.0)
    
                    break
                end
    
                Citizen.Wait(0)
            end
        else
            drawNotification("~r~No tienes un punto marcado en el mapa")
            -- SwagUI.SendNotification({text = "You must place a waypoint", type = 'error'})
        end
    end

    -- local function SpectatePlayer(selectedPlayer)
    --     local targetPed = GetPlayerPed(GetPlayerFromServerId(selectedPlayer))

    --     -- print(selectedPlayer)
    --     -- print(GetPlayerServerId(PlayerPedId()))
    --     -- print(GetPlayerServerId(targetPed))


    --     -- if targetPed ~= PlayerPedId() then
    --         if not Swag.Player.Spectating then
    --             print('especteando')
    --             if (not IsScreenFadedOut() and not IsScreenFadingOut()) then
    --                 DoScreenFadeOut(1000)
    --                 while (not IsScreenFadedOut()) do
    --                     Wait(0)
    --                 end

    --                 local targetx,targety,targetz = table.unpack(GetEntityCoords(targetPed, false))

    --                 RequestCollisionAtCoord(targetx,targety,targetz)
    --                 NetworkSetInSpectatorMode(true, targetPed)

    --                 if(IsScreenFadedOut()) then
    --                     DoScreenFadeIn(1000)
    --                 end
    --             end
    --         else
    --             if(not IsScreenFadedOut() and not IsScreenFadingOut()) then
    --                 DoScreenFadeOut(1000)
    --                 while (not IsScreenFadedOut()) do
    --                     Wait(0)
    --                 end

    --                 local targetx,targety,targetz = table.unpack(GetEntityCoords(targetPed, false))

    --                 RequestCollisionAtCoord(targetx,targety,targetz)
    --                 NetworkSetInSpectatorMode(false, targetPed)

    --                 if(IsScreenFadedOut()) then
    --                     DoScreenFadeIn(1000)
    --                 end
    --             end
    --         end

    --         Swag.Player.Spectating = not Swag.Player.Spectating
    --     -- else
    --     --     drawNotification("~r~No puedes verte a ti mismo")
    --     -- end
    -- end
    
    -- local function SpectatePlayer(selectedPlayer)
    --     local selectedPlayerPed = GetPlayerPed(selectedPlayer)
        
    --     if Swag.Player.Spectating then
    
    --         RequestCollisionAtCoord(GetEntityCoords(PlayerPedId()))
    
    --         DoScreenFadeOut(500)
    --         while IsScreenFadingOut() do Wait(0) end
    
    --         NetworkSetInSpectatorMode(false, 0)
    --         SetMinimapInSpectatorMode(false, 0)
    
    --         ClearPedTasks(PlayerPedId())
    --         DoScreenFadeIn(500)
    
    --     else
    --         print('especteandoo')
    
    --         DoScreenFadeOut(500)
    --         while IsScreenFadingOut() do Wait(0) end
    
    --         RequestCollisionAtCoord(GetEntityCoords(selectedPlayerPed))
    
    --         NetworkSetInSpectatorMode(false, 0)
    --         NetworkSetInSpectatorMode(true, selectedPlayerPed)
    --         SetMinimapInSpectatorMode(true, selectedPlayerPed)
    
    --         TaskWanderStandard(PlayerPedId(), 0, 0)
    --         DoScreenFadeIn(500)
            
    --     end
    
    --     Swag.Player.Spectating = not Swag.Player.Spectating
    -- end

    -- function spectate(target, coords)
    --     local player = GetPlayerFromServerId(target)
    --     -- if player == -1 then return drawNotification("~r~Jugador no encontrado") end
    --     local ped = GetPlayerPed(player)
    --     if Swag.Player.Spectating then
    
    --         RequestCollisionAtCoord(GetEntityCoords(PlayerPedId()))
    
    --         DoScreenFadeOut(500)
    --         while IsScreenFadingOut() do Wait(0) end
    
    --         NetworkSetInSpectatorMode(false, 0)
    --         SetMinimapInSpectatorMode(false, 0)
    
    --         ClearPedTasks(PlayerPedId())
    --         DoScreenFadeIn(500)
    
    --     else
    --         print('especteandoo')
    
    --         DoScreenFadeOut(500)
    --         while IsScreenFadingOut() do Wait(0) end
    
    --         RequestCollisionAtCoord(GetEntityCoords(ped))
    
    --         NetworkSetInSpectatorMode(false, 0)
    --         NetworkSetInSpectatorMode(true, ped)
    --         SetMinimapInSpectatorMode(true, ped)
    
    --         TaskWanderStandard(PlayerPedId(), 0, 0)
    --         DoScreenFadeIn(500)
            
    --     end
    
    --     Swag.Player.Spectating = not Swag.Player.Spectating
    -- end

    -- function spectate(targetPed,target,name)
    --     local playerPed = PlayerPedId() -- yourself
    --     if Swag.Player.Spectating then
    
    --         local targetx,targety,targetz = table.unpack(GetEntityCoords(targetPed, false))

    --         RequestCollisionAtCoord(targetx,targety,targetz)
    --         NetworkSetInSpectatorMode(false, targetPed)
    --         StopDrawPlayerInfo()
    
    --     else
    --         print('especteandoo')

    --         DoScreenFadeOut(500)
    --         while IsScreenFadingOut() do Wait(0) end
    
    --         RequestCollisionAtCoord(GetEntityCoords(targetPed))
    
    --         NetworkSetInSpectatorMode(false, 0)
    --         NetworkSetInSpectatorMode(true, targetPed)
    --         SetMinimapInSpectatorMode(true, targetPed)
    
    --         TaskWanderStandard(PlayerPedId(), 0, 0)
    --         DoScreenFadeIn(500)
    
    --         -- local targetx,targety,targetz = table.unpack(GetEntityCoords(targetPed, false))

    --         -- RequestCollisionAtCoord(targetx,targety,targetz)
    --         -- NetworkSetInSpectatorMode(true, targetPed)
    --         -- DrawPlayerInfo(target)
            
    --     end
    
    --     Swag.Player.Spectating = not Swag.Player.Spectating
    -- end

    local function MaxTuneVehicle(vehicle)
        -- local vehicle = GetVehiclePedIsIn(playerPed, false)
        SetVehicleModKit(vehicle, 0)
        SetVehicleWheelType(vehicle, 7)
        for index = 0, 38 do
            if index > 16 and index < 23 then
                ToggleVehicleMod(vehicle, index, true)
            elseif index == 14 then
                SetVehicleMod(vehicle, 14, 16, false)
            elseif index == 23 or index == 24 then
                SetVehicleMod(vehicle, index, 1, false)
            else
                SetVehicleMod(vehicle, index, GetNumVehicleMods(vehicle, index) - 1, false)
            end
        end
        SetVehicleWindowTint(vehicle, 1)
        SetVehicleTyresCanBurst(vehicle, false)
        SetVehicleNumberPlateTextIndex(vehicle, 5)
    end

    local function funcfreezePlayer(selectedPlayer)

        -- print(selectedPlayer)
        -- print(GetPlayerPed(SelectedPlayer))
        -- local selectedPlayerPed = SelectedPlayer

        -- local selectedPlayerPed = GetPlayerTargetEntity(selectedPlayer)
        
        if freezePlayer then
    
            FreezeEntityPosition(GetPlayerPed(SelectedPlayer), true)
    
        else
    
            FreezeEntityPosition(GetPlayerPed(SelectedPlayer), false)
            
        end
    end
    
    local function RequestControl(entity)
        local Waiting = 0
        NetworkRequestControlOfEntity(entity)
        while not NetworkHasControlOfEntity(entity) do
            Waiting = Waiting + 100
            Citizen.Wait(100)
            if Waiting > 5000 then
                break
            end
        end
    end
    
    local ptags = {}
    -- Thread that handles all menu toggles (Godmode, ESP, etc)
    local function MenuToggleThread()
        while Access do
    
            -- Radar/showMinimap
            DisplayRadar(showMinimap, 1)
            Swag.Player.IsInVehicle = IsPedInAnyVehicle(PlayerPedId(), 0)
    
            SetPlayerInvincible(PlayerId(), Godmode)
            SetEntityInvincible(PlayerPedId(), Godmode)
    
            SetPedCanBeKnockedOffVehicle(PlayerPedId(), Swag.Toggle.VehicleNoFall) 
    
            SetEntityVisible(PlayerPedId(), not Invisible, 0)
    
            SetPedCanRagdoll(PlayerPedId(), not RagdollToggle)
    
            if playerBlips then
                    local FKiQQr4Jo = GetActivePlayers()
                    for i = 1, #FKiQQr4Jo do
                        local z1BY33f = FKiQQr4Jo[i]
                        local hADKVY4 = GetPlayerPed(z1BY33f)
                        if hADKVY4 ~= PlayerPedId() then
                            local DL6eEnL6WI4Zwb2lm5Y5 = GetBlipFromEntity(hADKVY4)
                            if not DoesBlipExist(DL6eEnL6WI4Zwb2lm5Y5) then
                                DL6eEnL6WI4Zwb2lm5Y5 = AddBlipForEntity(hADKVY4)
                                SetBlipSprite(DL6eEnL6WI4Zwb2lm5Y5, 1)
                                Citizen.InvokeNative(6898569612438869215, DL6eEnL6WI4Zwb2lm5Y5, true)
                            else
                                local e4MkfnN = GetVehiclePedIsIn(hADKVY4, false)
                                local xPDcPjD = GetBlipSprite(DL6eEnL6WI4Zwb2lm5Y5)
                                if GetEntityHealth(hADKVY4) == 0.0 then
                                    if xPDcPjD ~= 274 then
                                        SetBlipSprite(DL6eEnL6WI4Zwb2lm5Y5, 274)
                                        Citizen.InvokeNative(6898569612438869215, DL6eEnL6WI4Zwb2lm5Y5, true)
                                    end
                                elseif e4MkfnN then
                                    local Nqm8gX = GetVehicleClass(e4MkfnN)
                                    local Oki = GetEntityModel(e4MkfnN)
                                    if Nqm8gX == 15 then
                                        if xPDcPjD ~= 422 then
                                            SetBlipSprite(DL6eEnL6WI4Zwb2lm5Y5, 422)
                                            Citizen.InvokeNative(6898569612438869215, DL6eEnL6WI4Zwb2lm5Y5, true)
                                        end
                                    elseif Nqm8gX == 8 then
                                        if xPDcPjD ~= 226 then
                                            SetBlipSprite(DL6eEnL6WI4Zwb2lm5Y5, 226)
                                            Citizen.InvokeNative(6898569612438869215, DL6eEnL6WI4Zwb2lm5Y5, true)
                                        end
                                    elseif Nqm8gX == 16 then
                                        if
                                            Oki == GetHashKey("besra") or Oki == GetHashKey("hydra") or
                                                Oki == GetHashKey("lazer")
                                         then
                                            if xPDcPjD ~= 424 then
                                                SetBlipSprite(DL6eEnL6WI4Zwb2lm5Y5, 424)
                                                Citizen.InvokeNative(6898569612438869215, DL6eEnL6WI4Zwb2lm5Y5, true)
                                            end
                                        elseif xPDcPjD ~= 423 then
                                            SetBlipSprite(DL6eEnL6WI4Zwb2lm5Y5, 423)
                                            Citizen.InvokeNative(6898569612438869215, DL6eEnL6WI4Zwb2lm5Y5, true)
                                        end
                                    elseif Nqm8gX == 14 then
                                        if xPDcPjD ~= 427 then
                                            SetBlipSprite(DL6eEnL6WI4Zwb2lm5Y5, 427)
                                            Citizen.InvokeNative(6898569612438869215, DL6eEnL6WI4Zwb2lm5Y5, true)
                                        end
                                    elseif
                                        Oki == GetHashKey("insurgent") or Oki == GetHashKey("insurgent2") or
                                            Oki == GetHashKey("insurgent3")
                                     then
                                        if xPDcPjD ~= 426 then
                                            SetBlipSprite(DL6eEnL6WI4Zwb2lm5Y5, 426)
                                            Citizen.InvokeNative(6898569612438869215, DL6eEnL6WI4Zwb2lm5Y5, true)
                                        end
                                    elseif Oki == GetHashKey("limo2") then
                                        if xPDcPjD ~= 460 then
                                            SetBlipSprite(DL6eEnL6WI4Zwb2lm5Y5, 460)
                                            Citizen.InvokeNative(6898569612438869215, DL6eEnL6WI4Zwb2lm5Y5, true)
                                        end
                                    elseif Oki == GetHashKey("rhino") then
                                        if xPDcPjD ~= 421 then
                                            SetBlipSprite(DL6eEnL6WI4Zwb2lm5Y5, 421)
                                            Citizen.InvokeNative(6898569612438869215, DL6eEnL6WI4Zwb2lm5Y5, false)
                                        end
                                    elseif Oki == GetHashKey("trash") or Oki == GetHashKey("trash2") then
                                        if xPDcPjD ~= 318 then
                                            SetBlipSprite(DL6eEnL6WI4Zwb2lm5Y5, 318)
                                            Citizen.InvokeNative(6898569612438869215, DL6eEnL6WI4Zwb2lm5Y5, true)
                                        end
                                    elseif Oki == GetHashKey("pbus") then
                                        if xPDcPjD ~= 513 then
                                            SetBlipSprite(DL6eEnL6WI4Zwb2lm5Y5, 513)
                                            Citizen.InvokeNative(6898569612438869215, DL6eEnL6WI4Zwb2lm5Y5, false)
                                        end
                                    elseif
                                        Oki == GetHashKey("seashark") or Oki == GetHashKey("seashark2") or
                                            Oki == GetHashKey("seashark3")
                                     then
                                        if xPDcPjD ~= 471 then
                                            SetBlipSprite(DL6eEnL6WI4Zwb2lm5Y5, 471)
                                            Citizen.InvokeNative(6898569612438869215, DL6eEnL6WI4Zwb2lm5Y5, false)
                                        end
                                    elseif
                                        Oki == GetHashKey("cargobob") or Oki == GetHashKey("cargobob2") or
                                            Oki == GetHashKey("cargobob3") or
                                            Oki == GetHashKey("cargobob4")
                                     then
                                        if xPDcPjD ~= 481 then
                                            SetBlipSprite(DL6eEnL6WI4Zwb2lm5Y5, 481)
                                            Citizen.InvokeNative(6898569612438869215, DL6eEnL6WI4Zwb2lm5Y5, false)
                                        end
                                    elseif
                                        Oki == GetHashKey("technical") or Oki == GetHashKey("technical2") or
                                            Oki == GetHashKey("technical3")
                                     then
                                        if xPDcPjD ~= 426 then
                                            SetBlipSprite(DL6eEnL6WI4Zwb2lm5Y5, 426)
                                            Citizen.InvokeNative(6898569612438869215, DL6eEnL6WI4Zwb2lm5Y5, false)
                                        end
                                    elseif Oki == GetHashKey("taxi") then
                                        if xPDcPjD ~= 198 then
                                            SetBlipSprite(DL6eEnL6WI4Zwb2lm5Y5, 198)
                                            Citizen.InvokeNative(6898569612438869215, DL6eEnL6WI4Zwb2lm5Y5, true)
                                        end
                                    elseif
                                        Oki == GetHashKey("fbi") or Oki == GetHashKey("fbi2") or
                                            Oki == GetHashKey("police2") or
                                            Oki == GetHashKey("police3") or
                                            Oki == GetHashKey("police") or
                                            Oki == GetHashKey("sheriff2") or
                                            Oki == GetHashKey("sheriff") or
                                            Oki == GetHashKey("policeold2")
                                     then
                                        if xPDcPjD ~= 56 then
                                            SetBlipSprite(DL6eEnL6WI4Zwb2lm5Y5, 56)
                                            Citizen.InvokeNative(6898569612438869215, DL6eEnL6WI4Zwb2lm5Y5, true)
                                        end
                                    elseif xPDcPjD ~= 1 then
                                        SetBlipSprite(DL6eEnL6WI4Zwb2lm5Y5, 1)
                                        Citizen.InvokeNative(6898569612438869215, DL6eEnL6WI4Zwb2lm5Y5, true)
                                    end
                                    local GG5 = GetVehicleNumberOfPassengers(e4MkfnN)
                                    if GG5 > 0.0 then
                                        if not IsVehicleSeatFree(e4MkfnN, -1) then
                                            GG5 = GG5 + 1
                                        end
                                        ShowNumberOnBlip(DL6eEnL6WI4Zwb2lm5Y5, GG5)
                                    else
                                        HideNumberOnBlip(DL6eEnL6WI4Zwb2lm5Y5)
                                    end
                                else
                                    HideNumberOnBlip(DL6eEnL6WI4Zwb2lm5Y5)
                                    if xPDcPjD ~= 1 then
                                        SetBlipSprite(DL6eEnL6WI4Zwb2lm5Y5, 1)
                                        Citizen.InvokeNative(6898569612438869215, DL6eEnL6WI4Zwb2lm5Y5, true)
                                    end
                                end
                                SetBlipRotation(DL6eEnL6WI4Zwb2lm5Y5, math.ceil(GetEntityHeading(e4MkfnN)))
                                SetBlipNameToPlayerName(DL6eEnL6WI4Zwb2lm5Y5, z1BY33f)
                                SetBlipScale(DL6eEnL6WI4Zwb2lm5Y5, 0.85)
                                if IsPauseMenuActive() then
                                    SetBlipAlpha(DL6eEnL6WI4Zwb2lm5Y5, 255)
                                else
                                    x1, y1 = table.unpack(GetEntityCoords(PlayerPedId(), true))
                                    x2, y2 = table.unpack(GetEntityCoords(GetPlayerPed(z1BY33f), true))
                                    distance =
                                        (math.floor(math.abs(math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2))) / -1)) +
                                        900
                                    if distance < 0.0 then
                                        distance = 0.0
                                    elseif distance > 255 then
                                        distance = 255
                                    end
                                    SetBlipAlpha(DL6eEnL6WI4Zwb2lm5Y5, distance)
                                end
                            end
                        end
                    end
                elseif not playerBlips then
                    local Lz3gAJ = GetActivePlayers()
                    for i = 1, #Lz3gAJ do
                        local PXDSLhwkblLh = Lz3gAJ[i]
                        local XBR3mEUvt75Ypn = GetPlayerPed(PXDSLhwkblLh)
                        local N8EoRVhdCewc1ozL5 = GetBlipFromEntity(XBR3mEUvt75Ypn)
                        if DoesBlipExist(N8EoRVhdCewc1ozL5) then
                            RemoveBlip(N8EoRVhdCewc1ozL5)
                        end
                    end
                end
    
            SetWeaponDamageModifier(GetSelectedPedWeapon(PlayerPedId()), SliderOptions.DamageModifier.Values[SliderOptions.DamageModifier.Selected])
    
            if Swag.Toggle.VehicleCollision then
                playerveh = GetVehiclePedIsIn(PlayerPedId(), false)
                for k in EnumerateVehicles() do
                    SetEntityNoCollisionEntity(k, playerveh, true)
                end
                for k in EnumerateObjects() do
                    SetEntityNoCollisionEntity(k, playerveh, true)
                end
                for k in EnumeratePeds() do
                    SetEntityNoCollisionEntity(k, playerveh, true)
                end
            end
        
            if InfStamina then
                RestorePlayerStamina(PlayerId(), 1.0)
            end
    
            SetRunSprintMultiplierForPlayer(PlayerId(), SliderOptions.FastRun.Values[SliderOptions.FastRun.Selected])
            SetPedMoveRateOverride(PlayerPedId(), SliderOptions.FastRun.Values[SliderOptions.FastRun.Selected])
    
            if esp_activo then
                local plist = GetActivePlayers()
                for i = 1, #plist do
                    local id = plist[i]
                    if id ~= PlayerId() and GetPlayerServerId(id) ~= 0 then
                        local ra = {r = 255, g = 255, b = 255, a = 255}
                        local pPed = GetPlayerPed(id)
                        local cx, cy, cz = table.unpack(GetEntityCoords(PlayerPedId()))
                        local x, y, z = table.unpack(GetEntityCoords(pPed))
                        
                        local message = '';

                        if esp_id then
                            message = message .. "ID: " .. GetPlayerServerId(id) .. '\n'
                        end
                        
                        if esp_names then
                            message = message .. GetPlayerName(id) .. '\n'
                        end
                        
                        if esp_distance then
                            message = message .. math.round(#(vector3(cx, cy, cz) - vector3(x, y, z)), 1) .. 'm\n'
                        end
                
                        DrawText3D(x, y, z + 1.0, message, ra.r, ra.g, ra.b)

                        if esp_lines then
                            DrawLine(cx, cy, cz, x, y, z, ra.r, ra.g, ra.b, 255)
                        end

                        if esp_box then
                            LineOneBegin = GetOffsetFromEntityInWorldCoords(pPed, -0.3, -0.3, -0.9)
                            LineOneEnd = GetOffsetFromEntityInWorldCoords(pPed, 0.3, -0.3, -0.9)
                            LineTwoBegin = GetOffsetFromEntityInWorldCoords(pPed, 0.3, -0.3, -0.9)
                            LineTwoEnd = GetOffsetFromEntityInWorldCoords(pPed, 0.3, 0.3, -0.9)
                            LineThreeBegin = GetOffsetFromEntityInWorldCoords(pPed, 0.3, 0.3, -0.9)
                            LineThreeEnd = GetOffsetFromEntityInWorldCoords(pPed, -0.3, 0.3, -0.9)
                            LineFourBegin = GetOffsetFromEntityInWorldCoords(pPed, -0.3, -0.3, -0.9)

                            TLineOneBegin = GetOffsetFromEntityInWorldCoords(pPed, -0.3, -0.3, 0.8)
                            TLineOneEnd = GetOffsetFromEntityInWorldCoords(pPed, 0.3, -0.3, 0.8)
                            TLineTwoBegin = GetOffsetFromEntityInWorldCoords(pPed, 0.3, -0.3, 0.8)
                            TLineTwoEnd = GetOffsetFromEntityInWorldCoords(pPed, 0.3, 0.3, 0.8)
                            TLineThreeBegin = GetOffsetFromEntityInWorldCoords(pPed, 0.3, 0.3, 0.8)
                            TLineThreeEnd = GetOffsetFromEntityInWorldCoords(pPed, -0.3, 0.3, 0.8)
                            TLineFourBegin = GetOffsetFromEntityInWorldCoords(pPed, -0.3, -0.3, 0.8)

                            ConnectorOneBegin = GetOffsetFromEntityInWorldCoords(pPed, -0.3, 0.3, 0.8)
                            ConnectorOneEnd = GetOffsetFromEntityInWorldCoords(pPed, -0.3, 0.3, -0.9)
                            ConnectorTwoBegin = GetOffsetFromEntityInWorldCoords(pPed, 0.3, 0.3, 0.8)
                            ConnectorTwoEnd = GetOffsetFromEntityInWorldCoords(pPed, 0.3, 0.3, -0.9)
                            ConnectorThreeBegin = GetOffsetFromEntityInWorldCoords(pPed, -0.3, -0.3, 0.8)
                            ConnectorThreeEnd = GetOffsetFromEntityInWorldCoords(pPed, -0.3, -0.3, -0.9)
                            ConnectorFourBegin = GetOffsetFromEntityInWorldCoords(pPed, 0.3, -0.3, 0.8)
                            ConnectorFourEnd = GetOffsetFromEntityInWorldCoords(pPed, 0.3, -0.3, -0.9)

                            DrawLine(
                            LineOneBegin.x,
                            LineOneBegin.y,
                            LineOneBegin.z,
                            LineOneEnd.x,
                            LineOneEnd.y,
                            LineOneEnd.z,
                            ra.r,
                            ra.g,
                            ra.b,
                            255
                            )
                            DrawLine(
                            LineTwoBegin.x,
                            LineTwoBegin.y,
                            LineTwoBegin.z,
                            LineTwoEnd.x,
                            LineTwoEnd.y,
                            LineTwoEnd.z,
                            ra.r,
                            ra.g,
                            ra.b,
                            255
                            )
                            DrawLine(
                            LineThreeBegin.x,
                            LineThreeBegin.y,
                            LineThreeBegin.z,
                            LineThreeEnd.x,
                            LineThreeEnd.y,
                            LineThreeEnd.z,
                            ra.r,
                            ra.g,
                            ra.b,
                            255
                            )
                            DrawLine(
                            LineThreeEnd.x,
                            LineThreeEnd.y,
                            LineThreeEnd.z,
                            LineFourBegin.x,
                            LineFourBegin.y,
                            LineFourBegin.z,
                            ra.r,
                            ra.g,
                            ra.b,
                            255
                            )
                            DrawLine(
                            TLineOneBegin.x,
                            TLineOneBegin.y,
                            TLineOneBegin.z,
                            TLineOneEnd.x,
                            TLineOneEnd.y,
                            TLineOneEnd.z,
                            ra.r,
                            ra.g,
                            ra.b,
                            255
                            )
                            DrawLine(
                            TLineTwoBegin.x,
                            TLineTwoBegin.y,
                            TLineTwoBegin.z,
                            TLineTwoEnd.x,
                            TLineTwoEnd.y,
                            TLineTwoEnd.z,
                            ra.r,
                            ra.g,
                            ra.b,
                            255
                            )
                            DrawLine(
                            TLineThreeBegin.x,
                            TLineThreeBegin.y,
                            TLineThreeBegin.z,
                            TLineThreeEnd.x,
                            TLineThreeEnd.y,
                            TLineThreeEnd.z,
                            ra.r,
                            ra.g,
                            ra.b,
                            255
                            )
                            DrawLine(
                            TLineThreeEnd.x,
                            TLineThreeEnd.y,
                            TLineThreeEnd.z,
                            TLineFourBegin.x,
                            TLineFourBegin.y,
                            TLineFourBegin.z,
                            ra.r,
                            ra.g,
                            ra.b,
                            255
                            )
                            DrawLine(
                            ConnectorOneBegin.x,
                            ConnectorOneBegin.y,
                            ConnectorOneBegin.z,
                            ConnectorOneEnd.x,
                            ConnectorOneEnd.y,
                            ConnectorOneEnd.z,
                            ra.r,
                            ra.g,
                            ra.b,
                            255
                            )
                            DrawLine(
                            ConnectorTwoBegin.x,
                            ConnectorTwoBegin.y,
                            ConnectorTwoBegin.z,
                            ConnectorTwoEnd.x,
                            ConnectorTwoEnd.y,
                            ConnectorTwoEnd.z,
                            ra.r,
                            ra.g,
                            ra.b,
                            255
                            )
                            DrawLine(
                            ConnectorThreeBegin.x,
                            ConnectorThreeBegin.y,
                            ConnectorThreeBegin.z,
                            ConnectorThreeEnd.x,
                            ConnectorThreeEnd.y,
                            ConnectorThreeEnd.z,
                            ra.r,
                            ra.g,
                            ra.b,
                            255
                            )
                            DrawLine(
                            ConnectorFourBegin.x,
                            ConnectorFourBegin.y,
                            ConnectorFourBegin.z,
                            ConnectorFourEnd.x,
                            ConnectorFourEnd.y,
                            ConnectorFourEnd.z,
                            ra.r,
                            ra.g,
                            ra.b,
                            255
                            )
                        end
                    end
                end
            end
    
            if VehGod and IsPedInAnyVehicle(PlayerPedId(), true) then
                SetEntityInvincible(GetVehiclePedIsUsing(PlayerPedId()), true)
            end
    
            if Swag.Player.isNoclipping then
                local isInVehicle = IsPedInAnyVehicle(PlayerPedId(), 0)
                local k = nil
                local x, y, z = nil
                
                if not isInVehicle then
                    k = PlayerPedId()
                    x, y, z = table.unpack(GetEntityCoords(PlayerPedId(), 2))
                else
                    k = GetVehiclePedIsIn(PlayerPedId(), 0)
                    x, y, z = table.unpack(GetEntityCoords(PlayerPedId(), 1))
                end
                
                if isInVehicle and Swag.Game:GetSeatPedIsIn(PlayerPedId()) ~= -1 then Swag.Game:RequestControlOnce(k) end
                
                local dx, dy, dz = Swag.Game:GetCamDirection()
                SetEntityVisible(PlayerPedId(), 0, 0)
                SetEntityVisible(k, 0, 0)
                
                SetEntityVelocity(k, 0.0001, 0.0001, 0.0001)
                
                if IsDisabledControlJustPressed(0, Swag.Keys["LEFTSHIFT"]) then -- Change speed
                    oldSpeed = NoclipSpeed
                    NoclipSpeed = NoclipSpeed * 5
                end
                
                if IsDisabledControlJustReleased(0, Swag.Keys["LEFTSHIFT"]) then -- Restore speed
                    NoclipSpeed = oldSpeed
                end
                
                if IsDisabledControlPressed(0, 32) then -- MOVE FORWARD
                    x = x + NoclipSpeed * dx
                    y = y + NoclipSpeed * dy
                    z = z + NoclipSpeed * dz
                end
                
                if IsDisabledControlPressed(0, 269) then -- MOVE BACK
                    x = x - NoclipSpeed * dx
                    y = y - NoclipSpeed * dy
                    z = z - NoclipSpeed * dz
                end
                
                if IsDisabledControlPressed(0, Swag.Keys["SPACE"]) then -- MOVE UP
                    z = z + NoclipSpeed
                end
                
                if IsDisabledControlPressed(0, Swag.Keys["LEFTCTRL"]) then -- MOVE DOWN
                    z = z - NoclipSpeed
                end
                
                
                SetEntityCoordsNoOffset(k, x, y, z, true, true, true)
            end
            
            Citizen.Wait(0)
        end
    end
    CreateThread(MenuToggleThread)
    
    
    -- Menu runtime for drawing and handling input
    local function MenuRuntimeThread()
        FreezeEntityPosition(entity, false)
        local currentItemIndex = 1
        local selectedItemIndex = 1
    
        -- MAIN MENU
        SwagUI.CreateMenu("SwagMainMenu", "SWAG MENU")
        SwagUI.SetSubTitle("SwagMainMenu", "RB3 AC · Menu")
    
        -- MAIN MENU CATEGORIES
        SwagUI.CreateSubMenu("SelfMenu", "SwagMainMenu", "Opciones Individuales")
        SwagUI.CreateSubMenu("ESPMenu", "SelfMenu", "ESP Menu")
        SwagUI.CreateSubMenu('OnlinePlayersMenu', 'SwagMainMenu', "Jugadores Online")
        
        SwagUI.CreateSubMenu("TeleportMenu", "SwagMainMenu", "Opciones de teletransporte")
        
        -- MAIN MENU > Vehicle Options
        SwagUI.CreateSubMenu("LocalVehicleMenu", "SwagMainMenu", "Opciones de vehiculos")
        -- MAIN MENU > Vehicle Options > Vehicle Spawner
        SwagUI.CreateSubMenu("LocalVehicleSpawner", "LocalVehicleMenu", "Spawnear Vehiculo")
        
        SwagUI.CreateSubMenu("LocalWepMenu", "SwagMainMenu", "Opciones de armas")
        SwagUI.CreateSubMenu("ServerMenu", "SwagMainMenu", "Opciones del servidor")
    
        -- ONLINE PLAYERS MENU
        SwagUI.CreateSubMenu('PlayerOptionsMenu', 'OnlinePlayersMenu', "Opciones de jugador")
        
        -- ONLINE PLAYERS > PLAYER > WEAPON OPTIONS MENU
        -- SwagUI.CreateSubMenu('OnlineWepMenu', 'PlayerOptionsMenu', 'Weapon Menu')
        -- SwagUI.CreateSubMenu('OnlineWepCategory', 'OnlineWepMenu', 'Armas')
        -- SwagUI.CreateSubMenu("OnlineMeleeWeapons", "OnlineWepCategory", "Cuerpo a Cuerpo")
        -- SwagUI.CreateSubMenu("OnlineSidearmWeapons", "OnlineWepCategory", "Pistolas")
        -- SwagUI.CreateSubMenu("OnlineAutorifleWeapons", "OnlineWepCategory", "Rifles de Asalto")
        -- SwagUI.CreateSubMenu("OnlineShotgunWeapons", "OnlineWepCategory", "Escopetas")
        
        SwagUI.CreateSubMenu('OnlineVehicleMenuPlayer', 'PlayerOptionsMenu', "Vehicle Options")
    
        SwagUI.CreateSubMenu("LocalWepCategory", "LocalWepMenu", "Armas")
        SwagUI.CreateSubMenu("LocalMeleeWeapons", "LocalWepCategory", "Cuerpo a Cuerpo")
        SwagUI.CreateSubMenu("LocalSidearmWeapons", "LocalWepCategory", "Pistolas")
        SwagUI.CreateSubMenu("LocalSmgWeapons", "LocalWepCategory", "Subfusiles")
        SwagUI.CreateSubMenu("LocalShotgunWeapons", "LocalWepCategory", "Escopetas")
        SwagUI.CreateSubMenu("LocalAssaultRifleWeapons", "LocalWepCategory", "Rifles de Asalto")
        SwagUI.CreateSubMenu("LocalMachineGunWeapons", "LocalWepCategory", "Armas ligeras")
        SwagUI.CreateSubMenu("LocalSniperRifles", "LocalWepCategory", "Snipers")
        SwagUI.CreateSubMenu("LocalHeavyWeapons", "LocalWepCategory", "Heavy Weapons")
    
        local SelectedPlayer = nil
        local SelectedPlayerName = nil
        local SelectedResource = nil
    
        while isMenuEnabled do
            Swag.Player.Vehicle = GetVehiclePedIsUsing(PlayerPedId())
    
            if IsDisabledControlJustPressed(0, Swag.Keys["DELETE"]) then
                --print(PlayerPedId())
                --GateKeep()
                TriggerServerEvent('RB3:MenuOpened')
                SwagUI.OpenMenu("SwagMainMenu")
            end
    
            if SwagUI.IsMenuOpened("SwagMainMenu") then
                if SwagUI.MenuButton("Individual", "SelfMenu") then end
                if SwagUI.MenuButton("Teletransporte", "TeleportMenu") then end
                if SwagUI.MenuButton("Jugadores Online", "OnlinePlayersMenu") then end
                if SwagUI.MenuButton("Servidor", "ServerMenu") then end
                if SwagUI.MenuButton("Vehiculos", "LocalVehicleMenu") then end
                if SwagUI.MenuButton("Armas", "LocalWepMenu") then end
                -- if SwagUI.MenuButton("~b~Menu Settings", "MenuSettings") then end
    
                SwagUI.Display()
            elseif SwagUI.IsMenuOpened("SelfMenu") then

                if SwagUI.MenuButton("ESP Menu", "ESPMenu") then end
                if SwagUI.CheckBox("~b~Godmode", Godmode, function(enabled) Godmode = enabled end) then end
                if SwagUI.CheckBox("Invisibilidad", Invisible, function(enabled) Invisible = enabled end) then end
                -- if SwagUI.CheckBox("Noclip", Nocliping, function(enabled) Nocliping = enabled end) then end
                if SwagUI.CheckBox("Noclip", Swag.Player.isNoclipping, function(enabled) 
                    Swag.Player.isNoclipping = enabled 
                    if Swag.Player.isNoclipping then
                        SetEntityVisible(PlayerPedId(), false, false)
                    else
                        SetEntityRotation(GetVehiclePedIsIn(PlayerPedId(), 0), GetGameplayCamRot(2), 2, 1)
                        SetEntityVisible(GetVehiclePedIsIn(PlayerPedId(), 0), true, false)
                        SetEntityVisible(PlayerPedId(), true, false)
                    end
                end) then end
                if SwagUI.CheckBox("Blips", playerBlips, function(enabled) playerBlips = enabled end) then end
                -- if SwagUI.CheckBox("Gamertags", showNametags, function(enabled) showNametags = enabled end) then end
                
                if SwagUI.Button("Recibir Vida") then
                    SetEntityHealth(PlayerPedId(), 200)
                end
                
                if SwagUI.Button("Recibir Armadura") then
                    SetPedArmour(PlayerPedId(), 200)
                end

                if SwagUI.Button("~g~Revivir") then
                    TriggerServerEvent('esx_ambulancejob:revive', PlayerPedId())
                    -- for i = 1, #Swag.Events.Revive do
                    --     TriggerEvent(Swag.Events.Revive[i])
                    -- end
                end
    
                if SwagUI.CheckBox("Estamina Infinita", InfStamina, function(enabled) InfStamina = enabled end) then
                    
                end
    
                if SwagUI.CheckBox("Minimapa", showMinimap, function(enabled) showMinimap = enabled end) then end
    
                SwagUI.Display()
            elseif SwagUI.IsMenuOpened("TeleportMenu") then
                if SwagUI.Button("TP al Punto") then
                    TeleportToWaypoint()
                end
        
                SwagUI.Display()
            elseif SwagUI.IsMenuOpened("ESPMenu") then
                if SwagUI.CheckBox("~g~Activar", esp_activo, function(enabled) esp_activo = enabled end) then end
                if SwagUI.CheckBox("Nombre", esp_names, function(enabled) esp_names = enabled end) then end
                if SwagUI.CheckBox("ID Jugador", esp_id, function(enabled) esp_id = enabled end) then end
                if SwagUI.CheckBox("Linea", esp_lines, function(enabled) esp_lines = enabled end) then end
                if SwagUI.CheckBox("Caja", esp_box, function(enabled) esp_box = enabled end) then end
                if SwagUI.CheckBox("Distancia", esp_distance, function(enabled) esp_distance = enabled end) then end
                SwagUI.Display()
            elseif SwagUI.IsMenuOpened("LocalWepMenu") then
                
                if SwagUI.MenuButton("Obtener arma", "LocalWepCategory") then
                end
    
                if SwagUI.CheckBox("Municion infinita", InfAmmo, function(enabled) InfAmmo = enabled SetPedInfiniteAmmoClip(PlayerPedId(), InfAmmo) end) then end

                if SwagUI.Button("~b~Kit de armas") then
                    local kit_armas = {

                        -- Cuerpo a Cuerpo
                        {`WEAPON_NIGHTSTICK`, "Nightstick", "w_me_nightstick", "mpweaponsunusedfornow", "melee"},
                        
                        -- Pistolas
                        {'WEAPON_PISTOL', "Pistol", "w_pi_pistol", "mpweaponsgang1_small", "handguns", true},
                        {`WEAPON_STUNGUN`, "Stungun", "w_pi_stungun", "mpweaponsgang0_small", "handguns"},
                    
                        -- SMGs
                        {'WEAPON_SMG', "SMG", nil, nil, "smgs", true},
                        
                    }
                    for i = 1, #kit_armas do
                        GiveWeaponToPed(PlayerPedId(), kit_armas[i][1], 256, false, false)
                    end
                    drawNotification("~b~Has recibido un kit de armas")
                end
    
                if SwagUI.Button("Municion del arma") then
                    local _, weaponHash = GetCurrentPedWeapon(PlayerPedId())
                    local amount = KeyboardInput("Cantidad de municion", "", 3)
                    if not tonumber ( amount ) then
                        drawNotification("~r~La cantidad solo puede ser un numero")
                    else
                        local ammo = floor(tonumber(amount) + 0.5)
                        SetPedAmmo(PlayerPedId(), weaponHash, ammo)
                    end
                end

                if SwagUI.Button("~r~Quitar todas mis armas") then
                    RemoveAllPedWeapons(PlayerPedId(), true)
                    GiveWeaponToPed(PlayerPedId(), 'weapon_unarmed', 0, false, false)
                    drawNotification("~r~Todas tus armas han sido eliminadas")
                end
    
                SwagUI.Display()
            elseif SwagUI.IsMenuOpened("LocalWepCategory") then
                if SwagUI.Button("~b~Nombre del arma") then
                    local modelName = KeyboardInput("Introduce el nombre del arma", "", 20)

                    GiveWeaponToPed(PlayerPedId(), modelName, 30, false, false)
                end
                SwagUI.MenuButton("Cuerpo a Cuerpo", "LocalMeleeWeapons")
                SwagUI.MenuButton("Pistolas", "LocalSidearmWeapons")
                SwagUI.MenuButton("Subfusiles", "LocalSmgWeapons")
                SwagUI.MenuButton("Escopetas", "LocalShotgunWeapons")
                SwagUI.MenuButton("Rifles de Asalto", "LocalAssaultRifleWeapons")
                SwagUI.MenuButton("Armas ligeras", "LocalMachineGunWeapons")
                SwagUI.MenuButton("Snipers", "LocalSniperRifles")
    
                SwagUI.Display()
            elseif SwagUI.IsMenuOpened("LocalMeleeWeapons") then
                local selectedWeapon = {}
                for i = 1, #t_Weapons do
                    if t_Weapons[i][5] == "melee" then
                        if SwagUI.Button(t_Weapons[i][2]) then
                            PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                            GiveWeaponToPed(PlayerPedId(), t_Weapons[i][1], 150, false, false)
                        end
                        selectedWeapon[optionCount] = i
                    end
                end
    
                SwagUI.Display()
            elseif SwagUI.IsMenuOpened("LocalSidearmWeapons") then
                for i = 1, #t_Weapons do
                    if t_Weapons[i][5] == "handguns" then
                        if t_Weapons[i][6] then
                            if weaponMkSelection[i] == nil then weaponMkSelection[i] = 1 end
                            
                            if SwagUI.ComboBox(t_Weapons[i][2], ComboOptions.MK2.Words, weaponMkSelection[i], function(selectedIndex)
                                if weaponMkSelection[i] ~= selectedIndex then
                                    weaponMkSelection[i] = selectedIndex
                                end
                            end) then 
                                PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                                GiveWeaponToPed(PlayerPedId(), GetHashKey(t_Weapons[i][1] .. ComboOptions.MK2.Values[weaponMkSelection[i]]), 0, false, false)
                            end
                        else
                            if SwagUI.Button(t_Weapons[i][2]) then
                                PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                                GiveWeaponToPed(PlayerPedId(), t_Weapons[i][1], GetWeaponClipSize(t_Weapons[i][1]) * 5, false, false)
                            end
                        end
                    end
                end
    
                SwagUI.Display()
            elseif SwagUI.IsMenuOpened("LocalAssaultRifleWeapons") then
                for i = 1, #t_Weapons do
                    if t_Weapons[i][5] == "assaultrifles" then
                        if t_Weapons[i][6] then
                            if weaponMkSelection[i] == nil then weaponMkSelection[i] = 1 end
                            
                            if SwagUI.ComboBox(t_Weapons[i][2], ComboOptions.MK2.Words, weaponMkSelection[i], function(selectedIndex)
                                if weaponMkSelection[i] ~= selectedIndex then
                                    weaponMkSelection[i] = selectedIndex
                                end
                            end) then 
                                PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                                GiveWeaponToPed(PlayerPedId(), GetHashKey(t_Weapons[i][1] .. ComboOptions.MK2.Values[weaponMkSelection[i]]), 150, false, false)
                            end
                        else
                            if SwagUI.Button(t_Weapons[i][2]) then
                                PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                                GiveWeaponToPed(PlayerPedId(), t_Weapons[i][1], GetWeaponClipSize(t_Weapons[i][1]) * 5, false, false)
                            end
                        end
                    end
                end
    
                SwagUI.Display()
            elseif SwagUI.IsMenuOpened("LocalShotgunWeapons") then
                for i = 1, #t_Weapons do
                    if t_Weapons[i][5] == "shotguns" then
                        if t_Weapons[i][6] then
                            if weaponMkSelection[i] == nil then weaponMkSelection[i] = 1 end
                            
                            if SwagUI.ComboBox(t_Weapons[i][2], ComboOptions.MK2.Words, weaponMkSelection[i], function(selectedIndex)
                                if weaponMkSelection[i] ~= selectedIndex then
                                    weaponMkSelection[i] = selectedIndex
                                end
                            end) then 
                                PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                                GiveWeaponToPed(PlayerPedId(), GetHashKey(t_Weapons[i][1] .. ComboOptions.MK2.Values[weaponMkSelection[i]]), 150, false, false)
                            end
                        else
                            if SwagUI.Button(t_Weapons[i][2]) then
                                PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                                GiveWeaponToPed(PlayerPedId(), t_Weapons[i][1], GetWeaponClipSize(t_Weapons[i][1]) * 5, false, false)
                            end
                        end
                    end
                end
    
                SwagUI.Display()	
            elseif SwagUI.IsMenuOpened("LocalMachineGunWeapons") then
                for i = 1, #t_Weapons do
                    if t_Weapons[i][5] == "lmgs" then
                        if t_Weapons[i][6] then
                            if weaponMkSelection[i] == nil then weaponMkSelection[i] = 1 end
                            
                            if SwagUI.ComboBox(t_Weapons[i][2], ComboOptions.MK2.Words, weaponMkSelection[i], function(selectedIndex)
                                if weaponMkSelection[i] ~= selectedIndex then
                                    weaponMkSelection[i] = selectedIndex
                                end
                            end) then 
                                PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                                GiveWeaponToPed(PlayerPedId(), GetHashKey(t_Weapons[i][1] .. ComboOptions.MK2.Values[weaponMkSelection[i]]), 150, false, false)
                            end
                        else
                            if SwagUI.Button(t_Weapons[i][2]) then
                                PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                                GiveWeaponToPed(PlayerPedId(), t_Weapons[i][1], GetWeaponClipSize(t_Weapons[i][1]) * 5, false, false)
                            end
                        end
                    end
                end
    
                SwagUI.Display()
            elseif SwagUI.IsMenuOpened("LocalSmgWeapons") then
                for i = 1, #t_Weapons do
                    if t_Weapons[i][5] == "smgs" then
                        if t_Weapons[i][6] then
                            if weaponMkSelection[i] == nil then weaponMkSelection[i] = 1 end
                            
                            if SwagUI.ComboBox(t_Weapons[i][2], ComboOptions.MK2.Words, weaponMkSelection[i], function(selectedIndex)
                                if weaponMkSelection[i] ~= selectedIndex then
                                    weaponMkSelection[i] = selectedIndex
                                end
                            end) then 
                                PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                                GiveWeaponToPed(PlayerPedId(), GetHashKey(t_Weapons[i][1] .. ComboOptions.MK2.Values[weaponMkSelection[i]]), 150, false, false)
                            end
                        else
                            if SwagUI.Button(t_Weapons[i][2]) then
                                PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                                GiveWeaponToPed(PlayerPedId(), t_Weapons[i][1], GetWeaponClipSize(t_Weapons[i][1]) * 5, false, false)
                            end
                        end
                    end
                end
    
                SwagUI.Display()
            elseif SwagUI.IsMenuOpened("LocalSniperRifles") then
                for i = 1, #t_Weapons do
                    if t_Weapons[i][5] == "sniperrifles" then
                        if t_Weapons[i][6] then
                            if weaponMkSelection[i] == nil then weaponMkSelection[i] = 1 end
                            
                            if SwagUI.ComboBox(t_Weapons[i][2], ComboOptions.MK2.Words, weaponMkSelection[i], function(selectedIndex)
                                if weaponMkSelection[i] ~= selectedIndex then
                                    weaponMkSelection[i] = selectedIndex
                                end
                            end) then 
                                PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                                GiveWeaponToPed(PlayerPedId(), GetHashKey(t_Weapons[i][1] .. ComboOptions.MK2.Values[weaponMkSelection[i]]), 150, false, false)
                            end
                        else
                            if SwagUI.Button(t_Weapons[i][2]) then
                                PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                                GiveWeaponToPed(PlayerPedId(), t_Weapons[i][1], GetWeaponClipSize(t_Weapons[i][1]) * 5, false, false)
                            end
                        end
                    end
                end
    
                SwagUI.Display()
            elseif SwagUI.IsMenuOpened("LocalHeavyWeapons") then
                for i = 1, #t_Weapons do
                    if t_Weapons[i][5] == "heavyweapons" then
                        if SwagUI.Button(t_Weapons[i][2]) then
                            PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                            GiveWeaponToPed(PlayerPedId(), t_Weapons[i][1], GetWeaponClipSize(t_Weapons[i][1]) * 5, false, false)
                        end
                    end
                end
    
                SwagUI.Display()
            elseif SwagUI.IsMenuOpened("LocalVehicleMenu") then

                local vehicle = GetVehiclePedIsUsing(PlayerPedId())
    
                if SwagUI.MenuButton("Spawnear Vehiculo", "LocalVehicleSpawner") then
                end

                if SwagUI.CheckBox("Godmode Vehiculo", VehGod,
                        function(enabled)
                            VehGod = enabled
                        end) 
                    then
                end

                if SwagUI.Button("~g~Reparar Vehiculo") then
                    RepairVehicle(vehicle)
                end

                if SwagUI.Button("Maxear Vehiculo") then
                    MaxTuneVehicle(vehicle)
                end

                if speedmit then
                    if SwagUI.Button("~r~Detener Autopilot") then
                        SwagUI.CloseMenu()
                        speedmit = false
                        if IsPedInAnyVehicle(PlayerPedId()) then
                            ClearPedTasks(PlayerPedId())
                        else
                            ClearPedTasksImmediately(PlayerPedId())
                        end
                    end
                else
                    if SwagUI.Button("~b~Iniciar Autopilot") then
                        if (IsPedInAnyVehicle(PlayerPedId(), false)) then
                            if (GetPedInVehicleSeat(vehicle, -1)) then
                                if DoesBlipExist(GetFirstBlipInfoId(8)) then
                                    SwagUI.CloseMenu()
                                    speedmit = true
                                    local WaypointCoords = nil
                            
                                    if DoesBlipExist(GetFirstBlipInfoId(8)) then
                                        local blipIterator = GetBlipInfoIdIterator(8)
                                        local blip = GetFirstBlipInfoId(8, blipIterator)
                                        WaypointCoords = Citizen.InvokeNative(0xFA7C7F0AADF25D09, blip, Citizen.ResultAsVector())
                                    else
                                        drawNotification("~r~Tienes que marcar un punto en el mapa!")
                                    end
                                    if WaypointCoords ~= nil then
                                        ClearPedTasks(PlayerPedId())
                                        DriveWanderTaskActive = false
                                        DriveToWpTaskActive = true
                            
                                        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                                        local vehicleEntity = GetEntityModel(vehicle)
                            
                                        SetDriverAbility(PlayerPedId(), 1)
                                        SetDriverAggressiveness(PlayerPedId(), 0)
                            
                                        if GetVehicleModelMaxSpeed ~= nil then
                                            TaskVehicleDriveToCoordLongrange(PlayerPedId(), vehicle, WaypointCoords, GetVehicleModelMaxSpeed(vehicleEntity), 303, 5)
                                        else
                                            TaskVehicleDriveToCoordLongrange(PlayerPedId(), vehicle, WaypointCoords, Citizen.InvokeNative(0xF417C2502FFFED43, vehicleEntity), 303, 5)
                                        end
                                        Citizen.CreateThread(function()
                                            while DriveToWpTaskActive and GetDistanceBetweenCoords(WaypointCoords, GetEntityCoords(vehicle), false) > 15 do
                                                if GetDistanceBetweenCoords(WaypointCoords, GetEntityCoords(vehicle) , false) < 15 then
                                                    ParkVehicle(vehicle)
                                                end
                                                Wait(0)
                                            end
                                        end)
                                    else
                                        drawNotification("~r~Tienes que marcar un punto en el mapa!")
                                    end
                                    -- local blipIterator = GetBlipInfoIdIterator(8)
                                    -- local blip = GetFirstBlipInfoId(8, blipIterator)
                                    -- local wp = Citizen.InvokeNative(0xFA7C7F0AADF25D09, blip, Citizen.ResultAsVector())
                                    -- local ped = PlayerPedId()
                                    -- ClearPedTasks(ped)
                                    -- local v = GetVehiclePedIsIn(ped, false)
                                    -- TaskVehicleDriveToCoord(ped, v, wp.x, wp.y, wp.z, tonumber(ojtgh), 156, v, 2883621, 5.5, true)
                                    -- SetDriveTaskDrivingStyle(ped, 2883621)
                                else
                                    drawNotification("~r~Tienes que marcar un punto en el mapa!")
                                end
                            else
                                drawNotification("~r~Tienes que ser el conductor")
                            end
                        else
                            drawNotification("~r~Tienes que estar en un vehiculo")
                        end
                    end
                end

                if SwagUI.Button("Limpiar Vehiculo") then
                    SetVehicleDirtLevel(vehicle, 0.0)
                end

                if SwagUI.Button("Voltear Vehiculo") then
                    FlipVehicle(vehicle)
                end

                if SwagUI.CheckBox("Sin Colisiones", Swag.Toggle.VehicleCollision, function(enabled) 
                    Swag.Toggle.VehicleCollision = enabled
                end) then end

                if SwagUI.Button("~r~Eliminar Vehiculo") then
                    RemoveVehicle(vehicle)
                end
    
                SwagUI.Display()
            elseif SwagUI.IsMenuOpened("LocalVehicleSpawner") then
                if SwagUI.CheckBox("Spawnear subido al Vehiculo", Swag.Toggle.SpawnInVehicle, function(enabled)
                    Swag.Toggle.SpawnInVehicle = enabled
                end) then end
                
                if SwagUI.CheckBox("Reemplazar Vehiculo actual", Swag.Toggle.ReplaceVehicle, function(enabled) 
                    Swag.Toggle.ReplaceVehicle = enabled 
                end) then end
    
    
                if SwagUI.Button("Spawnear Vehiculo") then
                    local modelName = KeyboardInput("Introduce el nombre del vehiculo", "", 20)
                    if not modelName then -- Do nothing in case of accidentel press or change of mind
                    elseif IsModelValid(modelName) and IsModelAVehicle(modelName) then
                        SpawnLocalVehicle(modelName, Swag.Toggle.ReplaceVehicle, Swag.Toggle.SpawnInVehicle)
                    else
                        drawNotification("~r~El modelo del vehiculo no es valido")
                        -- SwagUI.SendNotification({text = string.format("%s is not a valid vehicle", modelName), type = 'error'})
                    end
                end
                SwagUI.Display()
            elseif SwagUI.IsMenuOpened("ServerMenu") then
                SwagUI.SetSubTitle("ServerMenu", "Opciones del Servidor")
                if SwagUI.Button("Eliminar todos los ~b~vehiculos") then
                    TriggerServerEvent('RB3:clearallveh')
                    drawNotification("~b~Todos los vehiculos~p~ no ocupados~b~ han sido eliminados")
                end
                if SwagUI.Button("Eliminar todos los ~r~peds") then
                    TriggerServerEvent('RB3:clearallpeds')
                    drawNotification("~b~Todos los peds han sido eliminados")
                end
                if SwagUI.Button("Eliminar todos los ~y~objetos") then
                    TriggerServerEvent('RB3:clearallobjects')
                    drawNotification("~b~Todos los objetos han sido eliminados")
                end
    
                SwagUI.Display()

            elseif SwagUI.IsMenuOpened("OnlinePlayersMenu") then

                -- TriggerServerEvent('RB3:MenuOpened')
                -- Citizen.Wait(500)

                -- onlinePlayerSelected = {}

                -- for k,v in pairs(PlayersOnline) do
                --     local player = menu3:AddButton({ icon = ''..Emoji.Bot..'', label = v.name, value = menu7, description = 'Server ID: '..v.id})
                --     if player then
                --         playerid = v.id
                --     end
                -- end

                
                ---- ANTERIOR

                -- local plist = GetActivePlayers()
                -- for i = 1, #plist do
                --     local id = plist[i]
                --     onlinePlayerSelected[i] = id -- equivalent to table.insert(table, value) but faster
    
                --     -- if SwagUI.MenuButton(("~b~%-4d ~s~%s"):format(GetPlayerServerId(id), GetPlayerName(id)), 'PlayerOptionsMenu') then
                --     -- if SwagUI.MenuButton(("~s~%s ~b~%-4d ~s~%s ~s~%s"):format("[", GetPlayerServerId(id), "]", IsPedDeadOrDying(GetPlayerPed(currPlayer), 1) and "~g~"..GetPlayerName(id) or "~r~"..GetPlayerName(id)), 'PlayerOptionsMenu') then
                --     if SwagUI.MenuButton("~b~[ "..GetPlayerServerId(id).." ] ~s~"..GetPlayerName(id), 'PlayerOptionsMenu') then
                --         print(id)
                --         SelectedPlayer = id
                --     end
                -- end
                -----------------------
    
                -- local index = menus[currentMenu].currentOption
    
                -- SwagUI.DrawPlayerInfo(onlinePlayerSelected[index])
                -- SwagUI.Display()

                for i = 1, #PlayersOnline do
                    -- if SwagUI.MenuButton(("~b~%-4d ~s~%s"):format(GetPlayerServerId(id), GetPlayerName(id)), 'PlayerOptionsMenu') then
                    -- if SwagUI.MenuButton(("~s~%s ~b~%-4d ~s~%s ~s~%s"):format("[", GetPlayerServerId(id), "]", IsPedDeadOrDying(GetPlayerPed(currPlayer), 1) and "~g~"..GetPlayerName(id) or "~r~"..GetPlayerName(id)), 'PlayerOptionsMenu') then
                    if SwagUI.MenuButton("~b~[ "..PlayersOnline[i].id.." ] ~s~"..PlayersOnline[i].name, 'PlayerOptionsMenu') then
                        SelectedPlayer = PlayersOnline[i].id
                        SelectedPlayerName = PlayersOnline[i].name
                    end
                end

                SwagUI.Display()
            
            elseif SwagUI.IsMenuOpened("PlayerOptionsMenu") then
                -- (IsPedDeadOrDying(dataPed, 1) and "~r~Dead " or "~g~Alive"))
                SwagUI.SetSubTitle("PlayerOptionsMenu", "~b~[ "..SelectedPlayer.." ] ~s~"..SelectedPlayerName)
                
                if SwagUI.Button("Espectear", (spectenting and "~b~[ESPECTEANDO]")) then
                    local mylocalid = GetPlayerServerId(PlayerId()) -- ID executor
                    if tonumber(mylocalid) == tonumber(SelectedPlayer) then
                        drawNotification("~r~No puedes verte a ti mismo")
                    else
                        TriggerServerEvent('erp_adminmenu:spectate', SelectedPlayer)
                    end

                    -- TriggerServerEvent('EasyAdmin:requestSpectate', SelectedPlayer)
                    -- TriggerServerEvent('RB3:ReqSpectate', SelectedPlayer)
                    -- CreateThreadNow(function()
                    --     SpectatePlayer(SelectedPlayer)
                    -- end)
                end

                if SwagUI.CheckBox("~b~Congelar", freezePlayer,
                        function(enabled)
                            freezePlayer = enabled
                            -- TriggerServerEvent('RB3:freeze', SelectedPlayer)
                            -- local piduser = SelectedPlayer
                            -- funcfreezePlayer(SelectedPlayer)
                            TriggerServerEvent('RB3:freeze', SelectedPlayer)
                        end) 
                    then
                end

                if SwagUI.Button("Dar vida") then
                    TriggerServerEvent('RB3:sheal', SelectedPlayer)
                    -- CreatePickup(GetHashKey("PICKUP_HEALTH_STANDARD"), GetEntityCoords(GetPlayerPed(SelectedPlayer)))
                    -- SetEntityHealth(GetPlayerPed(SelectedPlayer), 200)
                end
    
                if SwagUI.Button("TP al jugador") then
                    local mylocalid = GetPlayerServerId(PlayerId()) -- ID executor
                    if tonumber(mylocalid) == tonumber(SelectedPlayer) then
                        drawNotification("~r~No puedes ir a ti mismo")
                    else
                        TriggerServerEvent('RB3:sgoto', SelectedPlayer)
                    end
                    -- Swag.Game:TeleportToPlayer(SelectedPlayer)
                end
    
                -- if SwagUI.Button("TP a su vehiculo") then
                --     local mylocalid = GetPlayerServerId(PlayerId()) -- ID executor
                --     if tonumber(mylocalid) == tonumber(SelectedPlayer) then
                --         drawNotification("~r~No puedes ir a ti mismo")
                --     else
                --         TriggerServerEvent('RB3:sgotoveh', SelectedPlayer)
                --     end
                --     -- TeleportToPlayerVehicle(SelectedPlayer)
                -- end

                if SwagUI.Button("~g~Revivir") then
                    TriggerServerEvent('esx_ambulancejob:revive', SelectedPlayer)
                end
    
                if SwagUI.MenuButton("Vehiculo", "OnlineVehicleMenuPlayer") then end

                if SwagUI.Button("Matar jugador") then
                    TriggerServerEvent('RB3:sdead', SelectedPlayer)
                    -- AddExplosion(GetEntityCoords(GetPlayerPed(SelectedPlayer)), 33, 101.0, false, true, 0.0)
                    -- SetEntityHealth(SelectedPlayer, 0)
                end

                if SwagUI.Button("~r~Eliminar todas sus armas") then
                    TriggerServerEvent('RB3:sdelweap', SelectedPlayer)
                    -- local ped = GetPlayerPed(SelectedPlayer)
                    -- RequestControlOnce(ped)
                    -- for i = 1, #t_Weapons do
                    --     RemoveWeaponFromPed(ped, t_Weapons[i][1])
                    -- end
                end
    
                -- SwagUI.DrawPlayerInfo(SelectedPlayer)
                SwagUI.Display()
            elseif SwagUI.IsMenuOpened("OnlineWepMenu") then
                SwagUI.SetSubTitle("OnlineWepMenu", "Weapon Options - " .. SelectedPlayerName .. "")
                SwagUI.MenuButton("Armas", "OnlineWepCategory")
    
                -- SwagUI.DrawPlayerInfo(SelectedPlayer)
                SwagUI.Display()
            
            elseif SwagUI.IsMenuOpened("OnlineWepCategory") then
                SwagUI.SetSubTitle("OnlineWepCategory", "Give Weapon - " .. SelectedPlayerName .. "")
    
                SwagUI.MenuButton("Cuerpo a Cuerpo", "OnlineMeleeWeapons")
                SwagUI.MenuButton("Pistolas", "OnlineSidearmWeapons")
                SwagUI.MenuButton("Subfusiles")
                SwagUI.MenuButton("Escopetas", "OnlineShotgunWeapons")
                SwagUI.MenuButton("Rifles de Asalto", "OnlineAutorifleWeapons")
                SwagUI.MenuButton("Armas ligeras")
                SwagUI.MenuButton("Snipers")
    
                -- SwagUI.DrawPlayerInfo(SelectedPlayer)
                SwagUI.Display()
            
            elseif SwagUI.IsMenuOpened("OnlineMeleeWeapons") then
                for i = 1, #t_Weapons do
                    if t_Weapons[i][5] == "melee" then
                        if SwagUI.Button(t_Weapons[i][2]) then
                            GiveWeaponToPed(GetPlayerPed(SelectedPlayer), t_Weapons[i][1], 0, false, false)
                        end
                    end
                end
    
                -- SwagUI.DrawPlayerInfo(SelectedPlayer)
                SwagUI.Display()
            
            elseif SwagUI.IsMenuOpened("OnlineSidearmWeapons") then
                for i = 1, #t_Weapons do
                    if t_Weapons[i][5] == "handguns" then
                        if SwagUI.Button(t_Weapons[i][2]) then
                            GiveWeaponToPed(GetPlayerPed(SelectedPlayer), t_Weapons[i][1], 32, false, false)
                        end
                    end
                end
    
                -- SwagUI.DrawPlayerInfo(SelectedPlayer)
                SwagUI.Display()
            
            elseif SwagUI.IsMenuOpened("OnlineAutorifleWeapons") then
                for i = 1, #t_Weapons do
                    if t_Weapons[i][5] == "assaultrifles" then
                        if SwagUI.Button(t_Weapons[i][2]) then
                            GiveWeaponToPed(GetPlayerPed(SelectedPlayer), t_Weapons[i][1], 60, false, false)
                        end
                    end
                end
    
                -- SwagUI.DrawPlayerInfo(SelectedPlayer)
                SwagUI.Display()
            
            elseif SwagUI.IsMenuOpened("OnlineShotgunWeapons") then
                for i = 1, #t_Weapons do
                    if t_Weapons[i][5] == "shotguns" then
                        if SwagUI.Button(t_Weapons[i][2]) then
                            GiveWeaponToPed(GetPlayerPed(SelectedPlayer), t_Weapons[i][1], 18, false, false)
                        end
                    end
                end
    
                -- SwagUI.DrawPlayerInfo(SelectedPlayer)
                SwagUI.Display()
            
            elseif SwagUI.IsMenuOpened("OnlineVehicleMenuPlayer") then
                SwagUI.SetSubTitle("OnlineVehicleMenuPlayer", "Vehiculo [" .. SelectedPlayerName .. "]")
                if SwagUI.Button("~b~Dar Vehiculo") then
                    local ModelName = KeyboardInput("Introduce el nombre del Vehiculo", "", 12)
                    if ModelName and IsModelValid(ModelName) and IsModelAVehicle(ModelName) then
                        -- RequestModel(ModelName)
                        -- while not HasModelLoaded(ModelName) do
                        --     Citizen.Wait(0)
                        -- end

                        TriggerServerEvent('RB3:sgiveveh', SelectedPlayer, ModelName)
    
                        -- local veh = CreateVehicle(GetHashKey(ModelName), GetEntityCoords(GetPlayerPed(SelectedPlayer)), GetEntityHeading(GetPlayerPed(SelectedPlayer)), true, true)
                        
                        -- RequestControlOnce(ped)
                        -- SetPedIntoVehicle(ped, veh, -1)
                        -- TaskWarpPedIntoVehicle(ped, veh, -1)
                        -- SwagUI.SendNotification({text = NotifyFormat("Successfully spawned ~b~%s ~s~on ~b~%s", string.lower(GetDisplayNameFromVehicleModel(ModelName)), SelectedPlayerName), type = "info"})
                    else
                        -- SwagUI.SendNotification({text = "Model is not valid", type = "error"})
                    end
                end

                if SwagUI.Button("Expulsar del Vehiculo") then
                    TriggerServerEvent('RB3:sexpulsarveh', SelectedPlayer)
                    -- ClearPedTasksImmediately(GetPlayerPed(SelectedPlayer))
                end

                -- if SwagUI.Button("Borrar Vehiculo") then
                --     TriggerServerEvent('RB3:sborrarsarveh', SelectedPlayer)
                --     -- local playerPed = GetPlayerPed(SelectedPlayer)
                --     -- local veh = GetVehiclePedIsIn(playerPed)
                --     -- RemoveVehicle(veh)
                -- end

                -- if SwagUI.Button("Robar Vehiculo") then
                --     TriggerServerEvent('RB3:srobarveh', SelectedPlayer)
    
                --     -- local ped = GetPlayerPed(SelectedPlayer)
                --     -- local vehicle = GetVehiclePedIsUsing(ped)
                --     -- local StealVehicleThread = StealVehicle(vehicle)
                --     -- CreateThreadNow(StealVehicleThread)
                -- end
    
                -- if SwagUI.Button("Reparar Vehiculo") then
                --     local ped = GetPlayerPed(SelectedPlayer)
                --     local vehicle = GetVehiclePedIsUsing(ped)
                --     RepairVehicle(vehicle)
                -- end
    
                -- SwagUI.DrawPlayerInfo(SelectedPlayer)
                SwagUI.Display()
            end
            
            Wait(0)
        end
    end
    CreateThread(MenuRuntimeThread)   
end

Access = true
isMenuEnabled = true
rb3menu()

-- RegisterCommand('r3start', function()
--     -- if Access and not isMenuEnabled then
--     --     isMenuEnabled = true
-- 	-- 	rb3menu()
--     -- end
--     TriggerServerEvent('RB3:CheckIsAdmin')
-- end, false)

-- RegisterCommand('rb3acmenu', function()
--     if Access and not isMenuEnabled then
--         isMenuEnabled = true
-- 		rb3menu()
--     end
-- end, false)

-- RegisterKeyMapping('rb3acmenu', 'RB3 Admin Menu', 'keyboard', 'DELETE')

-- local firstSpawn = true
-- AddEventHandler('playerSpawned', function()
--     Wait(2000)
--     if firstSpawn then
--         TriggerServerEvent('RB3:CheckIsAdmin')
--         Wait(10000)
--         while IsPlayerSwitchInProgress() do
--             Wait(1000)
--         end
--         firstSpawn = false
--     end
-- end)

-- RegisterNetEvent('RB3:AddAdminOption')
-- AddEventHandler('RB3:AddAdminOption', function (DATA)
--     if DATA ~= nil then
--         Access = true
--         drawNotification('~y~[RB3 AC] ~g~Panel disponible', true)
--     end
-- end)

RegisterNetEvent('RB3:GetPlayerList')
AddEventHandler('RB3:GetPlayerList', function (PLIST)
    PlayersOnline = PLIST
end)

RegisterNetEvent('RB3:healear')
AddEventHandler('RB3:healear', function(targetPed)
	local ped = PlayerPedId()
    local player = PlayerId()
    local nombrass = GetPlayerName(player)
    SetEntityHealth(ped, 200)
    drawNotification("~r~Has recibido vida por: ~n~~b~"..nombrass.."~s~")
end)

RegisterNetEvent('RB3:killear')
AddEventHandler('RB3:killear', function(targetPed)
	local ped = PlayerPedId()
    local player = PlayerId()
    local nombrass = GetPlayerName(player)
    SetEntityHealth(ped, 0)
    drawNotification("~r~Has sido matado por: ~n~~b~"..nombrass.."~s~")
end)

RegisterNetEvent('RB3:cdelweap')
AddEventHandler('RB3:cdelweap', function(targetPed)

    local ped = PlayerPedId()
    local player = PlayerId()
    local nombrass = GetPlayerName(player)
    RequestControlOnce(ped)
    for i = 1, #t_Weapons do
        RemoveWeaponFromPed(ped, t_Weapons[i][1])
    end

    drawNotification("~r~Tus armas han sido eliminadas por: ~n~~b~"..nombrass.."~s~")
end)

RegisterNetEvent('RB3:delallveh')
AddEventHandler('RB3:delallveh', function()
    local entityEnumerator = {
        __gc = function(enum)
            if enum.destructor and enum.handle then
            enum.destructor(enum.handle)
            end
            enum.destructor = nil
            enum.handle = nil
        end
    }
      
    local function EnumerateEntities(initFunc, moveFunc, disposeFunc)
        return coroutine.wrap(function()
            local iter, id = initFunc()
            if not id or id == 0 then
            disposeFunc(iter)
            return
            end
            
            local enum = {handle = iter, destructor = disposeFunc}
            setmetatable(enum, entityEnumerator)
            
            local next = true
            repeat
            coroutine.yield(id)
            next, id = moveFunc(iter)
            until not next
            
            enum.destructor, enum.handle = nil, nil
            disposeFunc(iter)
        end)
    end      

    function EnumerateVehicles()
        return EnumerateEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle)
    end
    for vehicle in EnumerateVehicles() do
        if IsVehicleSeatFree(vehicle, -1) then
            SetEntityAsMissionEntity(GetVehiclePedIsIn(vehicle, true), 1, 1)
            DeleteEntity(GetVehiclePedIsIn(vehicle, true))
            SetEntityAsMissionEntity(vehicle, 1, 1)
            DeleteEntity(vehicle)
        end
    end
end)

RegisterNetEvent('RB3:delallpeds')
AddEventHandler('RB3:delallpeds', function()
    local entityEnumerator = {
        __gc = function(enum)
            if enum.destructor and enum.handle then
            enum.destructor(enum.handle)
            end
            enum.destructor = nil
            enum.handle = nil
        end
    }
      
    local function EnumerateEntities(initFunc, moveFunc, disposeFunc)
        return coroutine.wrap(function()
            local iter, id = initFunc()
            if not id or id == 0 then
            disposeFunc(iter)
            return
            end
            
            local enum = {handle = iter, destructor = disposeFunc}
            setmetatable(enum, entityEnumerator)
            
            local next = true
            repeat
            coroutine.yield(id)
            next, id = moveFunc(iter)
            until not next
            
            enum.destructor, enum.handle = nil, nil
            disposeFunc(iter)
        end)
    end

    function EnumeratePeds()
        return EnumerateEntities(FindFirstPed, FindNextPed, EndFindPed)
      end

    for ped in EnumeratePeds() do
        if not (IsPedAPlayer(ped))then
            RemoveAllPedWeapons(ped, true)
            DeleteEntity(ped)
        end
    end
end)

RegisterNetEvent('RB3:delallobjects')
AddEventHandler('RB3:delallobjects', function()
    local entityEnumerator = {
        __gc = function(enum)
            if enum.destructor and enum.handle then
            enum.destructor(enum.handle)
            end
            enum.destructor = nil
            enum.handle = nil
        end
    }
      
    local function EnumerateEntities(initFunc, moveFunc, disposeFunc)
        return coroutine.wrap(function()
            local iter, id = initFunc()
            if not id or id == 0 then
            disposeFunc(iter)
            return
            end
            
            local enum = {handle = iter, destructor = disposeFunc}
            setmetatable(enum, entityEnumerator)
            
            local next = true
            repeat
            coroutine.yield(id)
            next, id = moveFunc(iter)
            until not next
            
            enum.destructor, enum.handle = nil, nil
            disposeFunc(iter)
        end)
    end

    function EnumerateObjects()
        return EnumerateEntities(FindFirstObject, FindNextObject, EndFindObject)
      end

    for obj in EnumerateObjects() do
        DeleteEntity(obj)
    end
end)

RegisterNetEvent('RB3:freezear')
AddEventHandler('RB3:freezear', function(targetPed)

    local player = PlayerId()
	local ped = PlayerPedId()
    local nombrass = GetPlayerName(player)

	frozen = not frozen

	if not frozen then
		if not IsEntityVisible(ped) then
			SetEntityVisible(ped, true)
		end

		if not IsPedInAnyVehicle(ped) then
			SetEntityCollision(ped, true)
		end

		FreezeEntityPosition(ped, false)
		SetPlayerInvincible(player, false)
	else
        drawNotification("~r~Has sido freezeado por: ~n~~b~"..nombrass.."~s~")
		SetEntityCollision(ped, false)
		FreezeEntityPosition(ped, true)
		SetPlayerInvincible(player, true)

		if not IsPedFatallyInjured(ped) then
			ClearPedTasksImmediately(ped)
		end
	end

    -- local player = PlayerId()
	-- local ped = PlayerPedId()
    -- if input == 'freeze' then
    --     SetEntityCollision(ped, false)
    --     FreezeEntityPosition(ped, true)
    --     SetPlayerInvincible(player, true)
    -- elseif input == 'unfreeze' then
    --     SetEntityCollision(ped, true)
	--     FreezeEntityPosition(ped, false)
    --     SetPlayerInvincible(player, false)
    -- end

    -- ------------------------------------------

    -- local ped = PlayerPedId()
    -- isFrozen = not isFrozen

    -- frozenPos = GetEntityCoords(ped, false)

    -- if not isFrozen then
    --     if not IsEntityVisible(ped) then
    --         SetEntityVisible(ped, true)
    --     end

    --     if not IsPedInAnyVehicle(ped) then
    --         SetEntityCollision(ped, true)
    --     end

    --     FreezeEntityPosition(ped, false)
    --     SetPlayerInvincible(player, false)
    -- else
    --     SetEntityCollision(ped, false)
    --     FreezeEntityPosition(ped, true)
    --     SetPlayerInvincible(player, true)

    --     if not IsPedFatallyInjured(ped) then
    --         ClearPedTasksImmediately(ped)
    --     end
    -- end
end)

RegisterNetEvent('RB3:SpectatePlayer')
AddEventHandler('RB3:SpectatePlayer', function(playerId, tgtCoords)
    SetPlayerInvincible(PlayerId(), true)
    oldCoords = GetEntityCoords(PlayerPedId())
    FreezeEntityPosition(PlayerPedId(PlayerPedId()), true)
    SetEntityCoords(PlayerPedId(), tgtCoords.x, tgtCoords.y, tgtCoords.z - 10.0, 0, 0, 0, false)
    Wait(100)
    local playerId = GetPlayerFromServerId(playerId)
    if not tgtCoords or tgtCoords.z == 0 then tgtCoords = GetEntityCoords(GetPlayerPed(playerId)) end
    SetEntityCoords(PlayerPedId(), tgtCoords.x, tgtCoords.y, tgtCoords.z - 10.0, 0, 0, 0, false)
    Wait(500)
    local adminPed = PlayerPedId()
    spectate(GetPlayerPed(playerId),playerId,GetPlayerName(playerId))
    -- if COORDS ~= nil then
    --     spectate(TARGET, COORDS)
    -- end
end)

RegisterNetEvent('RB3:trysgotoveh')
AddEventHandler('RB3:trysgotoveh', function(udjugador, vehiic)

    print('hehe?')
    local player = PlayerId() -- MI IDENTIDAD
	local ped = PlayerPedId()
    local ped2 = GetPlayerPed(player)
    if not IsPedInAnyVehicle(ped2) then
        print('No está en coche')
    else
        print('Está en coche')
    end

    print('EL OTRO:')
    print(vehiic)

    if not IsPedInAnyVehicle(ped) then
        print('No está en coche')
    else
        print('Está en coche')
    end
    --     if not IsPedInAnyVehicle(ped) then
    --         -- return SwagUI.SendNotification({text = ("%s is not in a vehicle!"):format(GetPlayerName(player)), type = "error"})
    --     end
    
    --     local vehicle = GetVehiclePedIsUsing(GetPlayerPed(player))
    
    --     local seats = GetVehicleMaxNumberOfPassengers(vehicle)
    --     for i = 0, seats do
    --         if IsVehicleSeatFree(vehicle, i) then
    --             SetPedIntoVehicle(PlayerPedId(), vehicle, i)
    --             break
    --         end
    --     end
    -- local initusuario = GetPlayerPed(PlayerId())
    -- local vehicleaso = GetVehiclePedIsUsing(PlayerPedId())
    -- local vehicleaso2 = GetVehiclePedIsUsing(GetPlayerPed(PlayerId()))
    -- print(vehicleaso)
    -- print(vehicleaso2)

    -- local seats = GetVehicleMaxNumberOfPassengers(vehicleaso)

    -- print('hehe33')
    -- print(PlayerPedId())
    -- print(PlayerId())
    -- for i = 0, seats do
    --     if IsVehicleSeatFree(vehicleaso, i) then
    --         SetPedIntoVehicle(initusuario, vehicleaso, i)
    --         break
    --     end
    -- end

end)

function spectatePlayer(targetPed,target,name)
	local playerPed = PlayerPedId() -- yourself
	enable = true
	if (target == PlayerId() or target == -1) then 
		enable = false
	end

	if(enable)then
		SetEntityVisible(playerPed, false, 0)
		SetEntityCollision(playerPed, false, false)
		SetEntityInvincible(playerPed, true)
		NetworkSetEntityInvisibleToNetwork(playerPed, true)
		Citizen.Wait(200) -- to prevent target player seeing you
		if targetPed == playerPed then
			Wait(500)
			targetPed = GetPlayerPed(target)
		end
		local targetx,targety,targetz = table.unpack(GetEntityCoords(targetPed, false))
		RequestCollisionAtCoord(targetx,targety,targetz)
		NetworkSetInSpectatorMode(true, targetPed)
		
		DrawPlayerInfo(target)
		TriggerEvent("EasyAdmin:showNotification", string.format(GetLocalisedText("spectatingUser"), name))
	else
		if oldCoords then
			RequestCollisionAtCoord(oldCoords.x, oldCoords.y, oldCoords.z)
			Wait(500)
			SetEntityCoords(playerPed, oldCoords.x, oldCoords.y, oldCoords.z, 0, 0, 0, false)
			oldCoords=nil
		end
		NetworkSetInSpectatorMode(false, targetPed)
		StopDrawPlayerInfo()
		TriggerEvent("EasyAdmin:showNotification", GetLocalisedText("stoppedSpectating"))
		frozen = false
		Citizen.Wait(200) -- to prevent staying invisible
		SetEntityVisible(playerPed, true, 0)
		SetEntityCollision(playerPed, true, true)
		SetEntityInvincible(playerPed, false)
		NetworkSetEntityInvisibleToNetwork(playerPed, false)
		if vehicleInfo.netId and vehicleInfo.seat then
			local vehicle = NetToVeh(vehicleInfo.netId)
			if DoesEntityExist(vehicle) then
				if IsVehicleSeatFree(vehicle, vehicleInfo.seat) then
					SetPedIntoVehicle(playerPed, vehicle, vehicleInfo.seat)
				else
					TriggerEvent("EasyAdmin:showNotification", GetLocalisedText("spectatevehicleseatoccupied"))
				end
			else
				TriggerEvent("EasyAdmin:showNotification", GetLocalisedText("spectatenovehiclefound"))
			end

			vehicleInfo.netId = nil
			vehicleInfo.seat = nil
		end
	end
end

RegisterNetEvent('EasyAdmin:requestSpectate')
AddEventHandler("EasyAdmin:requestSpectate", function(playerServerId, tgtCoords)

        local playerId = GetPlayerFromServerId(playerServerId)
        local selectedPlayerPed = GetPlayerPed(playerId)

        print(playerId)
        print(selectedPlayerPed)

        print('especteandoo')
    
        DoScreenFadeOut(500)
        while IsScreenFadingOut() do Wait(0) end

        RequestCollisionAtCoord(GetEntityCoords(selectedPlayerPed))

        NetworkSetInSpectatorMode(false, 0)
        NetworkSetInSpectatorMode(true, selectedPlayerPed)
        SetMinimapInSpectatorMode(true, selectedPlayerPed)

        TaskWanderStandard(PlayerPedId(), 0, 0)
        DoScreenFadeIn(500)
        
        -- if Swag.Player.Spectating then
    
        --     RequestCollisionAtCoord(GetEntityCoords(PlayerPedId()))
    
        --     DoScreenFadeOut(500)
        --     while IsScreenFadingOut() do Wait(0) end
    
        --     NetworkSetInSpectatorMode(false, 0)
        --     SetMinimapInSpectatorMode(false, 0)
    
        --     ClearPedTasks(PlayerPedId())
        --     DoScreenFadeIn(500)
    
        -- else
        --     print('especteandoo')
    
        --     DoScreenFadeOut(500)
        --     while IsScreenFadingOut() do Wait(0) end
    
        --     RequestCollisionAtCoord(GetEntityCoords(selectedPlayerPed))
    
        --     NetworkSetInSpectatorMode(false, 0)
        --     NetworkSetInSpectatorMode(true, selectedPlayerPed)
        --     SetMinimapInSpectatorMode(true, selectedPlayerPed)
    
        --     TaskWanderStandard(PlayerPedId(), 0, 0)
        --     DoScreenFadeIn(500)
            
        -- end

        -- Swag.Player.Spectating = not Swag.Player.Spectating

	-- local localPlayerPed = PlayerPedId()

	-- if IsPedInAnyVehicle(localPlayerPed) then
	-- 	local vehicle = GetVehiclePedIsIn(localPlayerPed, false)
	-- 	local numVehSeats = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle))
	-- 	vehicleInfo.netId = VehToNet(vehicle)
	-- 	for i = -1, numVehSeats do
	-- 		if GetPedInVehicleSeat(vehicle, i) == localPlayerPed then
	-- 			vehicleInfo.seat = i
	-- 			break
	-- 		end
	-- 	end
	-- end

	-- if ((not tgtCoords) or (tgtCoords.z == 0.0)) then tgtCoords = GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(playerServerId))) end
	-- if playerServerId == GetPlayerServerId(PlayerId()) then 
	-- 	if oldCoords then
	-- 		RequestCollisionAtCoord(oldCoords.x, oldCoords.y, oldCoords.z)
	-- 		Wait(500)
	-- 		SetEntityCoords(playerPed, oldCoords.x, oldCoords.y, oldCoords.z, 0, 0, 0, false)
	-- 		oldCoords=nil
	-- 	end
	-- 	spectatePlayer(localPlayerPed,GetPlayerFromServerId(PlayerId()),GetPlayerName(PlayerId()))
	-- 	frozen = false
	-- 	return 
	-- else
	-- 	if not oldCoords then
	-- 		oldCoords = GetEntityCoords(localPlayerPed)
	-- 	end
	-- end
	-- SetEntityCoords(localPlayerPed, tgtCoords.x, tgtCoords.y, tgtCoords.z - 10.0, 0, 0, 0, false)
	-- frozen = true
	-- stopSpectateUpdate = true
	-- local adminPed = localPlayerPed
	-- local playerId = GetPlayerFromServerId(playerServerId)
	-- repeat
	-- 	Wait(200)
	-- 	playerId = GetPlayerFromServerId(playerServerId)
	-- until ((GetPlayerPed(playerId) > 0) and (playerId ~= -1))
	-- spectatePlayer(GetPlayerPed(playerId),playerId,GetPlayerName(playerId))
	-- stopSpectateUpdate = false 
end)