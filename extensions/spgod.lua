module("extensions.spgod",package.seeall)
extension=sgs.Package("spgod")

spshenguanyu=sgs.General(extension,"spshenguanyu","god",5,true)

spwushen=sgs.CreateTriggerSkill{
	name="spwushen",
	events={sgs.CardUsed,sgs.CardResponsed},
	frequency=sgs.Skill_Frequent,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local card=nil
		if event==sgs.CardUsed then card=data:toCardUse().card 
		elseif event==sgs.CardResponsed then card=data:toResponsed().m_card 
		end
		if card:getSuit()==sgs.Card_Heart and player:hasSkill("spwushen") and card:getSkillName()~=self:objectName() then
			local players=sgs.SPlayerList()
			local acard=sgs.Sanguosha:cloneCard("fire_slash",sgs.Card_NoSuit,0)
			acard:setSkillName("spwushen")
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if player:canSlash(p,acard,false) then players:append(p) end
			end	
			if players:isEmpty() or not room:askForSkillInvoke(player,"spwushen") then return false end
			local playerx=room:askForPlayerChosen(player,players,"spwushen")
			local use=sgs.CardUseStruct()
			use.from=player
			use.to:append(playerx)
			use.card=acard
			room:useCard(use,false)
		end
	end,
}

chihun=sgs.CreateFilterSkill{
	name="chihun",
	view_filter=function(self,to_select)
		return to_select:isKindOf("BasicCard") and to_select:getSuit()~=sgs.Card_Heart
	end,
	view_as=function(self,card)
		local acard=sgs.Sanguosha:getWrappedCard(card:getId())
		acard:setSkillName("chihun")
		acard:setSuit(sgs.Card_Heart)
		acard:setModified(true)
		return acard
	end,
}

spmengyan_distance=sgs.CreateDistanceSkill{
	name="#spmengyan_distance",
	correct_func=function(self,from,to)
		return from:getMark("@spnightmare")-to:getMark("@spnightmare")
	end,
}

spmengyan=sgs.CreateTriggerSkill{
	name="spmengyan",
	events={sgs.Damage,sgs.Damaged,sgs.TurnStart},
	frequency=sgs.Skill_Compulsory,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.Damaged then 
			local damage=data:toDamage()
			if not player:hasSkill(self:objectName()) then return false end
			if damage.from:objectName()==player:objectName() or player:isDead() or damage.from:isDead() then return false end
			room:broadcastSkillInvoke(self:objectName())
			damage.from:gainMark("@spnightmare",damage.damage)
		end
		if event==sgs.TurnStart then
			local shenguanyu=room:findPlayerBySkillName(self:objectName())
			if player:getMark("@spnightmare")>0 and (player:getMark("@spnightmare")>3 or not shenguanyu) then
				local log=sgs.LogMessage()
				log.to:append(player)
				log.type="#spmengyan"
				room:sendLog(log)
				room:loseHp(player)
				player:loseMark("@spnightmare")
			end
		end
	end,	
}

spwuhun=sgs.CreateTriggerSkill{
	name="spwuhun",
	events={sgs.BuryVictim},
	frequency=sgs.Skill_Compulsory,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if not player:hasSkill("spwuhun") then return false end
		local maxspnightmare=0
		local players=sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:getMark("@spnightmare")>maxspnightmare then
				maxspnightmare=p:getMark("@spnightmare")
			end
		end
		if maxspnightmare==0 then return false end
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:getMark("@spnightmare")==maxspnightmare then
				players:append(p)
			end
		end
		local judge=sgs.JudgeStruct()
		judge.who=player
		judge.good=false
		judge.pattern=sgs.QRegExp("(Peach|GodSalvation):(.*):(.*)")
		judge.reason=self:objectName()
		room:judge(judge)
		if judge:isGood() then
			local target=room:askForPlayerChosen(player,players,"spwuhun")
			room:broadcastSkillInvoke(self:objectName(),1)
			local log=sgs.LogMessage()
			log.type="#spwuhun"
			log.from=player
			log.to:append(target)
			log.arg=maxspnightmare
			room:sendLog(log)			
			room:killPlayer(target)
		else
			room:revivePlayer(player)
			room:setPlayerProperty(player,"hp",sgs.QVariant(5))
			player:throwAllHandCardsAndEquips()
			player:drawCards(4)
			room:broadcastSkillInvoke(self:objectName(),2)
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				p:loseAllMarks("@spnightmare")
			end
			room:detachSkillFromPlayer(player,"spwuhun")
			return true
		end		
	end,
}

spshenguanyu:addSkill(spwushen)
spshenguanyu:addSkill(chihun)
spshenguanyu:addSkill(spmengyan_distance)
spshenguanyu:addSkill(spmengyan)
spshenguanyu:addSkill(spwuhun)

sgs.LoadTranslationTable{
	["spgod"] = "SP神",

	["spshenguanyu"] = "神关羽",
	["#spshenguanyu"] = "鬼神天降",

	["spwushen"] = "武神",
	["$spwushen1"] = "武神现世，天下莫敌！",
	["$spwushen2"] = "战意，化为青龙翱翔吧！",
	[":spwushen"] = "你每使用或者打出一张红桃牌，在其结算前，你可以选择一名合理的其他角色，视为对其使用了一张火【杀】",
	["chihun"]="赤魂",
	[":chihun"]="<b>锁定技</b>，你的基础牌的花色均视为红桃",
	["#spmengyan_distance"]="梦魇",
	["spmengyan"]="梦魇",
	[":spmengyan"]="<b>锁定技</b>，你每受到其他角色1点伤害，在其面前放置1枚梦魇标记。面前有梦魇标记的角色，其他角色与其计算距离时始终-x，其与其他角色计算距离时始终+x，x为其面前梦魇标记数。在你死后（或者丧失此技能后），所有带有梦魇标记的角色在其回合开始时移除一个梦魇标记并失去1点体力直到全部移除。你存活时，若某角色梦魇标记多于3个，其回合开始时也如此做。",	
	["$spmengyan"]="关某记下了", 
	["@spnightmare"]="梦魇",
	["#spmengyan"]="%to受【梦魇】影响",
	["spwuhun"]="武魂",
	[":spwuhun"]="<b>锁定技</b>，当你死亡时，你做一次判定，若结果不为桃或者桃园结义，选择一名持有最多梦魇标记的角色，其立刻死亡；否则你复活并将体力恢复至上限，然后弃置所有的手牌与装备并摸4张牌，然后所有其他角色失去所有的梦魇标记，然后你失去武魂。",
	["#spwuhun"]="%from的【武魂】触发，带有最多梦魇印记(%arg枚)的%to死亡",
	["$spwuhun1"]="我生不能啖汝之肉，死当追汝之魂！",
	["$spwuhun2"]="桃园之梦，再也不会回来了……",
	["~spshenguanyu"]="吾一世英名，竟葬于小人之手！",
	["designer:spshenguanyu"]="Nutari",
}

spshenzhugeliang=sgs.General(extension,"spshenzhugeliang","god",3,true)

