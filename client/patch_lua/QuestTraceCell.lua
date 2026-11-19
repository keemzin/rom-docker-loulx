local function _FindQuestTargetPos(questData, currentMapID)
	local targetX, targetY, targetZ = nil, nil, nil
	local isGate = false
	local targetMapID = questData.map or currentMapID

	-- 1. Check if the NPC/objective is right here on the current map
	local uid = questData.params and questData.params.uniqueid
	local npcId = questData.params and (questData.params.npc or questData.params.monster)
	if type(npcId) == "table" then npcId = npcId[1] end

	-- 1a. Check active NPCs loaded in scene proxy
	if NSceneNpcProxy and NSceneNpcProxy.Instance then
		if uid then
			local npcs = NSceneNpcProxy.Instance:FindNpcByUniqueId(uid)
			if npcs and #npcs > 0 and npcs[1] then
				local p = npcs[1]:GetPosition()
				if p then targetX, targetY, targetZ = p[1] or p.x, p[2] or p.y, p[3] or p.z end
			end
		end
		if not targetX and npcId then
			local myPos = Game.Myself:GetPosition()
			local npc = NSceneNpcProxy.Instance:FindNearestNpc(myPos, npcId)
			if npc then
				local p = npc:GetPosition()
				if p then targetX, targetY, targetZ = p[1] or p.x, p[2] or p.y, p[3] or p.z end
			end
		end
	end

	-- 1b. Check map's static NPC spawn points
	if not targetX then
		local npcPointMap = Game.MapManager:GetNPCPointMap()
		if npcPointMap then
			if uid and npcPointMap[uid] and npcPointMap[uid].position then
				local p = npcPointMap[uid].position
				targetX, targetY, targetZ = p[1], p[2], p[3]
			end
			if not targetX and npcId then
				for _, pt in pairs(npcPointMap) do
					if pt.npcid == npcId or pt.ID == npcId then
						local p = pt.position
						if p then
							targetX, targetY, targetZ = p[1], p[2], p[3]
							break
						end
					end
				end
			end
		end
	end

	-- 1c. Check FunctionQuestDisChecker
	if not targetX and uid and FunctionQuestDisChecker and FunctionQuestDisChecker.Me then
		local p = FunctionQuestDisChecker.Me():getDestPostByUniqueId(uid)
		if p then targetX, targetY, targetZ = p.x or p[1], p.y or p[2], p.z or p[3] end
	end

	-- 1d. If target map is current map (or unassigned), check explicit quest position
	if not targetX and (not questData.map or questData.map == currentMapID) and questData.pos then
		local p = questData.pos
		targetX = p.x or p[1]
		targetY = p.y or p[2]
		targetZ = p.z or p[3]
	end

	-- 2. If target was NOT found on current map AND destination is another map, calculate exit gate!
	if not targetX and targetMapID ~= currentMapID then
		local myPos = Game.Myself:GetPosition()
		local outterInfo, innerInfo = nil, nil
		if WorldTeleport and WorldTeleport.CreateOutterTeleportInfo then
			outterInfo, innerInfo = WorldTeleport.CreateOutterTeleportInfo(myPos, targetMapID, nil, questData.pos)
		end
		if outterInfo and outterInfo.epID then
			local exitPointMap = Game.MapManager:GetExitPointMap()
			if exitPointMap and exitPointMap[outterInfo.epID] then
				local p = exitPointMap[outterInfo.epID].position
				if p then
					targetX, targetY, targetZ = p[1], p[2], p[3]
					isGate = true
				end
			end
		end
		if not targetX then
			if MapInnerTeleport and MapInnerTeleport[currentMapID] and MapInnerTeleport[currentMapID].outter and MapInnerTeleport[currentMapID].outter[targetMapID] then
				local exitPointMap = Game.MapManager:GetExitPointMap()
				if exitPointMap then
					local minCost = 9999999999
					local bestEP = nil
					for epID, bTable in pairs(MapInnerTeleport[currentMapID].outter[targetMapID]) do
						if type(bTable) == "table" then
							for _, bv in pairs(bTable) do
								if type(bv) == "table" and bv.totalCost and bv.totalCost < minCost then
									minCost = bv.totalCost
									bestEP = epID
								end
							end
						end
					end
					if bestEP and exitPointMap[bestEP] then
						local p = exitPointMap[bestEP].position
						if p then
							targetX, targetY, targetZ = p[1], p[2], p[3]
							isGate = true
						end
					end
				end
			end
		end
		if outterInfo and WorldTeleport and WorldTeleport.DestroyOutterTeleportInfo then
			WorldTeleport.DestroyOutterTeleportInfo(outterInfo)
		end
		if innerInfo and WorldTeleport and WorldTeleport.DestroyInnerTeleportInfo then
			WorldTeleport.DestroyInnerTeleportInfo(innerInfo)
		end
	end

	return targetX, targetY, targetZ, isGate
