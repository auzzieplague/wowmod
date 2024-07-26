-- Output configuration
local output ="SAY";

-- Roles and spec tables
specs = {
    "Blood", "Frost", "Unholy", "Balance", "Feral",
    "Guardian", "Restoration", "Beast Mastery", "Marksmanship",
    "Survival", "Arcane", "Fire", "Frost", "Brewmaster",
    "Mistweaver", "Windwalker", "Holy", "Protection",
    "Retribution", "Discipline", "Holy", "Shadow",
    "Assassination", "Combat", "Subtlety", "Elemental",
    "Enhancement", "Restoration", "Affliction", "Demonology",
    "Destruction", "Arms", "Fury", "Protection",
    "Vengeance", "Havoc"
}
roles = {
    "Tank", "Melee", "Melee", "Ranged", "Melee",
    "Tank", "Healer", "Ranged", "Ranged",
    "Ranged", "Ranged", "Ranged", "Ranged", "Tank",
    "Healer", "Melee", "Healer", "Tank",
    "Melee", "Healer", "Healer", "Ranged",
    "Melee", "Melee", "Melee", "Ranged",
    "Melee", "Healer", "Ranged", "Ranged",
    "Ranged", "Melee", "Melee", "Tank",
    "Tank", "Melee"
}

-- Setup output text over box
INFO_TextFrame = CreateFrame("Frame");
INFO_TextFrame:ClearAllPoints();
INFO_TextFrame:SetHeight(300);
INFO_TextFrame:SetWidth(300);
INFO_TextFrame:SetScript("OnUpdate", INFO_TextFrame_OnUpdate);
INFO_TextFrame:Hide();
INFO_TextFrame.text = INFO_TextFrame:CreateFontString(nil, "BACKGROUND", "GameFontNormalSmall");
INFO_TextFrame.text:SetAllPoints();
INFO_TextFrame.text:SetJustifyH("LEFT");
INFO_TextFrame.left = 5;
INFO_TextFrame.top = -170;
INFO_TextFrame:SetPoint("LEFT", INFO_TextFrame.left, INFO_TextFrame.top);
INFO_TextFrameTime = 0;
INFO_TextFrame.sticky = false;
INFO_TextFrame.fadetime = 5;

-- Fade function
function INFO_TextFrame_OnUpdate()
    if (INFO_TextFrame.sticky == false) then
        if (INFO_TextFrameTime < GetTime() - INFO_TextFrame.fadetime) then
            local alpha = INFO_TextFrame:GetAlpha();
            if (alpha ~= 0) then INFO_TextFrame:SetAlpha(alpha - .05); end
            if (alpha == 0) then INFO_TextFrame:Hide(); end
        end
    end
end

-- Put text on screen
function INFO_TextMessage(message)
    INFO_TextFrame.text:SetText(message);
    INFO_TextFrame:SetAlpha(1);
    INFO_TextFrame:Show();
    INFO_TextFrameTime = GetTime();
end

local function ShowCommandList()
    local cmds = "Info Tool Command List:";
    cmds = cmds.."/info me, bg, stats, sticky\n";
    cmds = cmds.."bg, ashran, healers, tanks\n";
    cmds = cmds.."cleanbags, emptybags, vendorall\n";
    cmds = cmds.."cleantracker";
    print(cmds);
end

-- Item max refers to cutoff point 4=rare
local function VendorBags(itemMax)
    for b = 0, 4 do
        for s = 1, C_Container.GetContainerNumSlots(b) do
            local l = C_Container.GetContainerItemLink(b, s)
            if l then
                local itemName, itemLink, itemRarity = GetItemInfo(l)
                if (itemRarity < itemMax) then
                    if (itemName ~= "Hearthstone") then
                        C_Container.UseContainerItem(b, s)
                    end
                end
            end
        end
    end
end

-- Item max refers to cutoff point 4=rare
local function CleanBags(itemMax)
    for b = 0, 4 do
        for s = 1, C_Container.GetContainerNumSlots(b) do
            local l = C_Container.GetContainerItemLink(b, s)
            if l then
                local itemName, itemLink, itemRarity = GetItemInfo(l)
                if (itemRarity < itemMax) then
                    if (itemName ~= "Hearthstone") then
                        C_Container.PickupContainerItem(b, s)
                        DeleteCursorItem()
                    end
                end
            end
        end
    end
end

-- Cleanup objective / achievement tracker
local function CleanTracker()
    local x = GetNumQuestWatches();
    for i = 0, x - 1 do
        RemoveQuestWatch(GetQuestIndexForWatch(x - i));
    end
    local tracked = {GetTrackedAchievements()}
    for i = 1, #tracked do
        RemoveTrackedAchievement(tracked[i]);
    end
end

-- Initial call from XML file
function Info(self)
    ShowCommandList();
end

