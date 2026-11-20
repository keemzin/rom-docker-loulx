local UniqueConfirmView = class("UniqueConfirmView",BaseView)
UniqueConfirmView.ViewType = UIViewType.ConfirmLayer

function UniqueConfirmView:Init()
	self:FindObjs()
	-- self:FillTitle()
	self:FillContent()
	self:FillButton()
	self:InitCloseBtn()
end

function UniqueConfirmView:GetUnique()
	return self.viewdata and self.viewdata.unique
end

function UniqueConfirmView:FindObjs()
	self.isHandled = false
	-- self.titleLabel = GameObjectUtil.Instance:DeepFindChild(self.gameObject,"TitleLabel"):GetComponent(UILabel)
	self.contentLabel = GameObjectUtil.Instance:DeepFindChild(self.gameObject,"ContentLabel"):GetComponent(UILabel)
	self.confirmLabel = GameObjectUtil.Instance:DeepFindChild(self.gameObject,"ConfirmLabel"):GetComponent(UILabel)
	self.cancelLabel = GameObjectUtil.Instance:DeepFindChild(self.gameObject,"CancelLabel"):GetComponent(UILabel)
	self.confirmBtn = self:FindGO("ConfirmBtn")
	self.cancelBtn = self:FindGO("CancelBtn")

	self:AddButtonEvent("ConfirmBtn",function(go)
 		self:DoConfirm()
 		self:CloseSelf()
 	end)

 	self:AddButtonEvent("CancelBtn",function(go)
 		self:DoCancel()
 		self:CloseSelf()
 	end)
end

function UniqueConfirmView:InitCloseBtn()
	self.closeBtn = self:FindGO("CloseButton")
	if(self.closeBtn~=nil) then
		if(self.viewdata and self.viewdata.needCloseBtn) then
			self:Show(self.closeBtn)
		else
			self:Hide(self.closeBtn)
		end
	end
end

function UniqueConfirmView:DoConfirm()
	if(self.viewdata and self.viewdata.confirmHandler~=nil) then
		self.viewdata.confirmHandler(self.viewdata.source)
	end
end

function UniqueConfirmView:DoCancel()
	if(self.viewdata and self.viewdata.cancelHandler~=nil) then
		self.viewdata.cancelHandler(self.viewdata.source)
	end
end

function UniqueConfirmView:DoThird()
	if(self.viewdata and self.viewdata.thirdHandler~=nil) then
		self.viewdata.thirdHandler(self.viewdata.source)
	end
end

function UniqueConfirmView:CloseSelf()
	self.isHandled = true
	UniqueConfirmView.super.CloseSelf(self)
end

function UniqueConfirmView:OnEnter()
	UIManagerProxy.UniqueConfirmView = self
	UniqueConfirmView.super.OnEnter(self)
	self:FillButton()
end

function UniqueConfirmView:OnExit()
	if(self.isHandled==false and self.viewdata and self.viewdata.needExitDefaultHandle) then
		self:DoCancel()
	end
	if self.thirdBtn then
		GameObject.Destroy(self.thirdBtn)
		self.thirdBtn = nil
		self.thirdLabel = nil
	end
	UIManagerProxy.UniqueConfirmView = nil
	self.viewdata = nil
end

function UniqueConfirmView:FillTitle(text)
	text = text or (self.viewdata and self.viewdata.title)
	if(text~=nil and self.titleLabel~=nil) then
		self.titleLabel.text = text
	end
end

function UniqueConfirmView:FillContent(text)
	text = text or (self.viewdata and self.viewdata.content)
	if(text~=nil and self.contentLabel~=nil) then
		self.contentLabel.text = text
	end
end

function UniqueConfirmView:FillButton()
	if not self.viewdata then return end
	local confirmtext = self.viewdata.confirmtext
	if(confirmtext==nil or confirmtext=="") then
		self:Hide(self.confirmBtn)
	else
		self:Show(self.confirmBtn)
	end
	confirmtext = (confirmtext==nil or confirmtext=="") and ZhString.UniqueConfirmView_Confirm or confirmtext
	local canceltext = self.viewdata.canceltext
	if(canceltext==nil or canceltext=="") then
		self:Hide(self.cancelBtn)
	else
		self:Show(self.cancelBtn)
	end
	canceltext = (canceltext==nil or canceltext=="") and ZhString.UniqueConfirmView_CanCel or canceltext
	self.confirmLabel.text = confirmtext
	self.cancelLabel.text = canceltext

	local thirdtext = self.viewdata.thirdtext
	if thirdtext and thirdtext ~= "" then
		if not self.thirdBtn then
			self.thirdBtn = GameObject.Instantiate(self.confirmBtn)
			self.thirdBtn.name = "ThirdBtn"
			self.thirdBtn.transform.parent = self.confirmBtn.transform.parent
			self.thirdLabel = GameObjectUtil.Instance:DeepFindChild(self.thirdBtn, "ConfirmLabel"):GetComponent(UILabel)
			self:AddClickEvent(self.thirdBtn, function(go)
				self:DoThird()
				self:CloseSelf()
			end)
		end
		self:Show(self.thirdBtn)
		self.thirdLabel.text = thirdtext

		local scale = LuaVector3(0.80, 0.85, 1)
		self.cancelBtn.transform.localScale = scale
		self.confirmBtn.transform.localScale = scale
		self.thirdBtn.transform.localScale = scale

		self.cancelBtn.transform.localPosition = LuaVector3(-175, 0, 0)
		self.confirmBtn.transform.localPosition = LuaVector3(0, 0, 0)
		self.thirdBtn.transform.localPosition = LuaVector3(175, 0, 0)
	else
		if self.thirdBtn then
			self:Hide(self.thirdBtn)
		end
		local normalScale = LuaVector3(1, 1, 1)
		self.cancelBtn.transform.localScale = normalScale
		self.confirmBtn.transform.localScale = normalScale
		self.cancelBtn.transform.localPosition = LuaVector3(-120, 0, 0)
		self.confirmBtn.transform.localPosition = LuaVector3(120, 0, 0)
	end
end

return UniqueConfirmView
