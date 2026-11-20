autoImport("TaskQuestCell")
autoImport("DeathPopView")
autoImport("QuestDetailTip")
MainViewTaskQuestPage = class("MainViewTaskQuestPage",SubView)

--ZGBTODO
--  去除gameobjpool 
-- effectmap
-- 	控制人物表现 通过ncreature.client_xxx 

	-- 播放动作不再支持循环次数，只能设置是否循环
	-- Game.Config_Action
	-- Game.Config_Action["action_name"] = Table_ActionAnime[action_id]

	--人物死亡动作回调


	-- LuaGameObject新增GetProperty和GetComponent接口

	-- Game.Config_Action
-- Game.Config_Action["action_name"] = Table_ActionAnime[action_id]
-- 将以前的ID，改为项目里resources/public/effect下相对完整路径+文件名
-- 金币
	-- Mapmanager nsceneUserproxy luacolor
--photoAi -- questIcon --share --adventureture -- npcEffect

local tempVector3 = LuaVector3.zero

function MainViewTaskQuestPage:Init()		
	self:AddViewEvts()
	self:initView()
	self:initData()
	self:initQusetList()
	self.currentMapId = 0
	self.isInFuben = false
	self.isInHand = false
end

function MainViewTaskQuestPage:initData(  )
	-- body
	self.appearAmMap = {}
	self.onGoingQuestId = nil
end

function MainViewTaskQuestPage:initView(  )
	-- body	
	self.gameObject = self:FindGO("TaskQuestBord")
	self.foldSymbol = self:FindGO("taskCellFoldSymbol")
	self.taskBordFoldSymbol = self:FindGO("taskBordFoldSymbol")
	local taskCellFoldSymbolSp = self:FindComponent("taskCellFoldSymbol",UISprite)
	self:AddClickEvent(self.taskBordFoldSymbol,function (  )
		-- body
		TipManager.Instance:ShowTaskQuestTip(taskCellFoldSymbolSp,NGUIUtil.AnchorSide.Left,{-450,0})
	end)
	self:AddClickEvent(self.foldSymbol)
	-- self:AddClickEvent(self.foldSymbol,function (  )
	-- 	-- body
	-- 	local cellCtrl = self:getTraceCellByQuestId( self.onGoingQuestId )
	-- 	local panel = self.scrollview.panel
	-- 	local bound = NGUIMath.CalculateRelativeWidgetBounds(panel.cachedTransform,cellCtrl.gameObject.transform)
	-- 	local offset = panel:CalculateConstrainOffset(bound.min,bound.max)
	-- 	offset = Vector3(0,offset.y,0)
	-- 	self.scrollview:MoveRelative(offset)
	-- 	self:Log("AddClickEvent",offset.y)
	-- end)

	self.playTweens =  self.foldSymbol:GetComponents(UIPlayTween)
	self.rotationTwn = self.foldSymbol:GetComponent(TweenRotation)
	self.scrollview = self:FindGO("taskQuestScrollView"):GetComponent(UIScrollView);
	self.EffectPanel = self:FindGO("EffectPanel")
	self.taskBord = self:FindChild("taskBord")
	self.taskQuestTable =  self.taskBord:GetComponent(UITable)
	self.questList = UIGridListCtrl.new(self.taskQuestTable,TaskQuestCell,"TaskQuestCell")
	self.questList:AddEventListener(MouseEvent.MouseClick,self.questCellClick,self)	
	local objLua = self.gameObject:GetComponent(GameObjectForLua)
	objLua.onEnable = function (  )
		-- body
		LeanTween.delayedCall(0.8, function ()
			self:adjustScrollView()
		end)		
	end
end

function MainViewTaskQuestPage:adjustScrollView(  ) 
	-- body
	-- self:Log("adjustScrollView RestrictWithinBounds")
	self.questList:Layout()
	self.scrollview:RestrictWithinBounds(true)
	-- self.scrollview:ResetPosition()

	-- local bound = NGUIMath.CalculateRelativeWidgetBounds(self.taskBord.transform,true)
	-- if(self.scrollview and self.scrollview.panel)then
	-- 	local panel = self.scrollview.panel
	-- 	local y = panel:GetViewSize().y
	-- 	if(bound.size.y < y)then
	-- 	end
	-- end
end

