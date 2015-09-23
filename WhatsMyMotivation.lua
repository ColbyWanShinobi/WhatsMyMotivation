---------------------------
-- What's My Motivation? --
---------------------------

-- NAMESPACE
gs = {};
gs.util = {};

--Global namespace varibles
gs.DEBUG = false;

--Addon title
local addonTitle = "What's My Motivation?";
if (gs.DEBUG) then print('DEBUG: ' .. addonTitle .. ' Debugging ENABLED...'); end

-- Logfile data variables. These get written out to file upon reload and exiting
gsQuestData = {}; --Per account quest data
gsNpcData = {}; --Per account NPC data
gsNpcGreetings = {}; --Per account NPC greetings
gsQuestDataChar = {}; --Per character quest data
gsNpcDataChar = {}; --Per character NPC data

function gs.util.printHelper(printItem)
--Print the different data types appropriately
	if (type(printItem) == 'string' or type(printItem) == 'number') then
		return printItem;
	elseif (type(printItem) == 'table') then
		local tempString = "\n{";
		for i,j in pairs(printItem) do
	        tempString = tempString .. gs.util.printHelper(i) .. ': ' .. gs.util.printHelper(j) .. "\n";
	    end
	    tempString = tempString .. '}';
	    return tempString;
	elseif (type(printItem) == 'boolean') then
		if (printItem == true) then
			return 'true';
		else
			return 'false'
		end
	elseif (type(printItem) == nil) then
		return 'nil';
	else
		return 'Cannot print type: ' .. type(printItem);
	end
end

function gs.util.debugLog(debugValue)
--Print debug messages
	if (gs.DEBUG) then 
	   print ('gsDEBUG: ' .. gs.util.printHelper(debugValue));
	end
end

function gs.util.convertUnitGender(genNum)
--NPC gender is returned as a number. This translates it into a word
	gs.util.debugLog("gs.util.convertUnitGender()...");
	if (genNum == 1) then
		return 'Neuter';
	elseif (genNum == 2) then
		return 'Male';
	elseif (genNum == 3) then
		return 'Female';
	end
end

function gs.util.convertItemQuality(num)
--Item quality is a number. Convert it to an appropriate string
	if (num == 0) then
		return 'Gray';
	elseif (num == 1) then
		return 'Common';
	elseif (num == 2) then
		return 'Uncommon';
	elseif (num == 3) then
		return 'Rare';
	elseif (num == 4) then
		return 'Epic';
	elseif (num == 5) then
		return 'Legendary';
	elseif (num == 6) then
		return 'Artifact';
	elseif (num == 7) then
		return 'Heirloom';
	end
end

local function incCharConvoCount(guid)
--Increment the conversation count for a given NPC

	if (guid == nil) then
		guid = UnitGUID("target");
		if (guid == nil) then
			gs.util.debugLog("Unable to increment conversation count on a null guid. Exiting...");
			return;
		end
	end

	if (gsNpcDataChar[guid] == nil) then
		gsNpcDataChar[guid] = {};
	end

	if(gsNpcDataChar[guid].name == nil) then
		gsNpcDataChar[guid].name = UnitName("target");
	end

	if(gsNpcDataChar[guid].whenMet == nil) then
		gsNpcDataChar[guid].whenMet = {};
	end

	local nextConvo = #gsNpcDataChar[guid].whenMet + 1;
	gsNpcDataChar[guid].whenMet[nextConvo] = time();
	gs.util.debugLog("NPC Conversation Count: " .. nextConvo);
end

