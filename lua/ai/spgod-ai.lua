sgs.ai_skill_invoke.motian = function(self, data)
	local dying = data:toDying()
	return self:isEnemy(dying.who)
end

sgs.shendongzhuo_keep_value = 
{
    Analeptic=6
}

sgs.ai_skill_invoke.baozheng=function(self,data)
	local damage=data:toDamage()
	if not self:damageIsEffective(self.player,damage.nature,damage.from) or  (damage.to:getArmor() and damage.to:getArmor():getClassName()=="SilverLion" and damage.to:hasArmorEffect("SilverLion")) then return false end
	if self:hasSkills("mengwu|bumie",damage.to) then return false end
	if damage.nature~=sgs.DamageStruct_Normal and damage.to:hasSkill("wunv") then return false end
	if damage.from and damage.from:objectName()==self.player:objectName() and self:isEnemy(damage.to) then return true end
	if damage.to:objectName()==self.player:objectName()  then return true end
	return false
end	

sgs.ai_skill_cardask["@baozhengdec"]=function(self, data, pattern, target)
	if self.player:isKongcheng() then return "." end
	local cards={}
	for _,card in sgs.qlist(self.player:getHandcards()) do
		if card:isKindOf("BasicCard") then
			table.insert(cards,card)
		end
	end
	self:sortByKeepValue(cards)
	local dongzhuo=data:toPlayer()
	if self:isEnemy(dongzhuo) or (dongzhuo:getArmor() and dongzhuo:getArmor():getClassName()=="SilverLion") then return "." end
	return cards[1]:toString()
end

sgs.ai_skill_cardask["@baozhenginc"]=function(self, data, pattern, target)
	if self.player:isKongcheng() then return "." end
	local cards={}
	for _,card in sgs.qlist(self.player:getHandcards()) do
		if card:isKindOf("BasicCard") then
			table.insert(cards,card)
		end
	end
	self:sortByKeepValue(cards)
	local dongzhuo=data:toPlayer()
	if not self:isFriend(dongzhuo) then return "." end
	if (dongzhuo:getArmor() and dongzhuo:getArmor():getClassName()=="SilverLion") then return "." end
	return cards[1]:toString()
end

local xujiu_skill={}
xujiu_skill.name="xujiu"
table.insert(sgs.ai_skills,xujiu_skill)
xujiu_skill.getTurnUseCard=function(self)
	local cards = self.player:getCards("he")
	cards=sgs.QList2Table(cards)

	local basiccard

	self:sortByUseValue(cards,true)

	for _,card in ipairs(cards)  do
		if card:isKindOf("Jink") or card:isKindOf("Peach") then
			basiccard = card
			break
		end	
	end

	if basiccard then
		local suit = basiccard:getSuitString()
		local number = basiccard:getNumberString()
		local card_id = basiccard:getEffectiveId()
		local card_str = ("analeptic:xujiu[%s:%s]=%d"):format(suit, number, card_id)
		local analeptic = sgs.Card_Parse(card_str)

		assert(analeptic)

		return analeptic
	end
end

