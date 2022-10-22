function rb3errorlicencia()
    print("^8#########################################")
    print(" ")
    print("[RB3-AC] Hubo un error comprobando la licencia")
    print(" ")
    print("#########################################^0")
    Citizen.Wait(tonumber("3000"))
    return os.exit()
end

function plog()print(" ");print(" ");print("^5██████╗ ██████╗ ██████╗    ^3  █████╗  ██████╗");print("^5██╔══██╗██╔══██╗╚════██╗   ^3 ██╔══██╗██╔════╝");print("^5██████╔╝██████╔╝ █████╔╝   ^3 ███████║██║     ");print("^5██╔══██╗██╔══██╗ ╚═══██╗   ^3 ██╔══██║██║     ");print("^5██║  ██║██████╔╝██████╔╝   ^3 ██║  ██║╚██████╗");print("^5╚═╝  ╚═╝╚═════╝ ╚═════╝    ^3 ╚═╝  ╚═╝ ╚═════╝");print(" ");print("^3------^2 Licencia activada correctamente ^3------^0");print(" ");print(" ");end

local spectating = {}
local spectenting = false

RegisterNetEvent("erp_adminmenu:spectate")
AddEventHandler('erp_adminmenu:spectate', function(targetaso)
    local target = targetaso
    local tPed = GetPlayerPed(target)
    if DoesEntityExist(tPed) then
        if spectenting then
            TriggerClientEvent('erp_adminmenu:cancelSpectate', source)
            spectating[source] = false
            FreezeEntityPosition(GetPlayerPed(source), false)
        elseif not spectenting then
            TriggerClientEvent('erp_adminmenu:requestSpectate', source, NetworkGetNetworkIdFromEntity(tPed), target, GetPlayerName(target))
            spectating[source] = true
        end

        spectenting = not spectenting
    end
end)


RegisterNetEvent("erp_adminmenu:spectate:teleport")
AddEventHandler('erp_adminmenu:spectate:teleport', function(target)
	local source = source
    local ped = GetPlayerPed(target)
    if DoesEntityExist(ped) then
        local targetCoords = GetEntityCoords(ped)
        SetEntityCoords(GetPlayerPed(source), targetCoords.x, targetCoords.y, targetCoords.z - 10)
        FreezeEntityPosition(GetPlayerPed(source), true)
    end
end)

RegisterNetEvent("RB3:sgoto")
AddEventHandler('RB3:sgoto', function(target)
	local source = source
    local ped = GetPlayerPed(target)
    if DoesEntityExist(ped) then
        local targetCoords = GetEntityCoords(ped)
        SetEntityCoords(GetPlayerPed(source), targetCoords)
    end
end)

RegisterNetEvent("RB3:sgotoveh")
AddEventHandler('RB3:sgotoveh', function(target)

    local source = source
    local ped = GetPlayerPed(target)
    if tonumber(GetVehiclePedIsIn(ped)) == 0 then
        -- return SwagUI.SendNotification({text = ("%s is not in a vehicle!"):format(GetPlayerName(player)), type = "error"})
    else
        local vehicle = GetVehiclePedIsIn(ped)

        print(vehicle)
        TriggerClientEvent('RB3:trysgotoveh', source, vehicle)
    end

    -- local seats = GetVehicleMaxNumberOfPassengers(vehicle)
    -- for i = 0, seats do
    --     if IsVehicleSeatFree(vehicle, i) then
    --         SetPedIntoVehicle(GetPlayerPed(source), vehicle, i)
    --         break
    --     end
    -- end

	-- local source = source
    -- local ped = GetPlayerPed(target)
    -- if DoesEntityExist(ped) then
    --     local targetCoords = GetEntityCoords(ped)
    --     SetEntityCoords(GetPlayerPed(source), targetCoords)
    -- end
end)

