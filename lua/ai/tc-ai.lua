function SmartAI:immunityRecover(player)
	local player=player or self.player
	if player:getMark("@wheel")>0 then return true end
	if player:hasSkill("saiganran") then return true end
	if player:getLostHp()<=player:getMark("@broken") then return true end
	return false
end

function SmartAI:damageIsEffective(target,nature,player,card,basicdamage)
	target=target or self.player
	player=player or self.player
	nature=nature or sgs.DamageStruct_Normal
	-- if self:hasSkills("immortal|death",target) then return false end
	if player:hasSkill("jueqing") then return true end
	
	local jinxuandi = self.room:findPlayerBySkillName("wuling")
	if jinxuandi and jinxuandi:getMark("@fire") > 0 then nature = sgs.DamageStruct_Fire end
	
	if target:getMark("@fenyong")>0 then return false end
	
	if player:hasSkill("rexue") and nature~=sgs.DamageStruct_Fire then
		nature=sgs.DamageStruct_Fire
	end
	
	if player:hasSkill("chiyan") and nature==sgs.DamageStruct_Normal then
		nature=sgs.DamageStruct_Fire
	end	
	
	if (self:hasSkills("tianshi|lingti|dianxing",player) or player:hasFlag("juesi")) and nature~=sgs.DamageStruct_Thunder then
		nature=sgs.DamageStruct_Thunder
	end	
	
	if target:hasSkill("wuzhi") and target:getMark("@gale")==0 and nature~=sgs.DamageStruct_Normal then
		nature=sgs.DamageStruct_Normal
	end	
	
	if target:getMark("@gale")>0 and nature==sgs.DamageStruct_Normal then
		nature=sgs.DamageStruct_Fire
	end
	
	if target:hasSkill("chiyan") and nature==sgs.DamageStruct_Fire then
		return false
	end
	
	if target:hasSkill("daogu") and not target:getArmor() and nature~=sgs.DamageStruct_Normal then
		return false
	end	
	
	if target:hasSkill("shenjun") and target:getGender() ~= player:getGender() and nature ~= sgs.DamageStruct_Thunder then
		return false
	end

	if target:hasSkill("lingti") and nature==sgs.DamageStruct_Normal then
		return false
	end

	if target:getMark("@kekkai")+player:getMark("@kekkai")==1 and nature==sgs.DamageStruct_Normal then
		return false
	end
	
	if target:getMark("@dreamland")>0 or player:getMark("@dreamland")>0 then return false end
	
	if target:hasSkill("shengnv") and player:distanceTo(target)>1 then 
		return false
	end

	if target:hasSkill("tianshi") and nature == sgs.DamageStruct_Thunder then 
		return false
	end
	
	if target:getMark("@soul")>0 then return false end
	
	if target:getMark("@fog") > 0 and nature ~= sgs.DamageStruct_Thunder then
		return false
	end
	
	if player:hasSkill("ayshuiyong") and nature == sgs.DamageStruct_Fire then
		return false
	end

	local damage=basicdamage or 1
	if self:hasSkills("canbao|tianshi",player) then damage=damage+1 end
	if player:hasFlag("juesi") then damage=damage+1 end
	if player:hasSkill("relian") and not player:isWounded() then damage=damage+1 end
	if player:hasFlag("@rage") and splayer:isWounded() then damage=damage+1 end
	if player:hasSkill("mowang") and target:isNude() then damage=damage+1 end
	if nature==sgs.DamageStruct_Fire and target:getArmor() and target:getArmor():getClassName()=="Vine" then damage=damage+1 end	
	if player:hasSkill("lingti") and target:isChained() then damage=damage+1 end
	if target:hasSkill("shenge") then damage=basicdamage or 1 end
	if target:hasSkill("canbao") then damage=damage+1 end
	if nature~=sgs.DamageStruct_Thunder and target:getMark("@gale")>0 then damage=damage+1 end
	if card then
		if card:isKindOf("Slash") then
			if player:hasSkill("haoyin") or player:hasFlag("drank") then damage=damage+1 end
			if player:getWeapon() and player:getWeapon():getClassName()=="GudingBlade" and target:isKongcheng() then damage=damage+1 end
			if player:hasSkill("jie") and card:isRed() then damage=damage+1 end
		end	
		if player:hasFlag("luoyi") and (card:isKindOf("Slash") or card:isKindOf("Duel")) then damage=damage+1 end
	end
	if (player:hasSkill("fei") or target:hasSkill("fei"))and player:objectName()~=target:objectName() then damage=damage+1-player:distanceTo(target) end
	if player:hasSkill("tcfengyin") and not self:hasSkills("shenge|tianzhen",target) and not player:isNude() then return damage>0 end
	if self:hasSkills("shenge|tianshi",target) then damage=damage-1 end
	if self:hasSkills("shenge|tianshi|bumie|mengwu",target) and damage>1 then damage=1 end
	if target:hasSkill("jiaoxiu") and target:getMark("jiaoxiu")==0 then damage=math.min(damage,target:getHp()-1) end
	if target:getMark("@fog") and nature==sgs.DamageStruct_Thunder and damage>1 then damage=1 end
	if target:getArmor() and target:getArmor():getClassName()=="SilverLion" and damage>1 then damage=1 end
	return damage>0
end

function SmartAI:skipJudge(player,card)
	local player=player or self.player
	if self:hasSkills("zhai|xiongbao|shengnv|kanchuan|houjue|tianyun|liushui|tianzhen|tianran",player) then return true end
	if player:getMark("@dreamland")>0 or player:getMark("@soul")>0 then return true end
	if player:containsTrick("YanxiaoCard") then return true end
	if card then
		if player:hasSkill("rexue") and card:isKindOf("Indulgence") then return true end
	end	
	return false
end	

local yuhuo_skill={}
yuhuo_skill.name="yuhuo"
table.insert(sgs.ai_skills,yuhuo_skill)
yuhuo_skill.getTurnUseCard=function(self)
	if not self.player:hasFlag("yuhuoused") then
		return sgs.Card_Parse("#yuhuo_card:.:")
	end
end

sgs.ai_skill_use_func["#yuhuo_card"] = function(card, use, self)
	self:sort(self.enemies, "hp")
	if self.player:hasFlag("baozouused") then
		local enemies={}
		for _, enemy in ipairs(self.enemies) do
			if not self:cantbeHurt(enemy) and self:damageIsEffective(enemy,sgs.DamageStruct_Fire) then
				if #enemies<3 then table.insert(enemies,enemy) end
			end
		end
		if #enemies>0 then
			use.card=sgs.Card_Parse("#yuhuo_card:.:")
			for i=1,3,1 do 
				if enemies[i] and use.to then use.to:append(enemies[i]) end
			end	
			return
		end
	end
	if self.player:getHp()>2 then
		for _, enemy in ipairs(self.enemies) do
			if not self:cantbeHurt(enemy) and self:damageIsEffective(enemy,sgs.DamageStruct_Fire) and self.player:inMyAttackRange(enemy) then
				if self.player:getHp() > enemy:getHp() then
					use.card = sgs.Card_Parse("#yuhuo_card:.:")
					if use.to then
						use.to:append(enemy)
					end
					return
				end
			end
		end
	else
		local enemies={}
		for _, enemy in ipairs(self.enemies) do
			if not self:cantbeHurt(enemy) and self:damageIsEffective(enemy,sgs.DamageStruct_Fire,self.player) and self.player:inMyAttackRange(enemy) and (self.player:getHp()>1 or self.player:hasSkill("rexue"))then
				if #enemies<2 then table.insert(enemies,enemy) end
			end
		end
		if #enemies>0 then
			use.card=sgs.Card_Parse("#yuhuo_card:.:")
			for i=1,2,1 do 
				if enemies[i] and use.to then use.to:append(enemies[i]) end 
			end
			return
		end	
	end	
end

local baozou_skill={}
baozou_skill.name="baozou"
table.insert(sgs.ai_skills,baozou_skill)
baozou_skill.getTurnUseCard=function(self)
	if self.player:getMark("@baozou")>1 and not self.player:hasFlag("baozouused") then
		return sgs.Card_Parse("#baozou_card:.:")
	end
end

sgs.ai_skill_use_func["#baozou_card"]=function(card,use,self)
	if self.player:getHp()<3 and (self:getCardsNum("slash")>0 or not self.player:hasFlag("yuhuoused"))then use.card = sgs.Card_Parse("#baozou_card:.:") end
	return
end

sgs.ai_card_intention.yuhuo_card = 80
sgs.ai_use_priority.yuhuo_card = 6
sgs.ai_use_priority.baozou_card = 10

sgs.ai_skill_invoke.youhun = function(self, data)
    return true
end

sgs.ai_skill_invoke.xiongbao = function(self, data)
    return true
end

sgs.ai_cardsview.renxing=function(class_name,player)
	if class_name=="Peach" or class_name=="Nullification" then
		if not player:getPile("renxing"):isEmpty() then
			for _,id in sgs.qlist(player:getPile("renxing")) do
				local card=sgs.Sanguosha:getCard(id)
				if card:isKindOf(class_name) then return (card:objectName()..":renxing[%s:%s]=%d"):format(card:getSuitString(),card:getNumberString(),card:getEffectiveId()) end
			end
		end
	end
end

local renxing_skill={}
renxing_skill.name="renxing"
table.insert(sgs.ai_skills,renxing_skill)
renxing_skill.getTurnUseCard=function(self)
	if not self.player:getPile("renxing"):isEmpty() then
		for _,id in sgs.qlist(self.player:getPile("renxing"))do
			local card=sgs.Sanguosha:getCard(id)
			local dummyuse= {isDummy = true}
			self:useCardByClassName(card,dummyuse)
			if dummyuse.card then
				return sgs.Card_Parse((card:objectName()..":renxing[%s:%s]=%d"):format(card:getSuitString(),card:getNumberString(),card:getEffectiveId()))
			end
		end	
	end