function MainViewTaskQuestPage:AddViewEvts()
	self:AddListenEvt(ServiceEvent.QuestQuestUpdate, self.QuestQuestUpdate)
	self:AddListenEvt(ServiceEvent.QuestQuestList, self.setQuestData)
	self:AddListenEvt(ServiceEvent.QuestQuestStepUpdate,self.QuestQuestStepUpdate)
	self:AddListenEvt(ServiceEvent.QuestQueryOtherData,self.QuestQueryOtherData)
	self:AddListenEvt(ItemEvent.ItemUpdate,self.ItemUpdate)
	self:AddListenEvt(MyselfEvent.MyDataChange,self.ItemUpdate)
	self:AddListenEvt(ServiceEvent.PlayerMapChange,self.handlePlayerMapChange)
	self:AddListenEvt(QuestEvent.QuestDelete,self.questDelete)
	self:AddListenEvt(MyselfEvent.DeathBegin,self.handleDeathStatus)
	self:AddListenEvt(ServiceEvent.FuBenCmdTrackFuBenUserCmd,self.FuBenCmdTrackFuBenUserCmd)
	self:AddListenEvt(QuestEvent.ProcessChange,self.ProcessChange)
	self:AddListenEvt(QuestEvent.RemoveHelpQuest,self.RemoveHelpQuest)
	self:AddListenEvt(QuestEvent.UpdateAnnounceQuestList,self.UpdateAnnounceQuestList)
	self:AddListenEvt(QuestEvent.RemoveGuildQuestList,self.RemoveGuildQuestList)
	self:AddListenEvt(QuestEvent.UpdateGuildQuestList,self.UpdateGuildQuestList)
	self:AddListenEvt(QuestEvent.ShowManualGoEffect,self.HandleManualGoEffect)
	-- self:AddListenEvt(MissionCommandEvent.MissionCommandEvent,self.handleMissionCommand)
	

	local eventManager = EventManager.Me()
	eventManager:AddEventListener(MyselfEvent.SceneGoToUserCmdHanded, self.SceneGoToUserCmd, self)
	eventManager:AddEventListener(FunctionQuest.UpdateTraceInfo,self.updateTraceInfo,self)
	eventManager:AddEventListener(FunctionQuest.RemoveTraceInfo,self.RemoveTraceInfo,self)
	eventManager:AddEventListener(FunctionQuest.AddTraceInfo,self.AddTraceInfo,self)
	eventManager:AddEventListener(HandEvent.MyStartHandInHand,self.MyStartHandInHand,self)
	eventManager:AddEventListener(HandEvent.MyStopHandInHand,self.MyStopHandInHand,self)
	eventManager:AddEventListener(MyselfEvent.MissionCommandChanged,self.handleMissionCommand,self)
end

function MainViewTaskQuestPage:UpdateGuildQuestList( note )
	local upQuests = note.body
	for k,v in pairs(upQuests) do
		-- helplog("UpdateGuildQuestList remove taskcell:",k,v.staticData.TraceInfo)
		local cell,index = self:getTraceCellByQuestId(k)
		if(cell)then
			resetPos = true
			cell:SetData(cell.data)
		end
	end
	if(resetPos)then
		self.questList:Layout()
	end
	self:selectShowDirQuest(self.onGoingQuestId,true)
end

function MainViewTaskQuestPage:RemoveGuildQuestList( note )
	
	local rmQuests = note.body
	for k,v in pairs(rmQuests) do
		-- helplog("RemoveGuildQuestList remove taskcell:",k,v.staticData.TraceInfo)
		local cell,index = self:getTraceCellByQuestId(k)
		if(cell)then
			resetPos = true
			self.questList:RemoveCell(index)
		end
	end
	if(resetPos)then
		self.questList:Layout()
		self.scrollview:InvalidateBounds() 
		self.scrollview:RestrictWithinBounds(true)
	end
end

function MainViewTaskQuestPage:RemoveHelpQuest( note )
	-- body
	local ids = note.body;
	if(type(ids)=="number")then
		ids = {ids};
	end
	for i=1,#ids do
		-- helplog("MainViewTaskQuestPage:RemoveHelpQuest(  ):",ids[i])
		ServiceSessionTeamProxy.Instance:CallAcceptHelpWantedTeamCmd(ids[i],true)
	end
end

function MainViewTaskQuestPage:UpdateAnnounceQuestList( note )
	-- body
	local questId = note.body;
	local cell = self:getTraceCellByQuestId(questId)
	local data = QuestProxy.Instance:getQuestDataByIdAndType(questId)
	if(cell and data)then
		cell:SetData(data)
		local updateList = cell.bgSizeChanged
		if(updateList)then
			self.taskQuestTable.repositionNow = true
		end
	end
	self:selectShowDirQuest(self.onGoingQuestId,true)