local function incQuestActivityCount(questId, activity)
--Increment the count for number of times a quest is accepted, abandoned, or completed

	if (activity == nil) then
		gs.util.debugLog("Unable to increment quest activity count on a null activity. Exiting...");
		return;
	end

	if (questId == nil) then
		questId = GetQuestID();
		if (questId == nil) then
			gs.util.debugLog("Unable to gather quest info with a null quest ID. Exiting...");
			return;
		end
	end

	if (gsQuestDataChar[questId] == nil) then
		gsQuestDataChar[questId] = {}
	end
	

	if (activity == 'accept') then
		if(gsQuestDataChar[questId].whenAccepted == nil) then
			gsQuestDataChar[questId].whenAccepted = {}
		end
		local nextAccept = #gsQuestDataChar[questId].whenAccepted + 1;
		gsQuestDataChar[questId].whenAccepted[nextAccept] = time();
		gs.util.debugLog("Quest Accpet Count: " .. nextAccept);
	end

	if (activity == 'abandon') then
		if(gsQuestDataChar[questId].whenAbandoned == nil) then
			gsQuestDataChar[questId].whenAbandoned = {}
		end
		local nextAbandon = #gsQuestDataChar[questId].whenAbandoned + 1;
		gsQuestDataChar[questId].whenAbandoned[nextAbandon] = time();
		gs.util.debugLog("Quest Abandon Count: " .. nextAbandon);
	end

	if (activity == 'complete') then
		if(gsQuestDataChar[questId].whenCompleted == nil) then
			gsQuestDataChar[questId].whenCompleted = {}
		end
		local nextComplete = #gsQuestDataChar[questId].whenCompleted + 1;
		gsQuestDataChar[questId].whenCompleted[nextComplete] = time();
		gs.util.debugLog("Quest Completed Count: " .. nextComplete);
	end
end


local function gatherProgressText(questId)
	gs.util.debugLog("gatherProgressText()...");

	if (questId == nil) then
		questId = GetQuestID();
		if (questId == nil) then
			gs.util.debugLog("Unable to gather progress text with a null quest ID. Exiting...");
			return;
		end
	end

	local questProgressText = GetProgressText();
	--If there's no progress text, then there's no need to continue...
	if (questProgressText == nil) then
		gs.util.debugLog("Could not find quest progress text...")
		return;
	end

	if (gsQuestData[questId] == nil) then 
		gsQuestData[questId] = {};
	end
	if (gsQuestData[questId].progress == nil) then
		gs.util.debugLog("No progress logged for this quest yet");
		gsQuestData[questId].progress = {};
		gsQuestData[questId].progress[1] = questProgressText;
		return;
	end

	local nextQuestProgressIndex = #gsQuestData[questId].progress + 1;
	for i=1, #gsQuestData[questId].progress do
		if (gsQuestData[questId].progress[i] == questProgressText) then
			gs.util.debugLog("Duplicate progress text. skipping...")
			return;
		end
	end

	gs.util.debugLog("Adding additional progress text...");
	gsQuestData[questId].progress[nextQuestProgressIndex] = questProgressText;	
end

--[[
local function checkQuestCompletion()

	local questRewardText = GetRewardText();
	--If there's no reward text, then there's no need to continue...
	if (questRewardText == nil) then
		gs.util.debugLog("Could not find quest reward text.")
		return;
	end

	local questId = GetQuestID();

	if (gsQuestData[questId].rewardText == nil) then
		gs.util.debugLog("No award text logged for this quest yet");
		--questInfo.reward = {};
		gsQuestData[questId].rewardText = {};
		gsQuestData[questId].rewardText[1] = questRewardText;
	else
		gs.util.debugLog("Reward text has already been logged.");
		local nextQuestRewardIndex = #gsQuestData[questId].rewardText + 1;
		for i=1, #gsQuestData[questId].rewardText do
			if (gsQuestData[questId].rewardText[i] == questRewardText) then
				gs.util.debugLog("Duplicate reward text. skipping...")
				return;
			end
		end	
		gs.util.debugLog("Adding additional reward text...");
		gsQuestData[questId].rewardText[nextQuestRewardIndex] = questRewardText;
	end
end]]





