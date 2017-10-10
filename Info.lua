--local output ="INSTANCE_CHAT";
local output ="SAY";


--roles and spec tables
specs={
 "Blood", "Frost","Unholy", "Balance","Feral",
"Guardian", "Restoration","Beast Mastery","Marksmanship",
 "Survival", "Arcane", "Fire", "Frost", "Brewmaster",
 "Mistweaver", "Windwalker", "Holy", "Protection",
 "Retribution", "Discipline", "Holy", "Shadow",
 "Assassination", "Combat", "Subtlety", "Elemental",
 "Enhancement", "Restoration", "Affliction", "Demonology",
 "Destruction", "Arms", "Fury", "Protection",
 "Vengeance","Havoc"
}
roles={
 "Tank", "Melee", "Melee", "Ranged", "Melee",
 "Tank", "Healer", "Ranged", "Ranged",
 "Ranged", "Ranged", "Ranged", "Ranged", "Tank",
 "Healer", "Melee", "Healer", "Tank",
 "Melee", "Healer", "Healer", "Ranged",
 "Melee", "Melee", "Melee", "Ranged",
 "Melee", "Healer", "Ranged", "Ranged",
 "Ranged", "Melee", "Melee", "Tank",
 "Tank","Melee"
}

--setup output text over box
INFO_TextFrame = CreateFrame("Frame");
INFO_TextFrame:ClearAllPoints();
INFO_TextFrame:SetHeight(300);
INFO_TextFrame:SetWidth(300);
INFO_TextFrame:SetScript("OnUpdate", INFO_TextFrame_OnUpdate);
INFO_TextFrame:Hide();
INFO_TextFrame.text = INFO_TextFrame:CreateFontString(nil, "BACKGROUND", "GameFontNormalSmall");
INFO_TextFrame.text:SetAllPoints();
INFO_TextFrame.text:SetJustifyH("LEFT");
INFO_TextFrame.left=5;
INFO_TextFrame.top=-170;
INFO_TextFrame:SetPoint("LEFT", INFO_TextFrame.left, INFO_TextFrame.top);
INFO_TextFrameTime = 0;
INFO_TextFrame.sticky=false;
INFO_TextFrame.fadetime=5;


-- fade function (must not be local for callbacks)
function INFO_TextFrame_OnUpdate()
  if (INFO_TextFrame.sticky == false ) then 
      if (INFO_TextFrameTime < GetTime() - INFO_TextFrame.fadetime) then
        local alpha = INFO_TextFrame:GetAlpha();
        if (alpha ~= 0) then INFO_TextFrame:SetAlpha(alpha - .05); end
        if (alpha == 0) then INFO_TextFrame:Hide(); end
      end
   end
end

-- put text on screen
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
    print (cmds);
end

--item max refers to cuttof point 4=rare
local function VendorBags(itemMax)
    for b=0,4 
    do for s=1,GetContainerNumSlots(b) 
        do l=GetContainerItemLink(b,s) 
            if l then 
                itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice=GetItemInfo(l) 
                if (itemRarity < itemMax) then 
                    if (itemName ~= "Hearthstone") then 
                        UseContainerItem(b,s)
                    end
                    
                end 
            end 
        end 
    end
end

--item max refers to cuttof point 4=rare
local function CleanBags (itemMax)
    for b=0,4 
    do for s=1,GetContainerNumSlots(b) 
        do l=GetContainerItemLink(b,s) 
            if l then 
                itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice=GetItemInfo(l) 
                if (itemRarity < itemMax) then 
                    if (itemName ~= "Hearthstone") then 
                        PickupContainerItem(b,s) DeleteCursorItem()
                        --print (itemLink.." > "..itemRarity)
                    end
                    
                end 
            end 
        end 
    end
end


-- cleanup objective / achievement tracker
local function CleanTracker ()
    local x=GetNumQuestWatches();
    for i=0,x-1 do 
        RemoveQuestWatch(GetQuestIndexForWatch(x-i));
    end 
    local tracked={GetTrackedAchievements()} 
    for i=1,#tracked do 
        RemoveTrackedAchievement(tracked[i]);
    end
end

-- initial call from xml file
function Info(self)
    ShowCommandList();
end


-- slash command handler
local function handler(msg, editbox)    
     if msg == 'me' then
      local txt= "server:"..GetRealmName().."\n";
        txt=txt.."title:"..GetCurrentTitle().."\n";
        txt=txt.."stats:";
        INFO_TextMessage(txt);
     elseif msg == 'title' then
      INFO_TextMessage(GetCurrentTitle());
     elseif msg == 'sticky' then
        ToggleSticky();
     elseif msg =='bg' then
        GetBGInfo();
	elseif msg =='healers' then
        GetHealers();
     elseif msg =='stats' then
        GetSpecInfo();
     elseif msg =='cleantracker' then
        CleanTracker();
     elseif msg =='cleanbags' then
        CleanBags(4);
      elseif msg =='emptybags' then
        CleanBags(8);
      elseif msg =='vendorall' then
        VendorBags(8);
     else
        ShowCommandList();
     end
end

--slash command binding
SLASH_INFO1, SLASH_INFO2 = '/info', '/get';
SlashCmdList["INFO"] = handler; -- Also a valid assignment strategy

