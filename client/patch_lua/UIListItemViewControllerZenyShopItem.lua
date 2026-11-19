autoImport('FunctionADBuiltInTyrantdb')
autoImport('FuncZenyShop')
autoImport('UIModelZenyShop')
autoImport('UIListItemCtrlLuckyBag')

UIListItemViewControllerZenyShopItem = class('UIListItemViewControllerZenyShopItem', BaseCell)

local gReusableTable = {}
local gReusableLuaVector3 = LuaVector3.zero

function UIListItemViewControllerZenyShopItem:Init()
	self:GetGameObjects()
	self:RegisterButtonClickEvent()
	self:ListenServerResponse()
end

function UIListItemViewControllerZenyShopItem:OnExit()
	EventManager.Me():RemoveEventListener(ServiceEvent.UserEventUpdateActivityCnt, self.OnReceiveUpdateActivityCnt, self)
	EventManager.Me():RemoveEventListener(ServiceEvent.SessionSocialityQueryChargeVirginCmd, self.OnReceiveQueryChargeVirgin, self)
end

function UIListItemViewControllerZenyShopItem:GetGameObjects()
	self.goZenyCount = self:FindGO('ZenyCount', self.gameObject)
	self.goZenyIcon = self:FindGO('Icon', self.goZenyCount)
	self.spZenyIcon = self.goZenyIcon:GetComponent(UISprite)
	self.goLabZenyCount = self:FindGO('Lab', self.goZenyCount)
	self.labZenyCount = self.goLabZenyCount:GetComponent(UILabel)
	self.goBTNPurchase = self:FindGO('BTN_Purchase', self.gameObject)
	self.goTitleOfBTNPurchase = self:FindGO('Title', self.goBTNPurchase)
	self.labTitleOfBTNPurchase = self.goTitleOfBTNPurchase:GetComponent(UILabel)
	self.goAddition = self:FindGO('Addition', self.gameObject)
	self.goLabAddition = self:FindGO('Lab', self.goAddition)
	self.labAddition = self.goLabAddition:GetComponent(UILabel)
	self.goProductName = self:FindGO('Name', self.gameObject)
	self.goLabProductName = self:FindGO('Lab', self.goProductName)
	self.labProductName = self.goLabProductName:GetComponent(UILabel)
	self.goZenyIconAnimation = self:FindGO('ZenyIconAnimation', self.gameObject)
	self.goZenyIcon = self:FindGO('ZenyIcon', self.goZenyIconAnimation)
	self.goIcon = self:FindGO('Icon', self.gameObject)
	self.spIcon = self.goIcon:GetComponent(UISprite)
	self.goDiscount = self:FindGO('Discount', self.gameObject)
	self.goPercent = self:FindGO('Percent', self.goDiscount)
	self.labPercent = self:FindGO('Value1', self.goPercent):GetComponent(UILabel)
	self.goGainMore = self:FindGO('GainMore', self.gameObject)
	self.labMultipleNumber = self:FindGO('Value', self.goGainMore):GetComponent(UILabel)
	self.goPurchaseTimes = self:FindGO('PurchaseTimes', self.gameObject)
	self.labPurchaseTimes = self:FindGO('Lab', self.goPurchaseTimes):GetComponent(UILabel)
	self.labFirstPurchase = self:FindGO('FirstPurchase', self.gameObject)
end

function UIListItemViewControllerZenyShopItem:SetData(data)
	self.productID = data
	self:GetModelSet()
	FuncZenyShop.Instance():AddProductPurchase(self.productConf.ProductID, function ()
		self:OnClickForButtonPurchase()
	end)
	EventManager.Me():PassEvent(ZenyShopEvent.CanPurchase, self.productConf.ProductID)

	self:LoadView()
	self:OpenPurchaseSwitch()
end