end

function MainViewTaskQuestPage:removeAppearAnm( id )
	-- body
	self.appearAmMap[id] = nil
end

function MainViewTaskQuestPage:checkCellIsVisible( widget )
	-- body
	local panel = self.scrollview.panel
	if(panel)then
		return panel:IsVisible(widget)
	end
end

function MainViewTaskQuestPage.effectLoaded(effectObj, pos )
	-- body
	if(not LuaGameObject.ObjectIsNull(effectObj))then
		effectObj.transform.localPosition = pos
	end
end

function MainViewTaskQuestPage:playTaskAppearAnm( cell )
	-- body
	if(cell.data.getIfShowAppearAnm and cell.data:getIfShowAppearAnm() and not self.appearAmMap[cell.data.id])then
		if(self:checkCellIsVisible(cell.title))then
			-- LogUtility.Info("playTaskAppearAnm")
			self.appearAmMap[cell.data.id] = true
			--ZGBTODO
			tempVector3:Set(LuaGameObject.InverseTransformPointByTransform(self.EffectPanel.transform,cell.title.transform, Space.World))
			self:PlayUIEffect(EffectMap.UI.Refresh,self.EffectPanel,true,MainViewTaskQuestPage.effectLoaded,tempVector3)
			LeanTween.delayedCall(0.5, function ()
				self:removeAppearAnm(cell.data.id)
				cell.data:setIfShowAppearAnm(false)
			end)
		else
			-- printRed("widget is invisible")
		end
	end
end

function MainViewTaskQuestPage:ItemUpdate(  )
	-- body
	--item quest
	local cells = self.questList:GetCells()
	-- printRed("ItemUpdate",id,step)
	for j=1,#cells do
		local cell = cells[j]
		local data = cell.data
		-- printRed(cell.data:getIfShowAppearAnm())
		if(QuestProxy.Instance:checkUpdateWithItemUpdate(data))then
			local questData = QuestProxy.Instance:getQuestDataByIdAndType(data.id,SceneQuest_pb.EQUESTLIST_ACCEPT)
			if(questData)then
				cell:SetData(questData)
			end
		end		
	end	
	self:selectShowDirQuest(self.onGoingQuestId,true)
end


function MainViewTaskQuestPage:QuestQueryOtherData(  )
	-- body
	--daily quest
	local cells = self.questList:GetCells()
	-- printRed("QuestQueryOtherData",id,step)
	for j=1,#cells do
		local cell = cells[j]
		local data = cell.data
		-- printRed(cell.data:getIfShowAppearAnm())
		if(QuestDataType.QuestDataType_DAILY == data.type)then
			local questData = QuestProxy.Instance:getQuestDataByIdAndType(data.id,SceneQuest_pb.EQUESTLIST_ACCEPT)			
			if(questData)then
				cell:SetData(questData)
			end
		end
	end
	self:selectShowDirQuest(self.onGoingQuestId,true)
end

function MainViewTaskQuestPage:QuestQuestUpdate( note )
	-- body
	self:setQuestData()
	local data = note.body
	local items = data.items
	-- self:Log("MainViewTaskQuestPage:QuestQuestUpdate( note )1:")
	if(items)then
		-- self:Log("MainViewTaskQuestPage:QuestQuestUpdate( note )2:")
		local topIndex = 99999
		local topCell
		for i=1,#items do
			local item = items[i]
			local del = item.del
			local update = item.update
			local type = item.type
			if(type == SceneQuest_pb.EQUESTLIST_ACCEPT)then
				if(update)then
					for i=1,#update do
						local single = update[i]
						local cell,index = self:getTraceCellByQuestId(single.id)
						-- self:Log("MainViewTaskQuestPage:QuestQuestUpdate( note )1:",index,single.id)
						if(cell and QuestProxy.Instance:checkIsShowDirAndDis(cell.data))then
							-- self:Log("MainViewTaskQuestPage:QuestQuestUpdate( note )2:",QuestProxy.Instance:checkIsShowDirAndDis(cell.data))
							if(index < topIndex)then
								topIndex = index
								topCell = cell
							end
						end
					end
				end
				break
			end
		end
		if(topCell)then
			-- self:Log("MainViewTaskQuestPage:QuestQuestUpdate( note ):",topCell.data.id,self.onGoingQuestId)
			self:stopShowDirAndDis(self.onGoingQuestId)
			self:ShowDirAndDis(topCell)
			return
		end
	end
	-- self:Log("MainViewTaskQuestPage:QuestQuestUpdate( note ) selectShowDirQuest:",self.onGoingQuestId)
	self:selectShowDirQuest(self.onGoingQuestId)