end

local baseCell = autoImport("BaseCell")
QuestTraceCell = class("QuestTraceCell",baseCell)

function QuestTraceCell:Init()
	self:initView()
end

function QuestTraceCell:initView(  )

	self.stepName = self:FindComponent("StepName", UILabel);
	self.stepTarget = self:FindComponent("StepTarget", UILabel);
	self.traceScrollViewPanel = self:FindComponent("TraceScrollView", UIPanel);
	self.traceScrollView = self:FindComponent("TraceScrollView", UIScrollView);
	-- self.scrollViewDrag = self:FindComponent("Background", UIDragScrollView);
	
	self.traceMark = self:FindGO("TraceMark")
	self.angle = self:FindGO("angle")
	self.questState = self:FindGO("questState")
	self:AddButtonEvent("TraceMark",function ()
		if self.data.questData then
			local questData = self.data.questData
			local doDefault = function()
				if not self.isMainViewTrace then
					EventManager.Me():DispatchEvent(QuestManualEvent.BeforeGoClick, self)
				end
				FunctionQuest.Me():executeManualQuest( questData )
			end

			local currentMapID = SceneProxy.Instance:GetCurMapID()
			local targetX, targetY, targetZ, isGate = _FindQuestTargetPos(questData, currentMapID)

			if targetX and targetY and targetZ then
				local myPos = Game.Myself:GetPosition()
				local dist = VectorUtility.DistanceXZ(myPos, LuaVector3(targetX, targetY, targetZ))
				if dist and dist < 6 and not isGate then
					doDefault()
					return
				end

				local text = isGate and "Teleport to the exit gate towards this quest?" or "Teleport directly to the quest objective?"
				local confirmHandler = function()
					if ServiceGMProxy.Instance == nil then
						ServiceGMProxy.new()
					end
					local cmd = string.format("gocity mapid=%d x=%.2f y=%.2f z=%.2f", currentMapID, targetX, targetY, targetZ)
					ServiceGMProxy.Instance:Call(cmd)
					if not isGate then
						FunctionQuest.Me():executeManualQuest(questData)
					end
				end
				UIUtil.PopUpConfirmYesNoView("Quest Teleport", text, confirmHandler, doDefault, nil, "Teleport", "Walk")
			else
				doDefault()
			end
		end
	end)

	-- local upPanel = UIUtil.GetComponentInParents(self.gameObject, UIPanel);
	-- if(upPanel and self.traceScrollViewPanel)then
	-- 	self.traceScrollViewPanel.depth = upPanel.depth + 1
	-- end
end