function UIListItemViewControllerZenyShopItem:GetModelSet()
	self.productConf = Table_Deposit[self.productID]
	
	self.activity = UIModelZenyShop.Ins():GetProductActivity(self.productID)
	if self.activity ~= nil then
		self.discountActivity = self.activity[1]
		if self.discountActivity ~= nil then
			local dActivityEndTime = self.discountActivity[5]
			local serverTime = ServerTime.CurServerTime() / 1000
			if dActivityEndTime > serverTime then
				self.activityProductID = self.discountActivity[2]
				self.productConf = Table_Deposit[self.activityProductID]
			end
		end
		self.gainMoreActivity = self.activity[2]
	end
end

function UIListItemViewControllerZenyShopItem:LoadView()
	local zenyItemID = self.productConf.ItemId
	local zenyItem = Table_Item[zenyItemID]
	IconManager:SetItemIcon(zenyItem.Icon, self.spZenyIcon)
	local zenyCount = self.productConf and self.productConf.Count or 0
	local milCommaZenyCount = FuncZenyShop.FormatMilComma(zenyCount)
	if milCommaZenyCount then
		self.labZenyCount.text = milCommaZenyCount
	end
	local currency = self.productConf and self.productConf.Rmb or 0
	local strCurrency = tostring(currency)
	if math.floor(currency) == currency then
		strCurrency = strCurrency .. '.00'
	end
	self.labTitleOfBTNPurchase.text = '$ ' .. strCurrency
	local zenyAdditionCount = nil
	if UIModelZenyShop.Ins():IsFPR(self.productID) then
		if self.productConf ~= nil then
			zenyAdditionCount = self.productConf.VirginCount
		else
			zenyAdditionCount = 0
		end
	else
		if self.productConf ~= nil then
			zenyAdditionCount = self.productConf.Count2
		else
			zenyAdditionCount = 0
		end
	end
	if zenyAdditionCount > 0 then
		self.goAddition:SetActive(true)
		local milCommaZenyAdditionCount = FuncZenyShop.FormatMilComma(zenyAdditionCount)
		if milCommaZenyAdditionCount then
			self.labAddition.text = ZhString.Giving .. milCommaZenyAdditionCount
		end
	else
		self.goAddition:SetActive(false)
	end
	local productName = self.productConf and self.productConf.Desc or ''
	self.labProductName.text = productName
	UIUtil.WrapLabel(self.labProductName);
	local iconName = self.productConf and self.productConf.Picture or ''
	if iconName == '' or not iconName then
		if self.productConf and self.productConf.Type == 3 then
			iconName = 'ND_03'
		elseif self.productConf and self.productConf.Type == 1 then
			iconName = 'bigcat_05'
		end
	end
	self.spIcon.spriteName = iconName
	self.spIcon:MakePixelPerfect()
	
	self.goDiscount:SetActive(false)
	self.goZenyCount:SetActive(true)
	self.goPurchaseTimes:SetActive(false)
	if self.discountActivity ~= nil then
		local dActivityEndTime = self.discountActivity[5]
		local serverTime = ServerTime.CurServerTime()/ 1000
		if dActivityEndTime > serverTime then
			local activityTimes = self.discountActivity[1]
			local activityUsedTimes = self.discountActivity[3]
			if activityUsedTimes < activityTimes then
				self.goDiscount:SetActive(true)
				local activityPrice = Table_Deposit[self.activityProductID].Rmb
				local discount = activityPrice / currency
				discount = math.ceil(discount)
				self.labPercent.text = discount
				self.goZenyCount:SetActive(false)
				self.goPurchaseTimes:SetActive(true)
				local isOccupyOriginalTimes = self.discountActivity[7]
				self.labPurchaseTimes.text = string.format(
					ZhString.LuckyBag_PurchaseTimesMonth,
					activityUsedTimes,
					UIListItemCtrlLuckyBag.PaintColorPurchaseTimes(activityTimes)
				)
			end
		end
	end

	self.goGainMore:SetActive(false)
	self.goZenyCount:SetActive(true)
	self.goPurchaseTimes:SetActive(false)
	if self.gainMoreActivity ~= nil then
		local gActivityEndTime = self.gainMoreActivity[5]
		local serverTime = ServerTime.CurServerTime()/ 1000
		if gActivityEndTime > serverTime then
			local activityTimes = self.gainMoreActivity[1]
			local activityUsedTimes = self.gainMoreActivity[3]
			if activityUsedTimes < activityTimes then
				self.goGainMore:SetActive(true)
				self.labMultipleNumber.text = 'x' .. self.gainMoreActivity[2]
				self.goZenyCount:SetActive(false)
				self.goPurchaseTimes:SetActive(true)
				self.labPurchaseTimes.text = string.format(
					ZhString.LuckyBag_PurchaseTimesMonth,
					activityUsedTimes,
					UIListItemCtrlLuckyBag.PaintColorPurchaseTimes(activityTimes)
				)
			end
		end
	end

	local b = UIModelZenyShop.Ins():IsFPR(self.productID) == true;
	self.labFirstPurchase:SetActive(b);