end

sgs.ai_skill_use["@@mengwu"]=function(self,prompt)
	if not self.player:hasFlag("mengwuhp") then
		local n=self.player:getHandcardNum()/2
		local cards=self.player:getHandcards()
		cards=sgs.QList2Table(cards)
		self:sortByUseValue(cards)
		local discards={}
		for _,card in ipairs(cards) do
			if #discards<n then table.insert(discards,card) else break end
		end
		local card_str="#mengwu_card:"
		for var,card in ipairs(discards) do
			if var~=#discards then card_str=card_str..card:getId().."+" else card_str=card_str..card:getId() end
		end
		local targets={}
		if self.player:getMark("chengzhang")==0 then
			local x=100
			for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if p:getHandcardNum()<x then x=p:getHandcardNum() end
			end		
			for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if p:getHandcardNum()==x then table.insert(targets,p) end
			end
		else
			for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				table.insert(targets,p)
			end
		end	
		self:sort(targets)
		local target
		for _,t in ipairs(targets) do
			if self:isFriend(t) then target=t end
		end
		if target then
			card_str=card_str..":->"..target:objectName()
		else
			card_str=card_str..":->."
		end	
		return card_str
	else
		local x=self.player:getMark("mengwu")
		local targets={}
		for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if self.player:distanceTo(p)<=1 and not self:isFriend(p) and #targets<x then
				table.insert(targets,p)
			end
		end
		local card_str="#mengwu_hp_card:.:->"
		if #targets>0 then
			for var,target in ipairs(targets) do
				if var~=#targets then card_str=card_str..target:objectName().."+" else card_str=card_str..target:objectName() end
			end
		else
			card_str=card_str.."."
		end	
		return card_str
	end	
end

local zuiqiang_skill={}
zuiqiang_skill.name="zuiqiang"
table.insert(sgs.ai_skills,zuiqiang_skill)
zuiqiang_skill.getTurnUseCard=function(self)
	local cards = self.player:getCards("he")
	cards=sgs.QList2Table(cards)

	self:sortByKeepValue(cards)
	local basic_card
	local trick_card


	for _,card in ipairs(cards)  do
		if card:isKindOf("TrickCard") then
			trick_card = card
			break
		elseif card:isKindOf("BasicCard") then
			basic_card = card
			break
		end	
	end

	if trick_card then
		local suit = trick_card:getSuitString()
		local number = trick_card:getNumberString()
		local card_id = trick_card:getEffectiveId()
		local card_str = ("duel:zuiqiang[%s:%s]=%d"):format(suit, number, card_id)
		local duel = sgs.Card_Parse(card_str)

		assert(duel)

		return duel
	elseif basic_card then
		local suit = basic_card:getSuitString()
		local number = basic_card:getNumberString()
		local card_id = basic_card:getEffectiveId()
		local card_str = ("fire_slash:zuiqiang[%s:%s]=%d"):format(suit, number, card_id)
		local slash = sgs.Card_Parse(card_str)

		assert(slash)

		return slash
	end
end