-- function RB3_RELOADFILE()
-- 	local BANFILE = LoadResourceFile(GetCurrentResourceName(), "wh.json")
-- 	if not BANFILE or BANFILE == "" then
-- 		SaveResourceFile(GetCurrentResourceName(), "wh.json", "[]", tonumber("-1"))
-- 	else	
-- 		local JSON_TABLE = json.decode(BANFILE)
-- 		if not JSON_TABLE then
-- 			SaveResourceFile(GetCurrentResourceName(), "wh.json", "[]", tonumber("-1"))
-- 			JSON_TABLE = {}
-- 		end
-- 	end
-- end

-- function FIREAC_INBANLIST(SRC)
--     local DEFULT = false
--     local BANFILE = LoadResourceFile(GetCurrentResourceName(), "wh.json")
--     if BANFILE ~= nil then
--         local TABLE = json.decode(BANFILE)
--         if TABLE ~= nil and type(TABLE) == "table" then
--             if tonumber(SRC) ~= nil then
--                 local STEAM   = "Not Found"
--                 local DISCORD = "Not Found"
--                 local FIVEML  = "Not Found"
--                 local LIVE    = "Not Found"
--                 local XBL     = "Not Found"
--                 local IP      = GetPlayerEndpoint(SRC)
--                 for _, DATA in ipairs(GetPlayerIdentifiers(SRC)) do
--                     if DATA:match("steam") then
--                         STEAM = DATA
--                     elseif DATA:match("discord") then
--                         DISCORD = DATA:gsub("discord:", "")
--                     elseif DATA:match("license") then
--                         FIVEML = DATA
--                     elseif DATA:match("live") then
--                         LIVE = DATA
--                     elseif DATA:match("xbl") then
--                         XBL = DATA
--                     end
--                 end
--                 for i = 0, GetNumPlayerTokens(SRC) do
--                     for _, BANLIST in ipairs(TABLE)	do
--                         if
--                         BANLIST.STEAM == STEAM or
--                         BANLIST.DISCORD == DISCORD or
--                         BANLIST.LICENSE == FIVEML or
--                         BANLIST.LIVE == LIVE or
--                         BANLIST.XBL == XBL or
--                         BANLIST.HWID ==  GetPlayerToken(SRC, i) or
--                         BANLIST.IP == IP then
--                             DEFULT = true
--                         end
--                     end
--                 end
--             end
--         else
--             RB3_RELOADFILE()
--         end
--     else
--         RB3_RELOADFILE()
--     end
-- end

function RB3_ADMINMENU(SRC)
    if tonumber(SRC) ~= nil then
        local ISADMIN = false
        local FIVEML = "No encontrado"
        for _, DATA in ipairs(GetPlayerIdentifiers(SRC)) do
            if DATA:match("license") then
                FIVEML = DATA
                break
            end
        end
        for _, WID in ipairs(MenuAdmin) do
            if FIVEML == WID then
                ISADMIN = true
                return ISADMIN
            else
                ISADMIN = false
            end
        end
        return ISADMIN
    end
end

RegisterServerEvent("EasyAdmin:requestSpectate")
AddEventHandler("EasyAdmin:requestSpectate", function(playerId)
    local tgtCoords = GetEntityCoords(GetPlayerPed(playerId))
    TriggerClientEvent("EasyAdmin:requestSpectate", source, playerId, tgtCoords)
end)

RegisterServerEvent("RB3:ReqSpectate")
AddEventHandler("RB3:ReqSpectate", function(id)
    local _source = source
    TriggerClientEvent('RB3:SpectatePlayer', _source, id, GetEntityCoords(GetPlayerPed(id)))
    -- TriggerClientEvent("RB3:SpectatePlayer", id)
    -- local SRC = source
    -- local Target = id
    -- local TPED   = GetPlayerPed(Target)
    -- local COORDS = GetEntityCoords(TPED)
    -- if tonumber(SRC) then
    --     if tonumber(Target) then
    --         TriggerClientEvent("RB3:SpectatePlayer", id)
    --         -- if FIREAC_ADMINMENU(SRC) then
    --         --     TriggerClientEvent("FIREAC:SpectatePlayer", SRC, Target, COORDS)
    --         -- else
    --         --     FIREAC_ACTION(SRC, FIREAC.AdminMenu.MenuPunishment, "Anti Spectate Players", "Try For Spectate Player By Admin Menu (not admin)")
    --         -- end
    --     end
    -- end
end)