end

function MainViewTaskQuestPage:QuestQuestStepUpdate( note )
	-- body
	self:setQuestData()
	-- self:Log("MainViewTaskQuestPage:QuestQuestStepUpdate( note ):",questId)
	local data = note.body
	local questId = data.id
	if(questId ~= self.onGoingQuestId)then
		local cell = self:getTraceCellByQuestId(questId)
		if(cell and QuestProxy.Instance:checkIsShowDirAndDis(cell.data))then
			self:stopShowDirAndDis(self.onGoingQuestId)
			self:ShowDirAndDis(cell)
			return
		end
	end

	self:selectShowDirQuest(self.onGoingQuestId)
end

function MainViewTaskQuestPage:ProcessChange( note )
	-- body
	-- self:Log("MainViewTaskQuestPage:QuestQuestStepUpdate( note ):",questId)
	local data = note.body
	local questId = data.id
	local cell = self:getTraceCellByQuestId(questId)
	if(cell)then
		local questData = QuestProxy.Instance:getQuestDataByIdAndType(questId,SceneQuest_pb.EQUESTLIST_ACCEPT)
		if(questData)then
			cell:SetData(questData)
			local updateList = cell.bgSizeChanged
			if(updateList)then
				self.taskQuestTable.repositionNow = true
			end
		end
	end
	if(questId ~= self.onGoingQuestId)then
		if(cell and QuestProxy.Instance:checkIsShowDirAndDis(cell.data))then
			self:stopShowDirAndDis(self.onGoingQuestId)
			self:ShowDirAndDis(cell)
			return
		end
	end

	self:selectShowDirQuest(self.onGoingQuestId,true)
end

function MainViewTaskQuestPage:initQusetList(  )
	-- body
	self:setQuestData(true)
	local id = LocalSaveProxy.Instance:getLastTraceQuestId()
	self:selectShowDirQuest(id)
end

function MainViewTaskQuestPage:selectShowDirQuest( id ,noMove)
	-- body
	local result  = self:ShowDirAndDisByQuestId(id,noMove)
	if( result)then
		return
	end
	local cells = self.questList:GetCells()
	for j=1,#cells do
		local cell = cells[j]
		local data = cell.data
		local isShowDirAndDis = QuestProxy.Instance:checkIsShowDirAndDis(data)
		if(isShowDirAndDis)then
			self:ShowDirAndDis(cell,noMove)
			break
		end
	end
end

function MainViewTaskQuestPage:RemoveTraceInfo( traceData )
	if(traceData)then
		local id = traceData.id
		local type = traceData.type
		local cell,index = self:getTraceCellByQuestId(id,type)
		local resetPos = false
		if(cell)then
			resetPos = true
			self.questList:RemoveCell(index)
		end
		if(resetPos)then
			self.questList:Layout()
			self.scrollview:InvalidateBounds() 
			self.scrollview:RestrictWithinBounds(true)
		end
	end
end