sgs.ai_filterskill_filter.zuiqiang = function(card, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:isKindOf("BasicCard") then return ("fire_slash:zuiqiang[%s:%s]=%d"):format(suit, number, card_id)end
end 

sgs.ai_skill_choice.fu=function(self,choices,data)
	local damage=data:toDamage()
	if self:isFriend(damage.to) then return "black" end
	return "red"
end	

local xiexinskill={}
xiexinskill.name="xiexin"
table.insert(sgs.ai_skills,xiexinskill)
xiexinskill.getTurnUseCard=function(self)
	if not self.player:hasFlag("xiexinused") and self.player:getMark("@fu")>0 then
		return sgs.Card_Parse("#xiexin_card:.:")		
	end
end

sgs.ai_skill_use_func["#xiexin_card"]= function(card, use, self)
	self:sort(self.enemies,"defense")
	for _,enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() then
			use.card=sgs.Card_Parse("#xiexin_card:.:")
			if use.to then use.to:append(enemy) end
			return
		end	
	end	
end

sgs.ai_skill_invoke.nixi=function(self,data)
	local effect=data:toCardEffect()
	local slash=sgs.Sanguosha:cloneCard("fire_slash",sgs.Card_NoSuit,0)
	if self:isEnemy(effect.from) and self:slashIsEffective(slash,effect.from) and not(effect.card:isKindOf("AmazingGrace") or effect.card:isKindOf("GodSalvation")) then return true end
	return false
end	

sgs.ai_skill_cardask["@hougong-jink1"] = function(self, data, pattern, target)
    if sgs.ai_skill_cardask.nullfilter(self, data, pattern, target) then return "." end
    if self:getCardsNum("Jink") < 2 and not (self.player:getHandcardNum() == 1 and self:hasSkills(sgs.need_kongcheng)) then return "." end	
end

sgs.ai_skill_cardask["@hougong-heart-jink"] = function(self, data, pattern, target)
    if sgs.ai_skill_cardask.nullfilter(self, data, pattern, target) then return "." end
    if self:getCardsNum("Jink") < 2 and not (self.player:getHandcardNum() == 1 and self:hasSkills(sgs.need_kongcheng)) then return "." end	
end

sgs.ai_skill_cardask["@zuiqiangjink"] = function(self, data, pattern, target)
    if sgs.ai_skill_cardask.nullfilter(self, data, pattern, target) then return "." end
    if (self:getCardsNum("Slash") < 1 or self:getCardsNum("Jink") < 1) and not (self.player:getHandcardNum() == 1 and self:hasSkills(sgs.need_kongcheng)) then return "." end	
end

sgs.ai_skill_cardask["@zuiqiangslash"] = sgs.ai_skill_cardask["@wushuang-slash-1"]

local cardsamecolor=function(card1,card2)
	if card1:isRed() and card2:isRed() then return true end
	if card1:isBlack() and card2:isBlack() then return true end
	return false
end

sgs.ai_skill_cardask["#zhenyajink"]=function(self,data,pattern,target)
	if sgs.ai_skill_cardask.nullfilter(self, data, pattern, target) then return "." end
	if not self:damageIsEffective() then return "." end
	for _,card in ipairs(self:getCards("Jink")) do
		for _,cd in sgs.qlist(self.player:getCards("he")) do
			if card:getEffectiveId()~=cd:getEffectiveId() and cardsamecolor(card,cd) then
				return card:toString()
			end
		end
	end
	return "."
end	

sgs.ai_skill_cardask["#zhenyaslash"]=function(self,data,pattern,target)
	if sgs.ai_skill_cardask.nullfilter(self, data, pattern, target) then return "." end
	if not self:damageIsEffective() then return "." end
	for _,card in ipairs(self:getCards("Slash")) do
		for _,cd in sgs.qlist(self.player:getCards("he")) do
			if card:getEffectiveId()~=cd:getEffectiveId() and cardsamecolor(card,cd) then
				return card:toString()
			end
		end
	end
	return "."
end

sgs.ai_skill_cardask["#zhenyared"]=function(self,data,pattern,target)
	local cards=sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	for _,card in ipairs(cards) do
		if card:isRed() then
			return card:toString()
		end
	end
end

sgs.ai_skill_cardask["#zhenyablack"]=function(self,data,pattern,target)
	local cards=sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	for _,card in ipairs(cards) do
		if card:isBlack() then
			return card:toString()
		end
	end
end

sgs.ai_skill_invoke.shishi=function(self,data)
	local effect=data:toCardEffect()
	if effect.card:isKindOf("IronChain") or effect.card:isKindOf("AmazingGrace") or effect.card:isKindOf("GodSalvation") or effect.card:isKindOf("Ex_nihilo") then return false end
	if self:isFriend(effect.from) then return false end
	local value=sgs.QVariant()
	value:setValue(effect.card)
	self.room:setTag("shishicard",value)
	if effect.card:isKindOf("Snatch") or effect.card:isKindOf("Dismantlement") then
		self:sort(self.enemies,"handcard")
		for _,enemy in ipairs(self.enemies) do
			if not enemy:isNude() and self:hasTrickEffective(effect.card,enemy) then
				return true
			end
		end
	end
	if effect.card:isKindOf("SavageAssault") or effect.card:isKindOf("ArcheryAttack") then
		self:sort(self.enemies,"defense")
		for _,enemy in ipairs(self.enemies) do
			if self:aoeIsEffective(effect.card,enemy) and self:hasTrickEffective(effect.card,enemy) and self:damageIsEffective(enemy) and not self:cantbeHurt(enemy) then
				return true
			end
		end
	end
	if effect.card:isKindOf("Collateral") then
		self:sort(self.enemies,"defense")
		for _,enemy in ipairs(self.enemies) do
			if enemy:getWeapon() and self:hasTrickEffective(effect.card,enemy) then
				return true
			end
		end
	end
	if effect.card:isKindOf("FireAttack") then
		self:sort(self.enemies,"defense")
		for _,enemy in ipairs(self.enemies)  do
			if not enemy:isKongcheng() and self:hasTrickEffective(effect.card,enemy) and self:damageIsEffective(enemy,sgs.DamageStruct_Fire) and not self:cantbeHurt(enemy)then
				return true
			end
		end
	end
	if effect.card:isKindOf("Duel") then
	self:sort(self.enemies,"defense")
		for _,enemy in ipairs(self.enemies) do
			if self:hasTrickEffective(effect.card,enemy) and self:damageIsEffective(enemy) and not self:cantbeHurt(enemy) then
				return true
			end
		end
	end
	self.room:removeTag("shishicard")
	return false
end

sgs.ai_skill_use["@@shishi"]=function(self,prompt)
	local cards=self.player:getCards("he")
	cards=sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	card=cards[1]
	local shishicard=self.room:getTag("shishicard"):toCard()
	self.room:removeTag("shishicard")
	if shishicard:isKindOf("Snatch") or shishicard:isKindOf("Dismantlement") then
		self:sort(self.enemies,"handcard")
		for _,enemy in ipairs(self.enemies) do
			if not enemy:isNude() and self:hasTrickEffective(shishicard,enemy) and enemy:hasFlag("shishiable")then
				return "#shishi_card:"..card:getId()..":->"..enemy:objectName()
			end
		end
	elseif shishicard:isKindOf("FireAttack") then
		self:sort(self.enemies,"defense")
		for _,enemy in ipairs(self.enemies) do
			if not enemy:isKongcheng() and self:hasTrickEffective(shishicard,enemy) and enemy:hasFlag("shishiable") then
				return "#shishi_card:"..card:getId()..":->"..enemy:objectName()
			end
		end
	elseif shishicard:isKindOf("Collateral") then
		self:sort(self.enemies)
		for _,enemy in ipairs(self.enemies) do
			if enemy:getWeapon() and self:hasTrickEffective(shishicard,enemy) and enemy:hasFlag("shishiable")then
				return "#shishi_card:"..card:getId()..":->"..enemy:objectName()
			end
		end
	elseif shishicard:isKindOf("SavageAssault") or shishicard:isKindOf("ArcheryAttack") then
		self:sort(self.enemies,"defense")
		for _,enemy in ipairs(self.enemies) do
			if self:aoeIsEffective(shishicard,enemy) and self:hasTrickEffective(shishicard,enemy) and self:damageIsEffective(enemy) and not self:cantbeHurt(enemy) and enemy:hasFlag("shishiable")then
				return "#shishi_card:"..card:getId()..":->"..enemy:objectName()
			end
		end
	elseif shishicard:isKindOf("Duel") then
		self:sort(self.enemies,"defense")
		for _,enemy in ipairs(self.enemies) do
			if self:hasTrickEffective(shishicard,enemy) and self:damageIsEffective(enemy) and not self:cantbeHurt(enemy) and enemy:hasFlag("shishiable")then
				return "#shishi_card:"..card:getId()..":->"..enemy:objectName()
			end
		end
	end
	return "."
end

sgs.ai_skill_use["@@tianxie"]=function(self,prompt)
	assert(prompt~="#tianxieaskd")
	local cards=self.player:getCards("he")
	cards=sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	card=cards[1]
	if prompt=="#tianxieask1" then
		self:sort(self.friends_noself)
		for _,friend in ipairs(self.friends_noself) do
			if self:hasSkills("luoshen|xiongbao",friend) then
				return "#tianxieplayer_card:"..card:getId()..":->"..friend:objectName()
			end
		end
	end
	if prompt=="#tianxieask2" then
		self:sort(self.friends_noself)
		for _,friend in ipairs(self.friends_noself) do
			if (friend:containsTrick("indulgence") or friend:containsTrick("supply_shortage")) and not self:hasSkills("zhai|kanchuan|xiongbao|houjue|tianxie|shengnv",friend) then
				return "#tianxieplayer_card:"..card:getId()..":->"..friend:objectName()
			end
		end
		if (self.player:containsTrick("indulgence") or self.player:containsTrick("supply_shortage")) then
			return "#tianxieplayer_card:"..card:getId()..":->"..self.player:objectName()
		end
	end
	if prompt=="#tianxieask3" then
		self:sort(self.friends_noself)
		for _,friend in ipairs(self.friends_noself) do
			if self:hasSkills("hougong|haoshi|tuxi|qiaobian|yongsi|yingzi|jijiu|rende|huiguang",friend) or friend:getHandcardNum()<2 then
				return "#tianxieplayer_card:"..card:getId()..":->"..friend:objectName()
			end
		end
	end
	if prompt=="#tianxieask4" then
		self:sort(self.friends_noself)
		for _,friend in ipairs(self.friends_noself) do
			if friend:getHandcardNum()>5 or self:hasSkills("zhiheng|rende|lijian|tianwu",friend) then
				return "#tianxieplayer_card:"..card:getId()..":->"..friend:objectName()
			end
		end
		if self.player:getLostHp()>1 and self.player:getHandcardNum()<5 then
			return "#tianxieplayer_card:"..card:getId()..":->."
		end	
	end
	if prompt=="#tianxieask5" then
		self:sort(self.enemies,"handcard",true)
		for _,enemy in ipairs(self.enemies) do
			if ((enemy:hasSkill("yongsi") and enemy:getCards("he"):length()>1) or enemy:getHandcardNum()-enemy:getMaxCards()>1 or (enemy:getHandcardNum()-enemy:getMaxCards()>0 and self.player:getHandcardNum()-self.player:getMaxCards()>0))and not self:hasSkills("zhai|keji|qiaobian",enemy) then
				return "#tianxieplayer_card:"..card:getId()..":->"..enemy:objectName()
			end
		end
		if self.player:getHandcardNum()-self.player:getMaxCards()>1 then
			return "#tianxieplayer_card:"..card:getId()..":->."
		end	
	end
	if prompt=="#tianxieask6" then
		self:sort(self.enemies,"handcard",true)
		for _,enemy in ipairs(self.enemies) do
			if self:hasSkills("benghuai|jiangsi",enemy) then
				return "#tianxieplayer_card:"..card:getId()..":->"..enemy:objectName()
			end
		end
		self:sort(self.friends_noself)
		for _,friend in ipairs(self.friends_noself) do
			if self:hasSkills("biyue|spbiyue|shenge",friend) or (self:hasSkills("jushou|neojushou|kuiwei",friend) and not friend:faceUp()) or (friend:hasSkill("buji") and friend:getHandcardNum()<friend:getMaxHp()) or (friend:hasSkill("mihuan") and friend:getMark("@fantasy")>0) then
				return "#tianxieplayer_card:"..card:getId()..":->"..friend:objectName()
			end
		end
	end
	return "."
end


local moxingtrick={"collateral","ex_nihilo","duel","snatch","dismantlement","amazing_grace","savage_assault","archery_attack","god_salvation","fire_attack","iron_chain"}
local moxing_skill={}
moxing_skill.name="moxing"
table.insert(sgs.ai_skills,moxing_skill)
moxing_skill.getTurnUseCard=function(self)
	local cards={}
	for _,card in sgs.qlist(self.player:getCards("he")) do
		if card:isKindOf("BasicCard") or card:isKindOf("EquipCard") then table.insert(cards,card) end
	end
	if #cards==0 then return end
	self:sortByKeepValue(cards)
	local card=cards[1]
	if self.player:getMark("@charm")>0 and not self.player:isNude() then
		for _,pattern in ipairs(moxingtrick) do
			local acard=sgs.Sanguosha:cloneCard(pattern,card:getSuit(),card:getNumber())
			local dummyuse={isDummy=true}
			self:useCardByClassName(acard,dummyuse)
			if not self.player:hasFlag(pattern) and not self.player:isCardLimited(acard,sgs.Card_MethodUse) and dummyuse.card then
				return sgs.Card_Parse((pattern..":moxing[%s:%s]=%d"):format(card:getSuitString(),card:getNumberString(),card:getEffectiveId()))
			end
		end
	end	
end

sgs.ai_use_priority.moxing_card = 10

sgs.ai_skill_invoke.fuhei=function(self,data)
	local judge=data:toJudge()
	if judge:isGood() and self:isEnemy(judge.who) then return true end
	if judge:isBad() and self:isFriend(judge.who) then return true end
	return false
end

sgs.ai_skill_invoke.douzhi=sgs.ai_skill_invoke.fuhei

sgs.ai_skill_choice.xiling=function(self,choices,data)
	local judge=data:toJudge()
	if judge:isGood() and self:isEnemy(judge.who) then return "change" end
	if judge:isBad() and self:isFriend(judge.who) then return  "change" end
	return "notchange"
end 

sgs.ai_skill_cardchosen.xiling=function(self, who, flags)
	local cards=sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	return cards[1]:getEffectiveId()
end

sgs.ai_skill_invoke.ruoqi=function(self,data)
	local damage=data:toDamage()
	if damage.from and self:isEnemy(damage.from) and not damage.from:isNude() then sgs.ai_skill_choice.ruoqi="laiyuan" else sgs.ai_skill_choice.ruoqi="paidui" end
	return true
end

sgs.ai_skill_invoke.bobao=function(self,data)
	return true
end	

sgs.ai_skill_use["@@bobao"]=function(self,prompt)
	local cards=self.player:getHandcards()
	cards=sgs.QList2Table(cards)
	self:sortByUsePriority(cards,true)
	local use_card
	local bobaocard=sgs.Sanguosha:getCard(self.player:getPile("bobao"):first())
	local v=0
	if bobaocard then v=self:getUsePriority(bobaocard) end
	for _,card in ipairs(cards) do
		if card:isKindOf("BasicCard") or card:isNDTrick() and self:getUseValue(card)>=v then 
			use_card=card
			break
		end
	end
	if use_card then return "#bobao_card:"..use_card:getId()..":->." end
	return "."
end

function sgs.ai_skill_suit.bobao(self)
	local spade=0
	local heart=0
	local club=0
	local diamond=0
	for _,card in sgs.qlist(self.player:getCards("he")) do
		if card:getSuit()==sgs.Card_Heart then heart=heart+1
		elseif card:getSuit()==sgs.Card_Diamond then diamond=diamond+1
		elseif card:getSuit()==sgs.Card_Club then club=club+1
		else spade=spade+1 end
	end
	maxsuit=sgs.Card_Heart
	maxnumber=heart
	if math.max(maxnumber,spade)==spade then maxsuit=sgs.Card_Spade maxnumber=spade end
	if math.max(maxnumber,club)==club then maxsuit=sgs.Card_Club maxnumber=club end
	if math.max(maxnumber,diamond)==club then maxsuit=sgs.Card_Diamond maxnumber=diamond end
	return maxsuit
end

function getbobaosuit(player)
	if player:getMark("bobao")>0 then
		if player:getMark("@heart")>0 then return sgs.Card_Heart
		elseif player:getMark("@club")>0 then return sgs.Card_Club
		elseif player:getMark("@spade")>0 then return sgs.Card_Spade
		elseif player:getMark("@diamond")>0 then return sgs.Card_Diamond end
	end
	return sgs.Card_NoSuit
end

function getbobaopattern(player)
	if not player:getPile("bobao"):isEmpty() then
		local card=sgs.Sanguosha:getCard(player:getPile("bobao"):first())
		return card:objectName()
	end	
end		

local bobao_skill={}
bobao_skill.name="bobao"
table.insert(sgs.ai_skills,bobao_skill)
bobao_skill.getTurnUseCard=function(self,inclusive)
	local cards=self.player:getCards("he")
	cards=sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local suitcard
	for _,card in ipairs(cards) do
		if card:getSuit()==getbobaosuit(self.player) then
			suitcard=card
			break
		end
	end
	if suitcard then
		local suit = suitcard:getSuitString()
		local number = suitcard:getNumberString()
		local card_id = suitcard:getEffectiveId()
		local card_str = (getbobaopattern(self.player)..":bobao[%s:%s]=%d"):format(suit, number, card_id)
		local bobaocard = sgs.Card_Parse(card_str)
		
		assert(bobaocard)
		
		return bobaocard
	end	
end

sgs.ai_view_as.bobao = function(card, player, card_place)
    local suit = card:getSuitString()
    local number = card:getNumberString()
    local card_id = card:getEffectiveId()
    if card:getSuit()==getbobaosuit(player) then
        return (getbobaopattern(player)..":bobao[%s:%s]=%d"):format(suit, number, card_id)
    end
end

sgs.ai_use_priority.bobao_card=7

sgs.ai_skill_invoke.jiedi=function(self,data)
	local damage=data:toDamage()
	if damage and self:isFriend(damage.to) then return false end
	return true
end

sgs.ai_skill_askforag.jiedi=function(self,card_ids)
	local cards={}
	for _,id in ipairs(card_ids) do
		table.insert(cards,sgs.Sanguosha:getCard(id))
	end
	self:sortByKeepValue(cards)
	for _,card in ipairs(cards) do
		if card:getSuit()==getbobaosuit(self.player) then
			return card:getEffectiveId()
		end
	end
	return cards[#cards]:getEffectiveId()
end

local guwen_skill={}
guwen_skill.name="guwen"
table.insert(sgs.ai_skills,guwen_skill)
guwen_skill.getTurnUseCard=function(self,inclusive)
	if not self.player:hasFlag("guwenused") then
		return sgs.Card_Parse("#guwen_card:.:")
	end
end

sgs.ai_skill_use_func["#guwen_card"]=function(card, use, self)
	self:sort(self.enemies,"handcard",true)
	for _,enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() or (not self:needKongcheng(enemy) and enemy:getHandcardNum()<=self.player:getLostHp()) then
			use.card=sgs.Card_Parse("#guwen_card:.:")
			if use.to then use.to:append(enemy) end
			return
		end
	end
	return
end

sgs.ai_card_intention.guwen_card=100
sgs.ai_use_priority.guwen_card=10

sgs.ai_skill_invoke.zhancao=function(self,data)
	local damage=data:toDamage()
	if damage.to and self:isEnemy(damage.to) and self:getCardsNum("Slash")>0 then return true end
	if not damage.to and self:getOverflow()>0 then return true end
end	

local yazhi_skill={}
yazhi_skill.name="yazhi"
table.insert(sgs.ai_skills,yazhi_skill)
yazhi_skill.getTurnUseCard=function(self,inclusive)
	if not self.player:hasFlag("yazhiused") then
		return sgs.Card_Parse("#yazhi_card:.:")
	end
end

sgs.ai_skill_use_func["#yazhi_card"]=function(card, use, self)
	local cards={}
	for _,card in sgs.qlist(self.player:getHandcards()) do
		if card:isBlack() then table.insert(cards,card) end
	end
	self:sortByKeepValue(cards)
	self:sort(self.friends_noself)
	local target
	for _, friend in ipairs(self.friends_noself) do
		if friend:faceUp() and friend:hasSkill("kanchuan") or friend:hasSkill("tianzhen") then
			target = friend
			break
		end
		if friend:faceUp() and self.player:getHp() > 1 and friend:hasSkill("jijiu") then
			target = friend
			break
		end
		if friend:faceUp() and (friend:hasSkill("jushou") or friend:hasSkill("kuiwei")) and friend:getPhase() == sgs.Player_Play then
			target = friend
			break
		end
	end
	if not target then
		local x = self.player:getHp()
		if x >= 3 then
			for _,friend in ipairs(self.friend_noself) do
				if friend:faceUp() then
					target=friend
					break
				end
			end
		else
			self:sort(self.enemies)
			for _, enemy in ipairs(self.enemies) do
				if enemy:faceUp() and not (((enemy:hasSkill("jushou") or enemy:hasSkill("kuiwei")) and enemy:getPhase() == sgs.Player_Play) or enemy:hasSkill("jijiu") or enemy:hasSkill("huiguang") or enemy:hasSkill("kanchuan") or enemy:hasSkill("tianzhen")) then
					target = enemy
					break
				end
			end
		end
	end
	if self:getOverflow()>0 and target then
		use.card=sgs.Card_Parse("#yazhi_card:"..cards[1]:getEffectiveId()..":")
		if use.to then use.to:append(target) end
		return 
	end	
end

sgs.ai_use_priority.yazhi_card=3

sgs.ai_skill_invoke.yazhi=true

sgs.ai_skill_use["@@yazhi"]=function(self, prompt)
	self:sort(self.friends_noself)
	local target
	for _, friend in ipairs(self.friends_noself) do
		if friend:faceUp() and friend:hasSkill("kanchuan") or friend:hasSkill("tianzhen") then
			target = friend
			break
		end
		if friend:faceUp() and self.player:getHp() > 1 and friend:hasSkill("jijiu") and friend:hasSkill("huiguang") then
			target = friend
			break
		end
		if friend:faceUp() and (friend:hasSkill("jushou") or friend:hasSkill("kuiwei")) and friend:getPhase() == sgs.Player_Play then
			target = friend
			break
		end
	end
	if not target then
		local x = self.player:getHp()
		if x >= 3 then
			for _,friend in ipairs(self.friends_noself) do
				if friend:faceUp() then
					target = self.friend
					break
				end
			end
		else
			self:sort(self.enemies)
			for _, enemy in ipairs(self.enemies) do
				if enemy:faceUp() and not (((enemy:hasSkill("jushou") or enemy:hasSkill("kuiwei")) and enemy:getPhase() == sgs.Player_Play) or enemy:hasSkill("jijiu") or enemy:hasSkill("kanchuan") or enemy:hasSkill("tianzhen")) then
					target = enemy
					break
				end
			end
		end
	end

	if target then
		return "#yazhi_card:.:->" .. target:objectName()
	else
		return "."
	end
end

juesi_skill={}
juesi_skill.name="juesi"
table.insert(sgs.ai_skills,juesi_skill)
juesi_skill.getTurnUseCard=function(self,inclusive)
	if not self.player:hasFlag("juesi") then
		return sgs.Card_Parse("#juesi_card:.:")
	end
end

sgs.ai_skill_use_func["#juesi_card"]=function(card, use, self)
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	local slashtarget = 0
	local dueltarget = 0
	self:sort(self.enemies,"hp")
	for _,card in ipairs(cards) do
		if card:isKindOf("Slash") then
			for _,enemy in ipairs(self.enemies) do
				if self.player:canSlash(enemy, card, true) and self:slashIsEffective(card, enemy) and self:objectiveLevel(enemy) > 3 and sgs.isGoodTarget(enemy, self.enemies, self) then
					if getCardsNum("Jink", enemy) < 1 or (self:isEquip("Axe") and self.player:getCards("he"):length() > 4) then
						slashtarget = slashtarget + 1
					end
				end
			end
		end
		if card:isKindOf("Duel") then
			for _, enemy in ipairs(self.enemies) do
				if self:getCardsNum("Slash") >= getCardsNum("Slash", enemy) and sgs.isGoodTarget(enemy, self.enemies, self)
				and self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy)
				and self:damageIsEffective(enemy) and enemy:getMark("@late") < 1 then
					dueltarget = dueltarget + 1 
				end
			end
		end
	end		
	if (slashtarget+dueltarget) > 0 then
		return sgs.Card_Parse("#juesi_card:.:->.")
	end
end

sgs.ai_chaofeng.TCM01 = 6

sgs.ai_use_priority.juesi=10
sgs.ai_card_intention.juesi_card =80

local ganshe_skill={}
ganshe_skill.name="ganshe"
table.insert(sgs.ai_skills,ganshe_skill)
ganshe_skill.getTurnUseCard=function(self)
	if not self.player:hasFlag("ganshe_lost") then
		return sgs.Card_Parse("#ganshe_card:.:")
	end
end

sgs.ai_skill_use_func["#ganshe_card"] = function(card, use, self)
	local cards={}
	for _,card in sgs.qlist(self.player:getCards("he")) do
		if card:isKindOf("BasicCard") or card:isKindOf("Weapon") then
			table.insert(cards,card)
		end
	end
	self:sortByKeepValue(cards)
	local use_card=cards[1]
	self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if (enemy:isKongcheng() or enemy:isChained()) and self:damageIsEffective(enemy,sgs.DamageStruct_Thunder) then 
			use.card=sgs.Card_Parse("#ganshe_card:"..use_card:getId()..":")
			if use.to then use.to:append(enemy) end
			return 
		end
		if self.player:getHp()>1 and enemy:getHandcardNum()<=self.player:getHp()*2 and self:damageIsEffective(enemy,sgs.DamageStruct_Thunder) then 
			use.card=sgs.Card_Parse("#ganshe_card:"..use_card:getId()..":")
			if use.to then use.to:append(enemy) end	
			return
		end
	end
end
	
sgs.ai_card_intention.ganshe_card = 80
sgs.ai_use_priority.ganshe_card = 10	
	
sgs.ai_skill_invoke.fuyuan=function(self,data)
	for _,friend in ipairs(self.friends) do
		if friend:isWounded() and not self:immunityRecover(friend) then return true end
	end
end

sgs.ai_skill_playerchosen.fuyuan=function(self,targets)
	if self.player:getLostHp()>1 then
		return self.player
	end
	local choices = {}
	for _, target in sgs.qlist(targets) do
		if self:isFriend(target) and target:objectName()~=self.player:objectName() and not self:immunityRecover(target) then
			table.insert(choices, target)
		end
	end
	self:sort(choices, "hp")
	if #choices>0 then
		sgs.updateIntention(self.player,choices[1],-100)
		return choices[1]
	else
		return self.player
	end	
end	

local junheng_skill={}
junheng_skill.name="junheng"
table.insert(sgs.ai_skills,junheng_skill)
junheng_skill.getTurnUseCard=function(self)
	if not self.player:hasSkill("lingti") then
		return sgs.Card_Parse("#junheng_card:.:")
	end
end

function findenemy(self,friend)
	for _,enemy in ipairs(self.friends) do
		if friend:inMyAttackRange(enemy) then
			return true
		end
	end
	return false
end	

sgs.ai_skill_use_func["#junheng_card"]=function(card,use,self)
	local cards=self.player:getCards("he")
	cards=sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	card=cards[1]
	self:sort(self.friends)
	local minhp=self.player:getHp()
	local minfriend=self.player
	for _,friend in ipairs(self.friends) do
		if ((friend:getHp()<minhp and findenemy(self,friend)) or (friend:isLord() and  friend:isWounded()))  and not self:immunityRecover(friend) then 
			minhp=friend:getHp()
			minfriend=friend
		end
	end
	local targetenemy
	self:sort(self.enemies,"hp")
	for _,enemy in ipairs(self.enemies) do
		if enemy:getHp()>minhp and minfriend:inMyAttackRange(enemy) then 
			targetenemy=enemy
			break
		end
	end
	if targetenemy then
		use.card=sgs.Card_Parse("#junheng_card:"..card:getId()..":")
		if use.to then 
			use.to:append(minfriend)
			use.to:append(targetenemy)
		end
		return
	else
		self:sort(self.friends,"hp",true)
		local maxfriend
		for _,friend in ipairs(self.friends) do
			if friend:getHp()-minhp>2 and not friend:isLord() and minfriend:inMyAttackRange(friend) then
				maxfriend=friend
				break
			end
		end
		if maxfriend then
			use.card=sgs.Card_Parse("#junheng_card:"..card:getId()..":")
				if use.to then 
					use.to:append(minfriend)
					use.to:append(maxfriend)
				end
			return
		end
	end	
end

sgs.ai_skill_invoke.junheng=function(self,data)
	local dying=data:toDying()
	if self:immunityRecover(dying.who) then return false end
	if self:isFriend(dying.who) then
		self:sort(self.enemies,"hp")
		for _,enemy in ipairs(self.enemies) do
			if dying.who:inMyAttackRange(enemy) then
				sgs.ai_skill_playerchosen.junheng=enemy
				return true
			end
		end
	end
	return false
end

sgs.ai_use_priority.junheng_card = 10

local lingbao_skill={}
lingbao_skill.name="lingbao"
table.insert(sgs.ai_skills,lingbao_skill)
lingbao_skill.getTurnUseCard=function(self)
	if self.player:hasFlag("lingbaoused") or self.player:getPile("sprite"):length()>=4 then
		return sgs.Card_Parse("#lingbao_card:.:")
	end
end

sgs.ai_skill_use_func["#lingbao_card"] = function(card, use, self)
	if not self.player:hasFlag("lingbaoused") then
		local slashcount=self:getCardsNum("Slash")
		if slashcount>2 or self.player:getPile("sprite"):length()>=6 then
			self:sort(self.enemies,"defense")
			for _,enemy in ipairs(self.enemies) do
				local slash=sgs.Sanguosha:cloneCard("thunder_slash",sgs.Card_NoSuit,0)
				if self.player:canSlash(enemy,slash,false) and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy,sgs.DamageStruct_Thunder) then
					use.card=sgs.Card_Parse("#lingbao_card:.:")
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
	else
		local target
		for _,p in sgs.qlist(self.room:getAlivePlayers()) do
			if p:hasFlag("lingbaotarget") then target=p break end
		end
		if target then
			local slash=self:getCard("Slash")
			use.card=sgs.Card_Parse("#lingbao_card:"..slash:getId()..":")
			if use.to then use.to:append(target) end
			return
		end
	end				