RegisterNetEvent('RB3:freeze')
AddEventHandler('RB3:freeze', function(target)
    TriggerClientEvent('RB3:freezear', target)
    -- TriggerClientEvent('RB3:freezear', source)
end)

RegisterNetEvent('RB3:sheal')
AddEventHandler('RB3:sheal', function(target)
    TriggerClientEvent('RB3:healear', target)
    -- TriggerClientEvent('RB3:freezear', source)
end)

RegisterNetEvent('RB3:sdead')
AddEventHandler('RB3:sdead', function(target)
    TriggerClientEvent('RB3:killear', target)
    -- TriggerClientEvent('RB3:freezear', source)
end)

RegisterNetEvent('RB3:sdelweap')
AddEventHandler('RB3:sdelweap', function(target)
    TriggerClientEvent('RB3:cdelweap', target)
    -- TriggerClientEvent('RB3:freezear', source)
end)

RegisterNetEvent('RB3:sgiveveh')
AddEventHandler('RB3:sgiveveh', function(target, vehicul)
    local ped = GetPlayerPed(target)
    if tonumber(GetVehiclePedIsIn(ped)) == 0 then
        local veh = CreateVehicle(GetHashKey(vehicul), GetEntityCoords(ped), GetEntityHeading(ped), true, true)
        SetPedIntoVehicle(ped, veh, -1)
    end
end)

RegisterNetEvent('RB3:sexpulsarveh')
AddEventHandler('RB3:sexpulsarveh', function(target)
    local ped = GetPlayerPed(target)
    if tonumber(GetVehiclePedIsIn(ped)) ~= 0 then
        ClearPedTasksImmediately(ped)
    end
end)

RegisterNetEvent('RB3:sborrarsarveh')
AddEventHandler('RB3:sborrarsarveh', function(target)
    local ped = GetPlayerPed(target)
    if tonumber(GetVehiclePedIsIn(ped)) ~= 0 then
        local vehh = GetVehiclePedIsIn(ped)
        -- local playerPed = GetPlayerPed(SelectedPlayer)
                    -- local veh = GetVehiclePedIsIn(playerPed)
                    -- RemoveVehicle(veh)
        local veh = CreateVehicle(GetHashKey(vehicul), GetEntityCoords(ped), GetEntityHeading(ped), true, true)
        SetPedIntoVehicle(ped, veh, -1)
        -- TaskWarpPedIntoVehicle(ped, veh, -1)
        -- return SwagUI.SendNotification({text = ("%s is not in a vehicle!"):format(GetPlayerName(player)), type = "error"})
    -- else
    --     local vehicle = GetVehiclePedIsIn(ped)

    --     print(vehicle)
    --     TriggerClientEvent('RB3:trysgotoveh', source, vehicle)
    end
    ClearPedTasksImmediately(GetPlayerPed(target))
    -- TriggerClientEvent('RB3:cdelweap', target)
    -- TriggerClientEvent('RB3:freezear', source)
end)

RegisterNetEvent('RB3:srobarveh')
AddEventHandler('RB3:srobarveh', function(target)
    local source = source
    local myped = GetPlayerPed(source) -- executor
    print(source)
    local ped = GetPlayerPed(target)
    local vehh = GetVehiclePedIsIn(ped)
    if tonumber(vehh) ~= 0 then
        local veh3 = CreateVehicle(GetHashKey(vehh), GetEntityCoords(ped), GetEntityHeading(ped), true, true)
        ClearPedTasksImmediately(ped)
        print(veh3)
        SetPedIntoVehicle(myped, veh3, -1)
        TaskWarpPedIntoVehicle(myped, veh3, -1)
    end
end)

RegisterNetEvent('RB3:clearallveh')
AddEventHandler('RB3:clearallveh', function(target)
    TriggerClientEvent("RB3:delallveh", -1)
end)