spqixing=sgs.CreateTriggerSkill{
	name="spqixing",
	events={sgs.GameStart,sgs.EventPhaseEnd,sgs.Damaged},
	frequency=sgs.Skill_Frequent,
	can_trigger=function()
		return true
	end,	
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if not player:hasSkill(self:objectName()) then return end
		if event==sgs.GameStart then
			player:drawCards(7)
			local exchange=room:askForExchange(player,"spqixing",7,true)
			player:addToPile("spstar",exchange,false)
		end
		if event==sgs.EventPhaseEnd and (player:getPhase()==sgs.Player_Draw or player:getPhase()==sgs.Player_Discard)then
			room:broadcastSkillInvoke(self:objectName())
			if player:getPile("spstar"):length()==0 or not room:askForSkillInvoke(player,self:objectName()) then return false end		
			room:fillAG(player:getPile("spstar"), player)
			local cdid=room:askForAG(player, player:getPile("spstar"), true, self:objectName())
			local x=0
			local n=player:getPile("spstar"):length()
			while cdid~=-1 and x<n do
				x=x+1
				room:moveCardTo(sgs.Sanguosha:getCard(cdid),player,sgs.Player_PlaceHand,true)
				player:invoke("clearAG")
				if x==n then break end
				room:fillAG(player:getPile("spstar"), player)
				cdid=room:askForAG(player, player:getPile("spstar"), true, self:objectName())
			end
			player:invoke("clearAG")
			if x>0 then 
				local exchange=room:askForExchange(player,"spqixing",x,true)
				for _,id in sgs.qlist(exchange:getSubcards()) do
					player:addToPile("spstar",id,false)
				end	
			end
		end
		if event==sgs.Damaged then
			local damage=data:toDamage()
			if player:getPile("spstar"):length()>=7 or player:isDead() or not room:askForSkillInvoke(player,self:objectName()) then return false end
			local x=damage.damage
			if x>7-player:getPile("spstar"):length() then x=7-player:getPile("spstar"):length() end
			for i=1,x,1 do
				player:drawCards(1)
				local cdid=room:askForCardChosen(player,player,"he",self:objectName())
				player:addToPile("spstar",cdid,false)
			end
		end	
	end,
}

spdawu_card=sgs.CreateSkillCard{
	name="spdawu_card",
	will_throw=false,
	target_fixed=false,
	filter=function(self,targets,to_select)
		return #targets<sgs.Self:getPile("spstar"):length()
	end,
	on_use=function(self,room,source,targets)
		for i=1,#targets,1 do
			room:fillAG(source:getPile("spstar"), source)
			local cdid=room:askForAG(source, source:getPile("spstar"), false, self:objectName())
			room:throwCard(cdid,source)
			source:invoke("clearAG")
		end
		room:broadcastSkillInvoke("spdawu")
		for i=1,#targets,1 do
			targets[i]:gainMark("@fog")
		end
	end,
}

spdawu_vs=sgs.CreateViewAsSkill{
	name="spdawu",
	n=0,
	view_as=function()
		return spdawu_card:clone()
	end,
	enabled_at_play=function()
		return false
	end,
	enabled_at_response=function(self,player,pattern)
		return pattern=="@@spdawu"
	end,
}

spdawu=sgs.CreateTriggerSkill{
	name="spdawu",
	events={sgs.DamageForseen,sgs.DamageDone,sgs.EventPhaseStart,sgs.EventLoseSkill,sgs.BuryVictim},
	view_as_skill=spdawu_vs,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.EventLoseSkill and data:toString()==self:objectName() or event==sgs.BuryVictim and player:hasSkill(self:objectName()) then
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("@fog")>0 then
					p:loseAllMarks("@fog")
				end
			end	
		end
		local spszgl=room:findPlayerBySkillName(self:objectName())
		if not spszgl then return false end
		if event==sgs.EventPhaseStart and spszgl:getPhase()==sgs.Player_Finish then
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("@fog")>0 then
					p:loseAllMarks("@fog")
				end
			end	
			if spszgl:getPile("spstar"):length()==0 then return false end
			room:askForUseCard(spszgl,"@@spdawu","#spdawuask")
		end		
		if event==sgs.DamageForseen then
			local damage=data:toDamage()
			if player:getMark("@fog")==0 or damage.nature==sgs.DamageStruct_Thunder then return false end
			local log=sgs.LogMessage()
			log.from=player
			log.type="#spdawu"
			room:sendLog(log)
			return true
		end
		if event==sgs.DamageDone then
			local damage=data:toDamage()
			if player:getMark("@fog")==0 or damage.nature~=sgs.DamageStruct_Thunder then return false end
			if damage.damage<=1 then return false end
			damage.damage=1
			local log=sgs.LogMessage()
			log.from=player
			log.type="#spdawux"
			room:sendLog(log)
			data:setValue(damage)
			return false
		end
	end,	
}

spkuangfeng_card=sgs.CreateSkillCard{
	name="spkuangfeng_card",
	will_throw=false,
	target_fixed=false,
	filter=function(self,targets,to_select)
		return #targets<sgs.Self:getPile("spstar"):length()
	end,
	on_use=function(self,room,source,targets)
		for i=1,#targets,1 do
			room:fillAG(source:getPile("spstar"), source)
			local cdid=room:askForAG(source, source:getPile("spstar"), false, self:objectName())
			room:throwCard(cdid,source)
			source:invoke("clearAG")
		end
		room:broadcastSkillInvoke("spkuangfeng")
		for i=1,#targets,1 do
			targets[i]:gainMark("@gale")
		end
	end,
}

spkuangfeng_vs=sgs.CreateViewAsSkill{
	name="spkuangfeng",
	n=0,
	view_as=function()
		return spkuangfeng_card:clone()
	end,
	enabled_at_play=function()
		return false
	end,
	enabled_at_response=function(self,player,pattern)
		return pattern=="@@spkuangfeng"
	end,
}


spkuangfeng=sgs.CreateTriggerSkill{
	name="spkuangfeng",
	events={sgs.DamageForseen,sgs.EventPhaseStart,sgs.EventLoseSkill,sgs.BuryVictim},
	view_as_skill=spkuangfeng_vs,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.EventLoseSkill and data:toString()==self:objectName() or event==sgs.BuryVictim and player:hasSkill(self:objectName()) then
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("@gale")>0 then
					p:loseAllMarks("@gale")
				end
			end	
		end
		local spszgl=room:findPlayerBySkillName(self:objectName())
		if not spszgl then return false end
		if event==sgs.EventPhaseStart and spszgl:getPhase()==sgs.Player_Finish then
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("@gale")>0 then
					p:loseAllMarks("@gale")
				end
			end	
			if spszgl:getPile("spstar"):length()==0 then return false end
			room:askForUseCard(spszgl,"@@spkuangfeng","#spkuangfengask")
		end		
		if event==sgs.DamageForseen then
			local damage=data:toDamage()
			if player:getMark("@gale")==0 then return false end
			if damage.nature==sgs.DamageStruct_Normal then
				local log=sgs.LogMessage()
				log.from=player
				log.type="#spkuangfeng"
				room:sendLog(log)
				damage.nature=sgs.DamageStruct_Fire
			end	
			if damage.nature==sgs.DamageStruct_Fire then
				local log=sgs.LogMessage()
				log.from=player
				log.type="#spkuangfengx"
				room:sendLog(log)				
				damage.damage=damage.damage+1
				data:setValue(damage)
				return false
			end	
		end
	end,	
}

xinghun=sgs.CreateTriggerSkill{
	name="xinghun",
	events={sgs.BuryVictim},	
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if player:hasSkill("spkuangfeng") then 
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("@gale")>0 then
					p:loseAllMarks("@gale")
				end
			end
		end
		if player:hasSkill("spdawu") then 
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("@fog")>0 then
					p:loseAllMarks("@fog")
				end
			end
		end
		if not player:hasSkill(self:objectName()) then return false end
		if player:getPile("spstar"):isEmpty() or not room:askForSkillInvoke(player,"xinghun") then return false end
		local playerx=room:askForPlayerChosen(player,room:getOtherPlayers(player),"xinghun")
		room:acquireSkill(playerx,"spkuangfeng")
		room:acquireSkill(playerx,"spdawu")
		for _,id in sgs.qlist(player:getPile("spstar")) do
			playerx:addToPile("spstar",id,false)
		end
	end,	
}