-- Slash command handler
local function handler(msg, editbox)
    if msg == 'me' then
        local txt = "server:" .. GetRealmName() .. "\n";
        txt = txt .. "title:" .. GetCurrentTitle() .. "\n";
        txt = txt .. "stats:";
        INFO_TextMessage(txt);
    elseif msg == 'title' then
        INFO_TextMessage(GetCurrentTitle());
    elseif msg == 'sticky' then
        ToggleSticky();
    elseif msg == 'bg' then
        GetBGInfo();
    elseif msg == 'healers' then
        GetHealers();
    elseif msg == 'stats' then
        GetSpecInfo();
    elseif msg == 'cleantracker' then
        CleanTracker();
    elseif msg == 'cleanbags' then
        CleanBags(4);
    elseif msg == 'emptybags' then
        CleanBags(8);
    elseif msg == 'vendorall' then
        VendorBags(8);
    else
        ShowCommandList();
    end
end

-- Slash command binding
SLASH_INFO1, SLASH_INFO2 = '/info', '/get';
SlashCmdList["INFO"] = handler;

-- Toggle sticky text
function ToggleSticky()
    if (INFO_TextFrame.sticky == false) then
        INFO_TextFrame.sticky = true;
        INFO_TextMessage("Sticky:On");
    else
        INFO_TextFrame.sticky = false;
        INFO_TextMessage("Sticky:Off");
    end
end

function GetRoleFromSpec(spec)
    for i, v in ipairs(specs) do
        if v == spec then
            return roles[i]
        end
    end
    return "error"
end

function GetRaidLeader()
    local leader = "unknown";
    for i = 1, GetNumGroupMembers() do
        local name, rank = GetRaidRosterInfo(i);
        if (rank == 2) then
            leader = name;
        end
    end
    return leader;
end

-- Convoluted Lua split string method
function split(str, pat)
    local t = {}
    local fpat = "(.-)" .. pat
    local last_end = 1
    local s, e, cap = str:find(fpat, 1)
    while s do
        if s ~= 1 or cap ~= "" then
            table.insert(t, cap)
        end
        last_end = e + 1
        s, e, cap = str:find(fpat, last_end)
    end
    if last_end <= #str then
        cap = str:sub(last_end)
        table.insert(t, cap)
    end
    return t
end

-- Get general battleground info
function GetBGInfo()
    -- Counters
    local htanks = 0;
    local hheals = 0;
    local hmelee = 0;
    local hranged = 0;
    local hplayers = 0;
    local hnames = "";
    local atanks = 0;
    local aheals = 0;
    local amelee = 0;
    local aranged = 0;
    local aplayers = 0;
    local anames = "";
    local specName = "";

    -- Horde
    for i = 1, 40 do
        name, realm, class, role, spec = GetBattlefieldScore(i);
        faction = GetBattlefieldTeamInfo(0);
        if name then
            faction = GetBattlefieldTeamInfo(0);
            if faction == "Horde" then
                hplayers = hplayers + 1;
                if (role == "TANK") then htanks = htanks + 1; end
                if (role == "HEALER") then hheals = hheals + 1; end
                if (role == "DAMAGER") then
                    if (spec == "Melee") then hmelee = hmelee + 1; end
                    if (spec == "Ranged") then hranged = hranged + 1; end
                end
                hnames = hnames .. name .. ",";
            end
        end
    end

    -- Alliance
    for i = 1, 40 do
        name, realm, class, role, spec = GetBattlefieldScore(i);
        faction = GetBattlefieldTeamInfo(1);
        if name then
            faction = GetBattlefieldTeamInfo(1);
            if faction == "Alliance" then
                aplayers = aplayers + 1;
                if (role == "TANK") then atanks = atanks + 1; end
                if (role == "HEALER") then aheals = aheals + 1; end
                if (role == "DAMAGER") then
                    if (spec == "Melee") then amelee = amelee + 1; end
                    if (spec == "Ranged") then aranged = aranged + 1; end
                end
                anames = anames .. name .. ",";
            end
        end
    end

    local txt = "Info BG: H " .. hplayers .. " (t:" .. htanks .. " h:" .. hheals .. " m:" .. hmelee .. " r:" .. hranged .. ")\n";
    txt = txt .. "A " .. aplayers .. " (t:" .. atanks .. " h:" .. aheals .. " m:" .. amelee .. " r:" .. aranged .. ")\n";
    INFO_TextMessage(txt);
end

function GetHealers()
    local healers = "";
    for i = 1, 40 do
        name, realm, class, role, spec = GetBattlefieldScore(i);
        if name then
            if role == "HEALER" then
                healers = healers .. name .. ",";
            end
        end
    end
    local txt = "Healers: " .. healers;
    INFO_TextMessage(txt);
end

-- Get spec and role info
function GetSpecInfo()
    local num = 0;
    for i = 1, GetNumGroupMembers() do
        local name, _, _, _, _, _, _, _, _, role, _ = GetRaidRosterInfo(i);
        if name then
            local spec = GetSpecializationInfo(GetSpecialization());
            role = GetRoleFromSpec(spec);
            if role == "Tank" then
                num = num + 1;
            end
        end
    end
    local txt = "Info Spec: "..num.." tanks";
    INFO_TextMessage(txt);
end