end	

sgs.ai_skill_askforag.lingbao=function(self, card_ids)
	return card_ids[1]
end	

sgs.ai_card_intention.lingbao_card=100
sgs.ai_use_priority.lingbao_card = 7
	
local caoling_skill={}
caoling_skill.name="caoling"
table.insert(sgs.ai_skills,caoling_skill)
caoling_skill.getTurnUseCard=function(self)
	if self.player:getPile("sprite"):length()>=5 then
		return sgs.Card_Parse("#caoling_card:.:")
	end
end

sgs.ai_skill_use_func["#caoling_card"] = function(card, use, self)
	local sprite=self.player:getPile("sprite")
	local n=math.floor(sprite:length()/2)
	local redcards={}
	local blackcards={}
	for _,id in sgs.qlist(sprite) do
		local card=sgs.Sanguosha:getCard(id)
		if card:isRed() then table.insert(redcards,card) else table.insert(blackcards,card) end
	end
	self.room:setPlayerFlag(self.player,"-clblack")
	self.room:setPlayerFlag(self.player,"-clred")
	local targets={}
	if #redcards>=1 and #blackcards>=1 then
		self:sort(self.friends)
		for _,friend in ipairs(self.friends) do
			if not friend:hasFlag("caolingused") and friend:isWounded() and (friend:objectName()==self.player:objectName() or friend:getLostHp()>1 or friend:isLord()) and #targets<n then
				table.insert(targets,friend)
			end
		end
		if #targets>=1 then
			self.room:setPlayerFlag(self.player,"clblackred")
			use.card=sgs.Card_Parse("#caoling_card:.:")
			for i=1,#targets,1 do
				if use.to and targets[i] then use.to:append(targets[i]) sgs.updateIntention(self.player,targets[i],-80) end
			end	
			return
		end
	end
	if #redcards>=2 or #blackcards>=2 then
		if #redcards>#blackcards then
			self.room:setPlayerFlag(self.player,"clred")
			damagenature=sgs.DamageStruct_Fire
		else
			self.room:setPlayerFlag(self.player,"clblack")
			damagenature=sgs.DamageStruct_Thunder
		end	
		self:sort(self.enemies,"defense")
		for _,enemy in ipairs(self.enemies) do
			if not enemy:hasFlag("caolingused") and self:damageIsEffective(enemy,damagenature) and not self:cantbeHurt(enemy) and #targets<=n then
				table.insert(targets,enemy)
			end
		end
		if #targets>0 then
			use.card=sgs.Card_Parse("#caoling_card:.:")
			for i=1,#targets,1 do
				if use.to and targets[i] then use.to:append(targets[i]) sgs.updateIntention(self.player,targets[i],80) end
			end	
			return
		end
	end	