function QuestTraceCell:SetData(data)
	-- helplog("===QuestTraceCell:SetData==>>>>")
	-- TableUtil.Print( data )
	self.data = data
	local isAcceptable = true
	local questData = data.questData
	self.questId = questData.id
	self.stepTarget.text = ""
	if questData.staticData then
		-- helplog("===QuestTraceCell:SetData==>>>>", questData.staticData.Name)
		self.stepName.text = questData.staticData.Name
		--helplog("===parseTranceInfo==>>>>", questData.staticData.TraceInfo)
		local desStr = questData:parseTranceInfo()
		--helplog("===parseTranceInfo==>>>>", desStr)
		-- helplog("===QuestTraceCell==>>>>", questData.id)
		if(questData.type == QuestDataType.QuestDataType_DAILY)then
			local dailyData = QuestProxy.Instance:getDailyQuestData(SceneQuest_pb.EOTHERDATA_DAILY)
			local ratio = "0%"
			local exp = "0"
			if(dailyData)then
				ratio = dailyData.param4 * 100
				ratio = ratio.."%" 
				exp = dailyData.param3
			end
			desStr = string.format(desStr,exp)
			--helplog("===parseTranceInfo1==>>>>", desStr)
		end

		if data.type ~= SceneQuest_pb.EQUESTLIST_ACCEPT then
			if not desStr or desStr == "" then
				desStr = ""

				-- helplog("===questLevel===>>>>>>", questData.staticData.Level)
				local mylv = Game.Myself.data.userdata:Get(UDEnum.ROLELEVEL)
				-- helplog("===questMyLevel===>>>>>>", mylv)
				if questData.staticData.Level >= mylv then
					desStr = string.format(ZhString.QuestManual_Level, questData.staticData.Level)
					-- isAcceptable = false
				end

				preQuestList = questData.preQuest
				local isPrenameAdded = false
				-- helplog("===preQuestList===>>>>>>")
				-- TableUtil.Print( preQuestList )
				if preQuestList and #preQuestList > 0 then
					desStr = desStr .. ZhString.QuestManual_FormerQuest
					isPrenameAdded = true
					for i=1,#preQuestList do
						local questName = QuestManualProxy.Instance:GetQuestNameById( preQuestList[i] )
						if questName then
							desStr = desStr .. string.format(ZhString.QuestManual_QuestName, questName)
							-- isAcceptable = false
						end
					end
				end

				mustPreQuestList = questData.mustPreQuest
				-- TableUtil.Print( mustPreQuestList )
				if mustPreQuestList and #mustPreQuestList > 0 then
					if not isPrenameAdded then
						desStr = desStr .. ZhString.QuestManual_FormerQuest
					end

					for i=1,#mustPreQuestList do
						local questName = QuestManualProxy.Instance:GetQuestNameById( mustPreQuestList[i] )
						desStr = desStr .. string.format(ZhString.QuestManual_QuestName, questName)
					end
					-- isAcceptable = false
				end

				-- if isAcceptable then
				-- 	desStr = ZhString.QuestManual_Acceptable
				-- end
			end
		end

		-- helplog("===parseTranceInfo2=>>>>", desStr)
		self.stepTarget.text = string.gsub(desStr, "ffff00", "FFA823")
		self.traceScrollView:ResetPosition()
	else
		-- helplog("==data.questPreName==>>>", data.questPreName)
		self.stepName.text = data.questPreName
	end
	-- helplog("===QuestDataType==>>>>", data.type)
	if data.type then
		if data.type == SceneQuest_pb.EQUESTLIST_ACCEPT then 
			self.traceMark:SetActive(true)
			self.questState:SetActive(false)
		elseif data.type == SceneQuest_pb.EQUESTLIST_CANACCEPT then
			self.traceMark:SetActive(false)
			self.questState:SetActive(false)
			-- self.stepTarget.text = ZhString.QuestManual_Acceptable
		elseif data.type == SceneQuest_pb.EQUESTLIST_SUBMIT then
			self.traceMark:SetActive(false)
			self.questState:SetActive(true)
		else
			self.traceMark:SetActive(false)
			self.questState:SetActive(false)
		end
	end

	if self.angle then
		if questData.type == QuestDataType.QuestDataType_MAIN or questData.type == QuestDataType.QuestDataType_CCRASTEHAM then
			self.angle:SetActive(true)
		else
			self.angle:SetActive(false)
		end
	end

	local upPanel = UIUtil.GetComponentInParents(self.gameObject, UIPanel);
	if(upPanel and self.traceScrollViewPanel)then
		self.traceScrollViewPanel.depth = upPanel.depth + 1
	end
end

function QuestTraceCell:SetIsMainViewTrace(  )
	self.isMainViewTrace = true
end

-- EQUESTLIST_ACCEPT = 1;
-- EQUESTLIST_SUBMIT = 2;
-- EQUESTLIST_COMPLETE = 3;
-- EQUESTLIST_CANACCEPT = 4;