spshenzhugeliang:addSkill(spqixing)
spshenzhugeliang:addSkill(spkuangfeng)
spshenzhugeliang:addSkill(spdawu)
spshenzhugeliang:addSkill(xinghun)

sgs.LoadTranslationTable{
	["#spshenzhugeliang"] = "赤壁的妖术师",
	["spshenzhugeliang"] = "神诸葛亮",
	["spqixing"] = "七星",
	[":spqixing"] = "分发起始手牌时，共发你十一张牌，你选四张作为手牌，其余的面朝下置于一旁，称为“星”；摸牌阶段和弃牌阶段结束时，你可以用任意数量的手牌等量替换这些“星”。每当你受到1点伤害，你可以摸1张牌并将你的1张牌补充至星内\
◆星是移出游戏的牌。",
	["spstar"] = "星",
	["spkuangfeng"] = "狂风",
	[":spkuangfeng"] = "回合结束阶段开始时，你可以将X张“星”置入弃牌堆并选择X名角色，若如此做，每当这些角色受到的火焰伤害结算开始时，此伤害+1，受到的无属性伤害视为火焰伤害，直到你的下回合回合结束。",
	["spdawu"] = "大雾",
	[":spdawu"] = "回合结束阶段开始时，你可以将X张“星”置入弃牌堆并选择X名角色，若如此做，每当这些角色受到的非雷电伤害结算开始时，防止此伤害，也防止超过1点的雷电伤害，直到你的下回合结束。",
	["spdawu_card"]="大雾",
	["spkuangfeng_card"]="狂风",
	["#spkuangfengask"] = "您可以发动技能【狂风】",
	["#spdawuask"] = "您可以发动技能【大雾】",
	["~spdawu"] = "选译若干名角色→点击确定→然后在窗口中选译若干张牌",
	["~spkuangfeng"] = "选译若干名角色→点击确定→然后在窗口中选译若干张牌",
	["#spdawu"]="在【大雾】的掩护下，%from防止了此次非雷电伤害",
	["#spdawux"]="在【大雾】的掩护下，%from防止了超过1点的雷电伤害",
	["#spkuangfeng"] = "由于【狂风】的影响，%from受到的无属性伤害被视为火焰伤害",
	["#spkuangfengx"] = "由于【狂风】助长了火势，%from 受到的火焰伤害增加了1点。",
	["xinghun"]="星魂",
	[":xinghun"]="当你死亡时，若你至少有1颗“星”，你可以将全部的星交给另一个角色，该角色同时获得【狂风】，【大雾】",
	["$spqixing"] = " 伏望天慈，延我之寿",
	["$spkuangfeng"] = "万事俱备，只欠东风",
	["$spdawu1"] = "一天浓雾满长江，远近难分水渺茫",
	["$spdawu2"] = "返元气于洪荒，混天地为大块",
	["~spshenzhugeliang"] = "吾命将至，再不能临阵讨贼矣",
	["designer:spshenzhugeliang"]="Nutari",
}

shendongzhuo=sgs.General(extension,"$shendongzhuo","god","8",true)

motian=sgs.CreateTriggerSkill{
	name="motian",
	frequency=sgs.Skill_Frequent,
	events=sgs.Dying,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local dongzhuo=room:findPlayerBySkillName(self:objectName())
		if not dongzhuo or player:objectName()~=data:toDying().who:objectName() then return end
		if dongzhuo:isNude() or player:getHp()>0 or player:isDead() or not room:askForSkillInvoke(dongzhuo,self:objectName(),data) then return end
		local card=room:askForCard(dongzhuo,".|.|.|.|.","#motianask",data,sgs.Card_MethodDiscard)
		if card then
			local judge=sgs.JudgeStruct()
			judge.who=player
			judge.reason="motian"
			judge.pattern=sgs.QRegExp("(.*):("..card:getSuitString().."):(.*)")
			judge.good=false
			judge.play_animation=true
			room:judge(judge)
			if not judge:isGood() then
				local log=sgs.LogMessage()
				log.type="#motian"
				log.from=dongzhuo
				log.to:append(player)
				room:sendLog(log)
				local damage=sgs.DamageStruct()
				damage.from=dongzhuo
				room:killPlayer(player,damage)
				return true
			else
				dongzhuo:obtainCard(judge.card)
				return false
			end
		end
	end,	
}

dzsinue=sgs.CreateTriggerSkill{
	name="dzsinue",
	frequency=sgs.Skill_Compulsory,
	events={sgs.BuryVictim,sgs.Damage,sgs.CardUsed},
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)	
		local room=player:getRoom()
		local dongzhuo=room:findPlayerBySkillName(self:objectName())
		if not dongzhuo then return end
		if event==sgs.Damage then
			damage=data:toDamage()
			if damage.from:objectName()==dongzhuo:objectName() and damage.damage>2 then
				local log=sgs.LogMessage()
				log.type="#dzsinue"
				log.from=dongzhuo
				log.arg=damage.damage
				log.to:append(damage.to)
				room:sendLog(log)
				local recover=sgs.RecoverStruct()
				recover.recover=1
				recover.who=dongzhuo
				room:recover(dongzhuo,recover)
			end
		end
		if event==sgs.BuryVictim then
			local death=data:toDeath()
			if death.damage and death.damage.from:objectName()==dongzhuo:objectName() then
				local log=sgs.LogMessage()
				log.type="#dzsinuex"
				log.from=dongzhuo
				log.to:append(player)
				room:sendLog(log)
				local recover=sgs.RecoverStruct()
				recover.recover=1
				recover.who=dongzhuo
				room:recover(dongzhuo,recover)
			end
		end
		if event==sgs.CardUsed then
			local use=data:toCardUse()
			if use.card:isKindOf("Analeptic") and use.from:hasSkill(self:objectName()) then
				local log=sgs.LogMessage()
				log.type="#dzsinuea"
				log.from=player
				room:sendLog(log)
				local recover=sgs.RecoverStruct()
				recover.recover=1
				recover.who=player
				room:recover(player,recover)
			end
		end
	end,
}

canbao=sgs.CreateTriggerSkill{
	name="canbao",
	frequency=sgs.Skill_Compulsory,
	events={sgs.Predamage,sgs.DamageInflicted},
	priority=3,
	can_trigger=function()
		return true
	end,	
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local damage=data:toDamage()
		if event==sgs.Predamage then
			if damage.from:hasSkill(self:objectName()) then
				local log=sgs.LogMessage()
				log.type="#canbao"
				log.from=player
				log.to:append(damage.to)
				room:sendLog(log)
				damage.damage=damage.damage+1
				data:setValue(damage)
			end
		end
		if event==sgs.DamageInflicted then
			if damage.to:hasSkill(self:objectName()) then
				local log=sgs.LogMessage()
				log.type="#canbaox"
				log.to:append(damage.to)
				room:sendLog(log)
				damage.damage=damage.damage+1
				data:setValue(damage)
			end
		end
	end,
}