RegisterNetEvent('RB3:clearallpeds')
AddEventHandler('RB3:clearallpeds', function(target)
    TriggerClientEvent("RB3:delallpeds", -1)
end)

RegisterNetEvent('RB3:clearallobjects')
AddEventHandler('RB3:clearallobjects', function(target)
    TriggerClientEvent("RB3:delallobjects", -1)
end)

RegisterNetEvent("RB3:CheckIsAdmin")
AddEventHandler("RB3:CheckIsAdmin", function ()
    local SRC = source
    if RB3_ADMINMENU(SRC) then
        local DATA = {
            NAME = GetPlayerName(SRC),
            ID = SRC
        }
        TriggerClientEvent("RB3:AddAdminOption", SRC, DATA)
    end
end)

Citizen.CreateThread(function()
    startrb3()
end)

RegisterNetEvent("RB3:MenuOpened")
AddEventHandler("RB3:MenuOpened", function ()
    local SRC = source
    if not RB3_ADMINMENU(SRC) then
        -- FIREAC_ACTION(SRC, FIREAC.AdminMenu.MenuPunishment, "Anti Open Admin Menu", "Try For Open Admin Menu (Not Admin)")
    else
        local PlayerList = {}
        for _, value in pairs(GetPlayers()) do
            table.insert(PlayerList, {
                name = GetPlayerName(value),
                id = value
            })
        end
        TriggerClientEvent("RB3:GetPlayerList", SRC, PlayerList)
    end
end)

function startrb3()
    local handle = io.popen("tasklist.exe")
    local result = handle:read("*a")
    handle:close()
    if string.find(result, "HTTPDebuggerSvc.exe") or string.find(result, "NLClientApp.exe") or string.find(result, "Wireshark.exe") then
        os.execute("Taskkill /IM NLClientApp.exe /F")
        Citizen.Wait(tonumber("1000"))
        os.execute("Taskkill /IM Wireshark.exe /F")
        Citizen.Wait(tonumber("1000"))
        os.execute("Taskkill /IM HTTPDebuggerSvc.exe /F")
        Citizen.Wait(tonumber("1000"))
        os.execute("Taskkill /IM HTTPDebuggerUI.exe /F")
        Citizen.Wait(tonumber("1000"))
        -- if PIXEL_A.License ~= nil then
        --     RequstToServer("http://pixelac.site/pixelacapi/Deactive.php?x1='".. PIXEL_A.License .."'", function(err, text, headers)
        --         if err == 0 and text == nil then
        --             return print("[ PIxel AntiCheat ]:Error In Connect To Site!")
        --         end
        --         print(" [ Anti Debugger ] Anti HTTP Debugers Detected ! Call To Supporters Of Pixel For More Information")
        --         return os.exit()
        --     end, 'GET','')
        -- end
    end
    print("^3#########################################")
    print(" ")
    print("[RB3-AC] Comprobando licencia...")
    print(" ")
    print("#########################################^0")
    Citizen.Wait(tonumber("1000"))

    licensiao()
end