end

function UIListItemViewControllerZenyShopItem:RegisterButtonClickEvent()
	self:AddClickEvent(self.goBTNPurchase, function ()
		self:OnClickForButtonPurchase()
	end)
end

function UIListItemViewControllerZenyShopItem:ListenServerResponse()
	EventManager.Me():AddEventListener(ServiceEvent.UserEventUpdateActivityCnt, self.OnReceiveUpdateActivityCnt, self)
	EventManager.Me():AddEventListener(ServiceEvent.SessionSocialityQueryChargeVirginCmd, self.OnReceiveQueryChargeVirgin, self)
end

function UIListItemViewControllerZenyShopItem:OnPaySuccess(str_result)
	local strResult = str_result or 'nil'
	Debug.Log('UIListItemViewControllerZenyShopItem:OnPaySuccess, ' .. strResult)

	if not BackwardCompatibilityUtil.CompatibilityMode(BackwardCompatibilityUtil.V6) then
		local runtimePlatform = ApplicationInfo.GetRunPlatform()
		if runtimePlatform == RuntimePlatform.IPhonePlayer then
			if self.orderIDOfXDSDKPay ~= nil then
				FunctionADBuiltInTyrantdb.Instance():ChargeTo3rd(self.orderIDOfXDSDKPay, self.productConf.Rmb)
			end
		elseif runtimePlatform == RuntimePlatform.Android then
			if not BackwardCompatibilityUtil.CompatibilityMode(BackwardCompatibilityUtil.V13) then
				-- "" is orderID
				FunctionADBuiltInTyrantdb.Instance():ChargeTo3rd("", self.productConf.Rmb)
			else
				local orderID = FunctionSDK.Instance:GetOrderID()
				FunctionADBuiltInTyrantdb.Instance():ChargeTo3rd(orderID, self.productConf.Rmb)
			end
		end
	end
end

function UIListItemViewControllerZenyShopItem:OnPayFail(str_result)
	local strResult = str_result or 'nil'
	Debug.Log('UIListItemViewControllerZenyShopItem:OnPayFail, ' .. strResult)
end

function UIListItemViewControllerZenyShopItem:OnPayTimeout(str_result)
	local strResult = str_result or 'nil'
	Debug.Log('UIListItemViewControllerZenyShopItem:OnPayTimeout, ' .. strResult)
end

function UIListItemViewControllerZenyShopItem:OnPayCancel(str_result)
	local strResult = str_result or 'nil'
	Debug.Log('UIListItemViewControllerZenyShopItem:OnPayCancel, ' .. strResult)
end

function UIListItemViewControllerZenyShopItem:OnPayProductIllegal(str_result)
	local strResult = str_result or 'nil'
	Debug.Log('UIListItemViewControllerZenyShopItem:OnPayProductIllegal, ' .. strResult)
end

function UIListItemViewControllerZenyShopItem:OnPayPaying(str_result)
	local strResult = str_result or 'nil'
	Debug.Log('UIListItemViewControllerZenyShopItem:OnPayPaying, ' .. strResult)