baozheng=sgs.CreateTriggerSkill{
	name="baozheng$",
	events={sgs.Predamage,sgs.DamageInflicted},
	priority=2,
	frequency=sgs.Skill_NotFrequent,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local dongzhuo=room:findPlayerBySkillName(self:objectName())
		if not dongzhuo or not dongzhuo:hasLordSkill(self:objectName()) then return end
		local damage=data:toDamage()
		if event==sgs.Predamage and damage.from:objectName()==dongzhuo:objectName() then
			if not room:askForSkillInvoke(dongzhuo,self:objectName(),data) then return end
			local victim=sgs.QVariant()
			victim:setValue(dongzhuo)
			for _,p in sgs.qlist(room:getLieges(dongzhuo:getKingdom(),dongzhuo),data) do
				if room:askForCard(p,"BasicCard|.|.|hand|.","@baozhenginc:"..damage.to:objectName(),victim,sgs.Card_MethodDiscard,damage.to) then
					damage.damage=damage.damage+1
					data:setValue(damage)
					local log=sgs.LogMessage()
					log.type="#baozhengx"
					log.from=dongzhuo
					log.to:append(damage.to)
					room:sendLog(log)
					return
				end
			end	
		elseif event==sgs.DamageInflicted and damage.to:objectName()==dongzhuo:objectName() then
			if not room:askForSkillInvoke(dongzhuo,self:objectName(),data) then return end
			local victim=sgs.QVariant()
			victim:setValue(dongzhuo)
			for _,p in sgs.qlist(room:getLieges(dongzhuo:getKingdom(),dongzhuo),data) do
				if room:askForCard(p,"BasicCard|.|.|hand|.","@baozhengdec:"..damage.to:objectName(),victim,sgs.CardDiscarded,damage.to) then
				damage.damage=damage.damage-1
					data:setValue(damage)
					local log=sgs.LogMessage()
					log.type="#baozheng"
					log.from=dongzhuo
					log.to:append(damage.from)
					room:sendLog(log)
					return
				end
			end	
		end
	end,
}

shendongzhuo:addSkill(motian)
shendongzhuo:addSkill(dzsinue)
shendongzhuo:addSkill(canbao)
shendongzhuo:addSkill(baozheng)

sgs.LoadTranslationTable{
	["#shendongzhuo"] = "魔天之王",
	["shendongzhuo"] = "神董卓",
	["~shendongzhuo"]="居然敢……杀……我！",
	["motian"] = "魔天",
	[":motian"]="任何角色濒死时，你可以弃置一张牌，然后令那个角色判定，若判定牌花色与你弃置的牌相同，则其立刻死亡，凶手视为你；否则你收回判定牌",
	["#motian"]="%from的【魔天】被触发，%to即死",
	["#motianask"]="【魔天】 触发，请打出一张牌（包括手牌）",
	["dzsinue"]="肆虐",
	[":dzsinue"]="<b>锁定技</b>，当你对1个角色一次性造成超过2点伤害/你杀死任何角色/你使用【酒】时，你恢复1点体力",
	["#dzsinue"]="%from对%to造成了%arg点伤害，%from的【肆虐】被触发",
	["#dzsinuex"]="%from杀死了%to，%from的【肆虐】被触发",
	["canbao"]="残暴",
	[":canbao"]="<b>锁定技</b>，你造成和受到的伤害均+1。",
	["#canbao"]="%from的【残暴】被触发，对%to造成的伤害增加了1点",
	["#canbaox"]="%to的【残暴】被触发，%to受到的伤害增加了1点",
	["#dzsinuea"]="%from的【肆虐】被触发",
	["baozheng"]="暴政",
	[":baozheng"]="<b>主公技</b>，每当你即将造成1次伤害，你可以让与你同一势力的其他角色选择是否弃置1张基础牌，若弃置，则该伤害+1。每当你即将受到1次伤害，你可以让与你同一势力的其他角色选择是否弃置一张基础牌，若弃置则伤害-1",
	["@baozhengdec"]="你可以弃置1张基础牌减少 %src 即将受到的伤害1点",
	["@baozhenginc"]="你可以弃置1张基础牌增加 %src 即将受到的伤害1点",
	["#baozheng"]="%from的【暴政】被触发，%to即将造成的伤害减1",
	["#baozhengx"]="%from的【暴政】被触发，%to即将受到的伤害加1",
	["designer:shendongzhuo"]="Nutari",	
}

shenzhangfei=sgs.General(extension,"shenzhangfei","god","5",true)

haoyin=sgs.CreateTriggerSkill{
	name="haoyin",
	events={sgs.CardUsed,sgs.SlashHit},
	frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.CardUsed then
			local use=data:toCardUse()
			if use.card:isKindOf("Slash") then
				room:setPlayerFlag(player,"drank")
				return
			end
		end
		if event==sgs.SlashHit then
			if player:getMark("tiannu")==0 then
				room:loseHp(player)
			end
		end
	end,
}

xujiu=sgs.CreateFilterSkill{
	name="xujiu",
	view_filter=function(self,to_select)
		return to_select:isKindOf("Jink") or to_select:isKindOf("Peach")
	end,
	view_as=function(self,card)
		local analeptic=sgs.Sanguosha:cloneCard("analeptic",card:getSuit(),card:getNumber())
		analeptic:setSkillName(self:objectName())
		local acard=sgs.Sanguosha:getWrappedCard(card:getId())
		acard:takeOver(analeptic)
		return acard
	end,
}

zuiwu_max=sgs.CreateMaxCardsSkill{
	name="#zuiwu_max",
	extra_func=function(self,player)
		if player:hasSkill("zuiwu") then
			return player:getLostHp()
		end	
	end,
}	

zuiwu=sgs.CreateTriggerSkill{
	name="zuiwu",
	events={sgs.HpRecover,sgs.DrawNCards},
	frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.HpRecover then
			local recover=data:toRecover()
			if recover.card:isKindOf("Analeptic") then
				if player:getPile("drunk"):length()<player:getMaxHp() then player:addToPile("drunk",recover.card:getEffectiveId()) end
			end
		end
		if event==sgs.DrawNCards then
			local x=data:toInt()
			local y=player:getPile("drunk"):length()
			if y>0 then
				local log=sgs.LogMessage()
				log.type="#zuiwu"
				log.from=player
				log.arg=y
				room:sendLog(log)
				data:setValue(x+y)
			end
			return false
		end	
	end,
}

tiannu=sgs.CreateTriggerSkill{
	name="tiannu",
	events={sgs.EventPhaseStart},
	frequency=sgs.Skill_Wake,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.EventPhaseStart and player:getPhase()==sgs.Player_Start and player:getPile("drunk"):length()>=player:getMaxHp() then
			player:gainMark("tiannu")
			player:gainMark("@waked")
			for _,id in sgs.qlist(player:getPile("drunk")) do
				room:moveCardTo(sgs.Sanguosha:getCard(id),player,sgs.Player_PlaceHand,true)
			end
			for _,card in sgs.qlist(player:getJudgingArea()) do
				room:moveCardTo(card,player,sgs.Player_PlaceHand,true)
			end			
			room:setPlayerProperty(player,"hp",sgs.QVariant(player:getMaxHp()))
			room:acquireSkill(player,"paoxiao")
			room:acquireSkill(player,"shashen")
			room:setPlayerFlag(player,"jiangchi_invoke")
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				room:setPlayerFlag(p,"wuqian")
			end
			room:detachSkillFromPlayer(player,"xujiu")
			room:detachSkillFromPlayer(player,"zuiwu")
		end
		if event==sgs.EventPhaseStart and player:getPhase()==sgs.Player_Finish and player:getMark("tiannu")>0 then
			room:killPlayer(player)
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				room:setPlayerFlag(p,"-wuqian")
			end
		end
	end,
}