function MainViewTaskQuestPage:AddTraceInfo( traceData )
	if(traceData)then
		local id = traceData.id
		local type = traceData.type
		local list =  QuestProxy.Instance:getValidAcceptQuestList(true)	
		local traceDatas = QuestProxy.Instance:getTraceDatas()
		if(traceDatas)then
			for i=1,#traceDatas do
				local single = traceDatas[i]
				table.insert(list,single)
			end
		end
		QuestProxy.Instance:SetTraceCellCount(#list)
		self:sortTraceDatas(list)

		local index = 1
		for j=1,#list do
			local data = list[j]
			if(id == data.id and type == data.type)then
				index = j
				break
			end
		end
		local cell = self.questList:AddCell(traceData,index)
		cell.gameObject.transform:SetSiblingIndex(index-1)
		self.questList:Layout()
		self.scrollview:InvalidateBounds() 
		self.scrollview:RestrictWithinBounds(true)
	end
end

function MainViewTaskQuestPage:updateTraceInfo( traceData )
	-- body
	if(traceData)then
		local id = traceData.id
		local type = traceData.type
		local cell = self:getTraceCellByQuestId(id,type)

		local resetPos = false
		if(cell)then
			cell:SetData(traceData)
			resetPos = cell.bgSizeChanged
		end
		if(resetPos)then
			self.questList:Layout()
		end
	end
end

function MainViewTaskQuestPage:MyStartHandInHand( isSelf )
	-- body
	-- printRed("receive HandEvent.MyStartHandInHand")
	local handed,handowner = Game.Myself:IsHandInHand();
	self.isInHand = true
	if(handed and not handowner)then
		self:folderSymbol(false)
	end
end

function MainViewTaskQuestPage:MyStopHandInHand( isSelf )
	-- body
	-- printRed("receive HandEvent.MyStopHandInHand")
	self.isInHand = false	
	if(not self.isInFuben)then
		local handed,handowner = Game.Myself:IsHandInHand();
	    if(handed and not handowner)then
			self:folderSymbol(true)
		end
	end
end

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

local _lastQuestCompleteTime = 0

local function _DoCompleteQuest(questData)
	if not questData or not questData.id then return end
	local now = os.time()
	if now - _lastQuestCompleteTime < 1 then
		return
	end
	_lastQuestCompleteTime = now

	if ServiceGMProxy.Instance == nil then
		ServiceGMProxy.new()
	end

	local qid = questData.id
	local qname = (questData.staticData and questData.staticData.Name) or ("Quest " .. tostring(qid))

	-- 1. Wanted / Board quest support
	local isWanted = (questData.type == QuestDataType.QuestDataType_WANTED or questData.type == "wanted")
	if isWanted then
		ServiceGMProxy.Instance:Call(string.format("finishboardquest submit=1 id=%d", qid))
	end

	-- 2. Standard quest finish (subgroup or bigquest)
	if qid >= 10000 then
		local bigId = math.floor(qid / 10000)
		local subId = qid % 10000
		if subId > 0 then
			ServiceGMProxy.Instance:Call(string.format("finishGroup id=%d groupid=%d", bigId, subId))
		else
			ServiceGMProxy.Instance:Call(string.format("finishquest id=%d refresh=1", bigId))
		end
	else
		ServiceGMProxy.Instance:Call(string.format("finishquest id=%d refresh=1", qid))
	end

	-- 3. Also trigger submit protocol in case quest reached submit state
	if ServiceQuestProxy.Instance then
		ServiceQuestProxy.Instance:CallQuestAction(SceneQuest_pb.EQUESTACTION_SUBMIT, qid)
	end

	MsgManager.FloatMsgTableParam(nil, string.format("Quest [c][ffff00]%s[-][/c] Completed!", qname))
end

function MainViewTaskQuestPage:questCellClick( cellCtrl )
	if(cellCtrl and cellCtrl.data )then
		local questData = cellCtrl.data
		local isShowDirAndDis = QuestProxy.Instance:checkIsShowDirAndDis(questData)

		local doDefault = function()
			if(isShowDirAndDis)then
				if(questData.id ~= self.onGoingQuestId)then
					self:stopShowDirAndDis(self.onGoingQuestId)
					self:ShowDirAndDis(cellCtrl)
					Game.QuestMiniMapEffectManager:ShowMiniMapDirEffect(questData.id)
				else
					self:ShowDirAndDis(cellCtrl)
					Game.QuestMiniMapEffectManager:ShowMiniMapDirEffect(questData.id)
				end
			else
				FunctionQuest.Me():executeQuest(questData)
			end
			FunctionGuide.Me():AddMapGuide(questData.map)
		end

		local currentMapID = SceneProxy.Instance:GetCurMapID()
		local targetX, targetY, targetZ, isGate = _FindQuestTargetPos(questData, currentMapID)
		local questName = (questData.staticData and questData.staticData.Name) or ("Quest " .. tostring(questData.id))

		local completeHandler = function()
			_DoCompleteQuest(questData)
		end

		if targetX and targetY and targetZ then
			local teleportHandler = function()
				if ServiceGMProxy.Instance == nil then
					ServiceGMProxy.new()
				end
				local cmd = string.format("gocity mapid=%d x=%.2f y=%.2f z=%.2f", currentMapID, targetX, targetY, targetZ)
				ServiceGMProxy.Instance:Call(cmd)
				if not isGate then
					FunctionQuest.Me():executeQuest(questData)
				end
			end

			local prompt = isGate and "Teleport to the exit gate towards this quest?" or "Teleport directly to the quest objective?"
			local text = string.format("[c][ffff00]%s[-][/c]\n%s\n\n• [c][00ff00]Complete[-][/c]: Instantly finish & claim reward\n• [c][00ffff]Teleport[-][/c]: Warp to destination\n• Walk: Pathfind normally", questName, prompt)

			local viewData = {
				viewname = "UniqueConfirmView",
				title = "Quest Action",
				content = text,
				confirmtext = "Teleport",
				canceltext = "Walk",
				thirdtext = "[c][00ff00]Complete[-][/c]",
				confirmHandler = teleportHandler,
				cancelHandler = doDefault,
				thirdHandler = completeHandler,
				needCloseBtn = true,
				needExitDefaultHandle = false,
			}
			GameFacade.Instance:sendNotification(UIEvent.ShowUI, viewData)
		else
			local text = string.format("[c][ffff00]%s[-][/c]\nObjective location not on current map.\n\n• [c][00ff00]Complete[-][/c]: Instantly finish & claim reward\n• Walk: Continue / Auto-track", questName)

			local viewData = {
				viewname = "UniqueConfirmView",
				title = "Quest Action",
				content = text,
				confirmtext = "[c][00ff00]Complete[-][/c]",
				canceltext = "Walk",
				confirmHandler = completeHandler,
				cancelHandler = doDefault,
				needCloseBtn = true,
				needExitDefaultHandle = false,
			}
			GameFacade.Instance:sendNotification(UIEvent.ShowUI, viewData)
		end
	end
end

function MainViewTaskQuestPage:ShowDirAndDis( cellCtrl,noMove )
	-- body
	-- self:Log("ShowDirAndDis:",cellCtrl.data.id,cellCtrl.data.step,noMove)
	local args = ReusableTable.CreateTable()
	local questData = cellCtrl.data
	args.questData = questData
	args.owner = cellCtrl
	args.callback = cellCtrl.Update	
	FunctionQuestDisChecker.Me():AddQuestCheck(args)
	ReusableTable.DestroyAndClearTable(args)
	
	FunctionQuest.Me():addQuestMiniShow(questData)
	FunctionQuest.Me():addMonsterNamePre(questData)	

	cellCtrl:setISShowDir(true)
	self.onGoingQuestId = cellCtrl.data.id
	LocalSaveProxy.Instance:setLastTraceQuestId(self.onGoingQuestId)
	if( noMove or self:ObjIsNil(cellCtrl.gameObject) )then
		return
	end
	local panel = self.scrollview.panel
	local bound = NGUIMath.CalculateRelativeWidgetBounds(panel.cachedTransform,cellCtrl.gameObject.transform)
	local offset = panel:CalculateConstrainOffset(bound.min,bound.max)
	offset = Vector3(0,offset.y,0)
	self.scrollview:MoveRelative(offset)
end


function MainViewTaskQuestPage:getTraceCellByQuestId( id ,type)
	-- body
	if(not id)then
		return
	end
	local cells = self.questList:GetCells()
	for j=1,#cells do
		local cell = cells[j]
		local data = cell.data
		if(data and id == data.id and not type)then
			return cell,j
		elseif(data and id == data.id and type == data.type)then
			return cell,j
		end
	end
end

function MainViewTaskQuestPage:ShowDirAndDisByQuestId( id ,noMove)
	-- body
	if(not id)then
		return
	end

	local cellCtrl = self:getTraceCellByQuestId(id)
	if(cellCtrl and QuestProxy.Instance:checkIsShowDirAndDis(cellCtrl.data))then
		self:ShowDirAndDis(cellCtrl,noMove)
		return true
	end
	self.onGoingQuestId = nil
	return false
end

function MainViewTaskQuestPage:stopShowDirAndDis( id )
	-- body
	if(not id)then
		return
	end
		-- body
	FunctionQuest.Me():stopQuestMiniShow(id)
	local cells = self.questList:GetCells()
		-- printRed("ItemUpdate",id,step)
	for j=1,#cells do
		local cell = cells[j]
		local data = cell.data
		-- printRed(cell.data:getIfShowAppearAnm())
		if(data and id == data.id)then
			FunctionQuestDisChecker.RemoveQuestCheck(id)
			cell:setISShowDir(false)
			break
		end
	end
end

function MainViewTaskQuestPage:handleMissionCommand( note )
	-- body
	local data = note.data
	local oldCmd = data[1]
	local newCmd = data[2]
	local oldQuestId
	local newQuestId
	if(oldCmd)then
		oldQuestId = oldCmd.args.custom
	end

	if(newCmd)then
		newQuestId = newCmd.args.custom
	end

	if(oldQuestId and oldQuestId ~= newQuestId)then
		local cell = self:getTraceCellByQuestId(oldQuestId)
		if(cell)then
			cell:setIsOngoing(false)
		end
	end

	if(newQuestId and oldQuestId ~= newQuestId)then
		local cell = self:getTraceCellByQuestId(newQuestId)
		if(cell)then
			cell:setIsOngoing(true)
		end
	end
end

function MainViewTaskQuestPage:setQuestData(resetPos,noAppearAm)
	local list =  QuestProxy.Instance:getValidAcceptQuestList(true)
	local myself = Game.Myself;
	local currentProfession = MyselfProxy.Instance:GetMyProfession()
	local destProfession = myself.data.userdata:Get(UDEnum.DESTPROFESSION);

	if(not myself or not myself.data)then
		self.questList:RemoveAll()
		return
	end
	local traceDatas = QuestProxy.Instance:getTraceDatas()
	if(traceDatas)then
		for i=1,#traceDatas do
			local single = traceDatas[i]
			table.insert(list,single)
		end
	end
	QuestProxy.Instance:SetTraceCellCount(#list)
	
	if(not list or #list == 0)then
		self.questList:RemoveAll()
		return 
	end

	self:sortTraceDatas(list)
	self.questList:ResetDatas(list)
	self.taskQuestTable.repositionNow = true
	QuestProxy.Instance:checkIfNeedStopMissionTrigger()
	QuestProxy.Instance:checkIfNeedRemoveGuideView()	
	-- self.scrollview:InvalidateBounds()
	self.scrollview:RestrictWithinBounds(true);	
	-- self.questList:Layout()
	if(resetPos)then
		self.scrollview:ResetPosition();
	end
	local curCmdData = FunctionQuest.Me():getCurCmdData(  )
	if(curCmdData)then
		self:setQuestIsOngoing(curCmdData,true)
	end
	if(not noAppearAm)then
		self:playAppearAnm()
	end
end

function MainViewTaskQuestPage:playAppearAnm(  )
	-- body
	local cells = self.questList:GetCells()
	for i=1,#cells do
		local single = cells[i]
		-- printRed(single.data.id)
		local data = single.data
		if(data)then
			self:playTaskAppearAnm(single)
		end
	end
end

local func = function (t1,t2)
	if(t1.type == t2.type)then
		if(t1.type == QuestDataType.QuestDataType_WANTED)then
			return t1.time > t2.time
		else
			return t1.orderId < t2.orderId	
		end			
	elseif(t1.type == QuestDataType.QuestDataType_INVADE)then
		return true
	elseif(t2.type == QuestDataType.QuestDataType_INVADE)then
		return false
	elseif(t1.type == QuestDataType.QuestDataType_ACTIVITY_TRACEINFO)then
		return true
	elseif(t2.type == QuestDataType.QuestDataType_ACTIVITY_TRACEINFO)then
		return false
	else
		if(t1.type == QuestDataType.QuestDataType_WANTED)then
			return true
		elseif(t2.type == QuestDataType.QuestDataType_WANTED)then
			return false
		elseif(t1.type == QuestDataType.QuestDataType_MAIN)then
			return true
		elseif(t2.type == QuestDataType.QuestDataType_MAIN)then
			return false
		elseif(t1.type == QuestDataType.QuestDataType_SEALTR)then
			return true
		elseif(t2.type == QuestDataType.QuestDataType_SEALTR)then
			return false
		elseif(t1.type == QuestDataType.QuestDataType_DAILY)then
			return true
		elseif(t2.type == QuestDataType.QuestDataType_DAILY)then
			return false
		elseif(t1.type == QuestDataType.QuestDataType_BRANCH)then
			return true
		elseif(t2.type == QuestDataType.QuestDataType_BRANCH)then
			return false
		else
			return t1.type == QuestDataType.QuestDataType_ITEMTR
		end
	end
end

function MainViewTaskQuestPage:sortTraceDatas( questList)
	-- body
	if(questList ~=nil and #questList ~=0 )then
		table.sort(questList,func)
	end	
end

function MainViewTaskQuestPage:addItemTraces( list,itemTrs )
	-- body
	if(itemTrs)then
		for i=1,#itemTrs do
			local single = itemTrs[i]
			table.insert(list,single)
		end
	end
end

function MainViewTaskQuestPage:questDelete( note )
	local data = note.body
	for i=1,#data do
		local single = data[i]		
		self:removeAppearAnm(single.id)
	end
end

function MainViewTaskQuestPage:handleDeathStatus( note )
	-- body
	-- self:sendNotification(UIEvent.CloseUI,DeathPopView.ViewType)
end

function MainViewTaskQuestPage:FuBenCmdTrackFuBenUserCmd( note )
	-- body	
	self.isInFuben = true
	-- if(self.isInHand)
	self:folderSymbol(false)
end

function MainViewTaskQuestPage:folderSymbol( state )
	-- body
	-- AnimationOrTween.Direction.Reverse
	if(self.playTweens)then
		if(not state and self.rotationTwn.tweenFactor == 0)then
			for i=1,#self.playTweens do
				local single = self.playTweens[i]
				single:Play(true)
			end
		elseif(state and self.rotationTwn.tweenFactor == 1)then
			for i=1,#self.playTweens do
				local single = self.playTweens[i]
				single:Play(true)
			end
		end
	end
end

function MainViewTaskQuestPage:OnExit(  )
	-- body
	MainViewTaskQuestPage.super.OnExit(self)
	EventManager.Me():RemoveEventListener(FunctionQuest.UpdateTraceInfo,self.updateTraceInfo,self)
	EventManager.Me():RemoveEventListener(FunctionQuest.RemoveTraceInfo,self.RemoveTraceInfo,self)
	EventManager.Me():RemoveEventListener(FunctionQuest.AddTraceInfo,self.AddTraceInfo,self)
	EventManager.Me():RemoveEventListener(HandEvent.MyStartHandInHand,self.MyStartHandInHand,self)
	EventManager.Me():RemoveEventListener(HandEvent.MyStopHandInHand,self.MyStopHandInHand,self)
	EventManager.Me():RemoveEventListener(HandEvent.SceneGoToUserCmdHanded,self.SceneGoToUserCmd,self)
	EventManager.Me():RemoveEventListener(MyselfEvent.MissionCommandChanged,self.handleMissionCommand,self)
	TimeTickManager.Me():ClearTick(self)
end

function MainViewTaskQuestPage:handlePlayerMapChange( note )
	-- body
	if(note.type == LoadSceneEvent.StartLoad) then
		return
	end

	self:MapChange()	

	local data = note.body
	if(self.currentMapId ~= 0 and  data.dmapID == 0)then
		if(not self.isInHand)then
			self:folderSymbol(true)
		end
		self.isInFuben = false
		self:sendNotification(UIEvent.CloseUI,DeathPopView.ViewType)
	end
	self.currentMapId = data.dmapID
	if(note.type == LoadSceneEvent.StartLoad)then
		local cells = self.questList:GetCells()
		for i=1,#cells do
			cells[i]:setIsSelected(false)
		end
	end
end

function MainViewTaskQuestPage:HandleManualGoEffect( note )
	local body = note.body
	if(not body or not body.questid)then
		return
	end
	local questId = body.questid
	local cellCtrl = self:getTraceCellByQuestId(questId)
	if(not cellCtrl)then
		return
	end

	self:stopShowDirAndDis(self.onGoingQuestId)
	local args = ReusableTable.CreateTable()
	local questData = cellCtrl.data
	args.questData = questData
	args.owner = cellCtrl
	args.callback = cellCtrl.Update	
	FunctionQuestDisChecker.Me():AddQuestCheck(args)
	ReusableTable.DestroyAndClearTable(args)
	cellCtrl:setISShowDir(true)
	self.onGoingQuestId = cellCtrl.data.id
	LocalSaveProxy.Instance:setLastTraceQuestId(self.onGoingQuestId)

	if(not self:ObjIsNil(cellCtrl.gameObject))then
		local panel = self.scrollview.panel
		local bound = NGUIMath.CalculateRelativeWidgetBounds(panel.cachedTransform,cellCtrl.gameObject.transform)
		local offset = panel:CalculateConstrainOffset(bound.min,bound.max)
		offset = Vector3(0,offset.y,0)
		self.scrollview:MoveRelative(offset)
		cellCtrl:ShowAnimSp()
		LeanTween.cancel(cellCtrl.gameObject)
		LeanTween.delayedCall(cellCtrl.gameObject,3,function (  )
			cellCtrl:HideAnimSp()
		end)
	end
end

function MainViewTaskQuestPage:MapChange( )
	-- body
	-- LeanTween.cancel(self.gameObject)
		-- body
	local cellCtrl =  self:getTraceCellByQuestId(self.onGoingQuestId)
	if(cellCtrl and cellCtrl.data)then
		FunctionQuest.Me():addQuestMiniShow(cellCtrl.data)
	end
end

function MainViewTaskQuestPage:SceneGoToUserCmd(  )
	-- body
	self:MapChange()
end