end	

sgs.ai_skill_askforag.caoling=function(self, card_ids)
	local redcards={}
	local blackcards={}
	for _,id in ipairs(card_ids) do
		local card=sgs.Sanguosha:getCard(id)
		if card:isRed() then table.insert(redcards,card) else table.insert(blackcards,card) end
	end
	if self.player:hasFlag("clblackred") then
		self.room:setPlayerFlag(self.player,"-clblackred")
		self.room:setPlayerFlag(self.player,"clblack")
		return redcards[1]:getEffectiveId()
	elseif self.player:hasFlag("clblack") then
		return blackcards[1]:getEffectiveId()
	else
		return redcards[1]:getEffectiveId()
	end	
end	
	
sgs.ai_use_priority.lingbao_card = 10
	
sgs.ai_skill_use["@@tongsi"]=function(self, prompt)
	self:sort(self.enemies)
	self:sort(self.friends_noself)
	local n=self.player:getLostHp()*2
	local targets={}
	for _,friend in ipairs(self.friends_noself) do
		if friend:isChained() and #targets<n then
			table.insert(targets,friend)
		end
	end
	if #targets==n then
		local targetsname = {}
		for i=1,#targets,1 do
			table.insert(targetsname, targets[i]:objectName())
		end
		local card_str="#tongsi_card:.:->"..table.concat(targetsname,"+")
		return card_str
	end
	if not self.player:hasSkill("jiangsi") and n>#targets and self.player:isChained() then table.insert(targets,self.player) end
	if self.player:hasSkill("jiangsi") and n-#targets>1 and not self.player:isChained() and #self.enemies>0 then table.insert(targets,self.player) end
	for _,enemy in ipairs(self.enemies) do
		if not enemy:isChained() and #targets<n then
			table.insert(targets,enemy)
		end
	end
	if #targets>0 then
		local targetsname = {}
		for i=1,#targets,1 do
			table.insert(targetsname, targets[i]:objectName())
		end
		local card_str="#tongsi_card:.:->"..table.concat(targetsname,"+")
		return card_str
	end