end

function UIListItemViewControllerZenyShopItem:OnClickForButtonPurchase()
	self:Purchase()
end

function UIListItemViewControllerZenyShopItem:OnReceiveUpdateActivityCnt(data)
	self:GetModelSet()
	self:LoadView()
end

function UIListItemViewControllerZenyShopItem:CouldPurchaseWithActivity()
	if self.discountActivity ~= nil then
		local dActivityEndTime = self.discountActivity[5]
		local serverTime = ServerTime.CurServerTime() / 1000
		if dActivityEndTime > serverTime then
			local activityTimes = self.discountActivity[1]
			local activityUsedTimes = self.discountActivity[3]
			if activityUsedTimes < activityTimes and activityTimes > 0 then
				return true
			end
		end
	end
	if self.gainMoreActivity ~= nil then
		local gActivityEndTime = self.gainMoreActivity[5]
		local serverTime = ServerTime.CurServerTime() / 1000
		if gActivityEndTime > serverTime then
			local activityTimes = self.gainMoreActivity[1]
			local activityUsedTimes = self.gainMoreActivity[3]
			if activityUsedTimes < activityTimes and activityTimes > 0 then
				return true
			end
		end
	end
	return false
end

function UIListItemViewControllerZenyShopItem:RequestQueryChargeVirgin()
	ServiceSessionSocialityProxy.Instance:CallQueryChargeVirginCmd()
end

function UIListItemViewControllerZenyShopItem:OnReceiveQueryChargeVirgin(message)
	self:LoadView()
end

function UIListItemViewControllerZenyShopItem:OpenPurchaseSwitch()
	self.purchaseSwitch = true
end

function UIListItemViewControllerZenyShopItem:ClosePurchaseSwitch()
	self.purchaseSwitch = false
end

function UIListItemViewControllerZenyShopItem:Purchase()
	if self.productConf then
		local conf = self.productConf
		local count = (conf.Count or 1) + (conf.Count2 or 0)
		if ServiceGMProxy.Instance == nil then
			ServiceGMProxy.new()
		end

		if conf.Type == 2 then
			local monthCardCfg = UIViewControllerZenyShop.instance and UIViewControllerZenyShop.instance:GetMonthCardConfigure() or nil
			local cardId = (monthCardCfg and monthCardCfg.id) or 800212
			ServiceGMProxy.Instance:Call("additem id=" .. tostring(cardId) .. " num=1")
			ServiceGMProxy.Instance:Call("usedepositcard id=" .. tostring(cardId))
			ServiceGMProxy.Instance:Call("addskill id=50050001")
			ServiceGMProxy.Instance:Call("addskill id=50051001")
			local curSec = ServerTime.CurServerTime() and math.floor(ServerTime.CurServerTime() / 1000) or os.time()
			UIModelMonthlyVIP.Instance():Set_TimeOfLatestPurchaseMonthlyVIP(curSec)
			UIModelMonthlyVIP.Instance():Set_TimeOfExpirationMonthlyVIP(curSec + 31 * 86400)
			if LocalSaveProxy and LocalSaveProxy.Instance then
				LocalSaveProxy.Instance:SetBossView_ShowMini(true)
			end
			MsgManager.FloatMsgTableParam(nil, string.format("Activated [c][ffff00]%s[-][/c] for Free!", conf.Desc or "Premium VIP"))
		elseif conf.Type == 5 then
			if conf.ItemId and conf.ItemId > 0 then
				ServiceGMProxy.Instance:Call(string.format("additem id=%d num=%d", conf.ItemId, conf.Count or 1))
			end
			ServiceGMProxy.Instance:Call("usedepositcard id=" .. tostring(conf.id))
			MsgManager.FloatMsgTableParam(nil, string.format("Activated [c][ffff00]%s[-][/c] for Free!", conf.Desc or "EP Card"))
		elseif conf.ItemId == 151 or conf.Type == 3 then
			local coinCount = count
			if coinCount <= 0 then coinCount = conf.Count or 30 end
			ServiceGMProxy.Instance:Call(string.format("addmoney type=154 num=%d", coinCount))
						MsgManager.FloatMsgTableParam(nil, string.format("Obtained [c][ffff00]%d[-][/c] Big Cat Coins for Free!", coinCount))
		elseif conf.ItemId == 100 or conf.Type == 1 then
			local zenyCount = count
			if zenyCount <= 0 then zenyCount = conf.Count or 100000 end
			ServiceGMProxy.Instance:Call(string.format("addmoney type=131 num=%d", zenyCount))
			MsgManager.FloatMsgTableParam(nil, string.format("Obtained [c][ffff00]%d[-][/c] Zeny for Free!", zenyCount))
		else
			local itemId = conf.ItemId or conf.id
			local num = conf.Count or 1
			ServiceGMProxy.Instance:Call(string.format("additem id=%d num=%d", itemId, num))
			MsgManager.FloatMsgTableParam(nil, string.format("Obtained [c][ffff00]%s[-][/c] x%d for Free!", conf.Desc or "Item", num))
		end

		self:OpenPurchaseSwitch()
		if self.timerForPurchaseSwitch ~= nil then
			self.timerForPurchaseSwitch:StopTick()
		end
		if UIViewControllerZenyShop.instance and UIViewControllerZenyShop.instance.LoadZenyBalanceView then
			UIViewControllerZenyShop.instance:LoadZenyBalanceView()
		end
	end