shashen=sgs.CreateFilterSkill{
	name="shashen",
	view_filter=function(self,to_select)
		local room=sgs.Sanguosha:currentRoom()
		local place=room:getCardPlace(to_select:getEffectiveId())
		return place==sgs.Player_PlaceHand
	end,
	view_as=function(self,card)
		local thunderslash=sgs.Sanguosha:cloneCard("thunder_slash",card:getSuit(),card:getNumber())
		thunderslash:setSkillName(self:objectName())
		local acard=sgs.Sanguosha:getWrappedCard(card:getId())
		acard:takeOver(thunderslash)
		return acard
	end,
}

local skill=sgs.Sanguosha:getSkill("shashen")
if not skill then
        local skillList=sgs.SkillList()
        skillList:append(shashen)
        sgs.Sanguosha:addSkills(skillList)
end

shenzhangfei:addSkill(haoyin)
shenzhangfei:addSkill(xujiu)
shenzhangfei:addSkill(zuiwu)
shenzhangfei:addSkill(zuiwu_max)
shenzhangfei:addSkill(tiannu)

sgs.LoadTranslationTable{
	["#shenzhangfei"] = "酒神",
	["shenzhangfei"] = "神张飞",
	["~shenzhangfei"]="再拿酒来，老子还要杀！啊……",
	["haoyin"]="豪饮",
	[":haoyin"]="<b>锁定技</b>，你使用的【杀】均为酒【杀】。你的杀命中时，你需弃置失去1点体力(觉醒后不触发)",
	["@haoyin"]="请弃置一张酒",
	["xujiu"]="酗酒",
	[":xujiu"]="<b>锁定技</b>，你的【闪】和【桃】均视为【酒】",
	["zuiwu"]="醉舞",
	[":zuiwu"]="<b>锁定技</b>，你濒死使用【酒】恢复体力时，你把这张【酒】置于你的武将牌上，称为“醉”(“醉”的数量不超过你的体力上限)。你摸牌阶段多摸等同于“醉”数量的牌。你的手牌上限为你的体力上限",
	["drunk"]="醉",
	["#zuiwu"]="%from的【醉舞】触发，多摸了%arg张牌",
	["tiannu"]="天怒",
	[":tiannu"]="<b>觉醒技</b>，回合开始，若你的“醉”达到或者超过你的体力上限，你将判定区的牌和所有的“醉”加入手牌，并将体力重置为上限，你获得【咆哮】和【杀神】（<b>锁定技</b>，你的手牌均视为雷【杀】），失去【酗酒】和【醉舞】，同时你的杀无限距离，无视防具。【天怒】触发后，该回合回合结束你立刻死亡",
	["@kill"]="杀",
	["shashen"]="杀神",
	[":shashen"]="<b>锁定技</b>，你的手牌均视为雷【杀】",
	["designer:shenzhangfei"]="Nutari",
}

shendiaochan=sgs.General(extension,"shendiaochan","god","3",false)

tianwu_card=sgs.CreateSkillCard{
	name="tianwu_card",
	will_throw=false,
	target_fixed=false,
	filter=function(self,targets,to_select)
		if #targets>=sgs.Self:getLostHp()+2 then return false end
		return true
	end,
	feasible=function(self,targets)
		return #targets>=2
	end,
	on_use=function(self,room,source,targets)
		local slash=sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
		room:setPlayerFlag(source,"tianwuused")
		local x=0
		if #targets==2 then
			room:broadcastSkillInvoke("tianwu",1)
		elseif #targets==3 then
			room:broadcastSkillInvoke("tianwu",2)
		elseif #targets>3 then
			room:broadcastSkillInvoke("tianwu",3)
		end	
		for i=1,#targets,1 do
			for j=1,#targets,1 do
				if i~=j and targets[j]:isAlive() then
					room:getThread():delay(100)
					x=x+1
					targets[j]:addMark("qinggang")
					local use=sgs.CardUseStruct()
					use.from=targets[i]
					use.to:append(targets[j])
					use.card=slash
					room:useCard(use,false)
				end
			end
		end
		if source:getCards("he"):length()>x then
			room:askForDiscard(source,"tianwu",x,x,false,true)
		else
			x=x-source:getCards("he"):length()
			source:throwAllHandCardsAndEquips()
			if x>0 then room:loseHp(source,x) end
		end
	end,
}

tianwu_vs=sgs.CreateViewAsSkill{
	name="tianwu",
	n=0,
	view_as=function()
		return tianwu_card:clone()
	end,
	enabled_at_play=function()
		return not sgs.Self:hasFlag("tianwuused")
	end,
}

tianwu=sgs.CreateTriggerSkill{
	name="tianwu",
	events=sgs.EventPhaseEnd,
	view_as_skill=tianwu_vs,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		room:setPlayerFlag(player,"-tianwuused")
	end,
}

chenyu=sgs.CreateFilterSkill{
	name="chenyu",
	view_filter=function(self,to_select)
		return to_select:getSuit()==sgs.Card_Diamond or to_select:getSuit()==sgs.Card_Spade
	end,
	view_as=function(self,card)
		local acard=sgs.Sanguosha:getWrappedCard(card:getId())
		acard:setSkillName(self:objectName())
		if card:getSuit()==sgs.Card_Diamond then
			acard:setSuit(sgs.Card_Club)
		elseif card:getSuit()==sgs.Card_Spade then
			acard:setSuit(sgs.Card_Heart)
		end
		acard:setModified(true)
		return acard
	end,
}

spbiyue_max=sgs.CreateMaxCardsSkill{
	name="#spbiyue_max",
	extra_func=function(self,player)
		if player:hasSkill("spbiyue") then
			local x=0
			if player:isMale() then x=x+1 end
			for _,p in sgs.qlist(player:getSiblings()) do
				if p:isMale() and p:isAlive() then x=x+1 end
			end
			return x
		end
	end,
}

spbiyue=sgs.CreateTriggerSkill{
	name="spbiyue",
	events=sgs.EventPhaseStart,
	frequency=sgs.Skill_Frequent,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local diaochan=room:findPlayerBySkillName(self:objectName());
		if player:getPhase()==sgs.Player_Finish then
			if player:isMale()  then
				if not room:askForSkillInvoke(diaochan,self:objectName()) then return false end
				room:broadcastSkillInvoke("spbiyue")
				diaochan:drawCards(1);
			end	
		end	
	end,
}

hunsu=sgs.CreateTriggerSkill{
	name="hunsu",
	events=sgs.BeforeGameOverJudge,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if player:hasSkill(self:objectName()) then
			local damage=data:toDamageStar()
			if not damage then
				local damage=sgs.DamageStruct()
				damage.to=player
			end	
			if not damage.from or damage.from:objectName()~=player:objectName() then
				damage.from=player
				data:setValue(damage)
				local log=sgs.LogMessage()
				log.from=player
				log.type="#hunsu"
				room:sendLog(log)
			end	
			if not room:askForSkillInvoke(player,self:objectName(),data) then return end
			room:broadcastSkillInvoke("hunsu")
			local male=sgs.SPlayerList()
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:isMale() then male:append(p) end
			end
			local target=room:askForPlayerChosen(player,male,self:objectName())
			room:setPlayerProperty(target,"hp",sgs.QVariant(target:getMaxHp()))
			target:throwAllHandCardsAndEquips()
			if target:isChained() then room:setPlayerProperty(target,"chained",sgs.QVariant(false)) end
			if not target:faceUp() then target:turnOver() end
			room:acquireSkill(target,"wushuang")
			room:acquireSkill(target,"shenji")
			room:acquireSkill(target,"mashu")
			room:acquireSkill(target,"kuangbao")
			room:acquireSkill(target,"shenfen")
			target:drawCards(4)
			return false
		end
	end,
}