end	
			
	
local youren_skill={}
youren_skill.name="youren"
table.insert(sgs.ai_skills,youren_skill)
youren_skill.getTurnUseCard=function(self,inclusive)
	if self.player:canSlashWithoutCrossbow() or (self.player:getWeapon() and self.player:getWeapon():getClassName()=="Crossbow") then
		return sgs.Card_Parse("#youren_card:.:")
	end
end

sgs.ai_skill_use_func["#youren_card"]=function(card, use, self)
	local cards={}
	for _,card in sgs.qlist(self.player:getCards("he")) do
		if card:isKindOf("Slash") or card:isKindOf("EquipCard") then
			table.insert(cards,card)
		end
	end
	self:sortByKeepValue(cards)
	local use_card=cards[1]
	self:sort(self.enemies, "defense")
	local slash=sgs.Sanguosha:cloneCard("thunder_slash",use_card:getSuit(),use_card:getNumber())
	for _, enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy,slash,false) and self:damageIsEffective(enemy,sgs.DamageStruct_Thunder) then
			use.card=sgs.Card_Parse("#youren_card:"..use_card:getId()..":")
			if use.to then use.to:append(enemy) end
			return
		end
	end
end	

sgs.ai_use_priority.youren_card = 10

sgs.ai_skill_invoke.youren=function(self,data)
	local dying=data:toDying()
	return self:isEnemy(dying.who)
end	

sgs.ai_skill_use["@@zhidao"]=function(self,prompt)
	local current=self.room:getCurrent()
	local cards=self.player:getCards("h")
	cards=sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	card=cards[1]
	if self:isFriend(current) or (self.player:inMyAttackRange(current) and self.player:getHandcardNum()<4)then
		return "#zhidao_card:"..card:getId()..":->."
	end
	return "."
end

sgs.ai_skill_use["@@houjue"]=function(self,prompt)
	local targets={}
	self:sort(self.enemies)
	for _,enemy in ipairs(self.enemies) do
		if (not enemy:isNude()) and not (enemy:getEquips():isEmpty()  and enemy:getHandcardNum()==1 and not self:needKongcheng(enemy)) and self.player:inMyAttackRange(enemy) and not self:hasSkills("liushui|bizhan|shangshi|nosshangshi",enemy) and #targets<3-self.player:getHandcardNum() then
			table.insert(targets,enemy)
		end
	end
	if #targets==3-self.player:getHandcardNum() then
		local targetsname = {}
		for i=1,#targets,1 do
			table.insert(targetsname, targets[i]:objectName())
		end
		local card_str="#houjue_card:.:->"..table.concat(targetsname,"+")
		return card_str
	end	
	self:sort(self.friends_noself,"hp",true)
	for _,friend in ipairs(self.friends_noself) do
		if ((friend:isWounded() and friend:getArmor() and friend:getArmor():getClassName()=="SilverLion" and not self:hasSkills("longhun|duanliang|qixi|guidao|lijian|jujian",friend)) or self:hasSkills("liushui|bizhan|shangshi|nosshangshi",friend))and self.player:inMyAttackRange(friend) and not friend:isNude() and #targets<3-self.player:getHandcardNum() then
			table.insert(targets,friend) 
		end
	end
	if #targets>0 then
		local targetsname = {}
		for i=1,#targets,1 do
			table.insert(targetsname, targets[i]:objectName())
		end
		local card_str="#houjue_card:.:->"..table.concat(targetsname,"+")
		return card_str
	end
end

local tianran_skill={}
tianran_skill.name="tianran"
table.insert(sgs.ai_skills,tianran_skill)
tianran_skill.getTurnUseCard=function(self)
	local cards = self.player:getCards("he")
	cards=sgs.QList2Table(cards)

	local trick_card

	self:sortByUseValue(cards,true)

	for _,card in ipairs(cards)  do
		if card:isKindOf("TrickCard") then
			trick_card = card
			break
		end	
	end

	if trick_card then
		local suit = trick_card:getSuitString()
		local number = trick_card:getNumberString()
		local card_id = trick_card:getEffectiveId()
		local card_str = ("slash:tianran[%s:%s]=%d"):format(suit, number, card_id)
		local slash = sgs.Card_Parse(card_str)

		assert(slash)

		return slash
	end
end