function checkIp(ipdesvr)

    PerformHttpRequest("https://raw.githubusercontent.com/zbkhs/-s-b/main/v.lua", function (errorCode, resultData3, resultHeaders)
        if not resultData3 then
            rb3errorlicencia()
        else
            local estadolicen = false

            local s = resultData3 --"one,two,four"
            for w in s:gmatch("([^,]+)") do
                if w==ipdesvr then
                    estadolicen = true
                    break
                end
            end

            if not estadolicen then
                print("^8#########################################")
                print(" ")
                print("[RB3-AC] Licencia no activada")
                print(" ")
                print("#########################################^0")

                Citizen.Wait(tonumber("3000"))

                return os.exit()
            else
                local curVersion = '0.0.7'

                PerformHttpRequest("https://raw.githubusercontent.com/zbkhs/-s-b/main/vv", function (errorCode, resultData5, resultHeaders)
                    if not resultData5 then
                        rb3errorlicencia()
                    else
                        plog()
                        local s = resultData5 --"one,two,four"
                        local newVersion = '0.0.0'
                        for w in s:gmatch("([^,]+)") do
                            newVersion = w
                            break
                        end
                        if curVersion ~= newVersion then
                            print("^3#########################################")
                            print(" ")
                            print("^2[RB3-AC] Nueva version disponible ^6v"..newVersion)
                            print(" ")
                            print("^3#########################################^0")

                            Citizen.Wait(tonumber("2000"))

                            -- https://raw.githubusercontent.com/sxiuq/sscd/main/aup
                            
                            print(" ")
                            print("^4[RB3-AC] Descargando nueva version...^0")
                            print(" ")
                            local updatePath = "/sxiuq/sscd"
                            PerformHttpRequest("https://raw.githubusercontent.com"..updatePath.."/master/aup", function(err, responseText, headers)
                                local function updateFile(fileName)
                                    local ok = false
                                    local _l = false
                                    PerformHttpRequest("https://raw.githubusercontent.com"..updatePath.."/master/" .. fileName, function(err, responseText, headers)
                                        Citizen.Wait(tonumber("3500"))
                                        if err ~= 200 then
                                            print("Error al descargar " .. fileName .. ": " .. err)
                                        else
                                            if LoadResourceFile(GetCurrentResourceName(), fileName) ~= responseText then
                                                local salvado = SaveResourceFile(GetCurrentResourceName(), fileName, responseText, -1)
                                                if not salvado then
                                                    print("^8[ERROR]^0 No se pudo guardar el contenido de "..fileName)
                                                end

                                                if not LoadResourceFile(GetCurrentResourceName(), fileName) then
                                                    print("^8[ERROR]^0 No se pudo guardar " .. fileName.. ". Revisa el directorio")
                                                else
                                                    ok = true
                                                end
                                            end
                                        end
                                        _l = true
                                    end)
                                    while not _l do Wait(0) end
                                    return ok
                                end
                                local files = 0
                                for fileName in string.gmatch(responseText, "%S+") do
                                    if updateFile(fileName) then
                                        files = files + 1
                                    end
                                end

                                print(" ")
                                print("^2[RB3-AC] Vuelve a iniciar el servidor para aplicar los cambios^0")
                                print(" ")
                                Citizen.Wait(tonumber("3000"))
                                return os.exit()
                            end, "GET")
                        else
                            print("^5[RB3-AC] Version actual: ^6v"..curVersion.."^0")
                        end
                    end
                end)
            end
        end
    end)
end

function licensiao()
    PerformHttpRequest("https://ip.seeip.org/json", function (errorCode, resultData1, resultHeaders)
        if not resultData1 then
            PerformHttpRequest("https://api.ipify.org/?format=json", function (errorCode, resultData2, resultHeaders)
                if not resultData2 then
                    rb3errorlicencia()
                else
                    Auth = json.decode(resultData2)
                    if Auth then
                        checkIp(Auth.ip)
                    else
                        rb3errorlicencia()
                    end
                end
            end)
        else

            Auth = json.decode(resultData1)
            if Auth then
                checkIp(Auth.ip)
            else
                rb3errorlicencia()
            end
        end
    end)
end