shendiaochan:addSkill(tianwu)
shendiaochan:addSkill(chenyu)
shendiaochan:addSkill(spbiyue_max)
shendiaochan:addSkill(spbiyue)
shendiaochan:addSkill(hunsu)

sgs.LoadTranslationTable{
	["shendiaochan"]="神貂蝉",
	["#shendiaochan"]="天命的舞姬",
	["~shendiaochan"]="天舞即毕，妾身亦当烟消云散",
	["tianwu_card"]="天舞",
	["tianwu"]="天舞",
	[":tianwu"]="出牌阶段，你可以选择至多2+x个角色（至少2个），x为你已经失去的体力，视为其中的每名角色对其他角色各使用了一张【杀】，该杀无视防具，无视不能成为【杀】目标的技能，即使出【杀】者死亡也会继续。然后你需弃置【杀】总数的牌，若不足，每少1张你失去1点体力。一阶段限一次\
	◆视为以逆时针顺序每个被选择的角色依次对其他角色出了一张【杀】",
	["$tianwu1"] = "华彩之舞，摄人心魂",
	["$tianwu2"] = "眩光之舞，鸣动天下",
	["$tianwu3"] = "天武之舞，至死方休",
	["chenyu"]="沉鱼",
	[":chenyu"]="<b>锁定技</b>，你的黑桃牌视为红桃，你的方片牌视为梅花",
	["spbiyue"]="闭月",
	[":spbiyue"]="任何男性角色回合结束阶段开始，你摸1张牌。场上每有一个存活男性角色，你的手牌上限+1",
	["$spbiyue"] = "妾身有礼了",
	["hunsu"]="魂宿",
	[":hunsu"]="你死亡始终视为自杀。你死亡时，可以选择一名男性角色。其将体力恢复至上限，弃置其所有的装备和手牌，重置并翻至正面朝上，然后其获得【无双】【神戟】【马术】【狂暴】【神愤】，然后摸4张牌。",
	["$hunsu"]="妾身虽死，神魂仍在。",
	["#hunsu"]="%from的【魂宿】触发，死亡视为自杀",
	["cv:shendiaochan"]="Nutari",
	["designer:shendiaochan"]="Nutari",
}

shensunshangxiang=sgs.General(extension,"shensunshangxiang","god","3",false)

jiwu_max=sgs.CreateMaxCardsSkill{
	name="#jiwu_max",
	extra_func=function(self,player)
		if player:hasSkill("jiwu") then
			return player:getEquips():length()
		end
	end,
}	

jiwu=sgs.CreateTriggerSkill{
	name="jiwu",
	events={sgs.CardsMoveOneTime,sgs.DrawNCards},
	frequency=sgs.Skill_Frequent,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.CardsMoveOneTime then
			local move=data:toMoveOneTime()
			local ssx=room:findPlayerBySkillName(self:objectName())
			if not ssx then return end
			if move.from:objectName()~=player:objectName() then return false end
			if move.from:objectName()==ssx:objectName() then return false end
			if move.to_place~=sgs.Player_DiscardPile then return false end
			for _,id in sgs.qlist(move.card_ids) do
				local card=sgs.Sanguosha:getCard(id)
				if id~=-1 and card:isKindOf("EquipCard") and room:askForSkillInvoke(ssx,self:objectName()) then
					room:broadcastSkillInvoke(self:objectName())
					if card:isKindOf("Weapon") and not ssx:getWeapon() then
						room:moveCardTo(card,ssx,sgs.Player_PlaceEquip,true)
					elseif card:isKindOf("Armor") and not ssx:getArmor() then	
						room:moveCardTo(card,ssx,sgs.Player_PlaceEquip,true)
					elseif card:isKindOf("OffensiveHorse") and not ssx:getOffensiveHorse() then
						room:moveCardTo(card,ssx,sgs.Player_PlaceEquip,true)
					elseif card:isKindOf("DefensiveHorse") and not ssx:getDefensiveHorse() then
						room:moveCardTo(card,ssx,sgs.Player_PlaceEquip,true)
					else
						room:moveCardTo(card,ssx,sgs.Player_PlaceHand,false)
					end	
				end
			end
		elseif event==sgs.DrawNCards and player:hasSkill(self:objectName()) then
			local x=player:getEquips():length()
			if x>0 then
				local log=sgs.LogMessage()
				log.from=player
				log.arg=x
				log.type="#jiwu"
				room:sendLog(log)
				data:setValue(x+data:toInt())
				return
			end	
		end
	end,	
}

jihun_card=sgs.CreateSkillCard{
	name="jihun_card",
	will_throw=false,
	target_fixed=false,
	filter=function(self,targets,to_select)
		local card=sgs.Sanguosha:getCard(self:getEffectiveId())
		local slash
		if card:isRed() then slash=sgs.Sanguosha:cloneCard("fire_slash",card:getSuit(),card:getNumber()) else slash=sgs.Sanguosha:cloneCard("thunder_slash",card:getSuit(),card:getNumber()) end
		return #targets<3 and sgs.Self:canSlash(to_select,slash,false)
	end,
	on_use=function(self,room,source,targets)
		local card=sgs.Sanguosha:getCard(self:getEffectiveId())
		local slash
		if card:isRed() then slash=sgs.Sanguosha:cloneCard("fire_slash",card:getSuit(),card:getNumber()) else slash=sgs.Sanguosha:cloneCard("thunder_slash",card:getSuit(),card:getNumber()) end
		slash:setSkillName("jihun")
		slash:addSubcard(card:getId())
		local use=sgs.CardUseStruct()
		use.card=slash
		use.from=source
		for _,target in ipairs(targets) do
			use.to:append(target)
		end
		room:useCard(use,true)
	end,
}

jihunpattern=""
jihun=sgs.CreateViewAsSkill{
	name="jihun",
	n=1,
	view_filter=function(self,selected,to_select)
		if jihunpattern=="slash+peach" then return to_select:isKindOf("Weapon") or to_select:isKindOf("DefensiveHorse") end
		if jihunpattern=="slash" or jihunpattern=="turnslash" then return to_select:isKindOf("Weapon") end
		if jihunpattern=="peach" then return to_select:isKindOf("DefensiveHorse") end
		if jihunpattern=="jink" then return to_select:isKindOf("Armor") end
		if jihunpattern=="nullification" then return to_select:isKindOf("OffensiveHorse") end
	end,
	view_as=function(self,cards)
		if #cards==1 then
			local acard
			if (jihunpattern=="slash+peach" or jihunpattern=="turnslash") and cards[1]:isKindOf("Weapon") then
				if not sgs.Self:getWeapon() or cards[1]:getId()==sgs.Self:getWeapon():getId() then
					acard=jihun_card:clone()
				else
					acard=sgs.Sanguosha:cloneCard("slash",cards[1]:getSuit(),cards[1]:getNumber())
				end	
			elseif jihunpattern=="slash+peach" and cards[1]:isKindOf("DefensiveHorse") then
				acard=sgs.Sanguosha:cloneCard("peach",cards[1]:getSuit(),cards[1]:getNumber())
			else
				acard=sgs.Sanguosha:cloneCard(jihunpattern,cards[1]:getSuit(),cards[1]:getNumber())
			end
			acard:addSubcard(cards[1]:getId())
			acard:setSkillName("jihun")
			return acard
		end
	end,
	enabled_at_play=function()
		if (sgs.Self:canSlashWithoutCrossbow() or ((sgs.Self:getWeapon()) and (sgs.Self:getWeapon():getClassName()=="Crossbow"))) and sgs.Self:isWounded() then
			jihunpattern="slash+peach"
			return true
		elseif sgs.Self:canSlashWithoutCrossbow() or ((sgs.Self:getWeapon()) and (sgs.Self:getWeapon():getClassName()=="Crossbow")) then
			jihunpattern="turnslash"
			return true
		elseif sgs.Self:isWounded() then
			jihunpattern="peach"
			return true
		end
		return false
	end,
	enabled_at_response=function(self,player,pattern)
		if  (pattern=="nullification") or (pattern=="jink") or (pattern=="slash") or (pattern=="peach")then 
			jihunpattern = pattern
			return true
		end
		if (pattern=="peach+analeptic") then
			jihunpattern="peach"
			return true
		end
		return false
	end,
	enabled_at_nullification=function(self,player)
		if player:getOffensiveHorse() then return true end
		for _,card in sgs.qlist(player:getHandcards()) do
			if card:isKindOf("OffensiveHorse") or card:isKindOf("Nullification") then return true end
		end	
		return false
	end,
}