sgs.ai_filterskill_filter.tianran = function(card, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:isKindOf("TrickCard") then return ("slash:tianran[%s:%s]=%d"):format(suit, number, card_id) end
end

sgs.ai_skill_cardask["@tianran-jink"]= function(self, data, pattern, target)
	if self:isFriend(target) and target:hasSkill("shane") and not self.player:hasSkill("leiji") then return "." end
	for _, card in ipairs(self:getCards("Jink")) do
		if card:getSuit() == sgs.Card_Heart then
			return card:toString()
		end
	end
	return "."
end

sgs.ai_filterskill_filter.tianzhen = function(card, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:isKindOf("TrickCard") then return ("nullification:tianzhen[%s:%s]=%d"):format(suit, number, card_id) end
end

sgs.ai_skill_invoke.shane = function(self, data)
	local damage=data:toDamage()
	if damage and self:isEnemy(damage.to) and not self.player:isNude() then 
		sgs.ai_skill_choice.shane="shanee"
		sgs.updateIntention(self.player,damage.to,100)		
		return true
	elseif damage and self:isFriend(damage.to) then
		sgs.ai_skill_choice.shane="shaneshan"
		sgs.updateIntention(self.player,damage.to,-100)			
		return true
	end
	local recover=data:toRecover()
	if recover and recover.who:objectName()==self.player:objectName() then
		local target
		for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if p:hasFlag("dying") then target=p break end
		end
		if target and self:isFriend(target) and self.player:getHp()>1 then
			sgs.ai_skill_choice.shane="shaneshan"
			sgs.updateIntention(self.player,target,-100)
			return true
		elseif target and self:isEnemy(target) then
			sgs.updateIntention(self.player,target,100)
			sgs.ai_skill_choice.shane="shanee"
			return true
		end
	end
	return false
end

function sgs.ai_cardsview.imouto(class_name, player)
	if class_name == "Peach" then
		if player:hasSkill("imouto") and player:faceUp() then
			return ("peach:imouto[no_suit:0]=.")
		end
	end
end

local imouto_skill={}
imouto_skill.name="imouto"
table.insert(sgs.ai_skills,imouto_skill)
imouto_skill.getTurnUseCard=function(self)
	if self.player:faceUp() then
		return sgs.Card_Parse("peach:imouto[no_suit:0]=.")
	end	
end

sgs.ai_skill_invoke.imouto=function(self, data)
	local effect=data:toCardEffect()
	if effect and effect.to then
		if self.player:getHp()<=1 and not self.player:isNude() then return true end
	end
	local damage=data:toDamage()
	if damage and damage.to:objectName()==self.player:objectName() then return not self.player:faceUp() end
	return damage and self.player:getCards("he"):length()>1
end

sgs.ai_skill_discard.imouto=function(self, discard_num, min_num, optional, include_equip)
	local to_discard={}
	local cards=sgs.QList2Table(self.player:getCards("he"))
	if #cards>=1 then
		self:sortByKeepValue(cards)
		table.insert(to_discard,cards[1]:getEffectiveId())
	end	
	return to_discard
end	

local paiji_skill={}
paiji_skill.name="paiji"
table.insert(sgs.ai_skills,paiji_skill)
paiji_skill.getTurnUseCard=function(self,inclusive)
    local cards = self.player:getCards("h")
    cards=sgs.QList2Table(cards)
    
    local paiji
    
    self:sortByUseValue(cards,true)
    
    for _,card in ipairs(cards) do
        if (card:getSuit()==sgs.Card_Spade or card:getSuit()==sgs.Card_Heart) and card:isNDTrick()
			then
            paiji = card
            break
        end
    end

    if paiji then		
        local suit = paiji:getSuitString()
        local number = paiji:getNumberString()
        local card_id = paiji:getEffectiveId()
        local card_str = ("lightning:paiji[%s:%s]=%d"):format(suit, number, card_id)
        local lightning = sgs.Card_Parse(card_str)
        
        assert(lightning)
        
        return lightning
    end
end

local caice_skill={}
caice_skill.name="caice"
table.insert(sgs.ai_skills,caice_skill)
caice_skill.getTurnUseCard=function(self,inclusive)
	if not self.player:hasFlag("caiceused") then
		return sgs.Card_Parse("#caice_card:.:")
	end
end

sgs.ai_skill_use_func["#caice_card"]=function(card, use, self)
	self:sort(self.enemies,"handcard")
	for _,enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() or (not self:needKongcheng(enemy) and enemy:getHandcardNum()==1) then
			use.card=sgs.Card_Parse("#caice_card:.:")
			if use.to then use.to:append(enemy) end
			local a=math.random(1,10)
			if a>5 then sgs.ai_skill_choice.caice="BasicCard" elseif a>2 then sgs.ai_skill_choice.caice="TrickCard" else sgs.ai_skill_choice.caice="EquipCard" end
			return
		end
	end
	return
end

function sgs.ai_skill_suit.caice()
    local map = {0, 0, 1, 2, 2, 3, 3, 3}
    return map[math.random(1,8)]
end

sgs.ai_card_intention.caice_card=60
sgs.ai_use_priority.caice_card = 8

sgs.ai_skill_cardask["@yujian"]=function(self, data)
	local judge = data:toJudge()

    if self:needRetrial(judge) then
        local cards = sgs.QList2Table(self.player:getCards("he"))
        local card_id = self:getRetrialCardId(cards, judge)
        local card = sgs.Sanguosha:getCard(card_id)
        if card_id ~= -1 then
            return card:toString()
        end
    end

    return "."
end

sgs.ai_skill_invoke.yujian=function(self,data)
	local mamoru=self.room:findPlayerBySkillName("yujian")
	return self:isFriend(mamoru)
end	

sgs.ai_skill_use["@@wukou"]=function(self,prompt)
	local target
	self:sort(self.friends)
	for _,friend in ipairs(self.friends) do
		if ((friend:containsTrick("indulgence") or friend:containsTrick("supply_shortage")) and not self:skipJudge(friend)) or (friend:isWounded() and friend:getArmor() and friend:getArmor():getClassName()=="SilverLion" and not self:hasSkills("longhun|duanliang|qixi|guidao|lijian|jujian",friend)) then
			target=friend
			break
		end	
	end
	if not target then
		self:sort(self.enemies)
		for _,enemy in ipairs(self.enemies) do
			if not enemy:isNude() and (not self:hasSkills("liushui|aojiao|jueqing",enemy) or not enemy:getEquips():isEmpty())then
				target=enemy
			end	
		end
	end
	if target then
		return "#wukou_card:.:->"..target:objectName()
	end
	return "."
end	

sgs.ai_skill_invoke.menghuan = function(self,data)
	local damage=data:toDamage()
	if (self:isFriend(damage.to) and self:getAllPeachNum()+self.player:getHp()>1 and self.player:getMark("@fantasy")>0) or self.player:objectName()==damage.to:objectName() then 
		self:sort(self.enemies,"handcard",true)
		self:sort(self.friends,"handcard",false)
		for _,enemy in ipairs(self.enemies) do
			if enemy:getOverflow()>1 then
				sgs.ai_skill_choice.menghuan="mhlihun"
				sgs.ai_skill_playerchosen.menghuan=enemy
				return true
			end
		end
		for _,friend in ipairs(self.friends) do
			if friend:getHp()-friend:getHandcardNum()>0 and self.player:getHandcardNum()>5 then
				sgs.ai_skill_choice.menghuan="mhlihun"
				sgs.ai_skill_playerchosen.menghuan=friend
				return true
			end
		end
		sgs.ai_skill_choice.menghuan="mhguixin"
	end
end	

local yuliao_skill={}
yuliao_skill.name="yuliao"
table.insert(sgs.ai_skills,yuliao_skill)
yuliao_skill.getTurnUseCard=function(self,inclusive)
	if not self.player:hasFlag("yuliaoused") then
		return sgs.Card_Parse("#yuliao_card:.:")
	end
end

sgs.ai_skill_use_func["#yuliao_card"]=function(card, use, self)
	local cards=self.player:getCards("he")
	cards=sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	card=cards[1]
	self:sort(self.friends,"defense")
	for _,friend in ipairs(self.friends) do
		use.card=sgs.Card_Parse("#yuliao_card:"..card:getId()..":")
		if use.to then use.to:append(friend) end
		break
	end
end

sgs.ai_skill_choice.yuliao=function(self,choices)
	if self.player:getLostHp()<=2 and not self.player:getJudgingArea():isEmpty() and not self:skipJudge() then return "recyclerjudge" end
	if self.player:getLostHp()<=2 and not self.player:faceUp() then return "ylturnover" end
	if self.player:getLostHp()<=2 and self:hasSkills(sgs.cardneed_skill) then return "draw" end
	if self.player:isWounded() and not self:immunityRecover() and not self:hasSkills("longhun|shangshi|nosshangshi|miji|zaiqi") then return "recoverhp" end
	return "draw"
end	

sgs.ai_skill_cardask["@huiguang"]=function(self,data,pattern,target)
	local dying=data:toDying()
	if not self:isFriend(dying.who) then return "." end
	if self:immunityRecover(target) then return "." end
	local cards=self.player:getCards("he")
	cards=sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	sgs.updateIntention(self.player,target,-100)
	return cards[1]:toString()
end

sgs.ai_skill_choice.buji=function(self,choices)
	local x=100
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:getHandcardNum()<x then x=p:getHandcardNum() end
	end
	local targets={}
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:getHandcardNum()==x then table.insert(targets,p) end
	end
	local target
	for _,t in ipairs(targets) do
		if self:isFriend(t) then target=t end
	end
	if target then
		return "zhuanjiao"
	end
	return "qizhi"
end

sgs.ai_skill_playerchosen.buji=function(self,targets)
	for _,p in sgs.list(targets) do
		if self:isFriend(p) then return p end
	end
end

sgs.ai_chaofeng.TCA02 = 6

sgs.ai_card_intention.yuliao_card=-100
sgs.ai_use_priority.yuliao_card = 10

sgs.ai_skill_invoke.lianxie=function(self,data)
	local pattern=data:toString()
	if pattern and pattern=="jink" then return sgs.ai_skill_invoke.hujia 
	elseif pattern and pattern=="slash" then 
		local cards = self.player:getHandcards()
		for _, card in sgs.qlist(cards) do
			if card:isKindOf("Slash") then
				return false
			end
		end
		return true
	end
	local damage=data:toDamage()
	if damage then
		local enemies={}
		local friends={}
		for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if p:hasSkill("lianxie") then
				if self:isEnemy(p) then table.insert(enemies,p) end
				if self:isFriend(p) then table.insert(friends,p) end
			end
		end
		if #friends>=#enemies then return true end
		return false
	end
	local tohelp=data:toPlayer()
	if tohelp then
		if self:isFriend(tohelp) then return true end
	end	
	return false
end

sgs.ai_skill_cardask["@lianxieslash"]=function(self,data,pattern,target)
	local meido=data:toPlayer()
    if not self:isFriend(meido) then return "." end
    if self:needBear() then return "." end
    return self:getCardId("Slash") or "."
end 

sgs.ai_skill_cardask["@lianxiejink"]=function(self,data,pattern,target)
	local meido=data:toPlayer()
    if not self:isFriend(meido) then return "." end
    if self:needBear() then return "." end
    return self:getCardId("Jink") or "." 
end

lianxie_skill={}
lianxie_skill.name="lianxie"
table.insert(sgs.ai_skills,lianxie_skill)
lianxie_skill.getTurnUseCard=function(self,inclusive)
	if self.player:canSlashWithoutCrossbow() or ((self.player:getWeapon()) and (self.player:getWeapon():getClassName()=="Crossbow")) then
		if not self.player:hasFlag("lianxieend") then return sgs.Card_Parse("#lianxie_card:.:") end
	end
end

sgs.ai_skill_use_func["#lianxie_card"]=function(card, use, self)
	local slashnum=0
	local meidos={}
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasSkill("lianxie") and self:isFriend(p) then 
			table.insert(meidos,p) 
			slashnum=slashnum+self:getCardsNum("Slash",p) 
		end
	end
	if #meidos==0 or slashnum==0 then return end
	self:sort(self.enemies)
	local slash=sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
	for _,enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy,slash,true) and not self:slashProhibit(slash, enemy) 
        and self:slashIsEffective(slash, enemy) and not (self.player:hasFlag("slashTargetFix") and not enemy:hasFlag("SlashAssignee")) then
			use.card=sgs.Card_Parse("#lianxie_card:.:")
			if use.to then use.to:append(enemy) end
			return
		end
	end	
end

sgs.ai_skill_invoke.pianyi=function(self,data)
	local damage=data:toDamage()
	if self:isEnemy(damage.to) then return false end
	if self:isFriend(damage.from) and not self:isFriend(damage.to) then return false end
	return true 
end

sgs.ai_skill_use["@@pianyi"]=function(self,prompt)
	local cards={}
	for _,card in sgs.qlist(self.player:getCards("he")) do
		if card:isKindOf("BasicCard") then
			table.insert(cards,card)
		end
	end
	if #cards==0 then return "." end
	self:sortByKeepValue(cards)
	card=cards[1]
	self:sort(self.enemies)
	for _,enemy in ipairs(self.enemies) do
		if enemy:hasFlag("pianyiable") then
			return "#pianyi_card:"..card:getId()..":->"..enemy:objectName()
		end
	end
	if self.player:getHp()>1 and self.player:getHandcardNum()<3 and self.player:hasFlag("pianyiable") then return "#pianyi_card:"..card:getId()..":->"..self.player:objectName() end
	return "."
end

sgs.ai_skill_invoke.tongshi=function(self,data)
	if #self.friends>#self.enemies then sgs.ai_skill_choice.tongshi="draw" return true end
	local friends={}
	local enemis={}
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if self:isFriend(p) and not p:isNude() then table.insert(friends,p) end
		if self:isEnemy(p) and not p:isNude() then table.insert(enemis,p) end
	end
	if #friends<#enemis then sgs.ai_skill_choice.tongshi="discard" return true end
	return false
end	

sgs.ai_skill_invoke.niansui=function(self,data)
	local dying=data:toDying()
	if not self:isFriend(dying.who) then return true end
	return false
end	

sgs.TCA04_suit_value = 
{
	spade = 6,
	heart = 6
}

sgs.ai_skill_use["@@fuying"]=function(self,prompt)
	self:sort(self.enemies,"value")
	local targets={}
	for _,enemy in ipairs(self.enemies) do
		if #targets<2 and enemy:isAlive() then table.insert(targets,enemy) else break end
	end	
	if #targets==2 then
		return "#fuying_card:.:->"..targets[1]:objectName().."+"..targets[2]:objectName()
	end
	return "."
end

sgs.ai_skill_cardask["@huixiang"]=function(self,data,pattern,target)
	local use=data:toCardUse()
	if use.card:isKindOf("GodSalvation") or use.card:isKindOf("AmazingGrace") then return "." end
	if self:isFriend(use.from) and use.card:isRed() then return "." end
end

sgs.ai_skill_playerchosen.zaoyin=function(self,targets)
	local targets=sgs.QList2Table(targets)
	self:sort(targets)
	for _,target in ipairs(targets) do
		if self:isEnemy(target) and self:damageIsEffective(target,sgs.DamageStruct_Thunder) then
			return target
		end
	end
end

sgs.ai_skill_invoke.huanxing=function(self,data)
	local enemy=data:toPlayer()
	if self:hasSkills("jijiu|yuliao",enemy) then return true end
	if not self:damageIsEffective(enemy,sgs.DamageStruct_Thunder) then return false end
	if self:isEnemy(enemy) and not self:hasSkills("liushui|aojiao|rexue|tianyun",enemy) then return true end
	return false
end

liushui_skill={}
liushui_skill.name="liushui"
table.insert(sgs.ai_skills,liushui_skill)
liushui_skill.getTurnUseCard=function(self,inclusive)
	local cards={}
	for _,card in sgs.qlist(self.player:getCards("he")) do
		if not card:isEquipped() or card:getClassName()=="SilverLion" then table.insert(cards,card) end
	end	
	self:sortByUseValue(cards)
	
	local blackcard
	local ironchain=sgs.Sanguosha:cloneCard("ironchain",sgs.Card_NoSuit,0)
	
	for _,card in ipairs(cards) do
		if card:isBlack() then
			blackcard=card
			break
		end
	end
	
	if not blackcard then return nil end
	local number = blackcard:getNumberString()
	local card_id = blackcard:getEffectiveId()
	local suit=blackcard:getSuitString()
	local card_str = ("iron_chain:liushui[%s:%s]=%d"):format(suit,number,card_id)
	local skillcard = sgs.Card_Parse(card_str)
	assert(skillcard)
	return skillcard
end

sgs.ai_skill_use["@@yanliu"]=function(self,prompt)
	local cards={}
	for _,card in sgs.qlist(self.player:getCards("he")) do
		if card:isRed() then table.insert(cards,card) end
	end
	if #cards==0 then return end
	self:sortByKeepValue(cards)
	card=cards[1]
	local target
	for _,p in sgs.qlist(self.room:getAllPlayers()) do
		if p:hasFlag("yanliutarget") then
			target=p
			break
		end
	end
	if target:getEquips():length()>1 and self:isEnemy(target) and not (target:getArmor() and target:getArmor():getClassName()=="Vine") then 
		return "#yanliu_card:"..card:getId()..":->."
	end
	local targets={}
	for _,p in sgs.qlist(self.room:getAllPlayers()) do
		if p:hasFlag("yanliuable") and ((self:isFriend(p) and p:hasSkill("chiyan")) or (self:isEnemy(p) and self:damageIsEffective(p,sgs.DamageStruct_Fire)))then
			table.insert(targets,p)
		end
	end
	if #targets>0 then
		local targetsname = {}
		for i=1,#targets,1 do
			table.insert(targetsname, targets[i]:objectName())
		end
		local card_str="#yanliu_card:"..card:getId()..":->"..table.concat(targetsname,"+")
		return card_str
	end
	return "."
end	

sgs.ai_skill_use["@@fengwu"]=function(self,prompt)
	local enemies={}
	local card=self.room:getTag("fengwucard"):toCard()
	local nature=sgs.DamageStruct_Normal
	if card:isKindOf("FireSlash") then nature=sgs.DamageStruct_Fire elseif card:isKindOf("ThunderSlash") then nature=sgs.DamageStruct_Thunder end
	for _,enemy in ipairs(self.enemies) do
		if enemy:hasFlag("fengwuable") and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy,nature) then
			table.insert(enemies,enemy)
		end
	end
	self:sort(enemies,"defense")
	if #enemies>0 then
		return "#fengwu_card:.:->"..enemies[1]:objectName()
	end