-- toggle sticky text
function ToggleSticky ()
     if (INFO_TextFrame.sticky==false) then
        INFO_TextFrame.sticky=true;
        INFO_TextMessage("Sticky:On");
    else
        INFO_TextFrame.sticky=false;
        INFO_TextMessage("Sticky:Off");
    end
end

function GetRoleFromSpec (spec)
    i=1;
    while specs[i] do
        if specs[i]==spec then 
            return roles[i]
        end
    i=i+1
    end
    return "error"
end

function GetRaidLeader ()
    local leader="unkown";
    for i=1, GetNumGroupMembers() do
        name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i);
        if (rank==2) then 
            leader=name;
        end    
    end
    return leader;
end

 --convoluted lua split string method
function split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
	   table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end


-- get general battleground info
function GetBGInfo ()
    -- counters
    local htanks=0;
    local hheals=0;
    local hmelee=0;
    local hranged=0;
    local hplayers=0;
    local hnames="";
    local atanks=0;
    local aheals=0;
    local amelee=0;
    local aranged=0;
    local anames="";
    local aplayers=0;
    
    --loop through leaderboard, grab specs 
    for i=1, GetNumBattlefieldScores() do
        name, killingBlows, honorableKills, deaths, honorGained, 
        faction, race, class, classToken, damageDone, healingDone, 
        bgRating, ratingChange, preMatchMMR, mmrChange, talentSpec = GetBattlefieldScore(i);
        local role=GetRoleFromSpec(talentSpec);
        local unitname = split(name, "-");
        if faction==1 then --alliance
            aplayers=aplayers+1;
            if role == "Healer" then 
                aheals=aheals+1;
               anames=anames.."["..unitname[1].."] ";
            elseif role == "Tank" then 
                atanks=atanks+1;
            elseif role == "Melee" then 
                amelee=amelee+1;
            elseif role == "Ranged" then 
                aranged=aranged+1
            end
        else --horde
            hplayers=hplayers+1;
            if role == "Healer" then 
                hheals=hheals+1;
                hnames=hnames.."["..unitname[1].."] ";
            elseif role == "Tank" then 
                htanks=htanks+1;
            elseif role == "Melee" then 
                hmelee=hmelee+1;
            elseif role == "Ranged" then 
                hranged=hranged+1
            end
        end
    end
    
    local leader = GetRaidLeader();
   
    -- write report
    local txt=aplayers.." Alli:"..atanks.." Tanks, "..amelee.." Melee, "..aranged.." Rng";
    SendChatMessage(txt, output);
    if aheals>0 then
        txt=aheals.." Heals:"..anames;
        SendChatMessage(txt, output);
    end
    txt=hplayers.." Horde:"..htanks.." Tanks, "..hmelee.." Melee, "..hranged.." Rng";
 
    SendChatMessage(txt, output);
    if hheals>0 then
        txt=hheals.." Heals:"..hnames;
        SendChatMessage(txt, output);
    end
    SendChatMessage("Leader:"..leader, output);
end

function GetHealers ()
    -- counters
    local hheals=0;
    local hnames="";
    local aheals=0;
    local anames="";

    
    --loop through leaderboard, grab specs 
    for i=1, GetNumBattlefieldScores() do
        name, killingBlows, honorableKills, deaths, honorGained, 
        faction, race, class, classToken, damageDone, healingDone, 
        bgRating, ratingChange, preMatchMMR, mmrChange, talentSpec = GetBattlefieldScore(i);
        local role=GetRoleFromSpec(talentSpec);
        local unitname = split(name, "-");
        if faction==1 then --alliance
            if role == "Healer" then 
                aheals=aheals+1;
               anames=anames.."["..unitname[1].."] ";
            end
        else --horde
            if role == "Healer" then 
                hheals=hheals+1;
                hnames=hnames.."["..unitname[1].."] ";
            end
        end
    end
 

    if aheals>0 then
        txt=aheals.."Alli Healers:"..anames;
        SendChatMessage(txt, output);
		else
		SendChatMessage("Alliance have no healers!", output);
    end
    if hheals>0 then
        txt=hheals.."Horde Heals:"..hnames;
        SendChatMessage(txt, output);
		else
		SendChatMessage("Horde have no healers!", output);
    end
end

-- display ashran info text
function GetAshranInfo ()
    
    -- check if ashran, do special check for ashran
    
    np=GetNumGroupMembers(); 
    healers=0;
    healerNames="";
    tanks=0;
    local leader = GetRaidLeader();
    txt = txt..leader.." is leader\n"..healers.." heals found\n";   
    INFO_TextMessage(txt);
end

function GetSpecInfo ()
    local currentSpec = GetSpecialization()
    local currentSpecName = currentSpec and select(2, GetSpecializationInfo(currentSpec)) or "None"
    print("Your current spec:", currentSpecName)
end

function GetSpecStatPriority (currentSpecName)
    
end


-- add delete text into confirm delete box
hooksecurefunc(StaticPopupDialogs["DELETE_GOOD_ITEM"],"OnShow",function(s) s.editBox:SetText(DELETE_ITEM_CONFIRM_STRING) end)
-- get rid of role call
RolePollPopup:UnregisterEvent("ROLE_POLL_BEGIN");

--reposition tooltip
GameTooltip:SetScript("OnTooltipSetUnit", function(self)
    self:ClearAllPoints()
    self:SetPoint("BOTTOMRIGHT", WorldFrame, "BOTTOMRIGHT", -50, 230)
end)