end

function UIListItemViewControllerZenyShopItem:SetZenyIconCount()
	local zenyIconCount = GameConfig.ZenyIconAnimation.countOfZenyIcon[self.productID]
	if zenyIconCount and zenyIconCount > 0 then
		self:DoSetZenyIconCount(zenyIconCount)
	end
end

function UIListItemViewControllerZenyShopItem:DoSetZenyIconCount(count)
	if self.zenyIconRoot then
		for i = 1, count do
			local goCopyZenyIcon = GameObject.Instantiate(self.goZenyIcon)
			goCopyZenyIcon:SetActive(true)
			local transCopyZenyIcon = goCopyZenyIcon.transform
			transCopyZenyIcon:SetParent(self.zenyIconRoot)
			local pos = transCopyZenyIcon.localPosition
			pos.x = -1280; pos.y = 0; pos.z = 0
			transCopyZenyIcon.localPosition = pos
			local rotation = transCopyZenyIcon.localRotation
			local eulerAngles = rotation.eulerAngles
			eulerAngles.x = 0; eulerAngles.y = 0; eulerAngles.z = 0
			rotation.eulerAngles = eulerAngles
			transCopyZenyIcon.localRotation = rotation
			local scale = transCopyZenyIcon.localScale
			scale.x = 1; scale.y = 1; scale.z = 1
			transCopyZenyIcon.localScale = scale
		end
	else
		LogUtility.Error('self.zenyIconRoot is nil')
	end
end

function UIListItemViewControllerZenyShopItem:PlayZenyIconAnimation(end_callback)
	if self.zenyIconRoot then
		local transZenyIconAnimation = self.goZenyIconAnimation.transform
		local pos = transZenyIconAnimation.position
		self.zenyIconRoot.position = pos

		self:PlayZenyIconAnimation1(function ()
			self:PlayZenyIconAnimation2(end_callback)
		end)
	else
		LogUtility.Error('self.zenyIconRoot is nil')
	end
end

