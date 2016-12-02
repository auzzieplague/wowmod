local output ="INSTANCE_CHAT";
--local output ="SAY";


--roles and spec tables
specs={
 "Blood", "Frost","Unholy", "Balance","Feral",
"Guardian", "Restoration","Beast Mastery","Marksmanship",
 "Survival", "Arcane", "Fire", "Frost", "Brewmaster",
 "Mistweaver", "Windwalker", "Holy", "Protection",
 "Retribution", "Discipline", "Holy", "Shadow",
 "Assassination", "Combat", "Subtlety", "Elemental",
 "Enhancement", "Restoration", "Affliction", "Demonology",
 "Destruction", "Arms", "Fury", "Protection"
}
roles={
 "Tank", "Melee", "Melee", "Ranged", "Melee",
 "Tank", "Healer", "Ranged", "Ranged",
 "Ranged", "Ranged", "Ranged", "Ranged", "Tank",
 "Healer", "Melee", "Healer", "Tank",
 "Melee", "Healer", "Healer", "Ranged",
 "Melee", "Melee", "Melee", "Ranged",
 "Melee", "Healer", "Ranged", "Ranged",
 "Ranged", "Melee", "Melee", "Tank"
}

--setup output box
INFO_box = CreateFrame("Frame")
INFO_box.left =5;
INFO_box.top =-170;

INFO_box:ClearAllPoints()
INFO_box:SetBackdrop(StaticPopup1:GetBackdrop())
INFO_box:SetHeight(100)
INFO_box:SetWidth(300)
INFO_box:SetPoint("LEFT", INFO_box.left, INFO_box.top)
INFO_box:SetMovable(true);

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
INFO_TextFrame:SetPoint("LEFT", INFO_box.left+20, INFO_box.top+20);
INFO_TextFrameTime = 0;
INFO_TextFrame.sticky=false;
INFO_TextFrame.fadetime=10;


-- fade function
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
    local cmds = "/info [command]\n";
    cmds = cmds.."me - char info\n";
    cmds = cmds.."bg - battleground info\n";
    cmds = cmds.."cleanup - cleanup tracker";
    print (cmds);
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
function INFO(self)
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
        GetBGInfo ();
     elseif msg =='stats' then
        GetSpecInfo();
     elseif msg =='cleanup' then
        CleanTracker();
     else
        ShowCommandList();
     end
end

--slash command binding
SLASH_INFO1, SLASH_INFO2 = '/info', '/get';
SlashCmdList["INFO"] = handler; -- Also a valid assignment strategy

--removed sticky

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
--    local txt="Alliance:"..aplayers.." players" ;
--    SendChatMessage(txt, output);
    local txt=aplayers.." Alli:"..atanks.." Tanks, "..amelee.." Melee, "..aranged.." Rng";
    SendChatMessage(txt, output);
    if aheals>0 then
        txt=aheals.." Heals:"..anames;
        SendChatMessage(txt, output);
    end
    txt=hplayers.." Horde:"..htanks.." Tanks, "..hmelee.." Melee, "..hranged.." Rng";
    --txt="Horde:"..hplayers.." players" ;
    --SendChatMessage(txt, output);
    --txt=htanks.."x Tanks, "..hmelee.."x Melee, "..hranged.."x Ranged";
    SendChatMessage(txt, output);
    if hheals>0 then
        txt=hheals.." Heals:"..hnames;
        SendChatMessage(txt, output);
    end
    SendChatMessage("Leader:"..leader, output);
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