xunzhan=sgs.CreateTriggerSkill{
	name="xunzhan",
	events=sgs.CardFinished,
	frequency=sgs.Skill_Frequent,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local ssx=room:findPlayerBySkillName(self:objectName())
		if not ssx or ssx:isKongcheng() then return end
		if ssx:objectName()==player:objectName() then return end
		local use=data:toCardUse()
		local hasbasic=false
		for _,cd in sgs.qlist(ssx:getHandcards()) do
			if cd:isKindOf("BasicCard") then hasbasic=true end
		end
		if not use.card:isKindOf("EquipCard")or not hasbasic or not room:askForSkillInvoke(ssx,self:objectName(),data) or not room:getCardPlace(use.card:getEffectiveId())==sgs.Player_PlaceEquip then return false end
		local card=room:askForCard(ssx,"BasicCard|.|.|.|.","@xunzhan:"..player:objectName(),data,sgs.Card_MethodNone,player)
		if card then
			room:moveCardTo(card,player,sgs.Player_PlaceHand,true)
			local players=sgs.SPlayerList()
			local slash=sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if player:canSlash(p) then players:append(p) end
			end
			local choice="draw"
			if not players:isEmpty() then
				choice=room:askForChoice(player,self:objectName(),"draw+slash")
			end
			if choice=="draw" then
				room:broadcastSkillInvoke(self:objectName(),2)
				player:drawCards(1)
			else
				room:broadcastSkillInvoke(self:objectName(),1)
				local target=room:askForPlayerChosen(ssx,players,self:objectName())
				local slash=sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
				local use=sgs.CardUseStruct()
				use.card=slash
				use.from=player
				use.to:append(target)
				room:useCard(use,false)
			end
			if use.card:isKindOf("Weapon") and not ssx:getWeapon() then
				room:moveCardTo(use.card,ssx,sgs.Player_PlaceEquip,false)
			elseif use.card:isKindOf("Armor") and not ssx:getArmor() then	
				room:moveCardTo(use.card,ssx,sgs.Player_PlaceEquip,false)
			elseif use.card:isKindOf("OffensiveHorse") and not ssx:getOffensiveHorse() then
				room:moveCardTo(use.card,ssx,sgs.Player_PlaceEquip,false)
			elseif use.card:isKindOf("DefensiveHorse") and not ssx:getDefensiveHorse() then
				room:moveCardTo(use.card,ssx,sgs.Player_PlaceEquip,false)
			else
				room:moveCardTo(use.card,ssx,sgs.Player_PlaceHand,false)
			end	
		end
	end,
}

ronggui_card=sgs.CreateSkillCard{
	name="ronggui_card",
	will_throw=false,
	target_fixed=false,
	filter=function(self,targets,to_select)
		return #targets<1 and not to_select:hasFlag("rongguiused")
	end,
	on_use=function(self,room,source,targets)
		local target=targets[1]
		local usecard=sgs.Sanguosha:getCard(self:getEffectiveId())
		local card
		if usecard:isKindOf("Weapon") and target:getWeapon() then
			card=target:getWeapon()
		elseif usecard:isKindOf("Armor") and target:getArmor() then
			card=target:getArmor()
		elseif usecard:isKindOf("OffensiveHorse") and target:getOffensiveHorse() then
			card=target:getOffensiveHorse()
		elseif usecard:isKindOf("DefensiveHorse") and target:getDefensiveHorse() then
			card=target:getDefensiveHorse()
		end
		if card then
			room:setPlayerFlag(target,"rongguiused")
			room:moveCardTo(card,source,sgs.Player_PlaceHand,true)
			room:moveCardTo(usecard,target,sgs.Player_PlaceEquip,true)
		else
			room:moveCardTo(usecard,target,sgs.Player_PlaceEquip,true)
			if source:objectName()~=target:objectName() then
				if target:isKongcheng() or room:askForChoice(source,"ronggui","draw+discard")=="draw" then
					source:drawCards(1)	
				else
					local id=room:askForCardChosen(source,target,"h","xinyan")
					room:throwCard(id,target,source)
				end	
			end
		end
	end,
}

ronggui_vs=sgs.CreateViewAsSkill{
	name="ronggui",
	n=1,
	view_filter=function(self,selected,to_select)
		return to_select:isKindOf("EquipCard") and not to_select:isEquipped()
	end,
	view_as=function(self,cards)
		if #cards==1 then
			local acard=ronggui_card:clone()
			acard:setSkillName("ronggui")
			acard:addSubcard(cards[1]:getId())
			return acard
		end
	end,
}

ronggui=sgs.CreateTriggerSkill{
	name="ronggui",
	events=sgs.EventPhaseEnd,
	view_as_skill=ronggui_vs,	
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if player:getPhase()==sgs.Player_Play then
			for _,p in sgs.qlist(room:getAllPlayers()) do
				room:setPlayerFlag(p,"-rongguiused")
			end
		end
	end,
}

shensunshangxiang:addSkill(jiwu_max)
shensunshangxiang:addSkill(jiwu)
shensunshangxiang:addSkill(jihun)
shensunshangxiang:addSkill(xunzhan)
shensunshangxiang:addSkill(ronggui)

sgs.LoadTranslationTable{
	["shensunshangxiang"]="神孙尚香",
	["#shensunshangxiang"]="尚武的战姬",
	["~shensunshangxiang"]="还不可以死在这里",
	["jiwu"]="集武",
	[":jiwu"]="每当一张不属于你的装备牌进入弃牌堆，你可以获得之(若你没有装备对应的装备则自动装备)。你的手牌上限始终+x，摸牌阶段多摸x张牌，x为你装备区的牌数",
	["#jiwu"]="%from的【集武】触发，多摸了%arg张牌",
	["$jiwu1"]="装备还是越多越好",
	["$jiwu2"]="人家没有收集癖哦",
	["jihun_card"]="姬魂",
	["jihun"]="姬魂",
	[":jihun"]="你可以把一张装备牌按如下规则打出：武器牌:杀，若你没有装备武器(或者使用已装备的武器牌)，则该杀无限距离，可以额外指定两个目标，并且被视为火杀（红色）/雷杀（黑色）；防具：闪；进攻马：无懈可击；防御马：桃",
	["$jihun1"]="你们挡不住我的",
	["$jihun2"]="没什么好怕的啦",
	["xunzhan"]="迅战",
	[":xunzhan"]="每当其他角色装备了一张装备牌，你可以交给其一张基础牌。然后其可以做出一次选择：视为对其攻击范围内你指定的1名角色使用了1张杀；或者其摸1张牌。然后你获得此装备牌(若你没有装备对应的装备则自动装备)",
	["@xunzhan"]="你可以用一张基础牌发动迅战获得%src刚刚使用的装备牌",
	["$xunzhan1"]="速战速决",
	["$xunzhan2"]="没办法先休息会吧",
	["ronggui"]="戎闺",
	["ronggui_card"]="戎闺",
	[":ronggui"]="出牌阶段，你可以将一张手牌中的装备牌置于任意角色的装备区，若该角色装备区相同位置已有装备则替换原先的装备牌，你收回原先的装备牌并且该阶段不能再对其使用【戎闺】；若该角色装备区相同位置没有装备且该角色不为你，你可以选择以下一项摸1张牌；或弃置其一张手牌。",
	["rglose"]="自己失去1点体力",
	["rgdraw"]="令对方摸1张牌",
	["cv:shensunshangxiang"]="Nutari",
	["designer:shensunshangxiang"]="Nutari",	
}