--[[
local function checkGreeting()
--Check for and process NPC greeting text

	local npcGuid = UnitGUID("target");
	
	local npcGreeting = GetGossipText();
	--If there's no gossip text then look for greeting text...
	if (gossipText == nil) then
		gs.util.debugLog("Could not find gossip greeting. Checking for alternative...")
		gossipText = GetGreetingText();
	end

	if (npcGreeting == nil) then
		gs.util.debugLog("Could not find a greeting. Skipping...");
		return;
	end

	if (gsNpcGreetings[npcGreeting] == nil) then
		gs.util.debugLog("Found a new NPC greeting...");

		--Add this greeting to the db
		gsNpcGreetings[npcGreeting] = {};
		gsNpcGreetings[npcGreeting][1] = {}
		gsNpcGreetings[npcGreeting][1].guid = npcGuid;
		gsNpcGreetings[npcGreeting][1].name = UnitName("target");
	else
		gs.util.debugLog("Found matching NPC greeting...");
		gs.util.debugLog("Size of array: " .. #gsNpcGreetings[npcGreeting])


		--Scan the greeting array for the first available index
		nextIndex = #gsNpcGreetings[npcGreeting] + 1;
		for i = 1, #gsNpcGreetings[npcGreeting] do
			if (gsNpcGreetings[npcGreeting][i].guid == npcGuid) then
				gs.util.debugLog("This NPC already said this...");
				return;
			end
		end

		--This is a new greeting for this NPC. Add this npc to the greetign record
		gs.util.debugLog("This NPC is saying something new!");
		gs.util.debugLog("Next Greeting Index = " .. nextIndex);
		gsNpcGreetings[npcGreeting][nextIndex] = {};
		gsNpcGreetings[npcGreeting][nextIndex].guid = npcGuid;
		gsNpcGreetings[npcGreeting][nextIndex].name = UnitName("target");
	end
end
]]


local function gatherNPCDetails(guid)
	if (guid == nil) then
		guid = UnitGUID("target");
		if (guid == nil) then
			gs.util.debugLog("Unable to gather NPC data on a null guid. Exiting...");
			return;
		end
	end
	
	if (gsNpcData[guid] == nil) then
		print ("Adding new NPC to database...")
		gsNpcData[guid] = {};
	end

	local aList = {};
	aList.name = loadstring('return UnitName("target")');
	--aList.race = loadstring('local x = {UnitRace("target")}; return x[1];');
	aList.class = loadstring('return UnitClassBase("target")');
	aList.level = loadstring('return UnitLevel("target")');
	aList.classif = loadstring('return UnitClassification("unit"):gsub("^%l", string.upper)');
	--aList.family = loadstring('return UnitCreatureFamily("unit")');
	aList.type = loadstring('return UnitCreatureType("target")');
	aList.gender = loadstring('return gs.util.convertUnitGender(UnitSex("target"))');
	aList.faction = loadstring('local x = {UnitFactionGroup("target")}; return x[1];');

	for i,j in pairs(aList) do
		--gs.util.debugLog('Testing: ' .. i);
		if (gsNpcData[guid][i] == nil) then
			gs.util.debugLog("Found null value for: " .. i);
			gsNpcData[guid][i] = j();
		else
			gs.util.debugLog(i .. ': ' .. gsNpcData[guid][i]);
		end
	end

	--npc location
	if (gsNpcData[guid].location == nil) then
		gsNpcData[guid].location = {};
		gsNpcData[guid].location.xLocation, gsNpcData[guid].location.yLocation = GetPlayerMapPosition("player");
		gsNpcData[guid].location.zone = GetZoneText();
		gsNpcData[guid].location.subzone = GetSubZoneText();
		gsNpcData[guid].location.realZone = GetRealZoneText();
		gsNpcData[guid].location.minimapZone = GetMinimapZoneText();
	end

	--write per char npc data as well
	incCharConvoCount(guid);
end

local function gatherQuestData(questId)
	gs.util.debugLog('gatherQuestData()...');

	if (questId == nil) then
		questId = GetQuestID();
		if (questId == nil) then
			gs.util.debugLog("Unable to gather quest info with a null quest ID. Exiting...");
			return;
		end
	end
	
	if (gsQuestData[questId] == nil) then
		print ("Adding new quest to database...")
		gsQuestData[questId] = {};
	end

	local aList = {};
	aList.title = loadstring('return GetTitleText();');
	aList.text = loadstring('return GetQuestText();');
	aList.objective = loadstring('return GetObjectiveText();');
	aList.rewardedMoney = loadstring('return GetRewardMoney();');
	aList.rewardedTalentPoints = loadstring('return GetRewardTalents();');
	aList.rewardedTitle = loadstring('return GetRewardTitle();');
	aList.rewardedXp = loadstring('return GetRewardXP();');

	for i,j in pairs(aList) do
		--gs.util.debugLog('Testing: ' .. i);
		if (gsQuestData[questId][i] == nil) then
			gs.util.debugLog("Found null value for: " .. i);
			gsQuestData[questId][i] = j();
		else
			gs.util.debugLog(i .. ': ' .. gsQuestData[questId][i]);
		end
	end

	--quest location
	if (gsQuestData[questId].location == nil) then
		gsQuestData[questId].location = {};
		gsQuestData[questId].location.xLocation, gsQuestData[questId].location.yLocation = GetPlayerMapPosition("player");
		gsQuestData[questId].location.zone = GetZoneText();
		gsQuestData[questId].location.subzone = GetSubZoneText();
		gsQuestData[questId].location.realZone = GetRealZoneText();
		gsQuestData[questId].location.minimapZone = GetMinimapZoneText();
	end

	--group size for quest?
	local groupSize = GetSuggestedGroupNum();
	if (groupSize > 1 and gsQuestData[questId].groupSize == nil) then
		gsQuestData.groupSize = groupSize;
	end

	--Per char data...
	if (gsQuestDataChar[questId] == nil) then
		print ("Adding New Quest to character database...")
		gsQuestDataChar[questId] = {};
	end

	if (gsQuestDataChar[questId].title == nil) then
		if (gsQuestData[questId].title == nil) then
			GetTitleText();
		else
			gsQuestDataChar[questId].title = gsQuestData[questId].title;
		end	
	end


	
	
	
end

--[[XXxx Function xxXX
--Some NPCs just give quest details and don't give you gossip text. This checks for those tight lipped NPCs
local function checkTightLipped()
	gs.util.debugLog("checkTightLipped()...");
	local npcDataGuid = UnitGUID("target");
	
	if (gsNpcData[npcDataGuid] == nil) then
		gs.util.debugLog("Gathering NPC data for tight lipped NPC...");
		
		--Gather NPC
		SaveNpcData();
		
		--Add the tightlipped attribute to this NPC
		gsNpcData[npcDataGuid].tightLipped = 1;
	else
		if (gsNpcData[npcDataGuid].tightLipped ~= nil) then
			
			--increment the conversation counter array
			incConvoCount(npcDataGuid);
		end
	end
end]]--

--[[XXxx Function xxXX
--Save quest data
local function saveQuestData()
	gs.util.debugLog("saveQuestData()...");
	l

		questInfo.objectiveText = GetObjectiveText();
		questInfo.reward = {};
		--questInfo.choice = {};
		questInfo.reward.money = GetRewardMoney();
		questInfo.reward.talentPoints = GetRewardTalents();
		questInfo.reward.titleReward = GetRewardTitle();
		questInfo.reward.rewardXp = GetRewardXP();

		--group size for quest?
		local groupSize = GetSuggestedGroupNum();
		if (groupSize > 1) then
			questInfo.groupSize = groupSize;
		end

		--progress text
		local progressText = GetProgressText();
		if( progresstext ~= nil) then
			questInfo.progressText = progressText;
		end

		--quest location
		questInfo.location = {};
		questInfo.xLocation, questInfo.yLocation = GetPlayerMapPosition("player");
		questInfo.zone = GetZoneText();
		questInfo.subzone = GetSubZoneText();
		questInfo.realZone = GetRealZoneText();
		questInfo.minimapZone = GetMinimapZoneText();


		
		--Check for a spell as a reward
		local spellTexture, spellName, isTradeskillSpell, isSpellLearned = GetRewardSpell();
		if (spellName ~= nil) then
			questInfo.reward.spell = {};
			questInfo.reward.spell.name = spellName;
			questInfo.reward.spell.spellTexture = spellTexture;
			if (isTradeskillSpell) then
				questinfo.reward.spell.type = 'TradeSkill';
			elseif (isSpellLearned) then
				questinfo.reward.spell.type = 'LearnedSpell';
			end
		end
		
		
		--Add the new quest to our database
		gsQuestData[questId] = questInfo;

		--log per character quest data

		gsQuestDataChar[questId] = questInfoChar;



	end
end]]--

--[[
local function acceptQuest()
	gs.util.debugLog("acceptQuest()...");
	questInfo = {};
	local questId = GetQuestID();
	if (gsQuestData[questId] ~= nil and gsQuestDataChar[questId] ~= nil) then
		gs.util.debugLog("Found an existing quest. Incrementing acceptance counter...");

		nextIndex = #gsQuestDataChar[questId].whenAccepted + 1;
		gs.util.debugLog("Number of times accepted: " .. nextIndex);
		gsQuestDataChar[questId].whenAccepted[nextIndex] = time();
	else
		if (gsQuestData[questId] == nil) then
			gs.util.debugLog("Adding missing per account quest entry..");
			gsQuestData[questId] = {};
		end

		if (gsQuestDataChar[questId] == nil) then
			gs.util.debugLog("Adding per character quest entry and acceptance date...")
			gsQuestDataChar[questId] = {};
			gsQuestDataChar[questId].whenAccepted = {};
			gsQuestDataChar[questId].whenAccepted[1] = time();
		end	
	end

	
	
end]]



local function gatherNPCData()

	--Increment conversation count
	incCharConvoCount();

	gatherNPCDetails();

end

local function gatherQuestRewards(questId)
	gs.util.debugLog("Start gatherQuestRewards...")

	if (questId == nil) then
		questId = GetQuestID();
		if (questId == nil) then
			gs.util.debugLog("Unable to gather quest info with a null quest ID. Exiting...");
			return;
		end
	end

	--Gather Quest Item info
	--get number of quests
	local numEntries, numQuests = GetNumQuestLogEntries();
	if (numQuests > 0) then
		gs.util.debugLog("Found " .. numQuests .. " quests in the log...");
		--get quest log index
		local questLogIndex = GetQuestLogIndexByID(questId);

		--select the appropriate quest
		gs.util.debugLog("Selecting quest: " .. questLogIndex);
		SelectQuestLogEntry(questLogIndex);
		
		if (gsQuestData[questId] == nil) then
			print ("Adding new quest to database...")
			gsQuestData[questId] = {};
		end

		--local name, texture, numItems, quality, isUsable = GetQuestLogChoiceInfo(i);
		gs.util.debugLog(questId);
		if (gsQuestData[questId].level == nil) then
			local qi = {GetQuestLogTitle(questLogIndex)};
			gs.util.debugLog(qi);
			gs.util.debugLog("Adding level " .. qi[2] .. " to database for quest: ");
			gsQuestData[questId].level = qi[2];
		end
		
		--local numQuestRewards = GetNumQuestRewards();
		--gs.util.debugLog("Num of quest rewards: " .. numQuestRewards );
		--local numQuestChoices = GetNumQuestChoices();
		--gs.util.debugLog("Num of quest choices: " .. numQuestChoices);

		local numQuestLogRewards = GetNumQuestLogRewards();
		gs.util.debugLog("Num of quest log rewards: " .. numQuestLogRewards );
		local numQuestLogChoices = GetNumQuestLogChoices();
		gs.util.debugLog("Num of quest log choices: " .. numQuestLogChoices);

		--These are always rewarded
		if (numQuestLogRewards > 0) then
			gs.util.debugLog("Found " .. numQuestLogRewards .. " rewards to process...")
			
			if (gsQuestData[questId].reward == nil) then
				gs.util.debugLog("Creating reward array...");
				gsQuestData[questId].reward = {};
			end
			if (gsQuestData[questId].reward.item == nil) then
				gs.util.debugLog("Creating reward item array...");
				gsQuestData[questId].reward.item = {};
			end

			for i=1, numQuestLogRewards do
				local name, texture, numItems, quality, isUsable = GetQuestLogRewardInfo(i);
				gsQuestData[questId].reward.item[i] = {};
				gsQuestData[questId].reward.item[i].name = name; 
				gsQuestData[questId].reward.item[i].texture = texture;
				gsQuestData[questId].reward.item[i].numItems = numItemsReq;
				gsQuestData[questId].reward.item[i].quality = gs.util.convertItemQuality(quality);
				gsQuestData[questId].reward.item[i].isUsable =  isUsable;
				gsQuestData[questId].reward.item[i].link = GetQuestItemLink("reward", i);
			end
		end

		if (numQuestLogChoices > 0) then
			gs.util.debugLog("Found " .. numQuestLogChoices .. " choices to process...")
			
			if (gsQuestData[questId].choice == nil) then
				gs.util.debugLog("Creating choice array...");
				gsQuestData[questId].choice = {};
			end
			if (gsQuestData[questId].choice.item == nil) then
				gs.util.debugLog("Creating choice item array...");
				gsQuestData[questId].choice.item = {};
			end
			
			for i=1, numQuestLogChoices do
				local name, texture, numItems, quality, isUsable = GetQuestLogChoiceInfo(i);
				gsQuestData[questId].choice.item[i] = {};
				gsQuestData[questId].choice.item[i].name = name; 
				gsQuestData[questId].choice.item[i].texture = texture;
				gsQuestData[questId].choice.item[i].numItems = numItems;
				gsQuestData[questId].choice.item[i].quality = gs.util.convertItemQuality(quality);
				gsQuestData[questId].choice.item[i].isUsable =  isUsable;
				gsQuestData[questId].choice.item[i].link = GetQuestItemLink("choice", i);
			end
		end
		
	end

end

--[[XXxx Event Functions xxXX]]--
--[[xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx]]
local function GossipShowEvent()
	gs.util.debugLog("GossipShowEvent()...");
	--This event is triggered any time you speak to a gossip NPC
	
	--Gather NPC data
	gatherNPCData();
	--Now check for greetings
	--checkGreeting();

	--Get NPC greeting
	--local gossipText = GetGossipText();
	--checkGreeting(gossipText);
	
	--Gather Quest data if applicable
	--local hasQuests = ((GetGossipAvailableQuests() ~= nil) or (GetGossipActiveQuests() ~= nil));
	--if (hasQuests) then
		--gs.util.debugLog("This NPC has quests...");
		--saveQuestData();
		
	--end
	
end


--[[XXxx Function xxXX]]--
local function QuestGreetingEvent()
	gs.util.debugLog("QuestGreetingEvent()...");
	--You see this when the NPC greets you and shows you a list of quests
	
	--Gather NPC data
	gatherNPCData();

	--local gossipText = GetGossipText();
	--If there's no gossip text then look for greeting text...
	--if (gossipText == nil) then
		--gs.util.debugLog("Could not find gossip greeting. Checking for alternative...")
		--gossipText = GetGreetingText();
	--end
end

local function AddObjective(quest, objective, questText)
	gs.util.debugLog("AddObjective()...");
end

local function InitQuest(title)
	gs.util.debugLog("InitQuest()...");
end

local function QuestDetailsEvent()
	--Triggered every time you click on a quest dialog to show the details
	gs.util.debugLog("QuestDetailsEvent()...");

	--Gather NPC data
	gatherNPCData();

	--Gather quest data
	gatherQuestData();
end

local function AddProgressCompleted(quest, category, text)
	gs.util.debugLog("AddProgressCompleted()...");
end

local function QuestProgressEvent()
	gs.util.debugLog("QuestProgressEvent()...");

	--Gather NPC data
	gatherNPCData();


	--Gather NPC data
	--SaveNpcData();

	--Gather Quest progress text
	gatherProgressText();


end

local function QuestCompleteEvent()
	gs.util.debugLog("QuestCompleteEvent()...");
	--Triggered when you've finished all quest objectives and hit continue, now you can see your reward and hit the "Complete Quest" button

	gatherQuestRewards();
end

local function QuestTurnedInEvent(...)
	gs.util.debugLog("Starting QuestTurnedInEvent();");
	--local questID, xp, money = ...;
	--gs.util.debugLog('ID: ' .. questID);
	--gs.util.debugLog('XP: ' .. xp);
	--gs.util.debugLog('$$: ' .. money);
	--local qif = QuestInfo_GetRewardButton(QuestInfoFrame.rewardsFrame, besti)
end


local function MerchantGreetingEvent()
	gs.util.debugLog("MerchantGreetingEvent()...");

	--Gather NPC data
	gatherNPCData();
end

local function AuctionHouseGreetingEvent()
	gs.util.debugLog("AuctionHouseGreetingEvent()...");

	--Gather NPC data
	gatherNPCData();
end

local function TrainerGreetingEvent()
	gs.util.debugLog("TrainerGreetingEvent()...");

	--Gather NPC data
	gatherNPCData();
end

local function TaxiGreetingEvent()
	gs.util.debugLog("TaxiGreetingEvent()...");

	--Gather NPC data
	gatherNPCData();
end

local function ServerQuestQueryReadyEvent()
	--I've executed QueryQuestsCompleted(); to get a list of this characters completed quests.
	--The server will trigger this event once the result is ready
	--Then I can call  GetQuestsCompleted() to get the list of completed quests
	--Completed quests IDs are stored as keys and all values should be "TRUE"

end

local function QuestAcceptedEvent()
	gs.util.debugLog("QuestAcceptedEvent()...");

	--process quest acceptance
	incQuestActivityCount(_, 'accept');
end

local function QuestRemovedEvent()
	gs.util.debugLog("QuestRemovedEvent()...");

	--process quest abandon
	--incQuestActivityCount(_, 'abandon');

end

--Print a status message upon load
print("Addon: " .. addonTitle .. "Loaded...")

-- Create a dummy window to capture the events

WMMFrame = CreateFrame("Frame", nil, UIParent);
WMMFrame:Show();
WMMFrame:RegisterEvent("GOSSIP_SHOW");
WMMFrame:RegisterEvent("QUEST_PROGRESS");
WMMFrame:RegisterEvent("QUEST_COMPLETE");
WMMFrame:RegisterEvent("QUEST_GREETING");
WMMFrame:RegisterEvent("QUEST_DETAIL");
WMMFrame:RegisterEvent("MERCHANT_SHOW");
WMMFrame:RegisterEvent("AUCTION_HOUSE_SHOW");
WMMFrame:RegisterEvent("TRAINER_SHOW");
WMMFrame:RegisterEvent("TAXIMAP_OPENED");
WMMFrame:RegisterEvent("QUEST_QUERY_COMPLETE");
WMMFrame:RegisterEvent("QUEST_ACCEPTED");
WMMFrame:RegisterEvent("QUEST_REMOVED");
WMMFrame:RegisterEvent("QUEST_TURNED_IN");
WMMFrame:SetScript("OnEvent", function(self, event, a, b, c)
	if (event == "QUEST_GREETING") then
		QuestGreetingEvent();
	elseif (event == "GOSSIP_SHOW") then
		GossipShowEvent();
	elseif (event == "QUEST_COMPLETE") then
		QuestCompleteEvent();
	elseif (event == "QUEST_PROGRESS") then
		QuestProgressEvent();
	elseif (event == "QUEST_DETAIL") then
		QuestDetailsEvent();
	elseif (event == "MERCHANT_SHOW") then
		MerchantGreetingEvent();
	elseif (event == "AUCTION_HOUSE_SHOW") then
		AuctionHouseGreetingEvent();
	elseif (event == "TRAINER_SHOW") then
		TrainerGreetingEvent();
	elseif (event == "TAXIMAP_OPENED") then
		TaxiGreetingEvent();
	elseif (event == "QUEST_QUERY_COMPLETE") then
		ServerQuestQueryReadyEvent();
	elseif (event == "QUEST_ACCEPTED") then
		QuestAcceptedEvent();
	elseif (event == "QUEST_REMOVED") then
		QuestRemovedEvent();
	elseif (event == "QUEST_TURNED_IN") then
		QuestTurnedInEvent();
	end
end);