end

xinyan_skill={}
xinyan_skill.name="xinyan"
table.insert(sgs.ai_skills,xinyan_skill)
xinyan_skill.getTurnUseCard=function(self,inclusive)
	local cards=sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	
	local redcard
	
	for _,card in ipairs(cards) do
		if card:isRed() then
			redcard=card
			break
		end
	end
	
	if  redcard then 
		local number = redcard:getNumberString()
		local card_id = redcard:getEffectiveId()
		local suit=redcard:getSuitString()
		local card_str = ("slash:xinyan[%s:%s]=%d"):format(suit,number,card_id)
		local skillcard = sgs.Card_Parse(card_str)
		assert(skillcard)
		return skillcard
	end
end

sgs.ai_view_as.xinyan=function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:isRed() and card_place~=sgs.Player_PlaceEquip then
		return ("slash:xinyan[%s:%s]=%d"):format(suit,number,card_id)
	end
	if card:isBlack() and card_place~=sgs.Player_PlaceEquip then
		return ("jink:xinyan[%s:%s]=%d"):format(suit,number,card_id)
	end	
end	

sgs.ai_skill_choice.xinyan=function(self,choices,data)
	local victim=data:toPlayer()
	if self:isFriend(victim) then return "draw" end
	if victim:getWeapon() or victim:getArmor() then return "discard" end
	if self.player:getWeapon() and self.player:getWeapon():getClassName()=="GudingBlade" then return "discard" end
	if self:hasSkills(sgs.recover_skill,victim) then return "discard" end
	if self.player:getWeapon() and self.player:getWeapon():getClassName()=="MoonSpear" and self.player:getPhase()==sgs.Player_NotActive then return "draw" end
	if self.player:getWeapon() and self.player:getWeapon():getClassName()=="Crossbow" and self.player:getPhase()==sgs.Player_Play then return "draw" end
	if self.player:getPhase()==sgs.Player_NotActive and self.player:getHandcardNum()<=3 then return "draw" end
	return "draw"
end	

sgs.ai_skill_invoke.xuying=function(self,data)
	local effect=data:toCardEffect()
	if effect.card:isKindOf("AmazingGrace") or effect.card:isKindOf("GodSalvation") or effect.card:isKindOf("ExNihilo") then return false end
	if self:isFriend(effect.from) then return false end
	return true
end	

sgs.ai_skill_invoke.jiaoji=function(self,data)
	local use=data:toCardUse()
	if use.card:isKindOf("AmazingGrace") or use.card:isKindOf("GodSalvation") then return false end
	if self:isFriend(use.from) then return false end
	return true
end

sgs.ai_skill_cardask["@jiaoji"]=function(self,data,pattern,target)
	local current=self.room:getCurrent()
	if self:isEnemy(current) then return "." end
end

sgs.ai_skill_choice.dianxing=function(self,choices)
	return "recover"
end

sgs.ai_skill_invoke.destroy=function()
	return true
end	

function sgs.ai_cardsview.create(class_name, player)
	if class_name == "Peach" then
		if player:hasSkill("create") then
			return ("peach:create[no_suit:0]=.")
		end
	elseif class_name == "Nullification" then
		if player:hasSkill("create") then
			return ("nullification:create[no_suit:0]=.")
		end
	elseif class_name=="Jink" then
		if player:hasSkill("create") then
			return ("jink:create[no_suit:0]=.")
		end
	elseif class_name=="Slash" then
		if player:hasSkill("create") then
			return ("slash:create[no_suit:0]=.")
		end
	end	
end

local create_skill={}
create_skill.name="create"
table.insert(sgs.ai_skills,create_skill)
create_skill.getTurnUseCard=function(self)
	local x=math.random(1,3)
	if x==1 then
		return sgs.Card_Parse("thunder_slash:create[no_suit:0]=.")
	elseif x==2 then
		return sgs.Card_Parse("fire_slash:create[no_suit:0]=.")
	else
		return sgs.Card_Parse("slash:create[no_suit:0]=.")
	end	
end

sgs.ai_skill_use["@@liuzhuan"]=function(self,prompt)
	if self.player:hasFlag("liuzhuan1") then
		local friends={}
		for _,friend in ipairs(self.friends_noself) do
			if friend:isWounded() and not self:immunityRecover(friend) then table.insert(friends,friend) end
		end
		self:sort(friends,"defense")
		return "#liuzhuan_card:.:->"..friends[1]:objectName()
	else
		local enemies={}
		for _,enemy in ipairs(self.enemies) do
			if self:damageIsEffective(enemy) then table.insert(enemies,enemy) end
		end
		self:sort(enemies,"defense",false)
		return "#liuzhuan_card:.:->"..enemies[1]:objectName()
	end	
end

sgs.ai_skill_invoke.fenhui=function(self,data)
	if self:isEnemy(self.room:getCurrent()) then return true  end
	return false
end	