shenyuji=sgs.General(extension,"shenyuji","god","3",true,true)

chushi=sgs.CreateTriggerSkill{
	name="chushi",
	frequency=sgs.Skill_Compulsory,
	priority=3,
	events={sgs.Predamage,sgs.DamageInflicted},
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local damage=data:toDamage()
		if event==sgs.Predamage then
			player:drawCards(damage.damage)
			room:askForDiscard(player,self:objectName(),damage.damage,damage.damage)
			room:loseHp(damage.to,damage.damage)
			return true
		end
		if event==sgs.DamageInflicted then
			if player:getHandcardNum()<=damage.damage then
				player:throwAllHandCards()
			else
				room:askForDiscard(player,self:objectName(),damage.damage,damage.damage)
			end
			player:drawCards(damage.damage)
			room:loseHp(player,damage.damage)
			return true
		end
	end,
}

huozhongpattern=""
huozhong_vs=sgs.CreateViewAsSkill{
	name="huozhong",
	n=1,
	view_filter=function(self,selected,to_select)
		return to_select:getSuit()==sgs.Card_Spade and not to_select:isEquipped()
	end,
	view_as=function(self,cards)
		if #cards==1 then
			local acard=sgs.Sanguosha:cloneCard(huozhongpattern,cards[1]:getSuit(),cards[1]:getNumber())
			acard:addSubcard(cards[1]:getId())
			acard:setSkillName("huozhong")
			return acard
		end
	end,
	enabled_at_play=function()
		huozhongpattern="AmazingGrace"
		return true
	end,
	enabled_at_response=function(self,player,pattern)
		if pattern=="nullification" then
			huozhongpattern="nullification"
			return true
		end	
	end,
	enabled_at_nullification=function(self,player)
		for _,card in sgs.qlist(player:getHandcards()) do
			if card:getSuit()==sgs.Card_Spade or card:isKindOf("Nullification") then return true end
		end	
		return false
	end	
}	

huozhong=sgs.CreateTriggerSkill{
	name="huozhong",
	frequency=sgs.Skill_NotFrequent,
	priority=-2,
	events={sgs.CardsMoveOneTime},
	view_as_skill=huozhong_vs,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local yuji=room:findPlayerBySkillName("huozhong")
		if not yuji then return end
		if event==sgs.CardsMoveOneTime then
			local move=data:toMoveOneTime()
			if move.from:objectName()~=player:objectName() or player:objectName()==yuji:objectName() then return end
			if move.to_place~=sgs.Player_DiscardPile then return end
			for _,id in sgs.qlist(move.card_ids) do
				local card=sgs.Sanguosha:getCard(id)
				if card:getSuit()==sgs.Card_Spade then
					room:moveCardTo(card,yuji,sgs.Player_PlaceHand,false)
				end
			end
		end
	end,
}

cardSameColor=function(card1,card2)
	if card1:isRed() and card2:isRed() then return true end
	if card1:isBlack() and card2:isBlack() then return true end
	return false
end	

guiji=sgs.CreateTriggerSkill{
	name="guiji",
	events=sgs.FinishJudge,
	priority=2,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local yuji=room:findPlayerBySkillName(self:objectName())
		if not yuji then return end
		local judge=data:toJudge()
		if judge.card:isBlack() then
			if not player:isNude() and room:askForSkillInvoke(yuji,self:objectName()) then
				local id=room:askForCardChosen(yuji,player,"he",self:objectName())
				room:moveCardTo(sgs.Sanguosha:getCard(id),yuji,sgs.Player_PlaceHand,false)
			end
		end
	end,
}	

wangui_card=sgs.CreateSkillCard{
	name="wangui_card",
	will_throw=false,
	target_fixed=true,
	on_use=function(self,room,source,targets)
		source:loseMark("@haunted")
		source:turnOver()
		for _,card in sgs.qlist(source:getHandcards()) do
			source:addToPile("haunted",card,false)
		end
	end,
}	

wangui_vs=sgs.CreateViewAsSkill{
	name="wangui",
	n=0,
	view_as=function()
		return wangui_card:clone()
	end,
	enabled_at_play=function()
		return sgs.Self:getMark("@haunted")>0 and sgs.Self:getHandcardNum()>sgs.Self:aliveCount()
	end,
}

wangui=sgs.CreateTriggerSkill{
	name="wangui",
	frequency=sgs.Skill_Limited,
	view_as_skill=wangui_vs,
	events={sgs.GameStart,sgs.TurnStart,sgs.DamageForseen},
	priority=4,
	can_trigger=function()
		return true
	end,	
	on_trigger=function(self,event,player,data)
		if event==sgs.GameStart and player:hasSkill("wangui") then player:gainMark("@haunted") end
		local room=player:getRoom()
		local yuji=room:findPlayerBySkillName(self:objectName())
		if event==sgs.TurnStart and not yuji:getPile("haunted"):isEmpty() then
			if player:objectName()==yuji:objectName() then
				return true
			else
				if not room:askForSkillInvoke(yuji,"wangui",data) then return end
				local id=yuji:getPile("haunted"):first()
				room:throwCard(id,yuji)
				room:loseHp(player)
			end
		end
	end,
}

shenyuji:addSkill(chushi)
shenyuji:addSkill(huozhong)
shenyuji:addSkill(guiji)
shenyuji:addSkill(wangui)

sgs.LoadTranslationTable{
	["shenyuji"]="神于吉",
	["#shenyuji"]="乱世的妖鬼",
	["~shenyuji"]="呵呵，老身之死，于乱世无妨",
	["chushi"]="出世",
	[":chushi"]="<b>锁定技</b>，每当你即将造成一次伤害，你从牌堆摸X张牌并防止该伤害，然后你弃置X张手牌，令目标失去X点体力。每当你即将受到一次伤害，你弃置X张手牌（不足全弃）防止该伤害，然后从牌堆摸X张牌并失去X点体力。X为伤害量",
	["huozhong"]="惑众",
	[":huozhong"]="你可以把黑桃手牌当作五谷丰登和无懈可击来使用，你收回其他角色进入弃牌堆的黑桃牌",
	["guiji"]="鬼计",
	[":guiji"]="每当任何角色判定牌为黑色时，你可以获得其一张牌",
	["haunted"]="鬼影",
	["@haunted"]="鬼影",
	["wangui_card"]="万鬼",
	["wangui"]="万鬼",
	[":wangui"]="<b>限定技</b>，出牌阶段，若你的手牌数大于场上存活人数，你可以将全部的手牌置于你的武将牌上称为“鬼影”并将武将翻面。此后除你以外的角色回合开始前，你可以弃置1张鬼影令其失去1点体力，直至鬼影全部耗尽，此期间你跳过你的回合。",
	["designer:shenyuji"]="Nutari",
}