sgs.ai_filterskill_filter.xujiu = function(card, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:isKindOf("Jink") or card:isKindOf("Peach") then return ("analeptic:xujiu[%s:%s]=%d"):format(suit, number, card_id) end
end

sgs.ai_skill_askforag.spqixing = function(self, card_ids)
	local cards = {}
	for _, card_id in ipairs(card_ids) do
		table.insert(cards, sgs.Sanguosha:getCard(card_id))
	end
	self:sortByCardNeed(cards)
	if self.player:getPhase() == sgs.Player_Draw then
		return cards[#cards]:getEffectiveId()
	end
	if self.player:getPhase() == sgs.Player_Finish then
		return cards[1]:getEffectiveId()
	end
	return -1
end

sgs.ai_skill_invoke.xinghun=function(self,data)
	local lord=self.room:getLord()
	if self:isFriend(lord) then
		return true
	end	
	self:sort(self.friends,"hp",true)
	for _,friend in ipairs(self.friends_noself) do
		if friend then return true end
	end
	return false
end

sgs.ai_skill_playerchosen.xinghun=function(self,targets)
	local lord=self.room:getLord()
	if self:isFriend(lord) then return lord end
	self:sort(self.friends,"hp",true)
	for _,friend in ipairs(self.friends_noself) do
		return friend
	end
end
	
sgs.ai_skill_invoke.spwushen=function(self,data)
	local enemies={}
	local card=sgs.Sanguosha:cloneCard("fire_slash",sgs.Card_Heart,0)
	for _,target in ipairs(self.enemies) do
		if self:isEnemy(target) and not self:cantbeHurt(target) and self:slashIsEffective(card,target) then
			table.insert(enemies,target)
		end
	end
	self:sort(enemies,"defense")
	if #enemies>0 then
		return true		
	end
	return false
end

sgs.ai_skill_playerchosen.spwushen=function(self,targets)
	local enemies={}
	local card=sgs.Sanguosha:cloneCard("fire_slash",sgs.Card_Heart,0)
	for _,target in sgs.qlist(targets) do
		if self:isEnemy(target) and not self:cantbeHurt(target) and self:slashIsEffective(card,target) then
			table.insert(enemies,target)
		end
	end
	self:sort(enemies,"defense")
	if #enemies>0 then
		return enemies[1]
	end
	return targets:at(0)
end	

sgs.ai_skill_use["@@spkuangfeng"] = function(self,prompt)
	local is_chained = 0
	local targets = {}
	for _, enemy in ipairs(self.enemies) do
		if enemy:isChained() then
			is_chained = is_chained + 1
			table.insert(targets, enemy)
		end
		if enemy:getArmor() and enemy:getArmor():objectName() == "Vine" then
			table.insert(targets, 1, enemy)
			break
		end
	end
	local usecard=false
	if is_chained > 1 then usecard=true end
	self:sort(self.friends, "hp")
	if #targets > 0 and not self:isWeak(self.friends[1]) then
		if targets[1]:getArmor() and targets[1]:getArmor():objectName() == "Vine" then usecard=true end
	end
	if usecard then
		if #targets ==0 then table.insert(targets,self.enemies[1]) end
		if #targets > 0 then return "#spkuangfeng_card:.:->" .. table.concat(targets, "+") else return "." end
	else
		return "."
	end
end

sgs.ai_card_intention.spkuangfeng_card = 80

sgs.ai_skill_use["@@spdawu"] = function(self, prompt)
	self:sort(self.friends_noself, "hp")
	local targets = {}
	local lord = self.room:getLord()
	self:sort(self.friends_noself,"defense")
	if self:isFriend(lord) and not sgs.isLordHealthy() and not self.player:isLord() and not lord:hasSkill("buqu") then table.insert(targets, lord:objectName())
	else
		for _, friend in ipairs(self.friends_noself) do
			if self:isWeak(friend) and not friend:hasSkill("buqu") then table.insert(targets, friend:objectName()) break end
		end	
	end
	if self.player:getPile("spstar"):length() > #targets and self:isWeak() then table.insert(targets, self.player:objectName()) end
	if #targets > 0 then return "#spdawu_card:.:->" .. table.concat(targets, "+") end
	return "."
end

sgs.ai_card_intention.spdawu_card = -70

local tianwu_skill={}
tianwu_skill.name="tianwu"
table.insert(sgs.ai_skills,tianwu_skill)
tianwu_skill.getTurnUseCard=function(self)
	if not self.player:hasFlag("tianwuused") then
		return sgs.Card_Parse("#tianwu_card:.:")
	end
end

sgs.ai_skill_use_func["#tianwu_card"] = function(card, use, self)
	self:sort(self.enemies, "defense")
	local enemies={}
	local n
	if self.player:getCards("he"):length()<=2 then n=2 
	elseif self.player:getCards("he"):length()<=6 then n=3
	else n=4
	end
	if n>2+self.player:getLostHp() then n=2+self.player:getLostHp() end
	local slash=sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
	for _,enemy in ipairs(self.enemies) do
		if #enemies<n then
			local useful=false
			if #enemies==0 then useful=true else 
				for i=1,#enemies,1 do 
					if self:damageIsEffective(enemies[i],sgs.DamageStruct_Normal,enemy,slash) or self:damageIsEffective(enemy,sgs.DamageStruct_Normal,enemies[i],slash) then useful=true break end 
				end
			end
			if useful then table.insert(enemies,enemy) end
		end
	end
	
	if #enemies>=2 then
		use.card=sgs.Card_Parse("#tianwu_card:.:")
		for i=1,#enemies,1 do 
			if use.to then use.to:append(enemies[i]) end
		end
	end
	return
end	

sgs.ai_use_priority.tianwu_card = 10

sgs.ai_skill_invoke.spbiyue=function(self, data)
	local males={}
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:isMale() and not p:isNude() then table.insert(males,p) end
	end
	local f=0
	local e=0
	for _,male in ipairs(males) do
		if self:isFriend(male) then f=f+1 else e=e+1 end
	end
	return e>=f or self.player:getHandcardNum()<2
end

sgs.ai_skill_invoke.hunsu=function(self,data)
	local lord=self.room:getLord()
	if self:isFriend(lord) and lord:isMale() then
		return true
	end	
	self:sort(self.friends,"hp")
	for _,friend in ipairs(self.friends_noself) do
		if friend:isMale() then
			return true
		end	
	end
	return false
end

sgs.ai_skill_playerchosen.hunsu=function(self,targets)
	local lord=self.room:getLord()
	if self:isFriend(lord) and lord:isMale() then return lord end
	self:sort(self.friends,"hp")
	for _,friend in ipairs(self.friends_noself) do
		if friend:isMale() then
			return friend
		end	
	end
end

local jihun_skill={}
jihun_skill.name="jihun"
table.insert(sgs.ai_skills, jihun_skill)
jihun_skill.getTurnUseCard = function(self)
	if self.player:getHp()>1 then return end
	local cards=sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards,true)
	if self.player:getWeapon() then
		local card=self.player:getWeapon()
		if card:isRed() then
			return sgs.Card_Parse(("fire_slash:jihun[%s:%s]=%d"):format(card:getSuitString(),card:getNumberString(),card:getId()))
		elseif card:isBlack() then
			return sgs.Card_Parse(("thunder_slash:jihun[%s:%s]=%d"):format(card:getSuitString(),card:getNumberString(),card:getId()))
		end
	end	
	for _, card in ipairs(cards) do
		if card:isKindOf("Weapon") then
			return sgs.Card_Parse(("slash:jihun[%s:%s]=%d"):format(card:getSuitString(),card:getNumberString(),card:getId()))
		elseif card:isKindOf("DefensiveHorse") then
			return sgs.Card_Parse(("peach:jihun[%s:%s]=%d"):format(card:getSuitString(),card:getNumberString(),card:getId()))
		end	
	end
end

sgs.ai_view_as.jihun = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:isKindOf("Weapon") then
		return ("slash:jihun[%s:%s]=%d"):format(suit, number, card_id)
	elseif card:isKindOf("Armor") then
		return ("jink:jihun[%s:%s]=%d"):format(suit, number, card_id)
	elseif card:isKindOf("DefensiveHorse") then
		return ("peach:jihun[%s:%s]=%d"):format(suit, number, card_id)
	elseif card:isKindOf("OffensiveHorse") then
		return ("nullification:jihun[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.shensunshangxiang_keep_value = 
{
    Weapon=5,
	Armor=5.6,
	OffensiveHorse=5.4,
	DefensiveHorse=6.4,
}

sgs.ai_skill_cardask["@xunzhan"]=function(self,data)
	local use=data:toCardUse()
	local cards={}
	for _,card in sgs.qlist(self.player:getHandcards()) do
		if card:isKindOf("BasicCard") then
			table.insert(cards,card)
		end
	end
	self:sortByKeepValue(cards)
	basiccard=cards[1]
	if self:isFriend(use.from) then return basiccard:toString() end
	for _,p in sgs.qlist(self.room:getOtherPlayers(use.from)) do
		if not self:isFriend(use.from,p) and use.from:canSlash(p) then 
			return "."
		end
	end
	return basiccard:toString()
end

sgs.ai_skill_choice.xunzhan=function(self,choices)
	local ssx=self.room:findPlayerBySkillName("xunzhan")
	local enemies={}
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isFriend(p) and self.player:canSlash(p) and self:isEnemy(ssx) then return "draw" end
		if self:isEnemy(p) and self.player:canSlash(p) then table.insert(enemies,p) end
	end
	if #enemies>0 then return "slash" end
end

sgs.ai_skill_playerchosen.xunzhan=function(self,targets)
	for _,p in sgs.qlist(targets) do
		if self:isEnemy(p) and self:damageIsEffective(p) then
			return p
		end
	end
	return targets:first()
end

sgs.ai_skill_choice.ronggui=function(self,choices)
	local ssx=self.room:findPlayerBySkillName("xunzhan")
	if self:isFriend(ssx) or not ssx:isWounded() then return "recover" end
	if self.player:getHp()>2 then return "lose" else return "recover" end
end

function sgs.ai_armor_value.daogu(card)
	if not card then return 4 end
end