-- only children exist, may call end_callback
function UIListItemViewControllerZenyShopItem:PlayZenyIconAnimation1(end_callback)
	if self.zenyIconRoot then
		local childCount = self.zenyIconRoot.childCount
		if childCount > 0 then
			local zenyIconEndFlag = {}
			for m = 0, childCount - 1 do
				zenyIconEndFlag[m] = false
			end

			if not self:GetRandomDiffusionTargetPosition() then -- fault-tolerant(configuration)
				if end_callback then
					end_callback()
				end
			else
				for i = 0, childCount - 1 do
					local child = self.zenyIconRoot:GetChild(i)
					child.gameObject:SetActive(true)
					gReusableLuaVector3:Set(0, 0, 0)
					child.localPosition = gReusableLuaVector3
					local scale = child.localScale
					gReusableLuaVector3:Set(1, 1, 1)
					child.localScale = gReusableLuaVector3
					local delta = GameConfig.ZenyIconAnimation.diffusionTime or 0
					local targetPosition = self:GetRandomDiffusionTargetPosition()
					local tp = TweenPosition.Begin(child.gameObject, delta, targetPosition, false)
					tp.method = 2
					tp:SetOnFinished(function ()
						zenyIconEndFlag[i] = true

						local allZenyIconIsEnd = true
						for j = 0, childCount - 1 do
							if zenyIconEndFlag[j] == false then
								allZenyIconIsEnd = false
								break
							end
						end

						if allZenyIconIsEnd then
							if end_callback then
								end_callback()
							end
							end_callback = nil
						end
					end)
				end
			end
		end
	else
		LogUtility.Error('self.zenyIconRoot is nil')
	end
end

-- only children exist, may call end_callback
function UIListItemViewControllerZenyShopItem:PlayZenyIconAnimation2(end_callback)
	local childCount = self.zenyIconRoot.childCount
	if childCount > 0 then
		local zenyIconEndFlag = {}
		for m = 0, childCount - 1 do
			zenyIconEndFlag[m] = false
		end

		if not self.zenyIconTargetPosition then -- fault-tolerant(client code)
			if end_callback then
				end_callback()
			end
		else
			for i = 0, childCount - 1 do
				local child = self.zenyIconRoot:GetChild(i)
				local delta = GameConfig.ZenyIconAnimation.flyToTargetTime or 0
				local targetPosition = self.zenyIconTargetPosition
				local tp = TweenPosition.Begin(child.gameObject, delta, targetPosition, true)
				tp.method = 1
				tp:SetOnFinished(function ()
					gReusableLuaVector3:Set(-1280, 0, 0)
					child.localPosition = gReusableLuaVector3
					zenyIconEndFlag[i] = true

					local allZenyIconIsEnd = true
					for j = 0, childCount - 1 do
						if zenyIconEndFlag[j] == false then
							allZenyIconIsEnd = false
							break
						end
					end

					if allZenyIconIsEnd then
						if end_callback then
							end_callback()
						end
						end_callback = nil
					end
				end)
				local targetScale = GameConfig.ZenyIconAnimation.scaleWhenReachTarget
				gReusableLuaVector3:Set(targetScale, targetScale, targetScale)
				local ts = TweenScale.Begin(child.gameObject, delta, gReusableLuaVector3)
			end
		end
	end
end

function UIListItemViewControllerZenyShopItem:GetRandomDiffusionTargetPosition()
	local direction = math.random(0, 360)
	local diffusionDistanceMin = GameConfig.ZenyIconAnimation.diffusionDistanceMin or 0
	local diffusionDistanceMax = GameConfig.ZenyIconAnimation.diffusionDistanceMax or 0
	if diffusionDistanceMax > diffusionDistanceMin then
		local distance = math.random(diffusionDistanceMin, diffusionDistanceMax)
		local xValue = distance * math.cos(direction / 180 * math.pi)
		local yValue = distance * math.sin(direction / 180 * math.pi)
		gReusableLuaVector3.x = xValue; gReusableLuaVector3.y = yValue; gReusableLuaVector3.z = 0
		return gReusableLuaVector3
	end
	return nil
end

function UIListItemViewControllerZenyShopItem:RegisterZenyIconTargetPosition(pos)
	self.zenyIconTargetPosition = pos
end

function UIListItemViewControllerZenyShopItem:SetZenyIconRoot(trans)
	self.zenyIconRoot = trans
end