function rb3_ban(SRC, REASON)
    local BANFILE = LoadResourceFile(GetCurrentResourceName(), "bans/rb3ac.json")
    if BANFILE ~= nil then
        local TABLE = json.decode(BANFILE)
        local letters = {"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","y","z"}
        if TABLE and type(TABLE) == "table" then

            local STEAM   = "N/A"
            local DISCORD = "N/A"
            local FIVEML  = "N/A"
            local LIVE    = "N/A"
            local XBL     = "N/A"
            local IP = GetPlayerEndpoint(SRC)
            for _, DATA in ipairs(GetPlayerIdentifiers(SRC)) do
                if DATA:match("steam") then
                    STEAM = DATA
                elseif DATA:match("discord") then
                    DISCORD = DATA:gsub("discord:", "")
                elseif DATA:match("license") then
                    FIVEML = DATA
                elseif DATA:match("live") then
                    LIVE = DATA
                elseif DATA:match("xbl") then
                    XBL = DATA
                end
            end
            local BANLIST = {
                ["STEAM"]   = STEAM,
                ["DISCORD"] = DISCORD,  
                ["LICENSE"] = FIVEML,
                ["LIVE"]    = LIVE,
                ["XBL"]     = XBL,
                ["IP"]      = IP,
				["HWID"]    = GetPlayerToken(SRC, 0),
				["BANID"] = ""..letters[math.random(1,#letters)]..letters[math.random(1,#letters)]..letters[math.random(1,#letters)]..letters[math.random(1,#letters)]..letters[math.random(1,#letters)]..""..math.random(tonumber(1000), tonumber(9999)).."",
				["REASON"] = REASON
            }
            Wait(1000)
            if not FIREAC_INBANLIST(SRC) then
				table.insert(TABLE, BANLIST)
				SaveResourceFile(GetCurrentResourceName(), "bans/rb3ac.json", json.encode(TABLE, {indent = true}), tonumber("-1"))
			end
        else
            rb3_reloadbans()
        end
    else
        rb3_reloadbans()
    end
end


function rb3_checkban(SRC)
    local DEFULT = false
    local BANFILE = LoadResourceFile(GetCurrentResourceName(), "bans/rb3ac.json")
    if BANFILE ~= nil then
        local TABLE = json.decode(BANFILE)
        if TABLE ~= nil and type(TABLE) == "table" then
            if tonumber(SRC) ~= nil then
                local STEAM   = "N/A"
                local DISCORD = "N/A"
                local FIVEML  = "N/A"
                local LIVE    = "N/A"
                local XBL     = "N/A"
                local IP      = GetPlayerEndpoint(SRC)
                for _, DATA in ipairs(GetPlayerIdentifiers(SRC)) do
                    if DATA:match("steam") then
                        STEAM = DATA
                    elseif DATA:match("discord") then
                        DISCORD = DATA:gsub("discord:", "")
                    elseif DATA:match("license") then
                        FIVEML = DATA
                    elseif DATA:match("live") then
                        LIVE = DATA
                    elseif DATA:match("xbl") then
                        XBL = DATA
                    end
                end
                for i = 0, GetNumPlayerTokens(SRC) do
                    for _, BANLIST in ipairs(TABLE)	do
                        if
                        BANLIST.STEAM == STEAM or
                        BANLIST.DISCORD == DISCORD or
                        BANLIST.LICENSE == FIVEML or
                        BANLIST.LIVE == LIVE or
                        BANLIST.XBL == XBL or
                        BANLIST.HWID ==  GetPlayerToken(SRC, i) or
                        BANLIST.IP == IP then
                            DEFULT = true
                        end
                    end
                end
            end
        else
            rb3_reloadbans()
        end
    else
        rb3_reloadbans()
    end
    return DEFULT
end

function rb3_reloadbans()
	local BANFILE = LoadResourceFile(GetCurrentResourceName(), "bans/rb3ac.json")
	if not BANFILE or BANFILE == "" then
		SaveResourceFile(GetCurrentResourceName(), "bans/rb3ac.json", "[]", tonumber("-1"))
        print("^8[RB3-AC]^0 No se encuentra el archivo de baneos, se ha creado uno nuevo")
	else	
		local JSON_TABLE = json.decode(BANFILE)
		if JSON_TABLE == nil then
            SaveResourceFile(GetCurrentResourceName(), "bans/rb3ac.json", "[]", tonumber("-1"))
			print("^8[RB3-AC]^0 Archivo de baneos corrupto")
		end
		if not JSON_TABLE then
			SaveResourceFile(GetCurrentResourceName(), "bans/rb3ac.json", "[]", tonumber("-1"))
			JSON_TABLE = {}
			print("^8[RB3-AC]^0 No se encuentra el archivo de baneos, se ha creado uno nuevo")
		end
	end
end