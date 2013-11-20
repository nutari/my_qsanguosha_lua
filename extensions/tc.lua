module("extensions.tc",package.seeall)
extension=sgs.Package("tc")

--衫崎键

TC001=sgs.General(extension, "$TC001", "god", "5", true)

shenshang=sgs.CreateTriggerSkill{
	name="shenshang",
	events={sgs.DamageDone,sgs.Damage},
	priority=4,
	frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local damage=data:toDamage()
		local log=sgs.LogMessage()
		log.from=player
		if event==sgs.DamageDone and damage.to:hasSkill(self:objectName()) and damage.from:isMale() then
			log.type="#shenshanga"
			log.to:append(damage.from)
			room:sendLog(log)
			room:loseHp(damage.from)
			return false
		end
		if event==sgs.Damage and damage.from:hasSkill(self:objectName()) and not damage.from:isKongcheng() and damage.to:isFemale() and not damage.from:hasFlag("baozouused") then
			log.type="#shenshangb"
			log.to:append(damage.to)
			room:sendLog(log)
			room:askForDiscard(player,"shenshang",1,1,false)
			return false
		end
	end	,
}

hougong_max=sgs.CreateMaxCardsSkill{
	name="#hougong_max",
	extra_func=function(self,player)
		if player:hasSkill("hougong") then
			local x=0
			if player:isFemale() then x=x+1 end
			for _,p in sgs.qlist(player:getSiblings()) do
				if p:isFemale() and p:isAlive() then x=x+1 end
			end
			return x*2
		end
	end,
}

hougong=sgs.CreateTriggerSkill{
	name="hougong",
	events={sgs.DrawNCards,sgs.EventPhaseStart,sgs.CardEffected,sgs.CardFinished,sgs.CardAsked,sgs.PreHpRecover},
	priority=3,
	frequency=sgs.Skill_Compulsory,
	can_trigger = function(self, player)
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.DrawNCards and player:hasSkill(self:objectName()) then
			local room=player:getRoom()
			local x=data:toInt()
			local i=0
			local players=room:getAllPlayers()
			for _,p in sgs.qlist(players) do
				if p:isFemale() then i=i+1 end
			end
			if i>0 then
				local log=sgs.LogMessage()
				log.from=player
				log.arg=i
				log.type="#hougongm"
				room:sendLog(log)
			end
			data:setValue(i+x)
		end
		if event==sgs.CardEffected then
			local effect=data:toCardEffect()
			if effect.card:isKindOf("Slash") and effect.from:isFemale() and effect.to:hasSkill(self:objectName()) then
				local value=sgs.QVariant()
				value:setValue(effect.from)
				room:setTag("hougongsource",value)
				value:setValue(effect.to)
				room:setTag("hougongtarget",value)
			end	
		end
		if event==sgs.CardFinished then
			room:removeTag("hougongsource")
			room:removeTag("hougongtarget")
		end			
		if event==sgs.CardAsked then
			local pattern=data:toString()
			if player:hasFlag("hougong") or pattern~="jink" then return end
			local hougongsource=room:getTag("hougongsource"):toPlayer()
			local hougongtarget=room:getTag("hougongtarget"):toPlayer()
			if not hougongtarget or hougongtarget:objectName()~=player:objectName() then return end
			room:setPlayerFlag(player,"hougong")
			local jink=room:askForCard(player,"jink","@hougong-jink1:"..player:objectName(),data,sgs.Card_MethodUse,hougongsource)
			if jink then
				room:setPlayerFlag(player,"-hougong")
				return false
			else
				room:provide(nil)
				room:setPlayerFlag(player,"-hougong")
				return true
			end
		elseif event==sgs.PreHpRecover and player:hasSkill(self:objectName()) then
			local rec=data:toRecover()
			if rec.who:isFemale() then
				local log=sgs.LogMessage()
				log.from=player
				log.type="#hougongr"
				room:sendLog(log)
				rec.recover=rec.recover+1
			end
			data:setValue(rec)
			return false
		end
	end,
}

yuhuo_card=sgs.CreateSkillCard{
	name="yuhuo_card",
	target_fixed =false,
	will_throw=false,
	filter=function(self,targets,to_select,player)
		if #targets>2 and player:hasFlag("baozouused") then return false end
		if #targets>1 and not player:hasFlag("baozouused") then return false end
		if #targets>0 and player:getHp()>2 and not player:hasFlag("baozouused") then return false end
		return sgs.Self:inMyAttackRange(to_select) or player:hasFlag("baozouused")
	end,
	on_use=function(self,room,source,targets)
        local damage=sgs.DamageStruct()
        room:setPlayerFlag(source,"yuhuoused")
		if not source:hasFlag("baozouused") then
			room:loseHp(source,1)
		end
		damage.nature=sgs.DamageStruct_Fire
		damage.from=source
		for i=1,#targets,1 do
			if targets[i] then
				damage.damage=1
				damage.to=targets[i]
				room:damage(damage)
			end
		end
	end,
}

yuhuo_vs=sgs.CreateViewAsSkill{
	name="yuhuo",
	n=0,
	view_as=function()
		local acard=yuhuo_card:clone()
		return acard
	end,
	enabled_at_play=function(self,player)
		return not player:hasFlag("yuhuoused")
	end,
}

yuhuo=sgs.CreateTriggerSkill{
	name="yuhuo",
	view_as_skill=yuhuo_vs,
	events=sgs.EventPhaseEnd,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if player:getPhase()==sgs.Player_Play then
			room:setPlayerFlag(player,"-yuhuoused")
		end
	end,
}

baozou_card=sgs.CreateSkillCard{
	name="baozou_card",
	target_fixed=true,
	will_throw=true,
	filter=function()
		return false
	end,
	on_use=function(self,room,source,targets)
		room=source:getRoom()
		local recover=sgs.RecoverStruct()
		recover.who=source
		recover.recover=source:getMark("@baozou")
		source:loseAllMarks("@baozou")
		room:recover(source,recover)
		room:acquireSkill(source,"wushuang")
		room:acquireSkill(source,"paoxiao")
		room:setPlayerFlag(source,"tianyi_success")
		room:setPlayerFlag(source,"baozouused")
	end,
}

baozou_vs=sgs.CreateViewAsSkill{
	name="baozou",
	n=0,
	view_as=function()
		return baozou_card:clone()
 	end,
	enabled_at_play=function(self,player)
		if sgs.Self:getMark("@baozou")>1 and not player:hasFlag("baozouused") then return true end
	end
}

baozou=sgs.CreateTriggerSkill{
	name="baozou",
	view_as_skill=baozou_vs,
	events={sgs.EventPhaseEnd,sgs.Dying},
	priority=3,
	can_trigger=function(self,player)
		return player:hasSkill("baozou")
	end,	
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local damage=data:toDamage()
		if event==sgs.Dying and data:toDying().who:hasSkill(self:objectName()) then
			data:toDying().who:gainMark("@baozou",1)
		end
		if event==sgs.EventPhaseEnd and player:getPhase()==sgs.Player_Play and player:hasFlag("baozouused") then
			room:detachSkillFromPlayer(player,"wushuang")
			room:detachSkillFromPlayer(player,"paoxiao")
			room:setPlayerFlag(player,"-tianyi_success")
			room:setPlayerFlag(player,"-baozouused")
		end
	end
}

siji=sgs.CreateTriggerSkill{
	name="siji$",
	events={sgs.GameStart,sgs.BuryVictim},
	priority=4,
	frequency=sgs.Skill_Compulsory,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.GameStart then
			if not player:hasLordSkill(self:objectName()) then return false end
			local x=0
			local kurimu = room:findPlayerBySkillName("renxing")
			if kurimu then
				x=x+1
				room:acquireSkill(player,"renxing")
			end
			local chituru=room:findPlayerBySkillName("S")
			if chituru then
				x=x+1
				room:acquireSkill(player,"S")
			end
			local minatu=room:findPlayerBySkillName("rexue")
			if minatu then
				x=x+1
				room:acquireSkill(player,"rexue")
			end
			local mafuyu=room:findPlayerBySkillName("zhai")
			if mafuyu then
				x=x+1
				room:acquireSkill(player,"zhai")
			end
			if x>0 then room:loseMaxHp(player,x) end
		end
		local ken=room:findPlayerBySkillName(self:objectName())
		if not ken or not ken:hasLordSkill(self:objectName()) then return false end
		if event==sgs.BuryVictim then
			if (player:hasSkill("renxing") or player:hasSkill("mingli"))and not player:hasSkill(self:objectName()) then
				room:detachSkillFromPlayer(ken,"renxing")
			end
			if player:hasSkill("S") and not player:hasSkill(self:objectName()) then
				room:detachSkillFromPlayer(ken,"S")
			end
			if player:hasSkill("rexue") and not player:hasSkill(self:objectName()) then
				room:detachSkillFromPlayer(ken,"rexue")
			end
			if player:hasSkill("zhai") and not player:hasSkill(self:objectName()) then
				room:detachSkillFromPlayer(ken,"zhai")
			end
		end
	end,
}

TC001:addSkill(baozou)
TC001:addSkill(yuhuo)
TC001:addSkill(shenshang)
TC001:addSkill(hougong)
TC001:addSkill(hougong_max)
TC001:addSkill(siji)

sgs.LoadTranslationTable{
	["TC001"]="杉崎鍵",
	["#TC001"]="ハレム王",
	["~TC001"]="我美丽的后宫之梦，再也不会回来了",
	["baozou_card"]="暴走",
	["baozou_vs"]="暴走",
	["baozou"]="暴走",
	["@baozou"]="暴走",
	[":baozou"]="每当你进入濒死状态时，你获得1枚暴走印记。出牌阶段你可以弃置全部的暴走印记（至少2枚），恢复等量的体力并使自己处于暴走状态。暴走状态时，你获得无双和咆哮，你的杀可以指定一个额外目标并且不限距离，持续到回合结束。一阶段限用一次。",
	["yuhuo_card"]="浴火",
	["yuhuo"]="浴火",
	[":yuhuo"]="出牌阶段，你可以自减1点体力（暴走状态不减少），对你攻击范围内（暴走状态不限）的1个角色各造成1点火焰伤害，当你体力不高于3时，可以额外指定一个目标（若处于暴走状态，则无视当前体力可以指定2个额外的目标）。一回合限一次。",
	["shenshang"]="神伤",
	[":shenshang"]="<b>锁定技</b>，男性角色对你造成伤害前，其失去1点体力。你对女性角色造成伤害后，你弃置1张手牌（没有不弃）",
	["#shenshanga"]="%from的【神伤】被触发",
	["#shenshangb"]="因对%to造成伤害，%from的【神伤】被触发",
	["hougong"]="后宫",
	[":hougong"]="<b>锁定技</b>，你摸牌阶段多摸X张牌，你的手牌上限始终+X*2，x为场上女性角色数。女性角色对你使用的杀需要2张闪来抵消，女性角色使你恢复体力时额外恢复1点体力",
	["#hougongm"]="%from的【后宫】被触发，多摸了%arg张牌",
	["#hougong"]="【后宫】被触发，%from需要连续打出2张闪",
	["#hougongr"]="【后宫】被触发，%from额外恢复了1点体力",
	["#hougongd"]="%from的【后宫】被触发，需弃置%arg张牌",
	["@hougong-jink1"]="%src的【后宫】被触发，请先打出1张闪",
	["@hougong-jink2"]="%src的【后宫】被触发，请再打出1张闪",
	["siji"]="四季",
	[":siji"]="<b>主公技</b>，<b>锁定技</b>，游戏开始时，当桜野くりむ、紅葉知弦、椎名深夏、椎名真冬中任意人在场，你可以分别获得在场的角色的一个技能(任性，S，热血和宅)，然后你失去等同与4人中在场的人数的体力上限。当其中某人死去时，你丧失对应技能",
	["designer:TC001"]="Nutari",
	["illustrator:TC001"]="狗神煌",
}

--桜野くりむ

TC002 = sgs.General(extension, "TC002", "god", "3", false)

renxingpattern=""
renxing_card=sgs.CreateSkillCard{
	name="renxing_card",
	target_fixed=true,
	on_use=function(self,room,source)
		local idlist=sgs.IntList()
		for _,id in sgs.qlist(source:getPile("renxing")) do
			local card=sgs.Sanguosha:getCard(id)
			if card:isNDTrick() and not card:isKindOf("Nullification") then idlist:append(id) end
			if card:isKindOf("Peach") and source:isWounded() then idlist:append(id) end
		end
		if idlist:isEmpty() then return end
		room:fillAG(idlist,source)
		local id=room:askForAG(source,idlist,false,self:objectName())
		source:invoke("clearAG")
		if id~=-1 then
			local card=sgs.Sanguosha:getCard(id)
			room:setCardFlag(id,"renxing",source)
			room:setPlayerFlag(source,"renxinguse")
			if card:isKindOf("IronChain") and source:isCardLimited(card,sgs.Card_MethodUse) then
				local use=sgs.CardUseStruct()
				use.card=card
				use.from=source
				room:useCard(use)
			else
				room:askForUseCard(source,"@@renxing","@renxing:"..card:objectName())
			end	
			room:setPlayerFlag(source,"-renxinguse")
			renxingpattern=""
		end
	end
}

renxing=sgs.CreateViewAsSkill{
	name="renxing",
	view_as=function()
		if not sgs.Self:hasFlag("renxinguse") and renxingpattern=="" then
			return renxing_card:clone()
		else
			for _,id in sgs.qlist(sgs.Self:getPile("renxing")) do
				local card=sgs.Sanguosha:getCard(id)
				if card:hasFlag("renxing") or card:objectName()==renxingpattern then
					card:setSkillName("renxing")
					return card
				end
			end		
		end
	end,
	enabled_at_play=function(self,player)
		renxingpattern=""
		if player:getPile("renxing"):isEmpty() then return false end
		for _,id in sgs.qlist(player:getPile("renxing")) do
			local card=sgs.Sanguosha:getCard(id)
			if card:isNDTrick() and not card:isKindOf("Nullification") then return true end
			if card:isKindOf("Peach") and player:isWounded() then return true end
		end
		return false
	end,
	enabled_at_response=function(self,player,pattern)
		if player:getPile("renxing"):isEmpty() then return false end
		for _,id in sgs.qlist(player:getPile("renxing")) do
			local card=sgs.Sanguosha:getCard(id)
			if pattern=="nullification" and card:isKindOf("Nullification") then renxingpattern="nullification" return true end
			if string.find(pattern,"peach") and card:isKindOf("Peach") then renxingpattern="peach" return true end
		end
		return false
	end,
	enabled_at_nullification=function(self,player)
		if player:getPile("renxing"):isEmpty() then return false end
		for _,id in sgs.qlist(player:getPile("renxing")) do
			local card=sgs.Sanguosha:getCard(id)
			if card:isKindOf("Nullification") then return true end
		end
		return false
	end,
}	

renxing_tr=sgs.CreateTriggerSkill{
    name="#renxing_tr",
	events={sgs.PreCardUsed,sgs.CardUsed,sgs.CardsMoveOneTime,sgs.EventLoseSkill},
	priority=3,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.EventLoseSkill and data:toString()=="renxing" then
			player:removePileByName("renxing")
		end	
		if not player:hasSkill("renxing") then return end
		if event==sgs.PreCardUsed then
			local use=data:toCardUse()
			local card=use.card			
			if card:isKindOf("Peach") or card:isNDTrick() then
				if room:getCardPlace(card:getEffectiveId())==sgs.Player_PlaceSpecial then
					room:setCardFlag(card:getEffectiveId(),"renxing")
				end
			end
		end	
		if event==sgs.CardUsed then
			local use=data:toCardUse()
			local card=use.card			
			if card:isKindOf("Slash") then
				for _,p in sgs.qlist(use.to) do
					p:addMark("qinggang")
				end
				return false
			end
		end
		if event==sgs.CardsMoveOneTime then
			local move=data:toMoveOneTime()
			if move.reason.m_reason~=sgs.CardMoveReason_S_REASON_USE and move.reason.m_reason~=sgs.CardMoveReason_S_REASON_RECAST and move.reason.m_reason~=sgs.CardMoveReason_S_REASON_RESPONSE  then return end
			if move.from_places:contains(sgs.Player_PlaceSpecial) then return end
			if move.from:objectName()~=player:objectName() or not move.from:hasSkill("renxing") then return end
			if move.card_ids:isEmpty() or move.to_place~=sgs.Player_DiscardPile then return end
			for _,id in sgs.qlist(move.card_ids) do
				local card=sgs.Sanguosha:getCard(id)
				if (card:isKindOf("Peach") or card:isNDTrick()) and not card:hasFlag("renxing")  then
					local log=sgs.LogMessage()
					log.from=player
					log.arg=card:objectName()
					log.type="#renxing"
					room:sendLog(log)
					player:addToPile("renxing",card)
				end
			end
		end
	end,
}

mengwu_max=sgs.CreateMaxCardsSkill{
	name="#mengwu_max",
	extra_func=function(self,player)
		if player:hasSkill("mengwu") then
			return player:getLostHp()+player:aliveCount()
		end
	end,
}

mengwu_card=sgs.CreateSkillCard{
	name="mengwu_card",
	will_throw=false,
	filter=function(self,targets,to_select)
		if #targets>0 then return false end
		if sgs.Self:getMark("chengzhang")>0 then return to_select:objectName()~=sgs.Self:objectName() end
		local x=100
		for _,p in sgs.qlist(sgs.Self:getSiblings()) do
			if p:isAlive() and p:getHandcardNum()<x then x=p:getHandcardNum() end
		end
		return to_select:getHandcardNum()==x and sgs.Self:objectName()~=to_select:objectName()
	end,
	feasible=function(self,targets)
		return #targets>=0
	end,	
	on_use=function(self,room,source,targets)
		if #targets==0 then
			room:throwCard(self,source)
		else
			room:moveCardTo(self,targets[1],sgs.Player_PlaceHand,false)
		end
	end,
}

mengwu_hp_card=sgs.CreateSkillCard{
	name="mengwu_hp_card",
	filter=function(self,targets,to_select,player)
		return sgs.Self:distanceTo(to_select)<=1 and sgs.Self:objectName()~=to_select:objectName() and #targets<player:getMark("mengwu")
	end,
	feasible=function(self,targets)
		return #targets>0
	end,
	on_use=function(self,room,source,targets)
		for _,target in ipairs(targets) do
			room:loseHp(target)
		end	
	end,
}

mengwu_vs=sgs.CreateViewAsSkill{
	name="mengwu",
	n=999,
	view_filter=function(self,selected,to_select)
		return #selected<math.floor((sgs.Self:getHandcardNum())/2) and not to_select:isEquipped() and not sgs.Self:hasFlag("mengwuhp")
	end,
	view_as=function(self,cards)
		if #cards==0 and sgs.Self:hasFlag("mengwuhp") then
			return mengwu_hp_card:clone()
		end	
		if #cards>=math.floor((sgs.Self:getHandcardNum())/2) then
			local acard=mengwu_card:clone()
			for i=1,#cards,1 do
				acard:addSubcard(cards[i]:getId())
			end
			return acard
		end
	end,
	enabled_at_play=function()
		return false
	end,
}

mengwu=sgs.CreateTriggerSkill{
	name="mengwu",
	events={sgs.EventPhaseStart,sgs.DamageInflicted,sgs.CardDrawing,sgs.CardsMoveOneTime},
	view_as_skill=mengwu_vs,
	priority=-1,
	frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local damage=data:toDamage()
		if event==sgs.DamageInflicted and damage.to:hasSkill(self:objectName()) then
			if damage.damage>1 then
				room:setPlayerMark(player,"mengwu",damage.damage-1)
				room:setPlayerFlag(player,"mengwuhp")
				room:askForUseCard(player,"@@mengwu","@mengwuhp",1)
				room:setPlayerFlag(player,"-mengwuhp")
				room:setPlayerMark(player,"mengwu",0)
				damage.damage=1
				data:setValue(damage)
				return false
			end
		end
		if event==sgs.CardDrawing and player:hasSkill(self:objectName()) and not player:hasFlag("mengwua") then
			local card=sgs.Sanguosha:getCard(data:toInt())
			if not card:hasFlag("mengwu") then room:setPlayerFlag(player,"mengwua") end
		end	
		if event==sgs.CardsMoveOneTime then
			local move=data:toMoveOneTime()
			if move.to and player:objectName()==move.to:objectName() and move.to:hasFlag("mengwua") then
				local log=sgs.LogMessage()
				log.from=player
				log.type="#mengwux"
				room:sendLog(log)
				room:setPlayerFlag(player,"-mengwua")
				player:drawCards(1,true,self:objectName())				
				if player:getHandcardNum()>player:getMaxCards() then
					local used=room:askForUseCard(player,"@@mengwu","#mengwudis",2)
					if not used then
						local mengwucard=mengwu_card:clone()
						for _,cd in sgs.qlist(player:getHandcards()) do
							if mengwucard:subcardsLength()<math.floor((sgs.Self:getHandcardNum())/2) then
								mengwucard:addSubcard(cd:getId())
							else
								break
							end
						end
						mengwucard:use(room,player,sgs.SPlayerList())
					end
				end
			end	
			return false
		end
	end,
}

chengzhang=sgs.CreateTriggerSkill{
	name="chengzhang",
	events=sgs.Dying,
	priority=4,
	frequency=sgs.Skill_Wake,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if data:toDying().who:getMark("chengzhang")>0 then return end
		if player:objectName()~=data:toDying().who:objectName() then return end
		data:toDying().who:gainMark("chengzhang")
		data:toDying().who:gainMark("@waked")
		local log=sgs.LogMessage()
		log.from=data:toDying().who
		log.type="#chengzhang"
		room:sendLog(log)
		local recover=sgs.RecoverStruct()
		recover.who=data:toDying().who
		recover.recover=1
		room:recover(data:toDying().who,recover)
		room:detachSkillFromPlayer(data:toDying().who,"renxing")
		room:acquireSkill(data:toDying().who,"mingli")
		return false
	end,
}

mingli=sgs.CreateTriggerSkill{
	name="mingli",
	events={sgs.CardUsed,sgs.SlashProceed,sgs.CardEffected},
	priority=2,
	frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.SlashProceed then
			local effect=data:toSlashEffect()
			if effect.slash:isRed() then
				local log=sgs.LogMessage()
				log.from=player
				log.type="#minglis"
				room:sendLog(log)
				room:slashResult(effect,nil)
				return true
			end
		end
		if event==sgs.CardEffected then
			local effect=data:toCardEffect()
			if effect.card:isKindOf("TrickCard") or effect.card:isKindOf("Analeptic") or effect.card:isKindOf("Peach") then
				local log=sgs.LogMessage()
				log.from=player
				log.type="#minglit"
				room:sendLog(log)
				player:drawCards(1)
			end
		end
	end,
}

local skill=sgs.Sanguosha:getSkill("mingli")
if not skill then
        local skillList=sgs.SkillList()
        skillList:append(mingli)
        sgs.Sanguosha:addSkills(skillList)
end

TC002:addSkill(renxing)
TC002:addSkill(renxing_tr)
TC002:addSkill(mengwu)
TC002:addSkill(mengwu_max)
TC002:addSkill(chengzhang)

sgs.LoadTranslationTable{
	["TC002"]="桜野くりむ",
	["#TC002"]="ロリ会長",
	["~TC002"]="あたしやだ",
	["renxing_card"]="任性",
	["renxing"]="任性",
	[":renxing"]="你的杀无视防具，你的【桃】和非延时锦囊在因使用/打出/重铸而进入弃牌堆时你将其置于你的武将牌上，你可以在合理的时机再次使用这些牌，但是不能再次发动此效果。当你失去“任性”的时候，将这些牌全部弃置。",
	["#renxing"]="%from的任性发动，收回了【%arg】",
	["@renxing"]="请第二次使用%src",
	["~renxing"]="对合理的目标使用",
	["mengwu"]="萌物",
	[":mengwu"]="<b>锁定技</b>，你即将受到的超过1点的伤害时，你可以选择至多x-1个你距离1以内其他角色，令其各失去1点体力，然后你防止多于1点的伤害，x为伤害量。你的手牌上限为你的体力上限加上场上的存活人数。当你从牌堆摸牌后，额外摸取1张(不能重复触发)，若此效果发动后你的手牌超过你手牌上限，你需弃置其中的一半或者将一半的牌交给场上除你以外牌最少的角色（若觉醒技成长触发，则可以交给任意一名其他角色）",
	["#mengwux"]="%from的【萌物】发动，多摸了1张牌",
	["mengwu_hp_card"]="萌物",
	["mengwu_card"]="萌物",
	["@mengwuhp"]="请选择萌物流失体力的目标",
	["~mengwu1"]="选择若干距离1以内的其他角色->点击确定",
	["#mengwudis"]="请选择要弃置或者转交的牌",
	["~mengwu2"]="选择一半的手牌->点击确定",
	["qizhi"]="弃置",
	["zhuanjiao"]="转交",
	["chengzhang"]="成长",
	[":chengzhang"]="<b>觉醒技</b>，当你第一次濒死时，你立刻恢复1点体力，然后失去【任性】，获得【明理】(<b>锁定技</b>，你的红【杀】不能被躲闪。锦囊牌，酒，桃对你生效前，你摸1张牌)",
	["#chengzhang"]="%from第一次濒死，觉醒技【成长】发动",
	["mingli"]="明理",
	[":mingli"]="<b>锁定技</b>，你的红【杀】不能被躲闪。锦囊牌，酒，桃对你生效前，你摸1张牌",
	["#minglis"]="%from的【明理】发动，红【杀】不能被躲闪",
	["#minglit"]="%from的【明理】发动",
	["designer:TC002"]="Nutari",
	["illustrator:TC002"]="狗神煌",
}

--红叶知弦

TC003 = sgs.General(extension, "TC003", "god", "3", false)

S=sgs.CreateTriggerSkill{
	name="S",
	frequency=sgs.Skill_Compulsory,
	events={sgs.Damage,sgs.CardsMoveOneTime,sgs.EventPhaseEnd},
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local damage = data:toDamage()
		local log=sgs.LogMessage()
		if event==sgs.Damage then
			log.from=player
			log.type="#S"
			log.arg=damage.damage
			room:sendLog(log)
			player:drawCards(damage.damage)
			if damage.damage>1 and damage.from:objectName()~=damage.to:objectName() then
				log.type="#SS"
				log.to:append(damage.to)
				room:sendLog(log)
				room:setPlayerProperty(player,"maxhp",sgs.QVariant(player:getMaxHp()+1))
				if damage.to:isAlive() then room:loseMaxHp(damage.to,1)end
				local recover=sgs.RecoverStruct()
				recover.who = damage.from
				recover.reason = self:objectName()
				recover.recover = 1
				room:recover(damage.from,recover)
			end
		end
		if event==sgs.CardsMoveOneTime then
			local move=data:toMoveOneTime()
			if move.to and move.to:objectName()==player:objectName() and move.from and move.from:objectName()~=player:objectName() then
				local x=move.card_ids:length()
				room:setPlayerMark(player,"S",player:getMark("S")+x)
			end	
		end
		if event==sgs.EventPhaseEnd and player:getMark("S")>0 then
			room:setPlayerMark(player,"S",0)
		end	
	end,
}

Starget=sgs.CreateTargetModSkill{
	name="#Starget",
	residue_func=function(self,from,card)
		if from:hasSkill("S") then
			return from:getMark("S")
		end
	end,
}

hei=sgs.CreateProhibitSkill{
	name="hei",
	is_prohibited=function(self,from,to,card)
		if to:hasSkill("hei") then
			return card:isBlack() and (card:isKindOf("Slash") or card:isKindOf("TrickCard"))
		end
	end,
}

hei_tr=sgs.CreateTriggerSkill{
	name="#hei_tr",
	events={sgs.EventAcquireSkill,sgs.EventLoseSkill,sgs.FinishJudge},
	frequency=sgs.Skill_Compulsory,
	priority=2,
	can_trigger=function(self,player)
		return player:hasSkill("hei")
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.FinishJudge then
			local judge=data:toJudge()
			if not judge.who:hasSkill("hei") then return end
			if judge.card:isBlack() then
				judge.who:drawCards(2)
			end	
		end
	end,
}

kanchuan=sgs.CreateTriggerSkill{
	name="kanchuan",
	events={sgs.TurnedOver,sgs.EventPhaseStart},
	frequency=sgs.Skill_Compulsory,
	priority=2,
 	on_trigger=function(self,event,player,data)
        local room=player:getRoom()
		local log=sgs.LogMessage()
		log.from=player
		if event==sgs.TurnedOver and player:hasSkill(self:objectName()) and not player:faceUp() then
			log.type="#kanchuanx"
			room:sendLog(log)
			player:turnOver()
		end
		if event==sgs.EventPhaseStart and player:getPhase()==sgs.Player_Judge and player:hasSkill(self:objectName()) then
			local cards=player:getJudgingArea()
			if cards:length()>0 then
				log.type="#kanchuan"
				room:sendLog(log)
				for _,cd in sgs.qlist(cards) do
					player:obtainCard(cd)
				end
			end
		end
	end,
}

menghua=sgs.CreateTriggerSkill{
	name="menghua",
	events={sgs.EventPhaseEnd},
	priority=4,
	frequency=sgs.Skill_Wake,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if player:getHandcardNum()>player:getHp()*2 and player:getMark("menghua")==0 and player:getPhase()==sgs.Player_Play then
			local log=sgs.LogMessage()
			log.from=player
			log.arg=player:getHandcardNum()
			log.arg2=player:getHp()
			log.type="#menghua"
			room:sendLog(log)
			player:gainMark("menghua")
			player:gainMark("@waked")
			room:loseMaxHp(player,1)
			if player:isDead() then return end
			room:acquireSkill(player,"mengwu")
		end
	end
}

TC003:addSkill(S)
TC003:addSkill(Starget)
TC003:addSkill(hei)
TC003:addSkill(hei_tr)
TC003:addSkill(kanchuan)
TC003:addSkill(menghua)


sgs.LoadTranslationTable{
	["TC003"]="紅葉知弦",
	["#TC003"]="ドＳの書記",
	["~TC003"]="KEY君我先走一步了",
	["S"]="S",
	[":S"]="<b>锁定技</b>，你每造成一次伤害，摸x张牌，x为伤害量，一次性对一名其他角色造成超过1点的伤害时，其降低1点体力上限，你增加1点体力上限并回复1点体力。你在出牌阶段每获得其他角色区域内1张牌，你可以额外使用一张杀。",
	["#S"]="%from的【S】发动，摸了%arg张牌",
	["#SS"]="因为%from一次造成了2点以上的伤害，%to的体力上限减少了1，%from恢复了1点体力并增加了1点体力上限。",
	["hei"]="黑",
	[":hei"]="<b>锁定技</b>，你不能成为黑色的杀和锦囊牌的目标。你的判定牌为黑色时你摸2张牌。",
	["kanchuan"]="看穿",
	[":kanchuan"]="<b>锁定技</b>，你的武将牌被翻至背面时立刻翻回正面。你判定阶段开始时，你收回你判定区的所有牌",
	["#kanchuan"]="%from的【看穿】发动，收回了判定区的牌",
	["#kanchuanx"]="%from的【看穿】发动，将武将翻回正面",
	["menghua"]="萌化",
	[":menghua"]="<b>觉醒技</b>，若出牌阶段结束时你的手牌数超过你体力的2倍，则你减少1点体力上限并获得【萌物】。",
	["#menghua"]="%from的手牌数%arg超过了体力（%arg2）的2倍，触发了觉醒技【萌化】",
	["designer:TC003"]="Nutari",
	["illustrator:TC003"]="狗神煌",
}

--椎名深夏

TC004=sgs.General(extension,"TC004","god","4",false)

zuiqiang=sgs.CreateFilterSkill{
	name="zuiqiang",
	view_filter=function(self,to_select)
		return to_select:isKindOf("BasicCard") or to_select:isKindOf("TrickCard")
	end,
	view_as=function(self,card)
		local zuiqiangcard
		if card:isKindOf("TrickCard") then
			zuiqiangcard=sgs.Sanguosha:cloneCard("duel",card:getSuit(),card:getNumber())			
		elseif card:isKindOf("BasicCard") then
			zuiqiangcard=sgs.Sanguosha:cloneCard("fire_slash",card:getSuit(),card:getNumber())
		end
		local acard=sgs.Sanguosha:getWrappedCard(card:getId())
		acard:takeOver(zuiqiangcard)
		acard:setSkillName(self:objectName())
		return acard
	end,
}

zuiqiang_trigger=sgs.CreateTriggerSkill{
	name="#zuiqiang_trigger",
	events={sgs.CardEffected,sgs.GameStart,sgs.CardAsked,sgs.CardFinished,sgs.EventAcquireSkill,sgs.EventLoseSkill},
	priority=3.5,
	can_trigger = function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.CardEffected then
			local effect=data:toCardEffect()
			if effect.to:hasSkill("zuiqiang") and effect.card:isKindOf("Slash") then
				local card=effect.card
				local acard=sgs.Sanguosha:cloneCard("duel",card:getSuit(),card:getNumber())
				acard:addSubcard(card:getId())
				acard:setSkillName(self:objectName())
				effect.card=acard
				local log=sgs.LogMessage()
				log.from=player
				log.to:append(effect.from)
				log.arg=card:objectName()
				log.type="#zuiqiang"
				room:sendLog(log)
				data:setValue(effect)
			end
			if effect.card:isKindOf("Slash") or effect.card:isKindOf("Duel") then
				if effect.from:hasSkill("zuiqiang") then
					room:setPlayerFlag(effect.from,"zuiqiangSource")
					room:setPlayerFlag(effect.to,"zuiqiangTarget")
				end
				if effect.to:hasSkill("zuiqiang") then
					room:setPlayerFlag(effect.to,"zuiqiangSource")
					room:setPlayerFlag(effect.from,"zuiqiangTarget")
				end
			end
			return false
		end
		if event == sgs.CardFinished then
			local use=data:toCardUse()
			if not use.card:isKindOf("Nullification") then
				for _,p in sgs.qlist(room:getAllPlayers()) do
					room:setPlayerFlag(p,"-zuiqiangSource")
					room:setPlayerFlag(p,"-zuiqiangTarget")
				end
			end	
			return false
		end
		if event == sgs.CardAsked then
			if player:hasFlag("zuiqiang") then return false end
			if not player:hasFlag("zuiqiangTarget") then return false end
			local pattern = data:toString()
			local ask_str = ""
			if pattern == "jink" or pattern=="slash" then
				ask_str = "slash"
			else
				return false
			end
			local playerx
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:hasFlag("zuiqiangSource") and p:hasSkill("zuiqiang") then
					playerx=p
					break
				end
			end
			room:setPlayerFlag(player,"zuiqiang")
			local card = room:askForCard(player, ask_str, "@zuiqiang"..pattern..":"..playerx:objectName(),data,sgs.Card_MethodResponse,playerx)
			room:setPlayerFlag(player,"-zuiqiang")
			if card == nil then
				room:provide(nil)
				return true
			else
				return false
			end
        end
	end,
}

rexue_prohibit=sgs.CreateProhibitSkill{
	name="#rexue_prohibit",
	is_prohibited=function(self,from,to,card)
		if to:hasSkill("rexue") then
			return card:isKindOf("Indulgence") or card:isKindOf("SupplyShortage")
		end
	end,
}

rexue=sgs.CreateFilterSkill{
	name="rexue",
	view_filter=function(self,to_select)
		return to_select:getSuit()~=sgs.Card_Heart
	end,
	view_as=function(self,card)
		local acard=sgs.Sanguosha:getWrappedCard(card:getId())
		acard:setSkillName("rexue")
		acard:setSuit(sgs.Card_Heart)
		acard:setModified(true)
		return acard
	end,
}

rexue_trigger=sgs.CreateTriggerSkill{
	name="#rexue_trigger",
	events={sgs.Predamage,sgs.EventAcquireSkill},
	priority=2,
	frequency=sgs.Skill_Compulsory,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.EventAcquireSkill and data:toString()=="rexue" then
			room:acquireSkill(player,"#rexue_trigger")
		end
		if not player:hasSkill("rexue") then return end
		if event==sgs.Predamage then
			local damage=data:toDamage()
			if damage.nature==sgs.DamageStruct_Fire then return false end
			local log=sgs.LogMessage()
			log.from=player
			log.type="#rexue"
			room:sendLog(log)
			damage.nature=sgs.DamageStruct_Fire
			data:setValue(damage)
		end
	end,
}

jiaoxiu=sgs.CreateTriggerSkill{
	name="jiaoxiu",
	events={sgs.TurnStart,sgs.PreHpReduced},
	priority=4,
	frequency=sgs.Skill_Wake,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.PreHpReduced and player:getMark("jiaoxiu")==0 then
			local damage=data:toDamage()
			if damage.damage>player:getHp()-1 and damage.from:objectName()~=player:objectName() then
				damage.damage=player:getHp()-1
				local log=sgs.LogMessage()
				log.from=player
				log.type="#jiaoxiux"
				log.arg=damage.damage
				room:sendLog(log)
				if damage.damage>0 then
					data:setValue(damage)
				else
					return true
				end	
			end
		end
		if event==sgs.TurnStart and player:getHp()==1 and player:faceUp() and player:getMark("jiaoxiu")==0 then
			local log=sgs.LogMessage()
			log.from=player
			log.type="#jiaoxiu"
			room:sendLog(log)
			if player:getMaxHp()>1 then room:loseMaxHp(player) end
			player:drawCards(player:getMaxHp()-player:getHandcardNum())
			player:gainMark("jiaoxiu")
			player:gainMark("@waked")
			room:acquireSkill(player,"relian")
			room:acquireSkill(player,"nixi")
		end
	end,
}

relian_distance=sgs.CreateDistanceSkill{
	name="#relian_distance",
	correct_func=function(self,from,to)
		if from:hasSkill("relian") then
			return -from:getMaxHp()
		end
	end,
}

relian_max=sgs.CreateMaxCardsSkill{
	name="#relian_max",
	extra_func=function(self,player)
		if player:hasSkill("relian") then
			return player:getLostHp()
		end
	end,
}

relian=sgs.CreateTriggerSkill{
	name="relian",
	events={sgs.EventAcquireSkill,sgs.Damage,sgs.Predamage},
	priority=2,
	frequency=sgs.Skill_Compulsory,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.EventAcquireSkill and data:toString()==self:objectName() then
			room:acquireSkill(player,"#relian_distance")
		end
		local damage=data:toDamage()
		if event==sgs.Predamage and damage.from:hasSkill(self:objectName()) then
			if player:isWounded() then return end
			local log=sgs.LogMessage()
			log.from=player
			log.to:append(damage.to)
			log.type="#relian"
			room:sendLog(log)
			damage.damage=damage.damage+1
			data:setValue(damage)
			return false
		end
		if event==sgs.Damage and damage.from:hasSkill(self:objectName()) then
			local log=sgs.LogMessage()
			log.from=player
			log.type="#relianx"
			room:sendLog(log)
			local recover=sgs.RecoverStruct()
			recover.recover=damage.damage
			recover.who=player
			room:recover(player,recover)
		end
	end,
}

local skill=sgs.Sanguosha:getSkill("#relian_distance")
if not skill then
	local skillList=sgs.SkillList()
	skillList:append(relian_distance)
	sgs.Sanguosha:addSkills(skillList)
end

local skill=sgs.Sanguosha:getSkill("relian")
if not skill then
	local skillList=sgs.SkillList()
	skillList:append(relian)
	sgs.Sanguosha:addSkills(skillList)
end

local skill=sgs.Sanguosha:getSkill("#relian_max")
if not skill then
	local skillList=sgs.SkillList()
	skillList:append(relian_max)
	sgs.Sanguosha:addSkills(skillList)
end

nixi=sgs.CreateTriggerSkill{
	name="nixi",
	events={sgs.CardEffected,sgs.Predamage,sgs.CardFinished},
	priority=4,
	frequency=sgs.Skill_NotFrequent,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.CardEffected then
			local effect=data:toCardEffect()
			if effect.to:objectName()==effect.from:objectName() then return false end
			if effect.to:isKongcheng() then return false end
			if not (effect.card:isNDTrick() and not effect.card:isKindOf("Duel")) or not room:askForSkillInvoke(player,"nixi",data) then return false end
			local slash=room:askForCard(player,"Slash","@nixislash",data,sgs.Card_MethodNone,effect.from)
			if slash and not player:isProhibited(effect.from,slash) then
				room:setCardFlag(slash,"nixi")
				local use=sgs.CardUseStruct()
				use.card=slash
				use.from=player
				use.to:append(effect.from)
				room:useCard(use)
			end	
			if player:hasFlag("nixi_success") then
				local log=sgs.LogMessage()
				log.from=player
				log.type="#nixi"
				room:sendLog(log)
				room:setPlayerFlag(player,"-nixi_success")
				return true
			end
			return false
		end
		if event==sgs.Predamage then
			local damage=data:toDamage()
			if damage.card:isKindOf("Slash") and damage.card:hasFlag("nixi") then
				room:setPlayerFlag(player,"nixi_success")
				return true
			end	
		end
	end,
}

local skill=sgs.Sanguosha:getSkill("nixi")
if not skill then
	local skillList=sgs.SkillList()
	skillList:append(nixi)
	sgs.Sanguosha:addSkills(skillList)
end

TC004:addSkill(zuiqiang)
TC004:addSkill(zuiqiang_trigger)
TC004:addSkill(rexue)
TC004:addSkill(rexue_trigger)
TC004:addSkill(rexue_prohibit)
TC004:addSkill(jiaoxiu)

sgs.LoadTranslationTable{
	["TC004"]="椎名深夏",
	["#TC004"]="熱血最強",
	["~TC004"]="あたしより…強い奴がいるの…あ",
	["zuiqiang_vs"]="最强",
	["zuiqiang"]="最强",
	[":zuiqiang"]="<b>锁定技</b>，你的基础牌均视为火【杀】，锦囊牌均视为【决斗】。对你使用的杀被视为与你【决斗】。你使用的【杀】必须连续打出一张【杀】和一张【闪】才能抵消。任何角色与你决斗时需连续打出2张【杀】来响应。",
	["#zuiqiang"]="%from的【最强】被触发，%to对其使用的%arg被视为【决斗】。",
	["@zuiqiangjink"]="最强的 %src 杀你，请先打出1张【杀】",
	["@zuiqiangslash"]="最强的 %src 与你决斗，请先打出1张【杀】",
	["rexue"]="热血",
	[":rexue"]="<b>锁定技</b>，你的牌视为红桃，你即将造成的伤害视为火焰伤害。你不能成为乐不思蜀和兵粮寸断的目标。",
	["#rexue"]="%from的【热血】被触发，%from即将造成的伤害视为火焰伤害",
	["jiaoxiu"]="娇羞",
	[":jiaoxiu"]="<b>觉醒技</b>，你回合开始时若你体力为1，则你减少1点体力上限（上限已经为1的情况下不减少）并将手牌补充至体力上限，然后获得【热恋】(<b>锁定技</b>，你与其他角色计算距离时均-x，x为你当前体力。你未受伤时造成的伤害+1。你每造成1点伤害恢复1点体力。你的手牌上限为你的体力上限。)和【逆袭】(当【决斗】以外的锦囊对你生效前，你可以对对方使用一张【杀】，若该【杀】命中，你防止该【杀】的伤害并使该锦囊对你无效。)。该觉醒技触发前，其他角色不能对你造成使你体力低于1的伤害",
	["#jiaoxiu"]="%from的体力为1，【娇羞】触发",
	["#jiaoxiux"]="%from的【娇羞】触发，将受到的伤害降低至%arg点",
	["#relian_distance"]="热恋",
	["relian"]="热恋",
	[":relian"]="<b>锁定技</b>，你与其他角色计算距离时均-x，x为你最大体力。你未受伤时造成的伤害+1。你每造成1点伤害恢复1点体力。你的手牌上限为你的体力上限。",
	["#relian"]="%from的【热恋】发动，即将造成的伤害+1",
	["#relianx"]="%from的【热恋】发动",
	["nixi"]="逆袭",
	[":nixi"]="当【决斗】以外的锦囊对你生效前，你可以对对方使用一张【杀】，若该【杀】命中，你防止该【杀】的伤害并使该锦囊对你无效。",
	["@nixislash"]="请打出一张杀",
	["#nixi"]="【逆袭】成功，该锦囊对%from无效",
	["designer:TC004"]="Nutari",
	["illustrator:TC004"]="狗神煌",
}

--椎名真冬

TC005=sgs.General(extension, "TC005", "god", "3", false)

fei=sgs.CreateTriggerSkill{
	name="fei",
	events={sgs.DamageInflicted},
	priority=1,
	frequency=sgs.Skill_Compulsory,
	can_trigger=function()
		return true
	end,	
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local damage=data:toDamage()
		if damage.from and damage.from:hasSkill(self:objectName()) or damage.to:hasSkill(self:objectName()) then
			local x=0
			if damage.from then x=math.max(0,damage.from:distanceTo(damage.to)-1) end
			if x==0 then return end
			damage.damage=math.max(damage.damage-x,0)
			if damage.from:hasSkill(self:objectName()) then
				local log=sgs.LogMessage()
				log.from=damage.from
				log.to:append(damage.to)
				log.arg=damage.damage
				log.type="#fei"
				room:sendLog(log)
			else
				local log=sgs.LogMessage()
				log.from=damage.to
				log.to:append(damage.from)
				log.arg=damage.damage
				log.type="#feix"
				room:sendLog(log)
			end
			if damage.damage>=1 then
				data:setValue(damage)
			else
				return true
			end	
		end	
	end,
}

fu=sgs.CreateTriggerSkill{
	name="fu",
	events={sgs.GameStart,sgs.EventPhaseStart,sgs.Damaged},
	priority=2,
	frequency=sgs.Skill_Compulsory,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local damage=data:toDamage()
 		local mafuyu = room:findPlayerBySkillName("fu")
        if not mafuyu then return false end
		if event==sgs.Damaged and damage.from and damage.from:objectName()~=mafuyu:objectName() and damage.from:objectName()~=damage.to:objectName() and damage.from:distanceTo(damage.to)<=1 then
			local x=damage.damage
			local idlist=room:getNCards(x+1)
			room:fillAG(idlist,nil)
			room:getThread():delay(1000)
			local redlist=sgs.IntList()
			local blacklist=sgs.IntList()
			for _,id in sgs.qlist(idlist) do
				local card=sgs.Sanguosha:getCard(id)
				if card:isRed() then redlist:append(id) else blacklist:append(id) end
			end
			local choice
			if not redlist:isEmpty() and not blacklist:isEmpty() then
				choice=room:askForChoice(mafuyu,self:objectName(),"red+black",data)
			elseif blacklist:isEmpty() then
				choice="red"
			else
				choice="black"
			end	
			if choice=="red" then
				local move=sgs.CardsMoveStruct()
				move.card_ids=redlist
				move.to=mafuyu
				move.to_place=sgs.Player_PlaceHand
				room:moveCardsAtomic(move,true)
				if not blacklist:isEmpty() then
					local move=sgs.CardsMoveStruct()
					move.card_ids=blacklist
					if damage.from:isAlive() then move.to=damage.from else move.to=mafuyu end
					move.to_place=sgs.Player_PlaceHand
					room:moveCardsAtomic(move,true)
					mafuyu:gainMark("@fu")
				end
			else
				local move=sgs.CardsMoveStruct()
				move.card_ids=blacklist
				move.to=mafuyu
				move.to_place=sgs.Player_PlaceHand
				room:moveCardsAtomic(move,true)
				if not redlist:isEmpty() then
					local move=sgs.CardsMoveStruct()
					move.card_ids=redlist
					if damage.to:isAlive() then move.to=damage.to else move.to=mafuyu end
					move.to_place=sgs.Player_PlaceHand
					room:moveCardsAtomic(move,true)
					mafuyu:gainMark("@fu")
				end
			end	
			room:broadcastInvoke("clearAG")
		end		
	end,
}

zhai=sgs.CreateTriggerSkill{
	name="zhai",
	events={sgs.EventPhaseStart},
	priority=4,
	frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if player:getPhase()==sgs.Player_Discard or player:getPhase()==sgs.Player_Judge then
			local log=sgs.LogMessage()
			log.from=player
			log.type="#zhaix"
			log.arg=player:getPhaseString()
			room:sendLog(log)
			return true
		end
		if player:getPhase()==sgs.Player_Start and player:getHandcardNum()>10 then
			local log=sgs.LogMessage()
			log.from=player
			log.type="#zhai"
			log.arg=player:getHandcardNum()
			room:sendLog(log)
			room:showAllCards(player)
			local redcards=sgs.IntList()
			local blackcards=sgs.IntList()
			for _,card in sgs.qlist(player:getHandcards()) do
				if card:isRed() then
					redcards:append(card:getEffectiveId())
				else
					blackcards:append(card:getEffectiveId())
				end
			end
			local move=sgs.CardsMoveStruct()
			move.to_place=sgs.Player_DiscardPile
			if redcards:length()>blackcards:length() then
				move.card_ids=redcards
			elseif blackcards:length()>redcards:length() then
				move.card_ids=blackcards
			else
				local choice=room:askForChoice(mafuyu,self:objectName(),"red+black")
				if choice=="red" then
					move.card_ids=redcards
				else
					move.card_ids=blackcards
				end
			end
			room:moveCardsAtomic(move,true)
			room:broadcastInvoke("clearAG")
		end	
	end,
}

bing=sgs.CreateTriggerSkill{
	name="bing",
	events={sgs.TurnStart},
	priority=4,
	frequency=sgs.Skill_Wake,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if player:getMark("bing")==0 and player:getMark("@fu")>=3  and player:faceUp() then
			local log=sgs.LogMessage()
			log.from=player
			log.arg=player:getMark("@fu")
			log.type="#bing"
			room:sendLog(log)
			player:gainMark("@waked")
			player:gainMark("bing")
			room:loseMaxHp(player)
			room:acquireSkill(player,"CP")
		end
	end,
}

CP_card=sgs.CreateSkillCard{
	name="CP_card",
	target_fixed=false,
	will_throw=false,
	filter=function(self,targets,to_select)
		return #targets<2 and not to_select:isKongcheng()
	end,
	feasible=function(self,targets)
		return #target==2
	end,	
	on_use=function(self,room,source,targets)
		local id={}
		for i=1,2,1 do
			id[i]=room:askForCardChosen(source,target[i],"h","CP")
		end
		room:showCard(target[1],id[1])
		room:showCard(target[2],id[2])
		if sgs.Sanguosha:getCard(id[1]):getSuit()==sgs.Sanguosha2:getCard(id[1]):getSuit() then
			local recover=sgs.RecoverStruct()
			recover.who=source
			room:recover(target[1],recover,true)
			room:recover(target[2],recover,true)
		else
			local moves=sgs.CardsMoveList()
			local reason=sgs.CardMoveReason()
			reason.m_reason=sgs.CardMoveReason_S_REASON_ROB
			reason.m_skillName="CP"
			reason.m_player=source:objectName()
			for i=1,2,1 do
				local move=sgs.CardsMoveStruct()
				move.card_ids:append(id[i])
				move.reason=reason
				move.to=source
				move.to_place=sgs.Player_PlaceHand
				moves:append(move)				
			end
			room:moveCardsAtomic(moves,false)
			local targetlist=sgs.SPlayerList()
			targetlist:append(targets[1])
			targetlist:append(targets[2])
			local target=room:askForPlayerChosen(source,targetlist,"CP")
			target:loseHp(1)
		end	
	end,		
}

CP_vs=sgs.CreateViewAsSkill{
	name="CP",
	n=0,
	view_as=function()
		return CP_card:clone()
	end,
	enabled_at_play=function()
		return sgs.Self:getMark("@fu")>0 and not sgs.Self:hasFlag("CPused")
	end,
}

CP=sgs.CreateTriggerSkill{
	name="CP",
	events={sgs.EventPhaseEnd},
	view_as_skill=CP_vs,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if player:getPhase()==sgs.Player_Play then
			room:setPlayerFlag(player,"-CPused")			
		end		
	end,
}

local skill=sgs.Sanguosha:getSkill("CP")
if not skill then
        local skillList=sgs.SkillList()
        skillList:append(CP)
        sgs.Sanguosha:addSkills(skillList)
end

TC005:addSkill(fei)
TC005:addSkill(fu)
TC005:addSkill(zhai)
TC005:addSkill(bing)

sgs.LoadTranslationTable{
	["TC005"]="椎名真冬",
	["#TC005"]="無駄の腐女",
	["~TC005"]="啊，真冬果然是没用的人么",
	["fei"]="废",
	[":fei"]="<b>锁定技</b>，你造成和受到的伤害均-x，x为伤害来源到受伤害者的距离-1（最小为0）。",
	["#fei"]="%from的【废】被触发，%from即将对%to造成的伤害降低至%arg点",
	["#feix"]="%from的【废】被触发，%to即将对%from造成的伤害降低至%arg点",
	["#fu_distance"]="腐",
	["@fu"]="腐",
	["fu"]="腐",
	[":fu"]="<b>锁定技</b>，每当1名角色受到与其距离为1以内的其他角色（同时不为你）一次伤害时，你展示牌堆顶的X+1张牌，X为伤害量。你拿走其中一种颜色的牌，然后剩下的牌若为红色则将其交给受伤害者，若为黑色则交给伤害来源，若目标死亡则依旧交给你。展示的并非全部相同颜色时，你获得1枚腐标记。",
	["red"]="红色",
	["black"]="黑色",
	["zhai"]="宅",
	[":zhai"]="<b>锁定技</b>，你永远跳过判定和弃牌阶段。你回合开始阶段的开始，若你的手牌数超过10张，则你需展示所有的手牌并弃置数量较多的颜色的手牌",
	["#zhai"]="%from的手牌数（%arg）超过了10张，触发了【宅】",
	["#zhaix"]="【宅】被触发，%from跳过了%arg阶段。",
	["bing"]="病",
	[":bing"]="<b>觉醒技</b>，回合开始时，若你的“腐”标记不少于3个，则需失去1点体力上限，然后获得【CP】\
	【CP】:出牌阶段，你可以弃置2枚“腐”标记并选择2名有手牌的角色。你展示双方各一张手牌，若所展示的牌花色相同，则双方各恢复1点体力，否则你获得双方展示的牌，并另其中一方失去1点体力。一阶段限一次。",
	["#bing"]="%from的“腐”标记数（%arg）不少于3，触发【病】",
	["CP_card"]="CP",
	["CP"]="CP",
	[":CP"]="出牌阶段，你可以弃置2枚“腐”标记并选择2名有手牌的角色。你展示双方各一张手牌，若所展示的牌花色相同，则双方各恢复1点体力，否则你获得双方展示的牌，并另其中一方失去1点体力。一阶段限一次。",
	["designer:TC005"]="Nutari",
	["illustrator:TC005"]="狗神煌",
}


--松原飛鳥

TC006=sgs.General(extension,"TC006","god","3",false)

zhenya=sgs.CreateTriggerSkill{
	name="zhenya",
	events={sgs.CardAsked,sgs.CardUsed,sgs.Damaged,sgs.EventPhaseChanging},
	priority=2.5,
	frequency=sgs.Skill_Compulsory,
	can_trigger=function(self,player)
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local asuka=room:findPlayerBySkillName(self:objectName())
		if not asuka then return false end
		if event==sgs.CardUsed then
			local card=data:toCardUse().card
			if card:isKindOf("BasicCard") and asuka:getPhase()==sgs.Player_Play and asuka:objectName()~=player:objectName() then
				if player:hasSkill("tianran") or player:hasSkill("tianzhen") then return end
				local log=sgs.LogMessage()
				log.from=asuka
				log.to:append(player)
				log.type="#zhenya"
				room:sendLog(log)
				local discard
				if card:isRed() then
					discard=room:askForCard(player,".|.|.|.|red","#zhenyared:"..asuka:objectName(),data,sgs.Card_MethodDiscard)
				elseif card:isBlack() then
					discard=room:askForCard(player,".|.|.|.|black","#zhenyablack:"..asuka:objectName(),data,sgs.Card_MethodDiscard)
				end
				if not discard then
					local log=sgs.LogMessage()
					log.from=asuka
					log.to:append(player)
					log.type="#zhenyaxx"
					room:sendLog(log)
					return true
				end
			end
		end
		if event==sgs.CardAsked then
			local pattern=data:toString()
			if player:objectName()==asuka:objectName() or player:hasFlag("zhenya") or (player:hasSkill("tianran") or player:hasSkill("tianzhen")) or (pattern~="jink" and pattern~="slash")or asuka:getPhase()~=sgs.Player_Play then return end
			room:setPlayerFlag(player,"zhenya")
			local card=room:askForCard(player,pattern,"#zhenya"..pattern..":"..asuka:objectName(),data,sgs.CardAsked,asuka)
			if card then
				local log=sgs.LogMessage()
				log.from=asuka
				log.to:append(player)
				log.type="#zhenya"
				room:sendLog(log)
				local discard
				if card:isRed() then
					discard=room:askForCard(player,".|.|.|.|red","#zhenyared:"..asuka:objectName(),data,sgs.Card_MethodDiscard)
				elseif card:isBlack() then
					discard=room:askForCard(player,".|.|.|.|black","#zhenyablack:"..asuka:objectName(),data,sgs.Card_MethodDiscard)
				end
				if discard then
					room:provide(card)
				else
					local log=sgs.LogMessage()
					log.from=asuka
					log.to:append(player)
					log.type="#zhenyaxx"
					room:sendLog(log)
					room:provide(nil)
				end
			else
				room:provide(nil)
			end
			room:setPlayerFlag(player,"-zhenya")
			return true
		end
		if event==sgs.Damaged then
			local damage=data:toDamage()
			if not damage.to:hasSkill(self:objectName()) or damage.to:getMark("@overwhelm")>0 then return false end
			local log=sgs.LogMessage()
			log.from=damage.to
			log.type="#zhenyask"
			room:sendLog(log)
			asuka:gainMark("@overwhelm")
		end
		if event==sgs.EventPhaseChanging then
			local change=data:toPhaseChange()
			if asuka:getMark("@overwhelm")>0 and change.to==sgs.Player_NotActive and not asuka:hasFlag("tianxieuse") then
				local log=sgs.LogMessage()
				log.from=asuka
				log.type="#zhenyaskx"
				room:sendLog(log)
				asuka:loseMark("@overwhelm")
				asuka:gainAnExtraTurn()
			end
		end
	end,
}

shishi_prohibit=sgs.CreateProhibitSkill{
	name="#shishi_prohibit",
	is_prohibited=function(self,from,to,card)
		if to:hasSkill("shishi") and from:distanceTo(to)>1 then
			return card:isKindOf("Slash")
		end
	end,
}

shishi_card=sgs.CreateSkillCard{
	name="shishi_card",
	target_fixed=false,
	will_throw=true,
	filter=function(self,targets,to_select)
		if #targets>0 then return false end
		return to_select:hasFlag("shishiable")
	end,
	on_use=function(self,room,source,targets)
		value = sgs.QVariant()
		value:setValue(targets[1])
		room:setTag("shishitarget",value)
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			room:setPlayerFlag(p,"-shishiable")
		end
	end,
}

shishi_vs=sgs.CreateViewAsSkill{
	name="shishi_vs",
	n=1,
	view_filter=function(self,selected,to_select)
		return true
	end,
	view_as=function(self,cards)
		if #cards==1 then
			local acard=shishi_card:clone()
			acard:addSubcard(cards[1]:getId())
			acard:setSkillName("shishi")
			return acard
		end
	end,
	enabled_at_play=function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return false
	end,
}

shishi=sgs.CreateTriggerSkill{
	name="shishi",
	view_as_skill=shishi_vs,
	events={sgs.CardEffected,sgs.GameStart,sgs.EventAcquireSkill},
	frequency=sgs.Skill_Frequent,
	priority=5,
	can_trigger=function()
		return true
	end,	
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.GameStart or (event==sgs.EventAcquireSkill and data:toString()==self.objectName()) then
			room:acquireSkill(player,"#shishi_prohibit")
		end
		if event==sgs.CardEffected then
			local effect=data:toCardEffect()
			if not effect.to:hasSkill(self:objectName()) then return end
			local card=effect.card
			if not card:isNDTrick() then return false end
			if effect.to:isNude() or not room:askForSkillInvoke(effect.to,"shishi",data) then
				effect.to:drawCards(1)
			else
				local prompt = "#shishi:" .. effect.from:objectName()
				for _,p in sgs.qlist(room:getOtherPlayers(effect.to)) do
					if not effect.to:isProhibited(p,card) then
						room:setPlayerFlag(p,"shishiable")
						if (card:isKindOf("Dismantlement") or card:isKindOf("Snatch")) and p:isAllNude() then
							room:setPlayerFlag(p,"-shishiable")
						elseif card:isKindOf("FireAttack") and p:isKongcheng() then
							room:setPlayerFlag(p,"-shishiable")
						elseif card:isKindOf("Collateral") and not p:getWeapon() then
							room:setPlayerFlag(p,"-shishiable")
						end
					end
				end
				if room:askForUseCard(effect.to, "@@shishi", prompt) then
					local shishitarget=room:getTag("shishitarget"):toPlayer()
					room:removeTag("shishitarget")
					effect.from=effect.to
					effect.to=shishitarget
					data:setValue(effect)
				else
					effect.to:drawCards(1)
				end
			end
			for _,p in sgs.qlist(room:getOtherPlayers(effect.to)) do
				room:setPlayerFlag(p,"-shishiable")
			end
		end
	end,
}

tianxie_card=sgs.CreateSkillCard{
	name="tianxie_card",
	target_fixed=false,
	will_throw=false,
	filter=function(self,targets,to_select)
		if #targets>1 then return false end
		if to_select:isAllNude() then return false end
		return true
	end,
	feasible=function(self,targets)
		return #targets>=1
	end,	
	on_use=function(self,room,source,targets)
		if targets[1]~=nil then
			cdid=room:askForCardChosen(source,targets[1],"hej","tianxie")
			room:moveCardTo(sgs.Sanguosha:getCard(cdid),source,sgs.Player_PlaceHand,false)
			if targets[2]==nil and not targets[1]:isNude()  then
				cdid=room:askForCardChosen(source,targets[1],"hej","tianxie")
				room:moveCardTo(sgs.Sanguosha:getCard(cdid),source,sgs.Player_PlaceHand,false)
			elseif targets[2]~=nil then
				cdid=room:askForCardChosen(source,targets[2],"hej","tianxie")
				room:moveCardTo(sgs.Sanguosha:getCard(cdid),source,sgs.Player_PlaceHand,false)
			end
		end
	end,
}

tianxieplayer_card=sgs.CreateSkillCard{
	name="tianxieplayer_card",
	will_throw=true,
	filter=function(self,targets,to_select)
		return #targets==0 and to_select:objectName()~=sgs.Self:objectName()
	end,
	feasible=function(self,targets)
		return #targets>=0
	end,	
	on_use=function(self,room,source,targets)
		local data=sgs.QVariant()
		if #targets>0 then
			data:setValue(targets[1])
			room:setTag("tianxieTarget",data)
		else
			data:setValue(source)
			room:setTag("tianxieTarget",data)
		end
	end,
}

tianxie_vs=sgs.CreateViewAsSkill{
	name="tianxie",
	n=1,
	view_filter=function(self,selected,to_select)
		if sgs.Self:hasFlag("tianxieself") then return false else return true end
	end,
	view_as=function(self,cards)
		if #cards==0 and sgs.Self:hasFlag("tianxieself") then return tianxie_card:clone()
		elseif #cards==1 then
			local acard=tianxieplayer_card:clone()
			acard:addSubcard(cards[1]:getId())
			acard:setSkillName("tianxie")
			return acard
		end
	end,
	enabled_at_play=function()
		return false
	end,
	enabled_at_response=function()
		return false
	end,
}

function phase2string(phase)
	if phase==sgs.Player_RoundStart then return "round_start"
	elseif phase==sgs.Player_Start then return "start"
	elseif phase==sgs.Player_Judge then return "judge"
	elseif phase==sgs.Player_Draw then return "draw"
	elseif phase==sgs.Player_Play then return "play"
	elseif phase==sgs.Player_Discard then return "discard"
	elseif phase==sgs.Player_Finish then return "finish"
	elseif phase==sgs.Player_NotActive then return "not_active"
	end
end

tianxie=sgs.CreateTriggerSkill{
	name="tianxie",
	events={sgs.EventPhaseChanging,sgs.EventPhaseEnd,sgs.CardsMoveOneTime,sgs.Damage,sgs.PreHpRecover},
	view_as_skill=tianxie_vs,
	priority=4.5,
	can_trigger=function(self,player)
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local asuka=room:findPlayerBySkillName(self:objectName())
		if not asuka then return false end
		if event==sgs.EventPhaseChanging then
			if player:objectName()~=asuka:objectName() or asuka:isNude() then return false end
			if asuka:getMark("tianxie")>0 then
				local log=sgs.LogMessage()
				log.from=asuka
				log.arg=asuka:getMark("tianxie")
				log.type="#tianxiex"
				room:sendLog(log)
				asuka:drawCards(asuka:getMark("tianxie"))
				asuka:setMark("tianxie",0)
			end	
			local change=data:toPhaseChange()
			if change.to~=sgs.Player_RoundStart and change.to~=sgs.Player_NotActive and not player:isSkipped(change.to) then
				if not room:askForUseCard(asuka,"@@tianxie","#tianxieask"..change.to,1) then return false end
				local target=room:getTag("tianxieTarget"):toPlayer()
				room:removeTag("tianxieTarget")
				if target:objectName()~=asuka:objectName() then
					local phases=sgs.PhaseList()
					local log=sgs.LogMessage()
					log.from=asuka
					log.arg=phase2string(change.to)
					log.to:append(target)
					log.type="#tianxie"
					room:sendLog(log)
					phases:append(change.to)
					room:setCurrent(target)
					room:setPlayerFlag(player,"tianxieuse")
					room:setPlayerFlag(target,"tianxie")
					target:play(phases)
					room:setPlayerFlag(player,"-tianxieuse")
					room:setPlayerFlag(target,"-tianxie")
					room:setCurrent(player)
					return true
				else
					local log=sgs.LogMessage()
					log.from=asuka
					log.arg=phase2string(change.to)
					log.type="#tianxiea"
					room:sendLog(log)
					if change.to==sgs.Player_Draw then
						room:setPlayerFlag(asuka,"tianxieself")
						room:askForUseCard(asuka,"@@tianxie","#tianxieaskd",2)
						room:setPlayerFlag(asuka,"-tianxieself")
						local log=sgs.LogMessage()
						log.from=asuka
						log.type="#tianxieax"
						room:sendLog(log)
					elseif change.to==sgs.Player_Play then
						room:drawCards(asuka,2+asuka:getLostHp())
					end
					return true
				end
			end
		end
		if event==sgs.CardsMoveOneTime then
			local move=data:toMoveOneTime()
			if move.to_place==sgs.Player_PlaceHand and move.to:hasFlag("tianxie") and move.to:objectName()==player:objectName() then
				local x=move.card_ids:length()
				asuka:setMark("tianxie",x+asuka:getMark("tianxie"))
			end
		end
		if event==sgs.Damage then
			if player:hasFlag("tianxie") and data:toDamage().damage>=1 then
				local x=data:toDamage().damage
				asuka:setMark("tianxie",x+asuka:getMark("tianxie"))
			end
		end
		if event==sgs.PreHpRecover and player:hasFlag("tianxie") then
			local x=data:toRecover().recover
			asuka:setMark("tianxie",x+asuka:getMark("tianxie"))
		end
	end,
}

TC006:addSkill(zhenya)
TC006:addSkill(shishi)
TC006:addSkill(shishi_prohibit)
TC006:addSkill(tianxie)

sgs.LoadTranslationTable{
	["TC006"]="松原飛鳥",
	["#TC006"]="魔女幼馴染",
	["~TC006"]="あり得ない！",
	["zhenya"]="镇压",
	[":zhenya"]="<b>锁定技</b>，你的回合内其他角色每使用或者打出1张基础牌时，必须弃置1张同颜色的牌，否则此牌无效，此效果对有【天然】【天真】的目标无效。你每受到1次伤害，你在当前回合结束后获得一个额外的回合",
	["#zhenya"]="%from的镇压发动，%to需弃置1张同颜色的牌",
	["#zhenyared"]="%src的【镇压】发动，请弃置1张同颜色的牌(红色)",
	["#zhenyablack"]="%src的【镇压】发动，请弃置1张同颜色的牌(黑色)",
	["#zhenyax"]="受【镇压】影响，%from弃置了%arg",
	["#zhenyaxx"]="受%from的【镇压】影响，%to未能弃置相同颜色的牌",
	["#zhenyajink"]="请打出一张【闪】（受%src的镇压影响，打出该闪后需弃置一张相同颜色的牌才能生效）",
	["#zhenyaslash"]="请打出一张【杀】（受%src的镇压影响，打出该杀后需弃置一张相同颜色的牌才能生效）",
	["#zhenyask"]="%from的【镇压】发动，当前角色回合结束后开启一个额外的回合",
	["#zhenyaskx"]="%from的【镇压】发动，开始了一个额外的回合",
	["@overwhelm"]="镇压",
	["#shishi_prohibit"]="识势",
	["shishi_card"]="识势",
	["shishi_vs"]="识势",
	["shishi"]="识势",
	[":shishi"]="离你距离大于1的角色不能对你使用杀。当你成为非延时锦囊的目标时，你可以弃置1张牌，将目标转至一个合理的角色上(无视距离),并视为你为效果来源，若不如此做则你摸1张牌",
	["#shishi"]="你可以弃置1张牌(包括装备)将%src对你使用的锦囊效果转移给一个合理的角色",
	["~shishi"]="选一张牌->选择一个合理的角色->点击确定",
	["tianxie"]="天邪",
	["tianxieplayer_card"]="天邪",
	["tianxie_card"]="天邪",
	[":tianxie"]="你的回合开始，判定，摸牌，出牌，弃牌，回合结束阶段开始前，你可以弃置1张牌并选择一名其他角色（也可以不选）。若选择了其他角色，则其替你进行该阶段。该角色在该阶段每获得1张牌/制造1点伤害/恢复1点体力，在此阶段结束时你摸1张牌。若没有选择其他角色，则你跳过对应阶段，若是摸牌阶段你可以获得场上任意角色手牌、装备区和判定区的1-2张牌并加入手牌,若是出牌阶段则你摸2加你失去体力的牌",
	["#tianxie"]="%from发动【天邪】，跳过了%arg阶段,并令%to开始该阶段",
	["#tianxiea"]="%from发动【天邪】，跳过%arg阶段",
	["#tianxieax"]="%from发动【天邪】，获得场上2张牌",
	["#tianxiex"]="%from的【天邪】发动",
	["#tianxieask1"]="你可以弃置1张卡转移回合开始阶段",
	["#tianxieask2"]="你可以弃置1张卡转移判定阶段",
	["#tianxieask3"]="你可以弃置1张卡转移摸牌阶段",
	["#tianxieask4"]="你可以弃置1张卡转移出牌阶段",
	["#tianxieask5"]="你可以弃置1张卡转移弃牌阶段",
	["#tianxieask6"]="你可以弃置1张卡转移回合结束阶段",
	["#tianxieaskd"]="请选择【天邪】抽牌目标",
	["~tianxie1"]="请选择1张牌（包括装备）->选择任意一个角色->点击确定",
	["~tianxie2"]="选择1-2个非裸体的角色->点击确定",
	["designer:TC006"]="Nutari",
	["illustrator:TC006"]="狗神煌",
}
--杉崎林檎

TC007=sgs.General(extension, "TC007", "god", "3", false)

tianran_distance=sgs.CreateDistanceSkill{
	name="#tianran_distance",
	correct_func=function(self,from,to)
		if from:hasSkill("tianran") then
			return -from:getLostHp()
		end
	end,
}

tianran=sgs.CreateFilterSkill{
	name="tianran",
	view_filter=function(self,to_select)
		return to_select:isKindOf("TrickCard")
	end,
	view_as=function(self,card)
		local slash=sgs.Sanguosha:cloneCard("slash",card:getSuit(),card:getNumber())
		local acard=sgs.Sanguosha:getWrappedCard(card:getId())
		acard:takeOver(slash)
		acard:setSkillName("tianran")
		return acard
	end,
}

tianran_trigger=sgs.CreateTriggerSkill{
	name="#tianran_trigger",
	events={sgs.CardEffected,sgs.GameStart,sgs.CardUsed,sgs.DamageForseen,sgs.CardAsked,sgs.CardFinished},
	priority=2.5,
	frequency=sgs.Skill_Compulsory,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.DamageForseen and player:hasSkill("tianran") then
			local damage=data:toDamage()
			if damage.transfer or damage.chain then
				local log=sgs.LogMessage()
				log.from=player
				log.type="#tianrand"
				room:sendLog(log)
				return true
			end
		end
		if event==sgs.CardEffected then
			local effect=data:toCardEffect()
			if effect.to:hasSkill("tianran") then
				if not effect.card:isKindOf("TrickCard") then return end
				local ringo=effect.to
				local log=sgs.LogMessage()
				log.from=ringo
				log.arg=effect.card:objectName()
				log.type="#tianran"
				room:sendLog(log)
				return true
			end
			if effect.card:isKindOf("Slash") and effect.from:hasSkill("tianran") and effect.card:isRed() then
				local value=sgs.QVariant()
				value:setValue(effect.from)
				room:setTag("tianransource",value)
				value:setValue(effect.to)
				room:setTag("tianrantarget",value)
			end	
		end
		if event==sgs.CardFinished then
			room:removeTag("tianransource")
			room:removeTag("tianrantarget")
		end	
		if event==sgs.CardUsed then
			local use=data:toCardUse()
			if use.card:isKindOf("Slash") and use.from:hasSkill("tianran") then
				for _,p in sgs.qlist(use.to) do
					p:addMark("qinggang")
				end
				return false
			end
		end
		if event==sgs.CardAsked then
			local pattern=data:toString()
			if player:hasFlag("tianran") or pattern~="jink" then return end
			local tianransource=room:getTag("tianransource"):toPlayer()
			local tianrantarget=room:getTag("tianrantarget"):toPlayer()
			if not tianrantarget or tianrantarget:objectName()~=player:objectName() then return end
			room:setPlayerFlag(player,"tianran")
			local jink=room:askForCard(tianrantarget, "jink","@tianran-jink:"..tianransource:objectName(),data,sgs.Card_MethodNone,tianransource)
			if jink and jink:getSuit()==sgs.Card_Heart then
				room:provide(jink)
			else
				room:provide(nil)
			end
			room:setPlayerFlag(player,"-tianran")
			return true
		end
	end,
}

imouto=sgs.CreateViewAsSkill{
	name="imouto",
	n=0,
	view_as=function()
		local acard=sgs.Sanguosha:cloneCard("peach",sgs.Card_NoSuit,0)
		acard:setSkillName("imouto")
		return acard
	end,
	enabled_at_play=function()
		return sgs.Self:faceUp() and sgs.Self:isWounded()
	end,
	enabled_at_response=function(self,player,pattern)
		return(pattern=="peach" or pattern=="peach+analeptic") and sgs.Self:faceUp()
	end,
}

imouto_max=sgs.CreateMaxCardsSkill{
	name="#imouto_max",
	extra_func=function(self,player)
		if player:hasSkill("imouto") then
			return player:getLostHp()*2
		end
	end,
}

imouto_tr=sgs.CreateTriggerSkill{
	name="#imouto_tr",
	events={sgs.EventAcquireSkill,sgs.EventLoseSkill,sgs.CardUsed,sgs.CardEffected,sgs.DamageComplete,sgs.PreHpReduced},
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local ringo=room:findPlayerBySkillName("imouto")
		if not ringo then return end
		if event==sgs.CardUsed then
			local use=data:toCardUse()
			if use.from:hasSkill("imouto") and use.card:isKindOf("Peach") and use.card:getSkillName()=="imouto" then
				use.from:turnOver()
			end
		end
		if event==sgs.CardEffected then
			local effect=data:toCardEffect()
			if effect.to:objectName()==ringo:objectName() and effect.card:isKindOf("Slash") then
				if ringo:faceUp() or ringo:isNude() or not room:askForSkillInvoke(ringo,"imouto",data) then return end
				if room:askForDiscard(ringo,"imouto",1,1,true,true) then
					ringo:turnOver()
				end
			end
		end
		local damage=data:toDamage()
		if event==sgs.PreHpReduced then
			if ringo:faceUp() or (damage.to:objectName()~=ringo:objectName() and ringo:isNude()) then return end
			room:setPlayerFlag(ringo,"imouto")
		end
		if event==sgs.DamageComplete then
			if ringo:hasFlag("imouto") and not ringo:faceUp() then
				if room:askForSkillInvoke(ringo,"imouto",data) and (damage.to:objectName()==ringo:objectName() or (not ringo:isNude() and  room:askForDiscard(ringo,"imouto",1,1,true,true))) then
					ringo:turnOver()
				end
				room:setPlayerFlag(ringo,"-imouto")
			end
		end
	end,
}

shane=sgs.CreateTriggerSkill{
	name="shane",
	events={sgs.Predamage,sgs.PreHpRecover,sgs.EventPhaseEnd},
	frequency=sgs.Skill_Frequent,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local ringo=room:findPlayerBySkillName(self:objectName())
		if not ringo then return end
		if event==sgs.Predamage then
			local damage=data:toDamage()
			if damage.card:isKindOf("Slash") and damage.from:objectName()==ringo:objectName() then
				local choice=""
				if not room:askForSkillInvoke(ringo,self:objectName(),data) then return end
				if ringo:isNude() then
					choice=room:askForChoice(ringo,"shane","shaneshan+noshane")
				else
					choice=room:askForChoice(ringo,"shane","shaneshan+shanee+noshane")
				end
				local log=sgs.LogMessage()
				log.from=ringo
				if choice=="shaneshan" then
					log.type="#shansha"
					room:sendLog(log)
					if damage.to:isWounded() then
						local recover=sgs.RecoverStruct()
						recover.recover=damage.damage
						recover.who=ringo
						room:recover(damage.to,recover,true)
						ringo:drawCards(1+ringo:getLostHp())
					end
					return true
				elseif choice=="shanee"	 then
					log.type="#esha"
					room:sendLog(log)
					room:askForDiscard(ringo,self:objectName(),1,1,false,true)
					damage.damage=damage.damage+1
					damage.from=nil
					data:setValue(damage)
					return false
				end
			end
		end
		if event==sgs.PreHpRecover then
			local recover=data:toRecover()
			if recover.who:objectName()==ringo:objectName() and recover.card:isKindOf("Peach") and player:objectName()~=recover.who:objectName() then
				if not room:askForSkillInvoke(ringo,self:objectName(),data) then return end
				local choice=room:askForChoice(ringo,self:objectName(),"shaneshan+shanee+noshane")
				local log=sgs.LogMessage()
				log.from=ringo
				if choice=="shaneshan" then
					log.type="#shantao"
					room:sendLog(log)
					room:loseHp(ringo)
					recover.recover=recover.recover+1
					data:setValue(recover)
					return false
				elseif choice=="shanee" then
					log.type="#etao"
					room:sendLog(log)
					if player:getMaxHp()>recover.recover then room:loseMaxHp(player,recover.recover) else room:setPlayerProperty(player,"maxhp",sgs.QVariant(1)) end
					local recoverx=sgs.RecoverStruct()
					recover.recoverx=1
					recoverx.who=ringo
					room:recover(ringo,recoverx,true)
					return true
				end
			end
		end
		if event==sgs.EventPhaseEnd and player:getMark("shane")>0 then
			room:setPlayerMark(player,"shane",0)
		end	
	end,
}

TC007:addSkill(tianran)
TC007:addSkill(tianran_distance)
TC007:addSkill(tianran_trigger)
TC007:addSkill(imouto)
TC007:addSkill(imouto_tr)
TC007:addSkill(imouto_max)
TC007:addSkill(shane)

sgs.LoadTranslationTable{
	["TC007"]="杉崎林檎",
	["#TC007"]="天然の妹",
	["~TC007"]="ふぁっきん、ゆー！",
	["tianran"]="天然",
	["#tianran_distance"]="天然",
	[":tianran"]="<b>锁定技</b>,你的锦囊牌均视为【杀】。你不能成为延时锦囊的目标并且非延时锦囊对你无效。你的【杀】无视防具，且红色【杀】只能被红桃【闪】抵消。你不会受到传导或者转移的伤害。你到其他角色的距离始终-x，x为你失去的体力。\
	注：传导或者转移的伤害包括天香、偏移、流转、命轮等导致伤害目标改变的效果，包括铁索连环、附影的伤害传导效果",
	["#tianran"]="%from的【天然】触发，%arg对%from无效",
	["#tianrand"]="%from的【天然】触发，伤害无效",
	["@tianran-jink"]="【天然】的%src杀你，请打出一张红桃【闪】（非红桃的闪不会生效）",
	["imouto_card"]="妹魂",
	["imouto"]="妹魂",
	[":imouto"]="你的手牌上限为你的最大体力+已失去的体力。当你武将正面朝上时，在合理的时机，你可以将你的武将牌翻面，视为使用了1张桃。当【杀】对你生效前或者任何角色受到伤害时，若你武将背面朝上，可以弃一张牌将武将翻回正面，当且仅当你受到伤害的情况不用弃牌",
	["#imouto_trigger"]="妹魂",
	["shane"]="善恶",
	[":shane"]="你的【杀】即将造成伤害时，可以做出以下2中选择之一：弃1张牌，令杀的伤害+1并且伤害视为没有来源；防止此次伤害，并且若目标已受伤，则回复目标等量的体力，然后你摸x+1张牌，x为你已失去的体力。你对其他角色用【桃】时，可以做出以下选择之一：你自减1点体力，额外恢复目标1点体力；防止此次体力恢复，令目标失去等量的体力上限(该效果不能将上限减至0)，然后恢复自己1点体力",
	["shaneshan"]="善（防止伤害或者额外恢复）",
	["shanee"]="恶（额外造成伤害或者防止恢复）",
	["#shansha"]="%from选择了令目标恢复体力",
	["#esha"]="%from选择了弃置1张牌增加杀的伤害",
	["#shantao"]="%from选择了自减1点体力额外恢复",
	["#etao"]="%from选择了令目标失去体力上限",
	["noshane"]="不发动",
	["designer:TC007"]="Nutari",
	["illustrator:TC007"]="狗神煌",
}
--藤堂リリシア

TC008=sgs.General(extension, "TC008", "god", "3", false)

function getbobaosuit(player)
	if player:getMark("bobao")>0 then
		if player:getMark("@heart")>0 then return sgs.Card_Heart
		elseif player:getMark("@club")>0 then return sgs.Card_Club
		elseif player:getMark("@spade")>0 then return sgs.Card_Spade
		elseif player:getMark("@diamond")>0 then return sgs.Card_Diamond end
	end
	return sgs.Card_NoSuit
end

bobaopattern=""
bobao_card=sgs.CreateSkillCard{
	name="bobao_card",
	will_throw=true,
	target_fixed=true,
	on_use=function(self,room,source,targets)
		if not source:getPile("bobao"):isEmpty() then
			local cdid=source:getPile("bobao"):first()
			room:moveCardTo(sgs.Sanguosha:getCard(cdid),source,sgs.Player_PlaceHand,true)
		end
		cardx = sgs.Sanguosha:getCard(self:getEffectiveId())
		bobaopattern=cardx:objectName()
		if source:getMark("bobao")==0 then room:setPlayerMark(source,"bobao",1) end
		local suit=room:askForSuit(source,"bobao")
		if source:getMark("@heart")>0 then source:loseAllMarks("@heart") end
		if source:getMark("@diamond")>0 then source:loseAllMarks("@diamond") end
		if source:getMark("@club")>0 then source:loseAllMarks("@club") end
		if source:getMark("@spade")>0 then source:loseAllMarks("@spade") end
		source:gainMark("@"..sgs.Card_Suit2String(suit))
		source:addToPile("bobao",cardx)
	end,
}

bobao_vs=sgs.CreateViewAsSkill{
	name="bobao",
	n=1,
	view_filter=function(self,selected,to_select)
		if sgs.Self:getMark("bobao")==0 then return to_select:isKindOf("BasicCard") or to_select:isNDTrick()
		else return to_select:getSuit()==getbobaosuit(sgs.Self)
		end
	end,
	view_as=function(self,cards)
		if #cards==1 then
			local acard
			if sgs.Self:getMark("bobao")==0 then
				acard=bobao_card:clone()
			else
				acard=sgs.Sanguosha:cloneCard(bobaopattern,cards[1]:getSuit(),cards[1]:getNumber())
			end
			acard:addSubcard(cards[1]:getId())
			acard:setSkillName("bobao")
			return acard
		end
	end,
	enabled_at_play=function(self,player)
		if sgs.Self:getMark("bobao")==0 then return false end
		if string.find(bobaopattern,"slash") then
			return sgs.Self:canSlashWithoutCrossbow() or ((sgs.Self:getWeapon()) and (sgs.Self:getWeapon():getClassName()=="Crossbow"))
		elseif bobaopattern=="peach" then
			return sgs.Self:isWounded()
		elseif bobaopattern=="jink" or bobaopattern=="nullification" then
			return false
		elseif bobaopattern=="analeptic" then
			return not sgs.Self:hasUsed("Analeptic")
		else
			return true
		end
	end,
	enabled_at_response=function(self,player,pattern)
		if sgs.Self:getMark("bobao")>0 then return string.find(pattern,bobaopattern) or string.find(bobaopattern,pattern) end
	end,
	enabled_at_nullification=function(self,player)
		if bobaopattern=="nullification" then
			for _,card in sgs.qlist(player:getHandcards()) do
				if card:isKindOf("Nullification") or card:getSuit()==getbobaosuit(player) then
					return true
				end
			end
			if player:getWeapon() and player:getWeapon():getSuit()==getbobaosuit(player) then return true end
			if player:getArmor() and player:getArmor():getSuit()==getbobaosuit(player) then return true end
			if player:getDefensiveHorse() and player:getDefensiveHorse():getSuit()==getbobaosuit(player) then return true end
			if player:getOffensiveHorse() and player:getOffensiveHorse():getSuit()==getbobaosuit(player) then return true end
		end
		return false
	end,
}

bobao=sgs.CreateTriggerSkill{
	name="bobao",
	events={sgs.EventPhaseStart,sgs.EventLoseSkill,sgs.EventAcquireSkill},
	view_as_skill=bobao_vs,
	can_trigger=function()
		return true
	end,	
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.EventAcquireSkill and data:toString()=="bobao" then
			room:acquireSkill(player,"#bobao_tr")
		end
		if event==sgs.EventLoseSkill and data:toString()=="bobao" then
			player:removePileByName("bobao")
		end
		if player:hasSkill("bobao") and event==sgs.EventPhaseStart and player:getPhase()==sgs.Player_Play then
			if player:isKongcheng() or not room:askForSkillInvoke(player,"bobao",data) then return false end
			if player:getMark("bobao")>0 then room:setPlayerMark(player,"bobao",0) end
			if not room:askForUseCard(player,"@@bobao","@bobao") then
				if not player:getPile("bobao"):isEmpty() then
					local cdid=player:getPile("bobao"):first()
					room:moveCardTo(sgs.Sanguosha:getCard(cdid),player,sgs.Player_PlaceHand,true)
				end
			end
		end
	end,
}

aojiao=sgs.CreateTriggerSkill{
	name="aojiao",
	events={sgs.CardsMoveOneTime,sgs.Damaged,sgs.MaxHpChanged,sgs.EventPhaseEnd},
	priority=2,
	frequency=sgs.Skill_Compulsory,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.CardsMoveOneTime then
			local move=data:toMoveOneTime()
			if move.reason.m_skillName=="shijie" then return false end
			if not move.from or not move.from:hasSkill(self:objectName()) then return false end
			if move.from:objectName()~=player:objectName() then return false end
			if move.card_ids:isEmpty() then return false end
			if player:getHandcardNum()<math.min(2,player:getMaxHp()-3) then
				if player:getPhase()==sgs.Player_Discard then return false end
				local log=sgs.LogMessage()
				log.from=player
				log.type="#aojiaocard"
				room:sendLog(log)
				player:drawCards(math.min(2,player:getMaxHp()-3)-player:getHandcardNum())
			end
			if not (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) then return false end
			if player:getPhase()==sgs.Player_Play or player:getPhase()==sgs.Player_Discard then return false end
			if player:getMaxHp()<7 then
				local log=sgs.LogMessage()
				log.type="#aojiao"
				log.from=player
				room:sendLog(log)
				room:setPlayerProperty(player,"maxhp",sgs.QVariant(player:getMaxHp()+1))
			end
		end
		if event==sgs.Damaged and data:toDamage().to:hasSkill(self:objectName()) then
			if player:getMaxHp()>3 and player:isAlive() then
				local log=sgs.LogMessage()
				log.type="#aojiaox"
				log.from=player
				room:sendLog(log)
				room:loseMaxHp(player)
			end
		end
		if event==sgs.MaxHpChanged or (event==sgs.EventPhaseEnd and player:getPhase()==sgs.Player_Discard )then
			if player:getHandcardNum()<math.min(2,player:getMaxHp()-3) and player:hasSkill(self:objectName()) then
				local log=sgs.LogMessage()
				log.from=player
				log.type="#aojiaocard"
				room:sendLog(log)
				player:drawCards(math.min(2,player:getMaxHp()-3)-player:getHandcardNum())
			end
		end
	end,
}

jiedi_distance=sgs.CreateDistanceSkill{
	name="#jiedi_distance",
	correct_func=function(self,from,to)
		if from:hasSkill("jiedi") then
			return math.min(0,3-from:getMaxHp())
		end
	end,
}

jiedi=sgs.CreateTriggerSkill{
	name="jiedi",
	events={sgs.Damage,sgs.EventAcquireSkill},
	frequency=sgs.Skill_Frequent,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.EventAcquireSkill and data:toString()==self:objectName() then
			room:acquireSkill(player,"#jiedi_distance")
		end
		if event==sgs.Damage then
		local damage=data:toDamage()
			if player:hasSkill(self:objectName()) and player:distanceTo(damage.to)<2 then
				if damage.to:isKongcheng() then return false end
				if not room:askForSkillInvoke(player,"jiedi",data) then return false end
				local hcdids=damage.to:handCards()
				room:fillAG(hcdids,player)
				local card_id = room:askForAG(player, hcdids, true, "jiedi")
				if card_id~=-1 then
					local suit=getbobaosuit(player)
					if sgs.Sanguosha:getCard(card_id):getSuit()==suit then
						room:obtainCard(player,card_id)
						room:showCard(player,card_id)
					else
						room:throwCard(card_id,damage.to,player)
					end
				end
				player:invoke("clearAG")
			end
		end
	end,
}

TC008:addSkill(bobao)
TC008:addSkill(aojiao)
TC008:addSkill(jiedi)
TC008:addSkill(jiedi_distance)

sgs.LoadTranslationTable{
	["TC008"]="藤堂リリシア",
	["#TC008"]="新聞部長",
	["~TC008"]="このわたくし、あ！",
	["bobao_card"]="播报",
	["bobao"]="播报",
	[":bobao"]="出牌阶段开始，你可以展示1张基础或者非延时锦囊牌然后置于你的武将牌上，并说出1种花色，你所有该花色的牌在你下次宣称【播报】之前可以被当作展示的牌来使用。此法置于武将牌上的牌在下次宣称【播报】时收回手牌",
	["@bobao"]="你可以【播报】一张基础牌或者锦囊牌",
	["~bobao"]="点击一张基础牌或者锦囊牌->点击确定。",
	["@heart"]="红桃",
	["@diamond"]="方片",
	["@club"]="梅花",
	["@spade"]="黑桃",
	["aojiao"]="傲矫",
	[":aojiao"]="<b>锁定技</b>，当你处于出牌和弃牌阶段外，每失去1次牌，增加1点体力上限(不超过7点)。当你体力上限高于3时受到伤害，你失去1点体力上限。除弃牌阶段外你的手牌不会少于你的体力上限-3(最多2张)",
	["#aojiao"]="【傲矫】触发，%from增加了1点体力上限",
	["#aojiaox"]="【傲矫】触发，%from减少了1点体力上限",
	["#aojiaocard"]="%from的【傲矫】触发",
	["#jiedi_distance"]="揭底",
	["jiedi"]="揭底",
	[":jiedi"]="当你体力上限大于3时，你与其他角色计算距离时始终-x，x为你的体力上限-3。当你对距离为1以内的角色造成伤害时，你可以查看其手牌，然后选出1张与你播报宣传的花色相同的牌展示并加入手牌或者选一张花色不同的弃置",
	["designer:TC008"]="Nutari",
	["illustrator:TC008"]="狗神煌",
}

--藤堂アリス

TC009=sgs.General(extension, "TC009", "god", "3", false)

moxingtrick={"collateral","ex_nihilo","duel","snatch","dismantlement","amazing_grace","savage_assault","archery_attack","god_salvation","fire_attack","iron_chain"}
mxpattern=""

moxing_card=sgs.CreateSkillCard{
	name="moxing_card",
	target_fixed=true,
	will_throw=false,
	on_use=function(self,room,source,targets)
		local cardlist=""
		for v,cd in ipairs(moxingtrick) do
			local card=sgs.Sanguosha:cloneCard(cd,sgs.Card_NoSuit,0)
			if not source:hasFlag(cd) and not source:isCardLimited(card,sgs.Card_MethodUse) then
				cardlist=cardlist..cd.."+"
			end
		end
		cardlist=cardlist.."cancel"
		mxpattern=room:askForChoice(source,"moxing",cardlist)
		if mxpattern=="" or mxpattern=="cancel" then return end
		room:setPlayerFlag(source,"moxingchosen")
		room:askForUseCard(source,"@@moxing","#moxing:"..mxpattern)
		room:setPlayerFlag(source,"-moxingchosen")
	end,
}

moxing_vs=sgs.CreateViewAsSkill{
	name="moxing",
	n=1,
	view_filter=function(self,selected,to_select)
		return sgs.Self:hasFlag("moxingchosen") and (to_select:isKindOf("BasicCard") or to_select:isKindOf("EquipCard"))
	end,
	view_as=function(self,cards)
		if #cards==0 and not sgs.Self:hasFlag("moxingchosen") then
			return moxing_card:clone()
		end
		if #cards==1 then
			local acard=sgs.Sanguosha:cloneCard(mxpattern,cards[1]:getSuit(),cards[1]:getNumber())
			acard:addSubcard(cards[1]:getId())
			acard:setSkillName("moxing")
			return acard
		end
	end,
	enabled_at_play=function()
		return sgs.Self:getMark("@charm")>0
	end,
	enabled_at_response=function(self,player,pattern)
		return pattern=="@@moxing"
	end,	
}

moxing=sgs.CreateTriggerSkill{
	name="moxing",
	events={sgs.EventPhaseStart,sgs.EventPhaseEnd,sgs.CardUsed,sgs.CardsMoveOneTime},
	view_as_skill=moxing_vs,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.EventPhaseStart and player:getPhase()==sgs.Player_Play then
			player:gainMark("@charm",3+player:getLostHp())
		end
		if event==sgs.EventPhaseEnd and player:getPhase()==sgs.Player_Play then
			player:loseAllMarks("@charm")
			for _,cd in ipairs(moxingtrick) do
				room:setPlayerFlag(player,"-"..cd)
			end
		end
		if event==sgs.CardUsed then
			local use=data:toCardUse()
			if use.card:getSkillName()=="moxing" then
				player:loseMark("@charm")
				room:setPlayerFlag(player,use.card:objectName())
			end
		end
		if event==sgs.CardsMoveOneTime then
			local move=data:toMoveOneTime()
			if move.reason.m_reason==sgs.CardMoveReason_S_REASON_RECAST and move.reason.m_skillName=="moxing" and move.from:objectName()==player:objectName() then
				player:loseMark("@charm")
				room:setPlayerFlag(player,"iron_chain")				
			end
		end
	end,
}

moxingtarget=sgs.CreateTargetModSkill{
	name="#moxingtarget",
	pattern="TrickCard",
	extra_target_func=function(self,from,card)
		if from:hasSkill("moxing") and card:isNDTrick() then
			return 1
		end
	end,
}

younvprohibit=sgs.CreateProhibitSkill{
	name="#younvprohibit",
	is_prohibited=function(self,from,to,card)
		if to:isKongcheng() and to:hasSkill("younv") then
			return card:isKindOf("Slash") or card:isKindOf("Duel")
		elseif not to:isKongcheng() and to:hasSkill("younv") then
			return card:isKindOf("Snatch") or card:isKindOf("Dismantlement")
		end
	end,
}

younv=sgs.CreateTriggerSkill{
	name="younv",
	events={sgs.DrawNCards,sgs.EventAcquireSkill,sgs.EventLoseSkill},
	priority=2,
	frequency=sgs.Skill_Compulsory,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.EventAcquireSkill and data:toString()==self:objectName() then
			room:acquireSkill(player,"#younvprohibit")
		end
		if event==sgs.DrawNCards and player:hasSkill(self:objectName())then
			local x=data:toInt()
			local i=player:getLostHp()
			if i>0 then
				local log=sgs.LogMessage()
				log.from=player
				log.arg=i
				log.type="#younv"
				room:sendLog(log)
				data:setValue(x+i)
			end
		end
	end,
}

TC009:addSkill(moxing)
TC009:addSkill(moxingtarget)
TC009:addSkill(younv)
TC009:addSkill(younvprohibit)

sgs.LoadTranslationTable{
	["TC009"]="藤堂アリス",
	["#TC009"]="魔性の幼女",
	["~TC009"]="アリス、まだ遊びたい",
	["moxing"]="魔性",
	["moxing_viewas"]="魔性",
	["moxing_card"]="魔性",
	["moxing_scard"]="魔性",
	["moxingcollateral"]="魔性·借刀杀人",
	[":moxing"]="你的出牌阶段可以将一张基础牌或者装备牌当作任意一张非延时锦囊(除无懈可击)来使用，一回合限使用3+x次且每种锦囊限使用一次，x为你出牌阶段开始时失去的体力。你使用决斗、顺手牵羊、过河拆桥、火攻、铁索连环时可以额外指定一个目标",
	["cancel"]="取消",
	["#moxing"]="请使用%src",
	["~moxing"]="~选择该锦囊合理的目标->点击确定",
	["@charm"]="魔性",
	["jixu"]="继续选择目标",
	["tingzhi"]="停止选择目标",
	["younv"]="幼女",
	[":younv"]="<b>锁定技</b>，当你有手牌的时候不能成为过河拆桥和顺手牵羊的目标，无手牌时不能成为杀和决斗的目标。摸牌阶段，你多摸等同于你失去体力数量的牌",
	["#younv"]="%from的【幼女】触发，多摸了%arg张牌",
	["designer:TC009"]="Nutari",
	["illustrator:TC009"]="狗神煌",
}

--宇宙巡

TC010=sgs.General(extension,"TC010","god","3",false)

ouxiang=sgs.CreateTriggerSkill{
	name="ouxiang",
	events=sgs.Damaged,
	frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local damage=data:toDamage()
		local judge=sgs.JudgeStruct()
		judge.reason=self:objectName()
		judge.who=player
		judge.pattern=sgs.QRegExp("(.*):(.*):(.*)")
		judge.good=true
		local card
		local use=sgs.CardUseStruct()
		for i=1,damage.damage,1 do
			room:judge(judge)
			card=judge.card
			if card:getSuit()==sgs.Card_Heart and player:isWounded() then
				local recover=sgs.RecoverStruct()
				recover.who=player
				recover.recover=1
				room:recover(player,recover)
			elseif card:getSuit()==sgs.Card_Diamond and damage.from and damage.from:getHandcardNum()>damage.from:getHp() and damage.from:objectName()~=player:objectName()  then
				local jilei=0
				for _,card in sgs.qlist(player:getHandcards()) do
					if player:isJilei(card) then
						jilei=jilei+1
					end
				end
				local x=damage.from:getHandcardNum()-math.max(damage.from:getHp(),jilei)
				room:askForDiscard(damage.from,self:objectName(),x,x)
			elseif card:getSuit()==sgs.Card_Spade and damage.from and damage.from:faceUp() and damage.from:objectName()~=player:objectName() then
				damage.from:turnOver()
			elseif card:getSuit()==sgs.Card_Club and damage.from and not damage.from:getEquips():isEmpty() and damage.from:objectName()~=player:objectName() then
				damage.from:throwAllEquips()
			else
				player:obtainCard(card)
			end
		end
	end,
}

xiongbao=sgs.CreateTriggerSkill{
	name="xiongbao",
	events={sgs.EventPhaseChanging,sgs.Predamage},
	frequency=sgs.Skill_Compulsory,
	priority=2,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.EventPhaseChanging  then
			local change=data:toPhaseChange()
			if change.to==sgs.Player_Start then
				local x=player:getHp()
				local idlist=room:getNCards(x)
				room:fillAG(idlist,nil)
				room:getThread():delay(1000)
				local suits={}
				local suitsnum=0
				for _,id in sgs.qlist(idlist) do
					card = sgs.Sanguosha:getCard(id)
					if not suits[card:getSuit()] then
						suits[card:getSuit()]=true
						suitsnum=suitsnum+1
					end
					room:takeAG(player, card:getId())
				end
				for _,id in sgs.qlist(idlist) do
					idlist:removeOne(id)
				end
				room:broadcastInvoke("clearAG")
				if suitsnum==1 then
					room:acquireSkill(player,"relian")
					room:acquireSkill(player,"zuiqiang")
					player:gainMark("@rage")
					player:skip(sgs.Player_Discard)
				end
				player:skip(sgs.Player_Judge)
				player:skip(sgs.Player_Draw)
			elseif change.to==sgs.Player_NotActive then
				if player:getMark("@rage")>0 then
					player:loseMark("@rage")
					room:detachSkillFromPlayer(player,"relian")
					room:detachSkillFromPlayer(player,"zuiqiang")
				end
			end
		end
		if event==sgs.Predamage and player:getMark("@rage")>0 and player:isWounded() then
			local damage=data:toDamage()
			damage.damage=damage.damage+1
			local log=sgs.LogMessage()
			log.from=player
			log.type="#xiongbao"
			room:sendLog(log)
			data:setValue(damage)
			return false
		end
	end,
}

weizhuang=sgs.CreateTriggerSkill{
	name="weizhuang",
	events={sgs.ConfirmDamage,sgs.EventPhaseStart,sgs.GameStart,sgs.BuryVictim},
	frequency=sgs.Skill_Compulsory,
	priority=5,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if (event==sgs.EventPhaseStart and player:getPhase()==sgs.Player_Start and player:getMark("@rage")==0 or event==sgs.GameStart) and player:hasSkill(self:objectName()) then
			local playerx=room:askForPlayerChosen(player,room:getOtherPlayers(player),"weizhuang")
			local value=sgs.QVariant()
			value:setValue(playerx)
			room:setTag("weizhuangtarget",value)
			local log=sgs.LogMessage()
			log.type="#weizhuangx"
			log.from=player
			log.to:append(playerx)
			room:sendLog(log)
		end
		if event==sgs.BuryVictim and room:getTag("weizhuangtarget"):toPlayer():objectName()==player:objectName() then
			local meguru=room:findPlayerBySkillName(self:objectName())
			if not meguru then room:removeTag("weizhuangtarget") return end
			local playerx=room:askForPlayerChosen(meguru,room:getOtherPlayers(meguru),"weizhuang")
			local value=sgs.QVariant()
			value:setValue(playerx)
			room:setTag("weizhuangtarget",value)
			local log=sgs.LogMessage()
			log.type="#weizhuangx"
			log.from=meguru
			log.to:append(playerx)
			room:sendLog(log)			
		end
		if event==sgs.ConfirmDamage then
			local damage=data:toDamage()
			if not player:hasSkill(self:objectName()) or player:getMark("@rage")>0 then return false end
			local playerx=room:getTag("weizhuangtarget"):toPlayer()
			damage.from=playerx
			local log=sgs.LogMessage()
			log.from=player
			log.to:append(playerx)
			log.type="#weizhuang"
			room:sendLog(log)
			data:setValue(damage)
			return false
		end
	end,
}

TC010:addSkill(ouxiang)
TC010:addSkill("#zuiqiang_trigger")
TC010:addSkill(xiongbao)
TC010:addSkill(weizhuang)

sgs.LoadTranslationTable{
	["TC010"]="宇宙巡",
	["#TC010"]="アイドル",
	["~TC010"]="まだ鍵お告白しない、まだしにたくない",
	["ouxiang"]="偶像",
	[":ouxiang"]="<b>锁定技</b>，你每受到1点伤害，需判定。然后根据以下情况作出动作\
	若为红桃且你体力不满，则恢复1点体力；\
	若为黑桃且伤害来源正面朝上，则将目标翻面；\
	若为方片且伤害来源手牌多于其当前体力，则其弃置等同于差额的手牌\
	若为梅花且伤害来源装备区有装备，则其弃置装备区全部的牌\
	\
	此外的情况你收回判定牌。",
	["xiongbao"]="凶暴",
	[":xiongbao"]="<b>锁定技</b>，回合开始阶段，你展示牌堆顶的X张牌并加入手牌，然后跳过判定和摸牌阶段,X为你当前体力。若X张牌花色相同，则你进入“凶暴”状态直到回合结束。此期间你获得【最强】和【热恋】，你受伤时你即将造成的伤害均+1，你跳过弃牌阶段。",
	["#xiongbao"]="%from的【凶暴】触发，即将造成的伤害+1",
	["@rage"]="凶暴",
	["weizhuang"]="伪装",
	[":weizhuang"]="<b>锁定技</b>，游戏开始和回合开始时，你需指定你以外的一名玩家，直到下回合开始前，你造成的伤害来源均视为他。若你处于“凶暴”状态，此效果不发动。",
	["#weizhuangx"]="%from发动了【伪装】，目标为%to",
	["#weizhuang"]="%from的【伪装】触发，造成伤害的来源视为%to",
	["designer:TC010"]="Nutari",
	["illustrator:TC010"]="狗神煌",
}

--中目黒善樹

TC011=sgs.General(extension,"TC011","god","3",false)
TC011X=sgs.General(extension,"TC011X","god","3",true,true)

ruoqi=sgs.CreateTriggerSkill{
	name="ruoqi",
	events=sgs.Damaged,
	frequency=sgs.Skill_Frequent,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if not room:askForSkillInvoke(player,self:objectName(),data) then return end
		local judge=sgs.JudgeStruct()
		judge.who=player
		judge.reason=self:objectName()
		judge.pattern=sgs.QRegExp("(.*):(spade|club):(.*)")
		judge.good=true
		judge.play_animation=true
		room:judge(judge)
		if judge:isGood() then
			local damage=data:toDamage()
			local choice=""
			local x=2
			for i=1,2,1 do
				if damage.from and not damage.from:isNude() then choice=room:askForChoice(player,self:objectName(),"laiyuan+paidui") else choice="paidui" end
				if choice=="paidui" then
					break
				else
					x=x-1
					local cdid=room:askForCardChosen(player,damage.from,"he",self:objectName())
					room:moveCardTo(sgs.Sanguosha:getCard(cdid),player,sgs.Player_PlaceHand,false)
				end
			end
			if x>0 then player:drawCards(x) end
		else
			player:obtainCard(judge.card)
		end
	end,
}

paiji_vs=sgs.CreateViewAsSkill{
	name="paiji",
	n=1,
	view_filter=function(self,selected,to_select)
		return (to_select:getSuit()==sgs.Card_Spade or to_select:getSuit()==sgs.Card_Heart)and to_select:isNDTrick()
	end,
	view_as=function(self,cards)
		if #cards==1 then
			local acard=sgs.Sanguosha:cloneCard("lightning",cards[1]:getSuit(),cards[1]:getNumber())
			acard:addSubcard(cards[1]:getId())
			acard:setSkillName("paiji")
			return acard
		end
	end,
	enabled_at_play=function()
		return not sgs.Self:containsTrick("lightning")
	end,
}

paiji=sgs.CreateTriggerSkill{
	name="paiji",
	events={sgs.DamageForseen,sgs.FinishJudge,sgs.EventPhaseChanging,sgs.StartJudge},
	view_as_skill=paiji_vs,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local yoshiki=room:findPlayerBySkillName("paiji")
		if event==sgs.DamageForseen then
			local damage=data:toDamage()
			if damage.to:hasSkill("paiji") and damage.card:isKindOf("Lightning") then
				local log=sgs.LogMessage()
				log.from=player
				log.type="#paiji"
				room:sendLog(log)
				return true
			elseif damage.card:isKindOf("Lightning") and yoshiki then
				local log=sgs.LogMessage()
				log.from=yoshiki
				log.to:append(player)
				log.type="#paijix"
				room:sendLog(log)
				damage.from=yoshiki
				data:setValue(damage)
			end
		end
		if event==sgs.FinishJudge and yoshiki then
			local judge=data:toJudge()
			if judge.reason=="lightning" and judge.card:getSuit()~=sgs.Card_Heart then
				yoshiki:obtainCard(judge.card)
			end
		end
		if event==sgs.EventPhaseChanging then
			local change=data:toPhaseChange()
			if player:hasSkill("paiji") and change.to==sgs.Player_Finish and change.from~=sgs.Player_Judge then
				change.to=sgs.Player_Judge
				data:setValue(change)
				player:insertPhase(sgs.Player_Judge)
				return false
			end
		end
		if event==sgs.StartJudge and yoshiki then
			local judge=data:toJudge()
			if yoshiki:hasSkill("douzhi") and judge.reason=="lightning" then
				if yoshiki:objectName()~=judge.who:objectName() then
					judge.pattern=sgs.QRegExp("(.*):(spade|club):([2-9])")
					data:setValue(judge)
				else
					judge.pattern=sgs.QRegExp("(.*):(.*):(.*)")
					judge.good=true
					data:setValue(judge)
				end
			end
		end
	end,
}

fuhei=sgs.CreateTriggerSkill{
	name="fuhei",
	events=sgs.AskForRetrial,
	frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local judge=data:toJudge()
		if not room:askForSkillInvoke(player,self:objectName(),data) then return end
		local id=room:getNCards(1):first()
		local card=sgs.Sanguosha:getCard(id)
		local reason=sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER,player:objectName())
		reason.m_skillName=self:objectName()
		room:moveCardTo(card,nil,sgs.Player_PlaceTable,reason,true)	
		room:getThread():delay(500)
		if card:isBlack() then
			room:retrial(card,player,judge,self:objectName(),false)
		else
			room:moveCardTo(card,nil,sgs.Player_DiscardPile,false)
		end	
		return false
	end,
}

jibian=sgs.CreateTriggerSkill{
	name="jibian",
	events={sgs.FinishJudge},
	frequency=sgs.Skill_Wake,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local judge=data:toJudge()
		if judge.who:getHp()==1 and judge.who:hasSkill(self:objectName()) and judge.card:isRed() and (judge.card:getNumber()==1 or judge.card:getNumber()>10) then
			room:changeHero(player,"TC011X",true,false,false,true)
		end
	end,
}

juexin=sgs.CreateTriggerSkill{
	name="juexin",
	events=sgs.Damage,
	frequency=sgs.Skill_Frequent,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if not room:askForSkillInvoke(player,self:objectName()) then return end
		local judge=sgs.JudgeStruct()
		judge.reason=self:objectName()
		judge.who=player
		judge.pattern=sgs.QRegExp("(.*):(heart|diamond):(.*)")
		judge.good=true
		judge.play_animation=true
		room:judge(judge)
		player:obtainCard(judge.card)
		if judge:isGood() then
			player:drawCards(1)
		end
	end,
}

qifa=sgs.CreateTriggerSkill{
	name="qifa",
	events=sgs.CardFinished,
	frequency=sgs.Skill_NotFrequent,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local use=data:toCardUse()
		local room=player:getRoom()
		if use.card:isNDTrick() and use.from:hasSkill(self:objectName()) then
			if room:getCardPlace(use.card:getEffectiveId())~=sgs.Player_DiscardPile then return end
			if not room:askForSkillInvoke(player,self:objectName()) then return end
			local playerx=room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName())
			room:moveCardTo(use.card,playerx,sgs.Player_PlaceHand,false)
		end
	end,
}

douzhi=sgs.CreateTriggerSkill{
	name="douzhi",
	events=sgs.AskForRetrial,
	frequency=sgs.Skill_NotFrequent,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local judge=data:toJudge()
		if not room:askForSkillInvoke(player,self:objectName(),data) then return end
		local id=room:getNCards(1):first()
		room:getThread():delay(500)
		local card=sgs.Sanguosha:getCard(id)
		local reason=sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER,player:objectName())
		reason.m_skillName="douzhi"
		room:moveCardTo(card,nil,sgs.Player_PlaceTable,reason,true)		
		if card:isBlack() then
			room:askForDiscard(player,"douzhi",1,1,false,true)
		end
		room:retrial(card,player,judge,self:objectName(),false)
		return false
	end,
}

TC011:addSkill(ruoqi)
TC011:addSkill(paiji)
TC011:addSkill(fuhei)
TC011:addSkill(jibian)
TC011X:addSkill("paiji")
TC011X:addSkill(juexin)
TC011X:addSkill(douzhi)
TC011X:addSkill(qifa)

sgs.LoadTranslationTable{
	["TC011"]="中目黒善樹",
	["#TC011"]="弱気の転校生",
	["~TC011"]="ぼくも鍵を好きです",
	["TC011X"]="中目黒善樹（醒）",
	["#TC011X"]="覚醒の転校生",
	["~TC011X"]="ぼくがもともっと強いでいい",
	["ruoqi"]="弱气",
	[":ruoqi"]="你受到伤害时可以判定，若结果为黑，则你从伤害来源和牌堆中共获得2张牌，否则你收回判定牌",
	["laiyuan"]="伤害来源",
	["paidui"]="牌堆",
	["paiji"]="排挤",
	[":paiji"]="你可以把黑桃和红桃的非延时锦囊当作【闪电】来使用，你回合结束进行一个额外的判定阶段。你不会受到【闪电】的伤害，你是【闪电】伤害的来源，你收回【闪电】非红桃的判定牌",
	["#paiji"]="%from的【排挤】被触发，不会受到【闪电】的伤害",
	["#paijix"]="%from的【排挤】被触发，%to即将受到【闪电】的伤害来源视为%from",
	["fuhei"]="腹黑",
	[":fuhei"]="任何判定牌生效前，你可以展示牌堆顶的一张牌，若展示的牌为黑色，取代原判定牌",
	["jibian"]="激变",
	[":jibian"]="<b>觉醒技</b>，当你的判定牌为红色的AJQK且你体力为1时，你立刻变身为觉醒的中目黒善樹并恢复至满状态，性别为男性，并获得【启发】【决心】【斗志】，然后失去【腹黑】【弱气】 。",
	["juexin"]="决心",
	[":juexin"]="当你造成伤害时可以判定，你先收回判定牌，若为红色，则你摸1张牌。",
	["#qifa_prohibit"]="启发",
	["qifa"]="启发",
	[":qifa"]="当你使用结束的非延时锦囊进入弃牌堆时，你可以将其交给场上你以外的任意一个角色",
	["douzhi"]="斗志",
	[":douzhi"]="任何判定牌生效前，你可以展示牌堆顶的一张牌，若为黑色，你弃置1张牌。然后展示牌取代原判定牌。若你有【斗志】，则你的【排挤】会将【闪电】对其他角色成功的判定范围扩大至黑色的2-9，对你自己则永远失效",
	["designer:TC011"]="Nutari",
	["illustrator:TC011"]="狗神煌",
	["designer:TC011X"]="Nutari",
	["illustrator:TC011X"]="狗神煌",
}

--真儀瑠紗鳥（生徒会顧問）

TC012=sgs.General(extension,"TC012","god","4",false)

guwen_card=sgs.CreateSkillCard{
	name="guwen_card",
	will_throw=false,
	target_fixed=false,
	filter=function(self,targets,to_select)
		return #targets==0 and not to_select:isKongcheng()
	end,
	on_use=function(self,room,source,targets)
		room:setPlayerFlag(source,"guwenused")
		local target=targets[1]
		local hcdids=target:handCards()
		if source:getLostHp()==0 then
			room:showAllCards(target,source)
			return
		end
		room:fillAG(hcdids,source)
		local idlist=sgs.IntList()
		local x=0
		while x<source:getLostHp() do
			local cdid=room:askForAG(source,hcdids,true,"guwen")
			if cdid~=-1 then
				x=x+1
				source:invoke("clearAG")
				idlist:append(cdid)
				hcdids:removeOne(cdid)
				if hcdids:isEmpty() then break end
				room:fillAG(hcdids,source)
			else
				break
			end
		end
		source:invoke("clearAG")
		if not idlist:isEmpty() then
			local move=sgs.CardsMoveStruct()
			local reason=sgs.CardMoveReason()
			reason.m_reason=sgs.CardMoveReason_S_REASON_ROB
			reason.m_player=source:objectName()
			reason.m_skillName="guwen"
			move.reason=reason
			move.card_ids=idlist
			move.from_place=sgs.Player_PlaceHand
			move.from=target
			move.to=source
			move.to_place=sgs.Player_PlaceHand
			room:moveCardsAtomic(move,false)
		end
		if x>0 then
			room:askForDiscard(source,"guwen",x,x,false,false)
		end
	end,
}

guwen_vs=sgs.CreateViewAsSkill{
	name="guwen",
	n=0,
	view_as=function()
		return guwen_card:clone()
	end,
	enabled_at_play=function()
		return not sgs.Self:hasFlag("guwenused")
	end,
}

guwen=sgs.CreateTriggerSkill{
	name="guwen",
	events=sgs.EventPhaseEnd,
	view_as_skill=guwen_vs,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if player:getPhase()==sgs.Player_Play then
			room:setPlayerFlag(player,"-guwenused")
		end
	end,
}

zhancao_distance=sgs.CreateDistanceSkill{
	name="#zhancao_distance",
	correct_func=function(self,from,to)
		if from:hasSkill("zhancao") then
			return -to:getLostHp()
		end
	end,
}

zhancao=sgs.CreateTriggerSkill{
	name="zhancao",
	events={sgs.ConfirmDamage,sgs.Damaged,sgs.CardFinished,sgs.EventPhaseStart},
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local satori=room:findPlayerBySkillName(self:objectName())
		if not satori then return end
		if event==sgs.Damaged and player:getHp()==1 and player:objectName()~=satori:objectName() then
			if satori:isNude() or not room:askForSkillInvoke(satori,self:objectName(),data) then return end
			local value=sgs.QVariant()
			value:setValue(player)
			player:addMark("qinggang")
			if not room:askForUseSlashTo(satori,player,"#zhancaoask",false,true) then
				player:removeMark("qinggang")
			end
		end
		if event==sgs.ConfirmDamage then
			local damage=data:toDamage()
			if damage.from:hasSkill("zhancao") and damage.to:getHp()==1 and damage.card:isKindOf("Slash") then
				damage.damage=damage.damage+1
				data:setValue(damage)
			end
		end
		if event==sgs.EventPhaseStart and satori:getPhase()==sgs.Player_Discard then
			local cards=satori:getHandcards()
			local x=0
			for _,cd in sgs.qlist(cards) do
				if cd:isKindOf("Slash") then x=x+1 end
			end
			if x>satori:getMaxCards() then
				if not room:askForSkillInvoke(satori,self:objectName(),data) then return end
				room:showAllCards(satori)
				for _,cd in sgs.qlist(cards) do
					if not cd:isKindOf("Slash") then room:throwCard(cd,satori) end
				end
				return true
			end
		end
	end,
}

yazhi_card=sgs.CreateSkillCard{
	name="yazhi_card",
	will_throw=true,
	target_fixed=false,
	filter=function(self,targets,to_select)
		return #targets==0 and to_select:faceUp() and to_select:objectName()~=sgs.Self:objectName()
	end,
	on_use=function(self,room,source,targets)
		targets[1]:turnOver()
		targets[1]:drawCards(source:getHp())
		room:setPlayerFlag(source,"yazhiused")
		room:setPlayerFlag(source,"-yazhiresponse")
	end,
}

yazhi_vs=sgs.CreateViewAsSkill{
	name="yazhi",
	n=1,
	view_filter=function(self,selected,to_select)
		return not sgs.Self:hasFlag("yazhiresponse") and to_select:isBlack() and not to_select:isEquipped()
	end,
	view_as=function(self,cards)
		if #cards==0 and sgs.Self:hasFlag("yazhiresponse") then
			return yazhi_card:clone()
		elseif #cards==1 then
			local acard=yazhi_card:clone()
			acard:addSubcard(cards[1]:getId())
			acard:setSkillName("yazhi")
			return acard
		end
	end,
	enabled_at_play=function()
		return not sgs.Self:hasFlag("yazhiused") and not sgs.Self:isNude()
	end,
	enabled_at_response=function(self,player,pattern)
		return pattern=="@@yazhi"
	end,
}

yazhi=sgs.CreateTriggerSkill{
	name="yazhi",
	events={sgs.EventPhaseEnd,sgs.TurnedOver},
	view_as_skill=yazhi_vs,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.TurnedOver and not player:faceUp() then
			if not room:askForSkillInvoke(player,self:objectName()) then return end
			room:setPlayerFlag(player,"yazhiresponse")
			room:askForUseCard(player,"@@yazhi","#yazhiask")
			room:setPlayerFlag(player,"-yazhiresponse")
			room:setPlayerFlag(player,"-yazhiused")
		end
		if event==sgs.EventPhaseEnd and player:getPhase()==sgs.Player_Play then
			room:setPlayerFlag(player,"-yazhiused")
		end
	end,
}

TC012:addSkill(guwen)
TC012:addSkill(zhancao_distance)
TC012:addSkill(zhancao)
TC012:addSkill(yazhi)

sgs.LoadTranslationTable{
	["TC012"]="真儀瑠紗鳥(学)",
	["#TC012"]="生徒会顧問",
	["~TC012"]="まだ死んじゃだ？",
	["guwen_card"]="顾问",
	["guwen"]="顾问",
	[":guwen"]="出牌阶段，你可以查看一个角色全部的手牌，然后从中选出最多X张加入你的手牌，X为你已失去的体力，然后你再弃置等量的手牌，一阶段限一次。",
	["#zhancao_distance"]="斩草",
	["zhancao"]="斩草",
	[":zhancao"]="你与其他角色计算距离时始终-x，x为其已失去的体力。你的【杀】对体力为1的角色造成伤害时伤害+1。其他角色受到伤害后而体力变为1时，你可以立刻对其使用1张【杀】，该【杀】无视防具和距离限制。弃牌阶段，若你手牌中的【杀】超过你的手牌上限，你可以展示所有的手牌，然后弃置所有的非【杀】手牌并跳过弃牌阶段",
	["#zhancaoask"]="请对目标使用一张【杀】",
	["yazhi_card"]="压制",
	["yazhi"]="压制",
	[":yazhi"]="出牌阶段，你可以弃置1张黑色手牌将另一个正面朝上的角色翻面，然后其摸取X张牌，X为你当前体力。当你被其翻面至背面朝上时，你可以不用弃牌发动一次该效果",
	["#yazhiask"]="请选择压制的目标",
	["~yazhi"]="选择一个正面朝上的角色->点击确定",
	["designer:TC012"]="Nutari",
	["illustrator:TC012"]="狗神煌",
}

--宇宙守

TC013=sgs.General(extension,"TC013","god","3",true)

luren=sgs.CreateTriggerSkill{
	name="luren",
	events={sgs.TargetConfirming},
	priority=2,
	frequency=sgs.Skill_Compulsory,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.TargetConfirming then
			local use=data:toCardUse()
			if player:hasSkill(self:objectName()) and use.to:contains(player) and use.to:length()>1 and (use.card:isKindOf("BasicCard") or use.card:isKindOf("TrickCard")) then
				use.to:removeOne(player)
				data:setValue(use)
				local log=sgs.LogMessage()
				log.from=player
				log.arg=use.card:objectName()
				log.type="#luren"
				room:sendLog(log)
				player:drawCards(1)
				return false
			end
		end
	end,
}

yujian=sgs.CreateTriggerSkill{
	name="yujian",
	events={sgs.AskForRetrial,sgs.FinishJudge},
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local mamoru=room:findPlayerBySkillName(self:objectName())
		if not mamoru then return end
		if event==sgs.AskForRetrial and player:objectName()==mamoru:objectName() then
			if mamoru:isNude() then return end
			local card=room:askForCard(mamoru,"..","@yujian",data,sgs.Card_MethodResponse,nil,true,self:objectName())
			local judge=data:toJudge()
			if card then
				room:retrial(card,mamoru,judge,self:objectName(),true)
				if judge.who:objectName()~=mamoru:objectName() then mamoru:addMark("yujian") end
				return true
			end
		end
		if event==sgs.FinishJudge and mamoru:getMark("yujian")>0 then
			local judge=data:toJudge()
			if judge:isGood() and mamoru:objectName()~=judge.who:objectName() and room:askForSkillInvoke(judge.who,self:objectName(),data) then
				mamoru:drawCards(1)
			end
			mamoru:removeMark("yujian")
		end
	end,
}

caice_card=sgs.CreateSkillCard{
	name="caice_card",
	will_throw=false,
	target_fixed=false,
	filter=function(self,targets,to_select)
		return #targets==0 and not to_select:isKongcheng()
	end,
	on_use=function(self,room,source,targets)
		local target=targets[1]
		local cardtype=room:askForChoice(source,"caice","BasicCard+TrickCard+EquipCard")
		local suit=room:askForSuit(source,"caice")
		local log=sgs.LogMessage()
		log.from=source
		log.arg=sgs.Card_Suit2String(suit)
		log.arg2=cardtype
		log.type="#caice"
		room:sendLog(log)
		local cdid=room:askForCardChosen(source,target,"h","caice")
		local card=sgs.Sanguosha:getCard(cdid)
		room:moveCardTo(card,source,sgs.Player_PlaceHand,false)
		room:showCard(source,cdid)
		room:getThread():delay(1000)
		if card:getSuit()~=suit or not card:isKindOf(cardtype) then
			room:setPlayerFlag(source,"caiceused")
			room:askForDiscard(source,"caice",1,1)
		end
	end,
}

caice_vs=sgs.CreateViewAsSkill{
	name="caice",
	n=0,
	view_as=function()
		return caice_card:clone()
	end,
	enabled_at_play=function()
		return not sgs.Self:hasFlag("caiceused")
	end,
}

caice=sgs.CreateTriggerSkill{
	name="caice",
	events=sgs.EventPhaseEnd,
	view_as_skill=caice_vs,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if player:getPhase()==sgs.Player_Play then
			room:setPlayerFlag(player,"-caiceused")
		end
	end,
}

TC013:addSkill(luren)
TC013:addSkill(yujian)
TC013:addSkill(caice)

sgs.LoadTranslationTable{
	["TC013"]="宇宙守",
	["#TC013"]="無存在の弟",
	["~TC013"]="え、オレを忘れだ？",
	["luren"]="路人",
	[":luren"]="<b>锁定技</b>，当你被指定为指定了多个目标的基础牌或锦囊牌的目标之一时，你摸1张牌并使该效果对你无效",
	["#luren"]="%from的【路人】被触发，%arg对%from无效",
	["yujian"]="预见",
	[":yujian"]="任何判定牌生效前，你可以用一张牌替换之。你替换判定牌后，此判定牌立刻生效，该判定结束后，若判定结果对判定者为有利且判定者不为你，则其可以让你摸1张牌",
	["@yujian"]="请打出一张牌替换原判定牌",
	["caice_card"]="猜测",
	["caice"]="猜测",
	[":caice"]="出牌阶段，你可以选择1名角色，说出一种牌的类型和花色，然后展示其一张手牌并获得之。若展示的牌与你所说的类型花色均一致，则该回合你可以继续使用该技能；否则你弃置一张手牌且该阶段不能继续使用此技能",
	["BasicCard"]="基础牌",
	["TrickCard"]="锦囊牌",
	["EquipCard"]="装备牌",
	["#caice"]="%from猜了%arg的%arg2",
	["designer:TC013"]="Nutari",
	["illustrator:TC013"]="狗神煌",
}

--式見蛍

TCM00=sgs.General(extension,"TCM00","god","5",true)

wuzhi=sgs.CreateTriggerSkill{
	name="wuzhi",
	events={sgs.GameStart,sgs.CardFinished,sgs.EventPhaseChanging,sgs.EventPhaseStart,sgs.BuryVictim,sgs.DamageForseen,sgs.Damaged},
	priority=5,
	frequency=sgs.Skill_Compulsory,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.BuryVictim and player:hasSkill(self:objectName()) then
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("@material")>0 then
					room:acquireSkill(p,"lingti")
					p:loseMark("@material")
				end
			end
		end
		local kei=room:findPlayerBySkillName(self:objectName())
		if not kei then return end
		for _,p in sgs.qlist(room:getAllPlayers()) do
			if kei:distanceTo(p)<=1 and p:hasSkill("lingti") then
				room:detachSkillFromPlayer(p,"lingti")
				p:gainMark("@material")
			elseif kei:distanceTo(p)>1 and p:getMark("@material")>0 then
				room:acquireSkill(p,"lingti")
				p:loseMark("@material")
			end
		end
		if event==sgs.DamageForseen then
			local damage=data:toDamage()
			if damage.to:objectName()==kei:objectName() and damage.nature~=sgs.DamageStruct_Normal then
				damage.nature=sgs.DamageStruct_Normal
				data:setValue(damage)
				local log=sgs.LogMessage()
				log.from=kei
				log.type="#wuzhi"
				room:sendLog(log)
				return false
			end
		end
	end
}

lingyin=sgs.CreateTriggerSkill{
	name="lingyin",
	events={sgs.EventPhaseEnd,sgs.PreHpRecover,sgs.DamageDone},
	frequency=sgs.Skill_Compulsory,	
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local kei=room:findPlayerBySkillName(self:objectName())
		if event==sgs.PreHpRecover and player:getMark("@hurt")>0 then
			local recover=data:toRecover()
			local log=sgs.LogMessage()
			log.to:append(player)
			log.type="#lingyin"
			if player:getMark("@hurt")>=recover.recover and recover.recover>0 then
				log.arg=recover.recover
				room:sendLog(log)
				player:loseAllMarks("@hurt")
				return true
			elseif recover.recover>0 then
				log.arg=player:getMark("@hurt")
				room:sendLog(log)
				recover.recover=recover.recover-player:getMark("@hurt")
				player:loseAllMarks("@hurt")
				data:setValue(recover)
				return false
			end
		end
		if event==sgs.DamageDone then
			local damage=data:toDamage()
			if damage.from and damage.from:hasSkill(self:objectName()) and damage.from:objectName()~=damage.to:objectName() and damage.to:isAlive() and damage.nature~=sgs.DamageStruct_Normal then
				damage.to:gainMark("@hurt",damage.damage)
			end
		end
	end,
}

juesi_prohibit=sgs.CreateProhibitSkill{
	name="#juesi_prohibit",
	is_prohibited=function(self,from,to,card)
		if to:hasSkill("juesi") and from:getHp()>to:getHp() then 
			return card:isKindOf("Slash")
		end
	end,
}

juesi_card=sgs.CreateSkillCard{
	name="juesi_card",
	target_fixed=true,
	on_use=function(self,room,source)
		room:loseMaxHp(source)
		room:setPlayerFlag(source,"juesi")
	end,
}

juesi_vs=sgs.CreateViewAsSkill{
	name="juesi",
	view_as=function()
		return juesi_card:clone()
	end,	
	enabled_at_play=function()
		return not sgs.Self:hasFlag("juesi")
	end,
}	

juesi=sgs.CreateTriggerSkill{
	name="juesi",
	events={sgs.ConfirmDamage,sgs.EventPhaseEnd},
	priority=2,
	view_as_skill=juesi_vs,
	can_trigger=function(self,player)
		return player:hasFlag("juesi")
	end,	
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.ConfirmDamage then
			local damage=data:toDamage()
			damage.damage=damage.damage+1
			damage.nature=sgs.DamageStruct_Thunder
			data:setValue(damage)
			local log=sgs.LogMessage()
			log.from=player
			log.type="#juesi"
			room:sendLog(log)
			return false
		end
		if event==sgs.EventPhaseEnd and player:getPhase()==sgs.Player_Play then
			room:setPlayerFlag(player,"-juesi")
		end	
	end,
}

canming=sgs.CreateTriggerSkill{
	name="canming",
	events={sgs.EventPhaseStart,sgs.BuryVictim,sgs.PreHpRecover},
	priority=2,
	frequency=sgs.Skill_Compulsory,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local kei=room:findPlayerBySkillName(self:objectName())
		if not kei then return end
		if event==sgs.BuryVictim and not player:hasSkill(self:objectName()) then
			local log=sgs.LogMessage()
			log.from=kei
			log.type="#canmingx"
			room:sendLog(log)
			if(kei:getMaxHp()<5)then
				room:setPlayerProperty(kei,"maxhp",sgs.QVariant(math.min(kei:getMaxHp()+1,5)))
			end	
			local recover=sgs.RecoverStruct()
			recover.who=kei
			room:recover(kei,recover)
		end
		if event==sgs.EventPhaseStart and player:objectName()==kei:objectName() and player:getPhase()==sgs.Player_Finish then
			if kei:getLostHp()>=2 then
				room:loseMaxHp(kei)
			end	
		end
	end,
}

TCM00:addSkill(wuzhi)
TCM00:addSkill(lingyin)
TCM00:addSkill(juesi_prohibit)
TCM00:addSkill(juesi)
TCM00:addSkill(canming)

sgs.LoadTranslationTable{
	["TCM00"]="式見蛍",
	["#TCM00"]="死にたい",
	["~TCM00"]="僕、死にたく？死にたくない？",
	["wuzhi"]="物质",
	[":wuzhi"]="<b>锁定技</b>，你与其距离为1的角色的【灵体】技能无效。你受到的属性伤害被认为是无属性",
	["#wuzhi"]="%from的【物质】触发，受到的属性伤害被视为无属性",
	["@material"]="物质",
	["lingyin"]="灵印",
	[":lingyin"]="<b>锁定技</b>，你对其他角色每造成1点属性伤害时在其面前放置一枚伤残标记，伤残标记会吸收目标下一次体力恢复，若恢复的体力超过伤残标记的数量，则多出的部分可以正常恢复，无论吸收多少（至少1点）都清除全部的伤残标记。",
	["#lingyin"]="%to的伤残标记吸收了其即将受到的%arg点体力回复",
	["@hurt"]="伤残",
	["juesi_card"]="决死",
	["juesi"]="决死",
	[":juesi"]="任何体力高于你体力的角色不能对你使用杀。出牌阶段，你可以自减1点体力上限，若如此做，该回合内你造成的伤害+1，并且造成的伤害均视为雷属性伤害，持续到该阶段结束。一阶段限一次。",
	["#juesi"]="%from的【决死】触发，造成的伤害+1",
	["canming"]="残命",
	[":canming"]="<b>锁定技</b>，场上除你以外任何角色死亡时，你增加1点体力上限（上限不超过5）并恢复1点体力。你回合结束阶段开始时，若你失去的体力不少于2点，你失去1点体力上限",
	["#canming"]="%from的【残命】触发",
	["#canmingx"]="%from的【残命】触发，增加了1点体力上限并恢复了1点体力",
	["hp"]="体力",
	["maxhp"]="体力上限",
	["designer:TCM00"]="Nutari",
	["illustrator:TCM00"]="てぃんくる",
}

--ユー

TCM01=sgs.General(extension, "TCM01", "god", "3",false)

lingti_prohibit=sgs.CreateProhibitSkill{
	name="#lingti_prohibit",
	is_prohibited=function(self,from,to,card)
		if to:hasSkill("lingti") and not from:hasFlag("drank") then
			return card:isKindOf("Slash") and not card:isKindOf("ThunderSlash")
		end
	end,
}

lingti=sgs.CreateTriggerSkill{
	name="lingti",
	events={sgs.GameStart,sgs.EventAcquireSkill,sgs.DamageForseen,sgs.Predamage,sgs.EventLoseSkill,sgs.GameJudgeOver},
	priority=2,
	frequency=sgs.Skill_Compulsory,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if (event==sgs.GameStart and player:hasSkill("lingti"))or (event==sgs.EventAcquireSkill and data:toString()==self:objectName()) then
			room:acquireSkill(player,"#lingti_prohibit")
			room:setPlayerCardLimitation(player,"use,response","Slash",false)
		end
		if (event==sgs.EventLoseSkill and data:toString()==self:objectName())or (event==sgs.GameJudgeOver and player:hasSkill(self:objectName())) then
			room:removePlayerCardLimitation(player,"use,response","Slash")
		end
		if not player:hasSkill("lingti") then return false end
		if event==sgs.Predamage then
			local damage=data:toDamage()
			if damage.nature~=sgs.DamageStruct_Thunder then
				local log=sgs.LogMessage()
				log.from=player
				log.type="#lingtix"
				room:sendLog(log)
				damage.nature=sgs.DamageStruct_Thunder
				data:setValue(damage)
			end
			if damage.to:isChained() then
				local log=sgs.LogMessage()
				log.from=player
				log.to:append(damage.to)
				log.type="#lingtixx"
				room:sendLog(log)
				damage.damage=damage.damage+1
				data:setValue(damage)
			else
				room:setPlayerProperty(damage.to,"chained",sgs.QVariant(true))
			end
		end
		if event==sgs.DamageForseen then
			local damage=data:toDamage()
			if damage.nature==sgs.DamageStruct_Normal then
				local log=sgs.LogMessage()
				log.from=player
				log.type="#lingti"
				room:sendLog(log)
				return true
			end
		end
	end,
}

ganshe_card=sgs.CreateSkillCard{
	name="ganshe_card",
	target_fixed=false,
	will_throw=false,
	filter=function(self,targets,to_select)
		if #targets>0 then return false end
		return to_select:objectName()~=sgs.Self:objectName()
	end,
	on_use=function(self,room,source,targets)
		local target=targets[1]
		local log=sgs.LogMessage()
		log.from=source
		log.to:append(target)
		card = sgs.Sanguosha:getCard(self:getEffectiveId())
		room:showCard(source,card:getId())
		local data=sgs.QVariant()
		local cardx=room:askForCard(target,".|"..card:getSuitString().."|.|hand|.","@ganshe",data,sgs.Card_MethodNone)
		room:setPlayerFlag(source,"ganshe_lost")
		if cardx~=nil then
			log.type="#ganshe"
			room:sendLog(log)
			room:moveCardTo(cardx,source,sgs.Player_PlaceHand,true)
			room:loseHp(source,1)
		else
			log.type="#ganshexx"
			room:sendLog(log)
			local damage=sgs.DamageStruct()
			damage.from=source
			damage.to=target
			damage.damage=1
			damage.nature=sgs.DamageStruct_Thunder
			room:damage(damage)
		end
		if target:isAlive() and not target:isChained() then
			room:setPlayerProperty(target,"chained",sgs.QVariant(true))
			room:setEmotion(target,"chain")
		end
	end,
}

ganshe_vs=sgs.CreateViewAsSkill{
	name="ganshe",
	n=1,
	view_filter=function(self,selected,to_select)
		return to_select:isKindOf("BasicCard") or to_select:isKindOf("Weapon") and not to_select:isEquipped()
	end,
	view_as=function(self,cards)
		if #cards==1 then
			local acard=ganshe_card:clone()
			acard:addSubcard(cards[1])
			acard:setSkillName("ganshe")
			return acard
		end
	end,
	enabled_at_play=function()
		return not sgs.Self:hasFlag("ganshe_lost")
	end,
}

ganshe=sgs.CreateTriggerSkill{
	name="ganshe",
	events=sgs.EventPhaseEnd,
	view_as_skill=ganshe_vs,
	on_trigger=function(self,event,player,data)
		if player:getPhase()==sgs.Player_Play then
			room:setPlayerFlag(source,"-ganshe_lost")
		end
	end,
}

fuyuan=sgs.CreateTriggerSkill{
	name="fuyuan",
	events={sgs.CardsMoveOneTime,sgs.EventPhaseEnd},
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.CardsMoveOneTime and player:getPhase()==sgs.Player_Discard then
			local move=data:toMoveOneTime()
			if move.to_place~=sgs.Player_DiscardPile then return end
			if move.from:objectName()~=player:objectName() then return end
			if player:hasFlag("fuyuanused") then return false end
			local x=move.card_ids:length()
			player:setMark("fuyuan",player:getMark("fuyuan")+x)
			if player:getMark("fuyuan")>=2 then
				room:setPlayerFlag(player,"fuyuanused")
				local recover=sgs.RecoverStruct()
				recover.who=player
				recover.recover=1
				local fuyuantargets=sgs.SPlayerList()
				for _,p in sgs.qlist(room:getAllPlayers()) do
					if p:isWounded() then
						fuyuantargets:append(p)
					end
				end
				if fuyuantargets:isEmpty() or not room:askForSkillInvoke(player,"fuyuan",data) then return false end
				local target=room:askForPlayerChosen(player,fuyuantargets,"fuyuan")
				room:recover(target,recover,true)
				room:recover(player,recover,true)
			end
		end
		if event==sgs.EventPhaseEnd and player:getPhase()==sgs.Player_Discard then
			player:setMark("fuyuan",0)
			room:setPlayerFlag(player,"-fuyuanused")
		end
	end,
}

TCM01:addSkill(lingti)
TCM01:addSkill(lingti_prohibit)
TCM01:addSkill(ganshe)
TCM01:addSkill(fuyuan)

sgs.LoadTranslationTable{
	["TCM01"]="ユー",
	["#TCM01"]="無邪気の浮遊霊",
	["~TCM01"]="まだ死にたくない",
	["#lingti_prohibit"]="灵体",
	["lingti"]="灵体",
	[":lingti"]="<b>锁定技</b>，你不能成为雷杀或者带有【酒】效果的杀以外的杀的目标，你不能使用和打出杀。你不会受到无属性伤害，你造成的所有伤害带有雷属性。你即将造成伤害前，若目标已处于“连环状态”则伤害+1，否则先将目标的武将牌横置",
	["#lingti"]="%from的【灵体】被触发，防止了这次无属性伤害",
	["#lingtix"]="%from的【灵体】被触发，造成的伤害视为雷属性",
	["#lingtixx"]="%from的【灵体】被触发，对处于连环状态的%to造成的伤害+1",
	["ganshe_card"]="干涉",
	["ganshe"]="干涉",
	["ganshex"]="干涉",
	[":ganshe"]="出牌阶段，你可以展示1张基础牌或者手牌中的武器牌并指定一个角色，令其展示1张相同花色的手牌，若能展示，你获得目标展示的牌并失去1点体力，否则你对目标造成1点雷电伤害。然后若目标未被横置则横置之。一阶段限一次",
	["#ganshe"]="%from的【干涉】发动，%to展示了同花色的牌，",
	["#ganshexx"]="%from的【干涉】发动，%to没能展示牌",
	["@ganshe"]="请展示一张相同花色的牌",
	["fuyuan"]="复原",
	[":fuyuan"]="弃牌阶段，若你弃置了2张或者以上的牌，你可以先恢复场上任意一名已受伤的角色1点体力，再恢复自己1点体力",
	["designer:TCM01"]="Nutari",
	["illustrator:TCM01"]="てぃんくる",
}

--神無鈴音

TCM02=sgs.General(extension,"TCM02","god","3",false)

jiejie_card=sgs.CreateSkillCard{
	name="jiejie_card",
	will_throw=false,
	target_fixed=false,
	filter=function(self,targets,to_select)
		return #targets<3
	end,
	on_use=function(self,room,source,targets)
		for i=1,#targets,1 do
			targets[i]:gainMark("@kekkai")
		end
	end,
}

jiejie_vs=sgs.CreateViewAsSkill{
	name="jiejie",
	n=0,
	view_as=function()
		return jiejie_card:clone()
	end,
	enabled_at_play=function()
		return false
	end,
	enabled_at_response=function(self,player,pattern)
		return pattern=="@@jiejie"
	end,
}

jiejie=sgs.CreateTriggerSkill{
	name="jiejie",
	view_as_skill=jiejie_vs,
	events={sgs.EventPhaseStart,sgs.DamageForseen,sgs.CardEffected,sgs.BuryVictim,sgs.EventLoseSkill},
	frequency=sgs.Skill_Frequent,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if (event==sgs.BuryVictim and player:hasSkill(self:objectName()))or (event==sgs.EventLoseSkill and data:toString()==self:objectName()) then
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("@kekkai")>0 then
					p:loseAllMarks("@kekkai")
				end
			end
		end
		local rinne=room:findPlayerBySkillName(self:objectName())
		if not rinne then return false end
		if event==sgs.EventPhaseStart and rinne:getPhase()==sgs.Player_Start then
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("@kekkai")>0 then
					p:loseAllMarks("@kekkai")
				end
			end
			room:askForUseCard(rinne,"@@jiejie","#jiejieask")
		end
		if event==sgs.DamageForseen then
			local damage=data:toDamage()
			if damage.from:hasFlag("lingbaoused") then return false end
			if damage.from and damage.to:getMark("@kekkai")+damage.from:getMark("@kekkai")~=1 then return false end
			if damage.nature~=sgs.DamageStruct_Normal then return false end			
			local log=sgs.LogMessage()
			log.from=damage.to
			log.to:append(damage.from)
			log.type="#jiejie"
			room:sendLog(log)
			return true
		end
		if event==sgs.CardEffected then
			local effect=data:toCardEffect()
			if not effect.card:isNDTrick() then return false end
			if effect.to:getMark("@kekkai")+effect.from:getMark("@kekkai")~=1 then return false end
			if effect.from:hasFlag("lingbaoused") then return false end
			local log=sgs.LogMessage()
			log.from=effect.to
			log.to:append(effect.from)
			log.arg=effect.card:objectName()
			log.type="#jiejiex"
			room:sendLog(log)
			return true
		end
	end,
}

lingbao_card=sgs.CreateSkillCard{
	name="lingbao_card",
	will_throw=false,
	target_fixed=false,
	filter=function(self,targets,to_select)
		if self:subcardsLength()==0 then
			return #targets==0 and to_select:objectName()~=sgs.Self:objectName()
		else
			return to_select:hasFlag("lingbaotarget")
		end
	end,
	on_use=function(self,room,source,targets)
		if self:subcardsLength()==0 then
			local i=0
			if source:getPile("sprite"):length()==4 then
				for _,cdid in sgs.qlist(source:getPile("sprite")) do
					room:throwCard(cdid,source)
				end
			else
				while i<4 do
					room:fillAG(source:getPile("sprite"), source)
					local card_id = room:askForAG(source, source:getPile("sprite"), false, "lingbao")
					if card_id ~= -1 then
						i = i + 1
						room:throwCard(card_id,source)
					end
					source:invoke("clearAG")
				end
			end
			room:setFixedDistance(source,targets[1],1)
			room:setPlayerFlag(targets[1],"wuqian")
			room:setPlayerFlag(targets[1],"lingbaotarget")
			room:setPlayerFlag(source,"lingbaoused")
		else
			for _,card in sgs.qlist(self:getSubcards()) do
				cdid = self:getEffectiveId()
				cardx = sgs.Sanguosha:getCard(cdid)
			end
			local slash=sgs.Sanguosha:cloneCard("thunder_slash",cardx:getSuit(),cardx:getNumber())
			slash:setSkillName("lingbao")
			slash:addSubcard(self:getEffectiveId())
			local use=sgs.CardUseStruct()
			use.from=source
			use.to:append(targets[1])
			use.card=slash
			room:useCard(use,true)
		end
	end,
}

lingbao_vs=sgs.CreateViewAsSkill{
	name="lingbao",
	n=1,
	view_filter=function(self,selected,to_select)
		if sgs.Self:hasFlag("lingbaoused") then return to_select:isKindOf("Slash") else return false end
	end,
	view_as=function(self,cards)
		if #cards==0 and not sgs.Self:hasFlag("lingbaoused") then
			return lingbao_card:clone()
		elseif #cards==1 then
			local acard=lingbao_card:clone()
			acard:addSubcard(cards[1]:getId())
			acard:setSkillName("lingbao")
			return acard
		end
	end,
	enabled_at_play=function()
		return sgs.Self:getPile("sprite"):length()>=4 or sgs.Self:hasFlag("lingbaoused")
	end,
}

lingbao=sgs.CreateTriggerSkill{
	name="lingbao",
	events={sgs.EventPhaseEnd,sgs.BuryVictim,sgs.EventLoseSkill},
	view_as_skill=lingbao_vs,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if (event==sgs.EventLoseSkill and data:toString()=="lingbao")or(event==sgs.BuryVictim and player:hasSkill("lingbao")) then
			room:setPlayerFlag(player,"-lingbaoused")
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasFlag("lingbaotarget") then
					room:setFixedDistance(player,p,-1)
					room:setPlayerFlag(p,"-wuqian")
					room:setPlayerFlag(p,"-lingbaotarget")
					break
				end
			end
		end
		if not player:hasSkill("lingbao") then return false end
		if (event==sgs.EventPhaseEnd and player:getPhase()==sgs.Player_Play) or event==sgs.BuryVictim then
			room:setPlayerFlag(player,"-lingbaoused")
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasFlag("lingbaotarget") then
					room:setFixedDistance(player,p,-1)
					room:setPlayerFlag(p,"-wuqian")
					room:setPlayerFlag(p,"-lingbaotarget")
					break
				end
			end
		end
	end,
}

TCM02:addSkill("wunv")
TCM02:addSkill(jiejie)
TCM02:addSkill("xiling")
TCM02:addSkill(lingbao)

sgs.LoadTranslationTable{
	["TCM02"]="神無鈴音",
	["#TCM02"]="巫女服なしの巫女",
	["~TCM02"]="わたしまだ一人前じゃないね",
	["jiejie_card"]="结界",
	["jiejie"]="结界",
	[":jiejie"]="回合开始阶段，你可以选择至多3个角色，令其处于“结界内”，其余角色则处于“结界外”。“结界”内外的角色不能互相造成无属性伤害，互相使用的锦囊牌无效。当你发动“灵爆”后，该阶段内你发动的效果不受结界影响。",
	["#jiejieask"]="请选择处于结界的目标",
	["~jiejie"]="选择1-3个角色，点击确定",
	["#jiejie"]="%from与%to分属于“结界”内外，%from即将受到的无属性伤害无效",
	["#jiejiex"]="%from与%to分属于“结界”内外，%to的锦囊%arg对%from无效",
	["@kekkai"]="结界",
	["lingbao_card"]="灵爆",
	["lingbao"]="灵爆",
	[":lingbao"]="出牌阶段，若你的【灵】数量不少于4，则你可以指定一个角色并弃置4张灵并获得以下效果：你和目标的距离锁定为1，你无视目标的防具，你可以把“杀”当作“雷杀”对目标使用任意次。效果持续到出牌阶段结束，一阶段限一次",
	["designer:TCM02"]="Nutari",
	["illustrator:TCM02"]="てぃんくる",
}

--神無深螺

TCM03=sgs.General(extension,"TCM03","god","3",false)

wunv=sgs.CreateTriggerSkill{
	name="wunv",
	events={sgs.PreHpReduced,sgs.Damage},
	priority=2,
	frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local damage=data:toDamage()
		if damage.nature==sgs.DamageStruct_Normal then return false end
		if event==sgs.PreHpReduced and damage.damage>1 then
			damage.damage=1
			data:setValue(damage)
			local log=sgs.LogMessage()
			log.from=player
			log.type="#wunv"
			room:sendLog(log)
		end
		local log=sgs.LogMessage()
		log.from=player
		log.type="#wunvx"
		room:sendLog(log)
		player:drawCards(1)
	end,
}

wukou_card=sgs.CreateSkillCard{
	name="wukou_card",
	target_fixed=false,
	will_throw=true,
	filter=function(self,targets,to_select)
		return #targets==0 and not to_select:isAllNude()
	end,	
	on_use=function(self,room,source,targets)
		local cdid=room:askForCardChosen(source,targets[1],"hej","wukou")
		room:throwCard(cdid,targets[1],source)
	end
}

wukou_vs=sgs.CreateViewAsSkill{
	name="wukou",
	n=0,
	view_as=function()
		return wukou_card:clone()
	end,
	enabled_at_play=function()
		return false
	end,
}	

wukou=sgs.CreateTriggerSkill{
	name="wukou",
	events=sgs.CardFinished,
	view_as_skill=wukou_vs,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local sinra=room:findPlayerBySkillName(self:objectName())
		if not sinra then return false end
		if sinra:distanceTo(player)>1 then return false end
		local use=data:toCardUse()
		if not use.card:isKindOf("TrickCard") or use.from:objectName()==sinra:objectName() then return false end
		room:askForUseCard(sinra,"@@wukou","@wukou")
	end,
}

xiling_distance=sgs.CreateDistanceSkill{
	name="#xiling_distance",
	correct_func=function(self,from,to)
		if from:getPile("sprite"):length()>0 then
			return -math.floor(from:getPile("sprite"):length()/2)
		end
	end,
}

xiling=sgs.CreateTriggerSkill{
	name="xiling",
	events={sgs.AskForRetrial,sgs.EventLoseSkill},
	frequency=sgs.Skill_Frequent,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.EventLoseSkill and data:toString()==self:objectName() then
			player:removePileByName("sprite")
		end
		if event==sgs.AskForRetrial then
			local judge=data:toJudge()
			if not player:hasSkill(self:objectName()) or not room:askForSkillInvoke(player,self:objectName()) then return false end
			local id=room:getNCards(1):first()
			local card=sgs.Sanguosha:getCard(id)
			local reason=sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER,player:objectName())
			reason.m_skillName=self:objectName()
			room:moveCardTo(card,nil,sgs.Player_PlaceTable,reason,true)	
			room:getThread():delay(1000)
			if room:askForChoice(player,self:objectName(),"changejudge+notchange",data)=="changejudge" then
				room:retrial(card, player, judge, self:objectName(),true)
			else
				room:moveCardTo(card,player,sgs.Player_PlaceHand,false)
			end
			if not player:isKongcheng() then
				cardid=room:askForCardChosen(player,player,"h",self:objectName())
				player:addToPile("sprite",cardid)
			end
			return false
		end
	end,
}

caoling_card=sgs.CreateSkillCard{
	name="caoling_card",
	will_throw=false,
	target_fixed=false,
	filter=function(self,targets,to_select)
		return #targets<math.floor(sgs.Self:getPile("sprite"):length()/2) and not to_select:hasFlag("caolingused")
	end,
	on_use=function(self,room,source,targets)
		local cards={}
		local i=0
		while i<2 do
			room:fillAG(source:getPile("sprite"), source)
			local card_id = room:askForAG(source, source:getPile("sprite"), false, "caoling")
			if card_id ~= -1 then
				i = i + 1
				cards[i]=sgs.Sanguosha:getCard(card_id)
				room:throwCard(card_id,source)
			end
			source:invoke("clearAG")
		end
		if cards[1]:sameColorWith(cards[2]) then
			local damage=sgs.DamageStruct()
			damage.from=source
			for i=1,#targets,1 do
				if cards[1]:isRed() then damage.nature=sgs.DamageStruct_Fire else damage.nature=sgs.DamageStruct_Thunder end
				damage.damage=1
				damage.to=targets[i]
				room:damage(damage)
				room:setPlayerFlag(targets[i],"caolingused")
			end
		else
			local recover=sgs.RecoverStruct()
			recover.recover=1
			recover.who=source
			for i=1,#targets,1 do
				room:recover(targets[i],recover,true)
				room:setPlayerFlag(targets[i],"caolingused")
			end
		end		
	end,
}

caoling_vs=sgs.CreateViewAsSkill{
	name="caoling",
	n=0,
	view_as=function()
		return caoling_card:clone()
	end,
	enabled_at_play=function()
		return sgs.Self:getPile("sprite"):length()>=2
	end,
}

caoling=sgs.CreateTriggerSkill{
	name="caoling",
	events=sgs.EventPhaseEnd,
	view_as_skill=caoling_vs,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if player:getPhase()==sgs.Player_Play then
			for _,p in sgs.qlist(room:getAllPlayers()) do
				room:setPlayerFlag(p,"-caolingused")
			end
		end
	end,
}

TCM03:addSkill(wunv)
TCM03:addSkill(wukou)
TCM03:addSkill(xiling)
TCM03:addSkill(xiling_distance)
TCM03:addSkill(caoling)

sgs.LoadTranslationTable{
	["TCM03"]="神無深螺",
	["#TCM03"]="無口の巫女",
	["~TCM03"]="鈴音はあなたをよろしく…",
	["wunv"]="巫女",
	[":wunv"]="<b>锁定技</b>，你受到的属性伤害不超过1点。你每造成或者受到一次属性伤害摸1张牌",
	["#wunv"]="%from的【巫女】发动，受到的属性伤害减至1点",
	["#wunvx"]="%from的【巫女】发动",
	["wukou_card"]="无口",
	["wukou"]="无口",
	[":wukou"]="你与其距离为1以内的其他角色每使用1张锦囊牌结束，你可以弃置场上任意角色区域内（手牌，装备区，判定区）的1张牌。",
	["@wukou"]="你可以发动无口弃置一张牌",
	["~wukou"]="选择任意一名角色->点击确定",
	["xiling"]="吸灵",
	[":xiling"]="任何判定牌生效前，你可以展示牌堆顶的1张牌，然后你可以选择是否用该牌替换原有的判定牌，然后收回未作为判定牌的那张牌，并从手牌里选一张置于你的武将牌上，称为【灵】。你与其他角色计算距离时始终-x，x为灵数量的一半（向下取整）",
	["#xiling_distance"]="灵",
	["sprite"]="灵",
	["changejudge"]="改变判定牌",
	["notchange"]="不改变判定牌",
	["caoling"]="操灵",
	[":caoling"]="出牌阶段，若你的【灵】数量不少于2，则你可以选择至多x个角色，x为你【灵】的数量一半（向下取整），然后弃置2张【灵】，若弃置的【灵】颜色相同，则对选中的角色依次造成1点火焰（同为红色）或者雷电（同为黑色）伤害，若不同，则恢复选中角色各1点体力。一阶段一个角色限选择一次",
	["caoling_card"]="操灵",
	["designer:TCM03"]="Nutari",
	["illustrator:TCM03"]="てぃんくる",
}

--真儀瑠紗鳥（帰宅部長）

TCM04=sgs.General(extension,"TCM04","god","3",false)

zhidao_card=sgs.CreateSkillCard{
	name="zhidao_card",
	will_throw=false,
	target_fixed=true,
	on_use=function(self,room,player,targets)
		local target=room:getCurrent()
		card=sgs.Sanguosha:getCard(self:getEffectiveId())
		if card:isKindOf("BasicCard") then
			room:setPlayerFlag(target,"zhidaobc")
		elseif card:isKindOf("TrickCard") then
			room:setPlayerFlag(target,"zhidaotc")
		else
			room:setPlayerFlag(target,"zhidaoec")
		end
		room:moveCardTo(card,target,sgs.Player_PlaceHand,false)
		room:showCard(target,card:getId())
	end,
}

zhidao_vs=sgs.CreateViewAsSkill{
	name="zhidao",
	n=1,
	view_filter=function(self,selected,to_select)
		return true
	end,
	view_as=function(self,cards)
		if #cards==1 then
			local acard=zhidao_card:clone()
			acard:addSubcard(cards[1]:getId())
			acard:setSkillName("zhidao")
			return acard
		end
	end,
	enabled_at_play=function()
		return false
	end,
	enabled_at_response=function(self,player,pattern)
		return pattern=="@@zhidao"
	end,
}

zhidao=sgs.CreateTriggerSkill{
	name="zhidao",
	events={sgs.EventPhaseStart,sgs.CardUsed,sgs.EventPhaseEnd},
	frequency=sgs.Skill_Frequent,
	view_as_skill=zhidao_vs,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local magiru=room:findPlayerBySkillName(self:objectName())
		if not magiru then return false end
		if player:objectName()==magiru:objectName() then return false end
		if event==sgs.EventPhaseStart and player:getPhase()==sgs.Player_Play then
			room:askForUseCard(magiru,"@@zhidao","#zhidaoask")
		end
		if event==sgs.CardUsed then
			local use=data:toCardUse()
			if use.from:hasFlag("zhidaobc") and use.card:isKindOf("BasicCard") then magiru:drawCards(1) end
			if use.from:hasFlag("zhidaotc") and use.card:isKindOf("TrickCard") then magiru:drawCards(1) end
			if use.from:hasFlag("zhidaoec") and use.card:isKindOf("EquipCard") then magiru:drawCards(1)	end
		end
		if event==sgs.EventPhaseEnd and player:getPhase()==sgs.Player_Play then
			room:setPlayerFlag(player,"-zhidaobc")
			room:setPlayerFlag(player,"-zhidaotc")
			room:setPlayerFlag(player,"-zhidaoec")
		end
	end,
}

houjue_card=sgs.CreateSkillCard{
	name="houjue_card",
	filter=function(self,targets,to_select)
		return sgs.Self:objectName()~=to_select:objectName() and not to_select:isNude() and sgs.Self:inMyAttackRange(to_select) and #targets<3-sgs.Self:getHandcardNum()
	end,
	feasible=function(self,targets)
		return #targets>=0
	end,	
	on_use=function(self,room,source,targets)
		local moves=sgs.CardsMoveList()
		local reason=sgs.CardMoveReason()
		reason.m_reason=sgs.CardMoveReason_S_REASON_ROB
		reason.m_skillName="houjue"
		reason.m_player=source:objectName()
		for i=1,#targets,1 do
			local move=sgs.CardsMoveStruct()
			move.card_ids:append(room:askForCardChosen(source,targets[i],"he","houjue"))
			move.reason=reason
			move.to=source
			move.to_place=sgs.Player_PlaceHand
			moves:append(move)
			room:setPlayerFlag(targets[i],"houjue")
		end
		room:moveCardsAtomic(moves,false)
	end
}

houjue_vs=sgs.CreateViewAsSkill{
	name="houjue",
	n=0,
	view_as=function()
		return houjue_card:clone()
	end,
	enabled_at_play=function()
		return false
	end,
}	

houjue=sgs.CreateTriggerSkill{
	name="houjue",
	events={sgs.CardsMoveOneTime,sgs.EventPhaseStart,sgs.EventPhaseEnd,sgs.EventPhaseChanging},
	priority=2,
	view_as_skill=houjue_vs,
	frequency=sgs.Skill_Compulsory,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local magiru=room:findPlayerBySkillName(self:objectName())
		if not magiru then return false end
		if event==sgs.CardsMoveOneTime or (event==sgs.EventPhaseEnd and magiru:getPhase()==sgs.Player_Discard) then
			if magiru:getHandcardNum()<3 then
				if event==sgs.CardsMoveOneTime then
					local move=data:toMoveOneTime()
					local reason=move.reason
					if reason.m_skillName==self:objectName() or reason.m_skillName=="shijie" then return end
					if magiru:getPhase()==sgs.Player_Discard or (move.from:objectName()~=magiru:objectName() and move.to:objectName()~=magiru:objectName()) then return false end
				end
				room:askForUseCard(magiru,"@@houjue","@houjue")
				if magiru:getHandcardNum()<3 then
					magiru:drawCards(3-magiru:getHandcardNum())
				end	
			end
		end
		if event==sgs.EventPhaseStart and (magiru:getPhase()==sgs.Player_Draw or magiru:getPhase()==sgs.Player_Judge) then
			local log=sgs.LogMessage()
			log.from=player
			log.arg=magiru:getPhaseString()
			log.type="#houjuex"
			room:sendLog(log)
			return true
		end
		if event==sgs.EventPhaseChanging and data:toPhaseChange().to==sgs.Player_NotActive then
			local log=sgs.LogMessage()
			log.type="#houjue"			
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:hasFlag("houjue") then
					log.from=p
					room:sendLog(log)
					p:drawCards(1)
					room:setPlayerFlag(p,"-houjue")
				end
			end
		end	
	end,
}


TCM04:addSkill(zhidao)
TCM04:addSkill(houjue)

sgs.LoadTranslationTable{
	["TCM04"]="真儀瑠紗鳥(物)",
	["#TCM04"]="帰宅部長",
	["~TCM04"]="後輩なんでじあない、私は蛍がすきだ……",
	["zhidao_card"]="指导",
	["zhidao"]="指导",
	[":zhidao"]="其他角色出牌阶段开始时，你可以将一张牌交给他并展示，若如此做，该角色该回合内每使用一张同类型的牌，你摸1张牌",
	["#zhidaoask"]="你可以使用【指导】",
	["~zhidao"]="选择一张牌（包括装备）->点击确定",
	["houjue_card"]="后觉",
	["houjue"]="后觉",
	[":houjue"]="<b>锁定技</b>，你跳过判定和摸牌阶段。弃牌阶段外，当你手牌不足3时，你可以获得你攻击范围内的至多x名角色各1张牌，x为不足3张时所缺的牌数，然后若手牌数依旧不足3张则从牌堆中补足3张。其他角色因后觉而失去牌后，在当前角色回合结束后立刻摸1张牌",
	["@houjue"]="你可以发动后觉获得其他角色的牌",
	["~houjue"]="选择你射程内的若干角色->点击确定",
	["#houjue"]="%from因【后觉】失去了牌",
	["#houjuex"]="%from的【后觉】触发，跳过了%arg阶段",
	["designer:TCM04"]="Nutari",
	["illustrator:TCM04"]="てぃんくる",
}

--日向耀

TCM05=sgs.General(extension, "TCM05", "god", "3", false)

jiangsi=sgs.CreateTriggerSkill{
	name="jiangsi",
	events=sgs.EventPhaseStart,
	priority=2,
	frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if player:getPhase()==sgs.Player_Finish then
			local log=sgs.LogMessage()
			log.from=player
			log.type="#jiangsi"
			room:sendLog(log)
			room:loseHp(player)
			if player:isChained() then
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:isChained() and p:getHp()>player:getHp() then
						room:loseHp(p)
					end
				end
			end
		end
	end,
}

tongsi_card=sgs.CreateSkillCard{
	name="tongsi_card",
	will_throw=false,
	target_fixed=false,
	filter=function(self,targets,to_select)
		return #targets<sgs.Self:getLostHp()*2
	end,
	on_use=function(self,room,source,targets)
		for i=1,#targets,1 do
			if targets[i]:isChained() then
				room:setPlayerProperty(targets[i], "chained", sgs.QVariant(false))
			else
				room:setPlayerProperty(targets[i], "chained", sgs.QVariant(true))
			end
			room:setEmotion(targets[i],"chain")
		end
	end,
}

tongsi_vs=sgs.CreateViewAsSkill{
	name="tongsi",
	n=0,
	view_as=function()
		return tongsi_card:clone()
	end,
	enabled_at_play=function()
		return false
	end,
}

tongsi=sgs.CreateTriggerSkill{
	name="tongsi",
	view_as_skill=tongsi_vs,
	events=sgs.EventPhaseStart,
	frequency=sgs.Skill_Frequent,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if player:getPhase()==sgs.Player_Start then
			if not player:isWounded() or not room:askForSkillInvoke(player,"tongsi") then return false end
			room:askForUseCard(player,"@@tongsi","#tongsiask")
		end
	end,
}

yuanling=sgs.CreateTriggerSkill{
	name="yuanling",
	events={sgs.GameOverJudge,sgs.BuryVictim,sgs.Death},
	priority=7,
	frequency=sgs.Skill_Wake,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.GameOverJudge then
			if not player:hasSkill(self:objectName()) or player:getMark("yuanling")>0 then return false end
			player:gainMark("yuanling")
			player:gainMark("@waked")
			local log=sgs.LogMessage()
			log.type="#yuanling"
			log.from=player
			room:sendLog(log)
			room:revivePlayer(player)
			local recover=sgs.RecoverStruct()
			recover.recover=player:getMaxHp()-player:getHp()
			recover.who=player
			room:recover(player,recover)
			room:detachSkillFromPlayer(player,"jiangsi")
			room:acquireSkill(player,"lingti")
			room:acquireSkill(player,"youren")
			room:acquireSkill(player,"#youren_tr")
			if player:isChained() then room:setPlayerProperty(player, "chained", sgs.QVariant(false)) end
			if not player:faceUp() then player:turnOver() end
			return true
		end
		if (event==sgs.BuryVictim or event==sgs.Death and player:objectName()==data:toDeath().who:objectName())and player:isAlive() and player:hasSkill(self:objectName()) then
			return true
		end
	end,
}

youren_card=sgs.CreateSkillCard{
	name="youren_card",
	will_throw=false,
	target_fixed=false,
	filter=function(self,targets,to_select)
		cardx = sgs.Sanguosha:getCard(self:getEffectiveId())
        local slash=sgs.Sanguosha:cloneCard("thunder_slash",cardx:getSuit(),cardx:getNumber())
		return #targets==0 and sgs.Self:canSlash(to_select,slash,false)
	end,
	on_use=function(self,room,source,targets)
		cardx = sgs.Sanguosha:getCard(self:getEffectiveId())
        local slash=sgs.Sanguosha:cloneCard("thunder_slash",cardx:getSuit(),cardx:getNumber())
		slash:setSkillName("youren")
		slash:addSubcard(cardx:getId())
		local use=sgs.CardUseStruct()
		use.from=source,
		use.to:append(targets[1])
		use.card=slash
		slash:onUse(room,use)
		source:addHistory("Slash")
		source:invoke("addHistory","Slash:")
		room:broadcastInvoke("addHistory", "pushPile")		
	end,
}

youren_vs=sgs.CreateViewAsSkill{
	name="youren",
	n=1,
	view_filter=function(self,selected,to_select)
		return to_select:isKindOf("Slash") or to_select:isKindOf("EquipCard")
	end,
	view_as=function(self,cards)
		if #cards==1 then
			local acard=youren_card:clone()
			acard:addSubcard(cards[1]:getId())
			acard:setSkillName("youren")
			return acard
		end
	end,
	enabled_at_play=function()
		return sgs.Self:canSlashWithoutCrossbow() or (sgs.Self:getWeapon() and sgs.Self:getWeapon():getClassName()=="Crossbow")
	end,
}

youren=sgs.CreateTriggerSkill{
	name="youren",
	priority=3,
	events={sgs.Dying},
	view_as_skill=youren_vs,
	can_trigger=function(self,player)
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local akaru=room:findPlayerBySkillName("youren")
		if not akaru then return false end
		if event==sgs.Dying and player:objectName()==data:toDying().who:objectName() then
			local dying=data:toDying()
			if dying.damage.card:isKindOf("ThunderSlash") and dying.damage.card:getSkillName()=="youren" and dying.damage.from:hasSkill("youren") then
				if data:toDying().who:isDead() or data:toDying().who:getHp()>0 or not room:askForSkillInvoke(akaru,"youren",data) then return false end
				local judge=sgs.JudgeStruct()
				judge.who=akaru
				judge.pattern=sgs.QRegExp("(.*):(heart):(.*)")
				judge.play_animation=true
				judge.good=false
				room:judge(judge)
				if judge:isGood() then
					local log=sgs.LogMessage()
					log.from=akaru
					log.to:append(dying.who)
					log.type="#youren"
					room:sendLog(log)
					room:killPlayer(dying.who,dying.damage)
					return true
				end
			end
		end
	end
}

local skill=sgs.Sanguosha:getSkill("youren")
if not skill then
	local skillList=sgs.SkillList()
	skillList:append(youren)
	sgs.Sanguosha:addSkills(skillList)
end

TCM05:addSkill(jiangsi)
TCM05:addSkill(tongsi)
TCM05:addSkill(yuanling)
TCM05:addSkill("#lingti_prohibit")

sgs.LoadTranslationTable{
	["TCM05"]="日向耀",
	["#TCM05"]="死に近い",
	["~TCM05"]="へへ、死んじあだ",
	["jiangsi"]="将死",
	[":jiangsi"]="<b>锁定技</b>，你回合结束时，你失去1点体力。若你处于连环状态，则所有其他处于连环状态且体力高于你的角色均失去1点体力。",
	["#jiangsi"]="%from的【将死】发动",
	["tongsi_card"]="同死",
	["tongsi"]="同死",
	[":tongsi"]="回合开始时，若你已受伤，你可以指定至多x*2个角色，将其横置或者重置，x为你已失去的体力",
	["#tongsiask"]="请你可以发动【同死】",
	["~tongsi"]="选择若干个目标->点击确定",
	["youren_card"]="幽刃",
	["youren"]="幽刃",
	[":youren"]="出牌阶段，你可以把一张杀或者装备牌当作雷杀来使用，该杀无限距离。你的【幽刃】使其他角色濒死时，你可以判定，若不为红桃，其直接死亡（可以在【灵体】时使用）",
	["wraith"]="怨灵",
	["yuanling"]="怨灵",
	["#yuanling"]="%from的【怨灵】触发，将体力恢复至上限",
	[":yuanling"]="<b>觉醒技</b>，当你求桃后依旧濒死或死亡时，你将回满体力，重置并翻至正面朝上，然后失去【将死】，获得【灵体】和【幽刃】(出牌阶段，你可以把一张杀或者装备牌当作雷杀来使用，该杀无限距离。你的【幽刃】使其他角色濒死时，你可以判定，若不为红桃，其直接死亡(可以在【灵体】时使用))",
	["#youren"]="%from的【幽刃】触发，处于濒死的%to即死",
	["designer:TCM05"]="Nutari",
	["illustrator:TCM05"]="てぃんくる",
}

--式見傘

TCM06=sgs.General(extension,"TCM06","god","3",false)

chuqiao=sgs.CreateTriggerSkill{
	name="chuqiao",
	events={sgs.TurnStart,sgs.TurnedOver},
	priority=2,
	frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.TurnStart then
			if player:faceUp() then return end
			player:turnOver()
			return false
		end
		if event==sgs.TurnedOver then
			if not player:faceUp() then
				room:acquireSkill(player,"lingti")
			else
				if player:hasSkill("lingti") then
					room:detachSkillFromPlayer(player,"lingti")
				elseif player:getMark("@material")>0 then
					player:loseAllMarks("@material")
				end
			end
		end
	end,
}

junheng_card=sgs.CreateSkillCard{
	name="junheng_card",
	will_throw=true,
	target_fixed=false,
	filter=function(self,targets,to_select)
		if #targets==1 then
			return (to_select:getHp()>targets[1]:getHp() and targets[1]:inMyAttackRange(to_select))or(to_select:getHp()<targets[1]:getHp() and to_select:inMyAttackRange(targets[1]))
		else
			return #targets<=1
		end
	end,
	feasible=function(self,targets)
		return #targets==2
	end,
	on_use=function(self,room,source,targets)
		source:turnOver()
		local max
		local min
		if targets[1]:getHp()>targets[2]:getHp() then
			max=targets[1]
			min=targets[2]
		else
			max=targets[2]
			min=targets[1]
		end
		local recover=sgs.RecoverStruct()
		recover.who=min
		recover.recover=1
		room:recover(min,recover)
		room:loseHp(max)
	end,
}

junheng_vs=sgs.CreateViewAsSkill{
	name="junheng",
	n=1,
	view_filter=function(self,selected,to_select)
		return true
	end,
	view_as=function(self,cards)
		if #cards==1 then
			local acard=junheng_card:clone()
			acard:setSkillName("junheng")
			acard:addSubcard(cards[1]:getId())
			return acard
		end
	end,
	enabled_at_play=function()
		return not sgs.Self:hasSkill("lingti")
	end,
}

junheng=sgs.CreateTriggerSkill{
	name="junheng",
	events=sgs.Dying,
	view_as_skill=junheng_vs,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local san=room:findPlayerBySkillName("junheng")
		if not san or san:hasSkill("lingti") then return false end
		if player:objectName()~=data:toDying().who:objectName() then return end
		if san:objectName()==data:toDying().who:objectName()or san:isNude() or data:toDying().who:getHp()>0 or data:toDying().who:isDead() or not room:askForSkillInvoke(san,"junheng",data) then return false end
		room:askForDiscard(san,"junheng",1,1,false,true)
		local players=sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(data:toDying().who)) do
			if data:toDying().who:inMyAttackRange(p) then players:append(p) end
		end
		if players:isEmpty() then return end
		local playerx=room:askForPlayerChosen(san,players,"junheng")
		san:turnOver()
		room:loseHp(playerx)
		local recover=sgs.RecoverStruct()
		recover.who=san
		recover.recover=1
		room:recover(data:toDying().who,recover,true)
	end,
}

yuanqi_max=sgs.CreateMaxCardsSkill{
	name="#yuanqi_max",
	extra_func=function(self,player)
		if player:hasSkill("yuanqi") then
			return player:getMaxHp()
		end
	end,
}

yuanqi=sgs.CreateTriggerSkill{
	name="yuanqi",
	events={sgs.Damaged,sgs.EventLoseSkill},
	frequency=sgs.Skill_Compulsory,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.EventLoseSkill and (data:toString()==self:objectName() or data:toString()=="lingti") then
			player:loseAllMarks("@genki")
		end
		local san=room:findPlayerBySkillName(self:objectName())
		if not san then return false end
		if event==sgs.Damaged then
			local damage=data:toDamage()
			if damage.from and damage.from:objectName()~=san:objectName() and damage.to:objectName()~=san:objectName() then
				if not san:hasSkill("lingti") then return end
				local x=math.min(damage.damage,math.min(5,room:alivePlayerCount())-san:getMark("@genki"))
				if x>0 then
					san:drawCards(x)
					san:gainMark("@genki",x)
				end
			end
			if damage.to:objectName()==san:objectName() then
				san:turnOver()
			end
		end
	end,
}

TCM06:addSkill(chuqiao)
TCM06:addSkill("#lingti_prohibit")
TCM06:addSkill(junheng)
TCM06:addSkill(yuanqi_max)
TCM06:addSkill(yuanqi)

sgs.LoadTranslationTable{
	["TCM06"]="式見傘",
	["#TCM06"]="幽体離脱の妹",
	["~TCM06"]="お兄ちゃんはあたしのお兄ちゃんだ",
	["chuqiao"]="出窍",
	[":chuqiao"]="<b>锁定技</b>，当你的武将牌被翻至背面/正面朝上时，你获得/失去【灵体】技能。你回合开始若武将牌背面朝上，你将其翻至正面朝上后依旧可以进行正常的回合。",
	["junheng_card"]="均衡",
	["junheng"]="均衡",
	[":junheng"]="出牌阶段，若你不处于【灵体】，则你可以弃置1张牌并将自己的武将牌翻面，选择2个体力不相同的角色(其中体力较高那方必须在体力较少那方的射程内)，令其中体力较高的一方减少1点体力并回复体力较少1方1点体力。其他角色濒死时，若你不处于【灵体】，你可以弃置1张牌并将武将翻面，然后选择该角色以外的角色（必须在该角色射程内），令其减少1点体力回复濒死角色1点体力",
	["yuanqi"]="元气",
	[":yuanqi"]="<b>锁定技</b>，你的手牌上限始终+X，X为你最大体力。当你处于【灵体】时，每当除你以外的角色受到不来自于你的伤害时，每1点伤害你摸1张牌。此效果最多发动X次，X为场上存活人数且不大于5，直到你失去【灵体】时重置。你受到伤害时，将自己的武将牌翻面。",
	["yqdraw"]="摸牌",
	["yqrecover"]="恢复体力",
	["huifu"]="恢复你以外受伤角色1点体力",
	["nohuifu"]="不恢复",
	["#yuanqi"]="%from发动【元气】次数达到指定数量",
	["@genki"]="元气",
	["designer:TCM06"]="Nutari",
	["illustrator:TCM06"]="てぃんくる",
}

--神

TCX00 = sgs.General(extension, "$TCX00", "god", "1", false,true)

swtmp=""
shenyou=sgs.CreateViewAsSkill{
	name = "shenyou",
	n=1,
	view_filter=function(self,selected,to_select)
		return true
	end,
	view_as=function(self,cards)
		if #cards==1 then
			local acard = cards[1]
			acard=sgs.Sanguosha:cloneCard(swtmp,sgs.Card_NoSuit,0)
			acard:addSubcard(cards[1]:getId())
			acard:setSkillName(self:objectName())
			return acard
		end
	end,
	enabled_at_play=function()
		return false
	end,
	enabled_at_response=function(self,player,pattern)
		if  (pattern=="nullification") or (pattern=="jink") or (pattern=="slash") or (pattern=="peach")then
			swtmp = pattern
			return true
		end
		if (pattern=="peach+analeptic") then
			swtmp="peach"
			return true
		end
	end,
	enabled_at_nullification=function(self,player)
		return true
	end,
}

tianbing=sgs.CreateDistanceSkill{
	name="tianbing",
	correct_func=function(self,from,to)
		if from:hasSkill(self:objectName()) then
			return -100
		end
	end,
}

weiya=sgs.CreateTriggerSkill{
	name="weiya",
	frequency =sgs.Skill_Compulsory,
	priority=2,
	events= {sgs.SlashProceed},
	on_trigger = function(self,event,player,data)
		local room=player:getRoom()
		local effect = data:toSlashEffect()
		local log=sgs.LogMessage()
		log.from=player
		log.type="#weiya"
		room:sendLog(log)
		room:slashResult(effect,nil)
		return true
	end,
}

juesha=sgs.CreateTriggerSkill{
	name="juesha",
	frequency =sgs.Skill_Compulsory,
	priority=2,
	events={sgs.Predamage},
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local damage=data:toDamage()
		local log=sgs.LogMessage()
		log.from=player
		log.to:append(damage.to)
		log.type="#juesha"
		room:sendLog(log)
		if (event==sgs.Predamage) then
			local c=damage.damage
			if player:hasLordSkill("TCtianming") then
				room:loseMaxHp(damage.to,c+1)
			else
				room:loseMaxHp(damage.to,c)
			end
			return true
		end
	end,
}

huanxiang=sgs.CreateProhibitSkill{
	name = "huanxiang",
	is_prohibited=function(self,from,to,card)
		if to:hasSkill(self:objectName()) and from:distanceTo(to)<2 then
		return (card:isKindOf("Slash"))
		end
	end,
}

luanzhanc=sgs.CreateSkillCard{
	name="luanzhanc",
	target_fixed=false,
	will_throw=true,
	filter=function()
		return true
	end,
	on_use=function(self,room,source,targets)
		local use=sgs.CardUseStruct()
		local card=sgs.Sanguosha:cloneCard("fire_slash",sgs.Card_NoSuit,0)
		card:setSkillName("luanzhan")
		use.card=card
		use.from=source
		for i=1,10,1 do
			if targets[i]~=nil then
				use.to:append(targets[i])
			end
		end
		room:useCard(use,true)
	end,
}


luanzhan=sgs.CreateViewAsSkill{
	name="luanzhan",
	n=1,
	view_filter = function(self,selected,to_select)
		return to_select:isRed() or to_select:isBlack()
	end,
	view_as = function(self,cards)
		if #cards==1 then
			local acard=luanzhanc:clone()
			acard:addSubcard(cards[1])
			acard:setSkillName(self:objectName())
			return acard
		end
	end,
	enabled_at_play = function()
		return sgs.Self:canSlashWithoutCrossbow() or ((sgs.Self:getWeapon()) and (sgs.Self:getWeapon():getClassName()=="Crossbow"))
	end,
}

TCtianming=sgs.CreateTriggerSkill{
	name="TCtianming$",
	frequency =sgs.Skill_Compulsory,
	priority=2,
	events={sgs.GameStart},
	on_trigger=function(self,event,player,data)
		if event==sgs.GameStart then
			if not player:hasLordSkill(self:objectName()) then return end
			local room=player:getRoom()
			room:acquireSkill(player, "paoxiao")
		end
	end,
}

tczhuanshi=sgs.CreateTriggerSkill{
	name="#tczhuanshi",
	events={sgs.GameOverJudge,sgs.BuryVictim},
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.GameOverJudge and player:hasSkill(self:objectName()) and room:askForSkillInvoke(player,self:objectName()) then
			room:revivePlayer(player)
			return true
		end
		if event==sgs.BuryVictim and player:isAlive() then
			if player:getGeneralName()=="TCX00" then
				room:changeHero(player,"TCA00",true,true,false,true)
			elseif player:getGeneralName()=="TC006" then
				room:changeHero(player,"TCX03",true,true,false,true)
			elseif player:getGeneralName()=="TC007"	then
				room:changeHero(player,"TCX04",true,true,false,true)
			elseif player:getGeneralName()=="TC012" or player:getGeneralName()=="TCM04" then
				room:changeHero(player,"TCX06",true,true,false,true)
			elseif player:getGeneralName()=="TCM00" then
				room:changeHero(player,"TCX01",true,true,false,true)
			elseif player:getGeneralName()=="TCM01" then
				room:changeHero(player,"TCX02",true,true,false,true)
				room:removePlayerCardLimitation(player,"use,response","Slash")
			elseif player:getGeneralName()=="TC001"	then
				room:changeHero(player,"TCX07",true,true,false,true)
			end
			return true
		end
	end,
}

TCX00:addSkill(tianbing)
TCX00:addSkill(shenyou)
TCX00:addSkill(juesha)
TCX00:addSkill(weiya)
TCX00:addSkill(huanxiang)
TCX00:addSkill("lianying")
TCX00:addSkill(luanzhan)
TCX00:addSkill(TCtianming)
TCX00:addSkill(tczhuanshi)
TC006:addSkill("#tczhuanshi")
TC007:addSkill("#tczhuanshi")
TC012:addSkill("#tczhuanshi")
TCM04:addSkill("#tczhuanshi")
TCM00:addSkill("#tczhuanshi")
TCM01:addSkill("#tczhuanshi")
TC001:addSkill("#tczhuanshi")

sgs.LoadTranslationTable{
	["tc"] = "珍远",
	["TCX00"] = "Nutari",
	["#TCX00"] = "神",
	["~TCX00"] ="咦，我怎么死的？",
	["shenyou"] = "神佑",
	[":shenyou"] = "出牌阶段以外，你可以把任意牌当作杀闪桃和无懈可击来打出",
	["tianbing"] = "天兵",
	[":tianbing"] = "<b>锁定技</b>，你与其他角色计算距离时始终为1",
	["weiya"] = "威压",
	[":weiya"] = "<b>锁定技</b>，你的杀不能被躲闪",
	["#weiya"] = "%from发动威压，该杀不能躲闪。",
	["juesha"] = "绝杀",
	[":juesha"] = "<b>锁定技</b>，你即将造成的伤害均视为失去体力上限",
	["#juesha"] = "%from绝杀被触发，取代伤害，%to的体力上限降低了",
	["huanxiang"]= "幻象",
	[":huanxiang"]= "<b>锁定技</b>，距离你距离为1的角色不能对你出杀",
	["luanzhan"]="乱战",
	["luanzhanc"]="乱战",
	["luanzhan"]="乱战",
	[":luanzhan"]="出牌阶段，你可以把你的任意牌当作不限目标数量的火杀来使用。",
	["designer:TCX00"]="Nutari",
	["illustrator:TCX00"]="てぃんくる",
	["TCtianming"]="天命",
	[":TCtianming"]="<b>主公技</b>，<b>锁定技</b>，你获得咆哮，并且绝杀会额外降低目标1点体力上限",
	["#test"]="test %from %arg %to %arg2",
	["#tczhuanshi"]="转世",
}

--☆式見蛍

TCX01=sgs.General(extension, "TCX01", "god", "1", false,true)

cunzai=sgs.CreateTriggerSkill{
	name="cunzai",
	events={sgs.CardUsed,sgs.CardFinished,sgs.CardResponsed},
	priority=2,
	frequency=sgs.Skill_Compulsory,
	can_trigger=function(self,player)
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local use=data:toCardUse()
 		local kei = room:findPlayerBySkillName("cunzai")
        if not kei then return false end
		local log=sgs.LogMessage()
		log.from=kei
		if (event==sgs.CardUsed and use.card:isKindOf("BasicCard")) or (event==sgs.CardResponsed and data:toResponsed().m_card:isKindOf("BasicCard")) then
			log.type="#cunzai"
			room:sendLog(log)
			kei:drawCards(1)
		end
		if event==sgs.CardFinished and use.card:isNDTrick() and use.from:objectName()~=kei:objectName() then
			log.to:append(use.from)
			if not use.from:isNude() then
				log.type="#cunzaix"
				room:sendLog(log)
				local card_id = room:askForCardChosen(kei, use.from, "he", "cunzai")
				room:moveCardTo(sgs.Sanguosha:getCard(card_id), kei, sgs.Player_PlaceHand,false)
			else
				log.type="#cunzaixx"
				room:sendLog(log)
				room:loseHp(use.from,1)
			end
		end
	end,
}

youhun=sgs.CreateTriggerSkill{
	name="youhun",
	events={sgs.GameStart,sgs.CardsMoveOneTime,sgs.GameOverJudge,sgs.EventPhaseStart,sgs.EventAcquireSkill,sgs.EventLoseSkill,sgs.BuryVictim,sgs.Death},
	priority=4,
	frequency=sgs.Skill_Frequent,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if not player:hasSkill(self:objectName()) then return end
		if (event==sgs.BuryVictim or event==sgs.Death and player:objectName()==data:toDeath().who:objectName())and player:isAlive() and player:hasSkill(self:objectName()) then
			return true
		end
		if event==sgs.GameStart or (sgs.EventAcquireSkill and data:toString()==self:objectName()) then
			player:gainMark("@ghost",2)
			room:acquireSkill(player,"#youhun_prohibit")
		end
		if event==sgs.EventLoseSkill and (data:toString()=="cunzai" or data:toString()=="youhun" or data:toString()=="chuangzao") then
			if player:getMark("@ghost")==0 or not room:askForSkillInvoke(player,self:objectName(),data) then return false end
			room:acquireSkill(player,"cunzai")
			room:acquireSkill(player,"youhun")
			room:acquireSkill(player,"chuangzao")
		end
		if event==sgs.CardsMoveOneTime and player:getPhase()==sgs.Player_Discard then
			local move=data:toMoveOneTime()
			if move.reason.m_reason~=sgs.CardMoveReason_S_REASON_RULEDISCARD or move.to_place~=sgs.Player_DiscardPile then return end
			local x=0
			for _,id in sgs.qlist(move.card_ids) do
				if sgs.Sanguosha:getCard(id):isKindOf("Peach") or sgs.Sanguosha:getCard(id):isKindOf("Analeptic") then
					x=x+1
				end
			end
			if x>0 then player:gainMark("@ghost",x) end
			return false
		end
		if event==sgs.EventPhaseStart and player:getPhase()==sgs.Player_Finish then
			if player:getMark("@ghost")<5 then player:gainMark("@ghost",2) end
		end
		if event==sgs.GameOverJudge then
			if player:getMark("@ghost")==0 or not room:askForSkillInvoke(player, "youhun")  then return false end
			local log=sgs.LogMessage()
			log.from=player
			log.type="#youhun"
			room:sendLog(log)
			room:revivePlayer(player)
			player:loseMark("@ghost",1)
			room:setPlayerProperty(player,"maxhp",sgs.QVariant(1))
			room:setPlayerProperty(player,"hp",sgs.QVariant(1))
			for _,skill in sgs.qlist(player:getVisibleSkillList()) do
				room:attachSkillToPlayer(player,skill:objectName())
			end 
			return true
		end
	end,
}

youhun_prohibit=sgs.CreateProhibitSkill{
	name="#youhun_prohibit",
	is_prohibited=function(self,from,to,card)
		if to:hasSkill("youhun") and to:getMark("@ghost")>0 then
			return card:isKindOf("Indulgence")
		end
	end,
}

chuangzao_card=sgs.CreateSkillCard{
	name="chuangzao_card",
	target_fixed=false,
	will_throw=false,
	filter=function(self,targets,to_select)
		return #targets==0
	end,
	on_use=function(self,room,source,targets)
		local target=targets[1]
		source:loseMark("@ghost",5)
		local isGood=target:isKongcheng() or source:pindian(target,self:objectName())
		if isGood then
			local skills={}
			local skilllist=""
			for _,skill in sgs.qlist(target:getVisibleSkillList()) do
				if not source:hasSkill(skill:objectName()) then
				table.insert(skills,skill:objectName())
				end
			end
			for var,sk in ipairs(skills) do
				if var==#skills then skilllist=skilllist..sk break end
				skilllist=skilllist..sk.."+"
			end
			local skill_name= room:askForChoice(source,"chuangzao",skilllist)
			local skillx=sgs.Sanguosha:getSkill(skill_name)
			room:detachSkillFromPlayer(target,skill_name)
			local value=sgs.QVariant(skill_name)
			if not(skillx:isLordSkill() or skillx:getFrequency() == sgs.Skill_Limited
				or skillx:getFrequency() == sgs.Skill_Wake) and room:askForChoice(source,"chuangzao","huode+buhuode",value)=="huode" then
				room:acquireSkill(source,skill_name)
			end
		else
			room:loseHp(source,1)
		end
	end,
}

chuangzao=sgs.CreateViewAsSkill{
	name="chuangzao",
	n=0,
	view_as=function()
		return chuangzao_card:clone()
	end,
	enabled_at_play=function(self,player)
		return sgs.Self:getMark("@ghost")>=5
	end,
}

TCX01:addSkill(cunzai)
TCX01:addSkill(youhun)
TCX01:addSkill(youhun_prohibit)
TCX01:addSkill(chuangzao)

sgs.LoadTranslationTable{
	["TCX01"]="☆式見蛍",
	["#TCX01"]="マテリアルゴースト",
	["~TCX01"]="死んじゃった？でもわたしも死んじゃったでしょう",
	["cunzai"]="存在",
	[":cunzai"]="<b>锁定技</b>，每有一个角色使用或者打出1张基础牌，你摸1张牌，每有一个其他角色使用1张非延时锦囊牌结束，你获得其1张牌，若其没有牌，其失去1点体力",
	["#cunzai"]="%from的【存在】发动",
	["#cunzaix"]="%from的【存在】发动，%from获得了%to1张牌",
	["#cunzaixx"]="%from的【存在】发动，没有牌的%to失去了1点体力",
	["youhun"]="幽魂",
	[":youhun"]="游戏开始时你获得2枚灵体印记，若你回合结束时灵体印记不足5枚则你可以获得2枚灵体印记，你弃牌阶段每弃置1张酒或者桃获得1个鬼灵印记。当你即将死亡时，你可以弃置1个鬼灵印记将体力和体力上限恢复至1点。当你失去【存在】【幽魂】【创造】时，你可以弃置1个鬼灵标记获得全部的3个技能。当你至少有1个鬼灵印记的时候，你不能成为乐不思蜀的目标。",
	["#youhun"]="你弃置了1枚鬼灵印记将体力上限和体力恢复至了1点。",
	["@ghost"]="鬼灵",
	["chuangzao"]="创造",
	["chuangzao_card"]="创造",
	[":chuangzao"]="出牌阶段，你可以弃置5个鬼灵印记与另一个角色拼点，若你赢，你令目标失去1个技能，若该技能非主公技，限定技，觉醒技，你可以选择是否获得该技能。若你没赢，你失去1点体力。",
	["huode"]="获得该技能",
	["buhuode"]="不获得该技能",
	["designer:TCX01"]="Nutari",
	["illustrator:TCX01"]="てぃんくる",
}

--☆ユー

TCX02=sgs.General(extension, "TCX02", "god", "2", false,true)

shenge=sgs.CreateTriggerSkill{
	name="shenge",
	events={sgs.GameStart,sgs.ConfirmDamage,sgs.DamageForseen,sgs.PreHpReduced,sgs.MaxHpChanged,sgs.HpLost,sgs.EventAcquireSkill,sgs.TurnStart,sgs.PindianVerifying,sgs.EventLoseSkill,sgs.GameOverJudge,sgs.BuryVictim},
	priority=5,
	frequency=sgs.Skill_Compulsory,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.EventLoseSkill and (data:toString()=="shenge" or data:toString()=="shijie") then
			room:acquireSkill(player,data:toString())
		end
		if event==sgs.GameOverJudge and player:hasSkill(self:objectName()) then
			if player:getHp()>0 then
				room:revivePlayer(player)
				return true
			end
		end
		if event==sgs.BuryVictim and player:isAlive() and player:hasSkill(self:objectName()) then
			return true
		end
		if event==sgs.HpLost and player:hasSkill(self:objectName()) then
			local log=sgs.LogMessage()
			log.from=player
			log.type="#shengeax"
			room:sendLog(log)
			return true
		end
		local damage=data:toDamage()
		if event==sgs.ConfirmDamage or event==sgs.DamageForseen then
			if damage.from and damage.from:hasSkill(self:objectName()) then
				local log=sgs.LogMessage()
				log.from=damage.from
				log.type="#shengepd"
				room:sendLog(log)
				damage.from=nil
				data:setValue(damage)
				return false
			elseif damage.from and damage.to:hasSkill(self:objectName()) then
				local log=sgs.LogMessage()
				log.from=damage.to
				log.type="#shengead"
				room:sendLog(log)
				damage.from=nil
				data:setValue(damage)
				return false
			end
		end
		if event==sgs.PreHpReduced and damage.to:hasSkill(self:objectName()) then
			local log=sgs.LogMessage()
			log.from=damage.to
			log.type="#shenged"
			if damage.damage<=1 then damage.damage=0 else damage.damage=1 end
			log.arg=damage.damage
			room:sendLog(log)
			if damage.damage==0 then return true else data:setValue(damage) end
			return false
		end
		if event==sgs.MaxHpChanged and player:getMaxHp()<2 and player:hasSkill(self:objectName()) then
			local log=sgs.LogMessage()
			log.from=player
			log.type="#shengemax"
			room:sendLog(log)
			room:setPlayerProperty(player,"maxhp",sgs.QVariant(2))
			room:setPlayerProperty(player,"hp",sgs.QVariant(2))
		end
 		local yuu = room:findPlayerBySkillName("shenge")
        if not yuu then return false end
		if event==sgs.TurnStart and not player:hasSkill("shenge") then
			local cdid=room:getNCards(1):first()
			card = sgs.Sanguosha:getCard(cdid)
			local reason=sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER,yuu:objectName())
			reason.m_skillName=self:objectName()
			room:moveCardTo(card,nil,sgs.Player_PlaceTable,reason,true)
			room:moveCardTo(card,nil,sgs.Player_DiscardPile,true)	
			if card:getSuit()==sgs.Card_Spade then
			local log=sgs.LogMessage()
				log.from=yuu
				log.to:append(player)
				log.type="#shengesx"
				room:sendLog(log)
				room:setEmotion(player,"bad")
				room:setEmotion(yuu,"good")
				room:getThread():delay(500)
				yuu:gainAnExtraTurn()
				return true
			end
		end
		if event==sgs.PindianVerifying and data:toPindian().to:objectName()==yuu:objectName() then
			local pd=data:toPindian()
			pd.to=pd.from
			pd.to_number=pd.from_number
			data:setValue(pd)
			return false
		end
	end,
}

shijie=sgs.CreateTriggerSkill{
	name="shijie",
	events={sgs.EventPhaseStart,sgs.Damaged,sgs.CardsMoving,sgs.CardDrawing},
	priority=5,
	frequency=sgs.Skill_Compulsory,
	can_trigger=function(self,player)
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if (event==sgs.EventPhaseStart and player:getPhase()==sgs.Player_Finish and player:hasSkill(self:objectName())) or (event==sgs.Damaged and data:toDamage().damage>0 and data:toDamage().to:hasSkill(self:objectName()))then
			room:setPlayerFlag(player,"-shengex")
			local log=sgs.LogMessage()
			log.from=player
			log.type="#shijie"
			room:sendLog(log)
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if not p:isAllNude() then
					local card_id = room:askForCardChosen(player, p, "hej", "shijie")
					room:moveCardTo(sgs.Sanguosha:getCard(card_id), player, sgs.Player_PlaceHand,false)
				else
					room:loseHp(p)
				end
			end
			if event==sgs.Damaged and player:getPhase()==sgs.Player_NotActive then
				local log=sgs.LogMessage()
				log.from=player
				log.type="#shijiex"
				room:sendLog(log)
				player:gainAnExtraTurn()
			end
		end
		local yuu=room:findPlayerBySkillName("shijie")
		if not yuu then return false end
		if event==sgs.CardsMoving then
			local move=data:toMoveOneTime()
			if move.card_ids:isEmpty() or move.to and move.to:objectName()~=player:objectName() or player:getPhase()==sgs.Player_Draw then return end
			if yuu:objectName()==player:objectName() or move.to_place~=sgs.Player_PlaceHand then return false end
			reason=sgs.CardMoveReason()
			reason.m_reason=sgs.CardMoveReason_S_REASON_DISMANTLE
			reason.m_player=yuu:objectName()
			reason.m_skillName=self:objectName()
			for _,id in sgs.qlist(move.card_ids) do
				local card = sgs.Sanguosha:getCard(id)
				local log=sgs.LogMessage()
				log.from=yuu
				log.arg=card:objectName()
				log.to:append(player)
				log.type="#shijieax"
				room:sendLog(log)
				room:moveCardTo(card,nil,nil,sgs.Player_DiscardPile,reason)
			end
			return false
		elseif event==sgs.CardDrawing then
			if room:getTag("FirstRound"):toBool() then return false end
			if player:objectName()==yuu:objectName() or player:getPhase()==sgs.Player_Draw then return false end
			reason=sgs.CardMoveReason()
			reason.m_reason=sgs.CardMoveReason_S_REASON_DISMANTLE
			reason.m_player=yuu:objectName()
			reason.m_skillName=self:objectName()
			local cdid = data:toInt()
            local card = sgs.Sanguosha:getCard(cdid)
            room:moveCardTo(card, nil, nil, sgs.Player_DiscardPile, reason)
			local log=sgs.LogMessage()
			log.from=yuu
			log.arg=card:objectName()
			log.to:append(player)
			log.type="#shijieax"
			room:sendLog(log)
			return true
		end	
	end,
}

TCX02:addSkill(shenge)
TCX02:addSkill(shijie)

sgs.LoadTranslationTable{
	["TCX02"]="☆ユー",
	["#TCX02"]="世界の意識",
	["~TCX02"]="も遊びません？詰まんないな",
	["shenge"]="神格",
	[":shenge"]="<b>锁定技</b>，你免疫诸多效果（见详情）。你即将造成的伤害和你即将受到的伤害均没有来源，你即将受到的伤害均-1并且不大于1点。其他角色回合开始前你需展示牌堆顶的一张牌，若为黑桃，其跳过其的回合，由你立刻开始1个额外的回合。\
	注：你的体力上限不会少于2。你不会失去体力。你体力高于0时不会死亡。你不会失去【神格】【世界】。对你的拼点结果始终为对方没有赢。（此人慎用）",
	["#shenged"]="%from的【神格】发动，受到的伤害减少至%arg点",
	["#shengead"]="%from的【神格】发动，其即将受到的伤害视为没有来源。",
	["#shengepd"]="%from的【神格】发动，其即将造成的伤害视为没有来源。",
	["#shengeax"]="%from的【神格】发动，未受到伤害的情况下不会失去体力",
	["shenge_xx"]="神格",
	["#shengemax"]="【神格】发动，将体力上限回复至2点。",
	["#shengesx"]="%from的【神格】发动成功，%to跳过了他的回合，%from立刻开始1个额外的回合",
	["shijie"]="世界",
	[":shijie"]="<b>锁定技</b>，你回合结束或者受到伤害时，从所有其他角色的牌区(手牌，装备区和判定区)获得1张牌，没有牌者失去1点体力。若该效果在你的回合外发动，你立刻开始1个额外的回合。你在场时，除处于自己的摸牌阶段外，其他玩家在获得手牌时将之置入弃牌堆。",
	["#shijie"]="【世界】触发，%from从所有角色那里获得1张牌，没有牌的角色失去1点体力",
	["#shijiex"]="【世界】触发，%from开始一个额外的回合",
	["#shijieax"]="%from的【世界】触发，%to弃置了即将获得的%arg",
	["designer:TCX02"]="Nutari",
	["illustrator:TCX02"]="てぃんくる",
}

--☆松原飛鳥

TCX03=sgs.General(extension, "TCX03", "god", "2", false,true)

genyuan=sgs.CreateTriggerSkill{
	name="genyuan",
	events={sgs.CardsMoveOneTime,sgs.DamageForseen,sgs.ConfirmDamage},
	priority=4.5,
	frequency=sgs.Skill_Compulsory,
	can_trigger=function(self,player)
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
        local asuka = room:findPlayerBySkillName("genyuan")
		if not asuka then return false end
		if event==sgs.ConfirmDamage or event==sgs.DamageForseen then
			local damage=data:toDamage()
			if damage.to:objectName()==asuka:objectName() and not (damage.card and (damage.card:isKindOf("BasicCard") or damage.card:isKindOf("TrickCard"))) then
				local log=sgs.LogMessage()
				log.from=asuka
				log.to:append(damage.to)
				log.type="#genyuanno"
				room:sendLog(log)
				return true
			end
			if not (damage.from and damage.from:objectName()==asuka:objectName()) then
				local log=sgs.LogMessage()
				log.from=asuka
				log.to:append(damage.to)
				log.type="#genyuanx"
				room:sendLog(log)
				damage.from=asuka
				data:setValue(damage)
				return false
			end	
		end
		if event==sgs.CardsMoveOneTime then
			local move=data:toMoveOneTime()
			local cdids=move.card_ids
			if cdids:isEmpty() then return end
			if move.from and move.from:objectName()~=player:objectName() then return end
			if move.to_place==sgs.Player_DiscardPile and not move.from:hasSkill("genyuan") then
				local ids=sgs.IntList()
				local movex=sgs.CardsMoveStruct()
				local reason=sgs.CardMoveReason()
				reason.m_reason=sgs.CardMoveReason_S_REASON_RECYCLE
				reason.m_player=asuka:objectName()
				reason.m_skillName=self:objectName()
				movex.reason=reason
				for _,id in sgs.qlist(cdids) do
					if id~=-1 and not ids:contains(id) and sgs.Sanguosha:getCard(id):getSkillName()~="lianxie" then
						ids:append(id)
					end
				end
				if not ids:isEmpty() then
					local log=sgs.LogMessage()
					log.from=asuka
					log.type="#genyuan"
					room:sendLog(log)
					movex.card_ids=ids
					movex.from_place=sgs.Player_DiscardPile
					movex.to_place=sgs.Player_PlaceHand
					movex.to=asuka
					room:moveCardsAtomic(movex,true)
				end
			end
		end
	end,
}

monv_card=sgs.CreateSkillCard{
	name="monv_card",
	will_throw=false,
	target_fixed=true,
	on_use=function(self,room,source,targets)
		local skills={}
		local skilllist=""
		for _,skill in sgs.qlist(source:getVisibleSkillList()) do
			if not (skill:objectName()=="genyuan" or skill:objectName()=="monv")  then
				table.insert(skills,skill:objectName())
			end
		end
		if #skills==0 then return end
		for var,sk in ipairs(skills) do
			skilllist=skilllist..sk.."+"
		end
		skilllist=skilllist.."cancel"
		local skill_name= room:askForChoice(source,"monv",skilllist)
		if skill_name~="cancel" then room:detachSkillFromPlayer(source,skill_name) end
	end,
}

monv_vs=sgs.CreateViewAsSkill{
	name="monv",
	n=0,
	view_as=function()
		return monv_card:clone()
	end,
}

monv=sgs.CreateTriggerSkill{
	name="monv",
	events={sgs.GameStart,sgs.EventAcquireSkill,sgs.EventLoseSkill,sgs.Death,sgs.BuryVictim},
	priority=5,
	frequency=sgs.Skill_NotFrequent,
	view_as_skill=monv_vs,
	can_trigger=function(self,player)
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local asuka = room:findPlayerBySkillName("monv")
		if not asuka then return false end
		if event==sgs.Death and data:toDeath().who:objectName()==player:objectName() and player:getMark("@rule")==0 then
			if asuka:getMark("@witch")==0 then return false end
			if player:objectName()==asuka:objectName() then return false end
			if not room:askForSkillInvoke(asuka,"monv") then return false end
			room:revivePlayer(player)
			room:setPlayerProperty(player,"hp",sgs.QVariant(player:getMaxHp()))
			if player:getMaxHp()>1 then room:setPlayerProperty(player,"maxhp",sgs.QVariant(player:getMaxHp()-1)) end
			room:setPlayerProperty(asuka,"maxhp",sgs.QVariant(asuka:getMaxHp()+1))
			room:setPlayerProperty(asuka,"hp",sgs.QVariant(asuka:getHp()+1))
			for _,skill in sgs.qlist(player:getVisibleSkillList()) do
				room:detachSkillFromPlayer(player,skill:objectName())
				room:acquireSkill(asuka,skill:objectName())
			end
			asuka:loseMark("@witch")
			player:gainMark("@rule")
			return true
		end
		if event==sgs.BuryVictim then
			if player:getMark("@rule")==0 or player:isAlive() then return true end
			local log=sgs.LogMessage()
			log.from=asuka
			log.to:append(player)
			log.type="#monv"
			room:sendLog(log)
			local cards=player:getHandcards()
			for _,cd in sgs.qlist(cards) do
				room:obtainCard(asuka,cd)
			end
			cards=player:getEquips()
			for _,cd in sgs.qlist(cards) do
				room:obtainCard(asuka,cd)
			end
			asuka:gainMark("@witch")
			player:loseMark("@rule")
			local damage=sgs.DamageStruct()
			damage.from=asuka
			damage.damage=1
			return false
		end
		if (event==sgs.GameStart and player:hasSkill("monv")) or (sgs.EventAcquireSkill and data:toString()=="monv") then
			player:gainMark("@witch",3)
		end
		if event==EventLoseSkill and data:toString()=="monv" then
			player:loseAllMarks("@witch")
		end
	end,
}

TCX03:addSkill(genyuan)
TCX03:addSkill(monv)

sgs.LoadTranslationTable{
	["TCX03"]="☆松原飛鳥",
	["#TCX03"]="諸悪の根源",
	["~TCX03"]="就算是我也有输的时候么",
	["genyuan"]="根源",
	[":genyuan"]="<b>锁定技</b>，任何角色即将造成或者受到的伤害来源均视为你。任何不属于你的牌移动至弃牌堆时，你获得之。任何非基础/锦囊牌造成的伤害对你无效",
	["#genyuanno"]="%from的【根源】触发，防止了此次伤害",
	["#genyuan"]="%from的【根源】触发",
	["#genyuanx"]="【根源】触发，%to即将受到的伤害来源视为%from",
	["monv_card"]="魔女",
	["monv"]="魔女",
	[":monv"]="开局你有3个魔女印记。任何其他角色即将死亡时，你可以弃置1枚魔女印记，令其免于死亡并将其体力恢复至上限，然後你收取其所有的武将技能和1点体力上限作为代价并放置一枚支配印记。带有支配印记的角色死亡时，你获得其所有牌并补充一枚魔女印记。出牌阶段，你可以弃置任意数量获得的技能",
	["#monv"]="【支配】发动，%from收回了%to所有的牌并获得了1个魔女印记",
	["@witch"]="魔女",
	["@rule"]="支配",
	["designer:TCX03"]="Nutari",
	["illustrator:TCX03"]="狗神煌",
}

--☆杉崎林檎

TCX04=sgs.General(extension, "TCX04", "god", "3", false,true)

tianzhen=sgs.CreateFilterSkill{
	name="tianzhen",
	view_filter=function(self,to_select)
		return to_select:isKindOf("TrickCard")
	end,
	view_as=function(self,card)
		local null=sgs.Sanguosha:cloneCard("nullification",card:getSuit(),card:getNumber())
		local acard=sgs.Sanguosha:getWrappedCard(card:getId())
		acard:takeOver(null)
		acard:setSkillName("tianzhen")
		return acard
	end,
}

tianzhen_trigger=sgs.CreateTriggerSkill{
	name="#tianzhen_trigger",
	events={sgs.GameStart,sgs.CardUsed,sgs.TurnedOver,sgs.EventLoseSkill,sgs.MaxHpChanged,sgs.CardEffected,sgs.GameOverJudge,sgs.BuryVictim},
	priority=2,
	frequency=sgs.Skill_Compulsory,
	can_trigger=function(self,player)
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.EventLoseSkill and (data:toString()=="tianzhen" or data:toString()=="mihuan" or data:toString()=="menghuan") then
			if player:getMark("@destroy")==0 then room:acquireSkill(player,data:toString()) end
		end
		if event==sgs.GameOverJudge and player:hasSkill("tianzhen") then
			if player:getHp()>0 then
				room:revivePlayer(player)
				return true
			end
		end
		if event==sgs.BuryVictim and player:isAlive() and player:hasSkill("tianzhen") then
			return true
		end
		if event==sgs.CardEffected then
			local effect=data:toCardEffect()
			if effect.to:hasSkill("tianzhen") and effect.card:isKindOf("TrickCard") then
				local log=sgs.LogMessage()
				log.from=effect.to
				log.arg=effect.card:objectName()
				log.type="#tianzhenc"
				room:sendLog(log)
				return true
			end
		end
		if event==sgs.TurnedOver and not player:faceUp() and player:hasSkill("tianzhen") then
			local log=sgs.LogMessage()
			log.from=player
			log.type="#tianzhenb"
			room:sendLog(log)
			player:turnOver()
		end
		if event==sgs.MaxHpChanged and player:getMaxHp()<3 and player:hasSkill("tianzhen") then
			local log=sgs.LogMessage()
			log.from=player
			log.type="#tianzhenx"
			room:sendLog(log)
			room:setPlayerProperty(player,"maxhp",sgs.QVariant(3))
		end
	end,
}

mihuan_start_card=sgs.CreateSkillCard{
	name="mihuan_start_card",
	target_fixed=true,
	on_use=function(self,room,source)
		local choice=room:askForChoice(source,"mihuan","lose+recover")
		if choice=="lose" then
			room:setPlayerFlag(source,"mihuanlose")
		else
			room:setPlayerFlag(source,"mihuanrecover")
		end
		room:askForUseCard(source,"@@mihuan","@mihuan"..choice)
		room:setPlayerFlag(source,"-mihuanlose")
		room:setPlayerFlag(source,"-mihuanrecover")
	end
}	

mihuan_card=sgs.CreateSkillCard{
	name="mihuan_card",
	will_throw=false,
	target_fixed=false,
	filter=function(self,targets,to_select)
		if #targets>0 or to_select:hasFlag("mihuanused") then return false end
		if sgs.Self:hasFlag("mihuanlose") then
			return to_select:getHp()>=self:subcardsLength()
		elseif sgs.Self:hasFlag("mihuanrecover") then
			return to_select:getLostHp()>=self:subcardsLength()
		end
	end,
	on_use=function(self, room, source, targets)
		if source:hasFlag("mihuanlose") then	
			local target=targets[1]
			room:loseHp(target,self:subcardsLength())
			room:moveCardTo(self,target,sgs.Player_PlaceHand,false)
			room:setPlayerFlag(target,"mihuanused")
		else
			local target=targets[1]
			local recover=sgs.RecoverStruct()
			recover.recover=self:subcardsLength()
			recover.who=source
			room:recover(target,recover,true)
			room:throwCard(self,source)
			source:gainMark("@fantasy",self:subcardsLength())
			room:setPlayerFlag(target,"mihuanused")
		end
	end,
}

mihuan_vs=sgs.CreateViewAsSkill{
	name="mihuan",
	n=999,
	view_filter=function(self,selected,to_select)
		return to_select:isKindOf("TrickCard") and (sgs.Self:hasFlag("mihuanlose") or sgs.Self:hasFlag("mihuanrecover"))
	end,
	view_as=function(self,cards)
		if #cards>0 then		
			local acard=mihuan_card:clone()
			local i = 0
			while(i < #cards) do
				i = i + 1
				acard:addSubcard(cards[i]:getId())
			end
			acard:setSkillName("mihuan")
			return acard
		elseif not (sgs.Self:hasFlag("mihuanlose") or sgs.Self:hasFlag("mihuanrecover")) then
			return mihuan_start_card:clone()
		end	
	end,
	enabled_at_play=function()
		return true
	end
}

mihuan=sgs.CreateTriggerSkill{
	name="mihuan",
	events={sgs.EventPhaseStart,sgs.EventPhaseEnd},
	view_as_skill=mihuan_vs,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.EventPhaseEnd and player:getPhase()==sgs.Player_Play then
			for _,p in sgs.qlist(room:getAllPlayers()) do
				room:setPlayerFlag(p,"-mihuanused")
			end	
		end
		if event==sgs.EventPhaseStart and player:getPhase()==sgs.Player_Finish then
			local x=player:getMark("@fantasy")
			if x>0 then
				local log=sgs.LogMessage()
				log.from=player
				log.arg=x
				log.type="#mihuanx"
				room:sendLog(log)
				room:drawCards(player,x)
			end
		end
	end,
}

menghuan=sgs.CreateTriggerSkill{
	name="menghuan",
	events={sgs.HpLost,sgs.DamageForseen},
	frequency=sgs.Skill_NotFrequent,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local ringo=room:findPlayerBySkillName(self:objectName())
		if not ringo then return end
		if event==sgs.DamageForseen then
			local damage=data:toDamage()
			local log=sgs.LogMessage()
			log.from=damage.from
			log.to:append(damage.to)
			log.type="#beforedamage"
			room:sendLog(log)
			if damage.to:objectName()~=ringo:objectName() and ringo:getMark("@fantasy")==0 then return end
			if not room:askForSkillInvoke(ringo,self:objectName(),data) then return false end
			log.from=player
			log.type="#menghuan"
			room:sendLog(log)
			if damage.to:objectName()~=ringo:objectName() then ringo:loseMark("@fantasy") end
			room:loseHp(ringo)
			return true
		end
		if event==sgs.HpLost and player:hasSkill(self:objectName()) then
			x=data:toInt()
			local i=0
			local choice=""
			while i<x do
				i=i+1
				choice=room:askForChoice(player,"menghuan","mhlihun+mhguixin")
				if choice=="mhlihun" then
					target=room:askForPlayerChosen(player,room:getOtherPlayers(player),"menghuan")
					local hc=0
					if not target:isNude() then
						hc=target:getCards("he"):length()
						local move=sgs.CardsMoveStruct()
						local reason=sgs.CardMoveReason()
						reason.m_reason=sgs.CardMoveReason_S_REASON_ROB
						reason.m_player=player:objectName()
						reason.m_skillName=self:objectName()
						for _,card in sgs.qlist(target:getCards("he")) do
							move.card_ids:append(card:getEffectiveId())
						end
						move.reason=reason
						move.from=target
						move.to=player
						move.to_place=sgs.Player_PlaceHand
						room:moveCardsAtomic(move,true)
					end
					local hp=target:getHp()-target:getHandcardNum()
					if hp>0 then
						hp=math.min(hp,player:getCards("he"):length())
						local exchange=room:askForExchange(player,self:objectName(),hp,true)
						room:moveCardTo(exchange,target,sgs.Player_PlaceHand,false)
						if hc<hp then
							local log=sgs.LogMessage()
							log.from=player
							log.to:append(target)
							log.type="#menghuanx"
							room:sendLog(log)
							c=data:toInt()
							if c-1==0 then return true else data:setValue(c-1) end
						end
					end
				else
					for _,p in sgs.qlist(room:getOtherPlayers(player)) do
						if not p:isAllNude() then
							cdid=room:askForCardChosen(player,p,"hej","menghuan")
							room:moveCardTo(sgs.Sanguosha:getCard(cdid),player,sgs.Player_PlaceHand,false)
						end
					end
				end
			end
		end
	end,
}

TCX04:addSkill(tianzhen)
TCX04:addSkill(tianzhen_trigger)
TCX04:addSkill(mihuan)
TCX04:addSkill(menghuan)

sgs.LoadTranslationTable{
	["TCX04"]="☆杉崎林檎",
	["#TCX04"]="天真無邪",
	["~TCX04"]="林檎はもっともっとおにちゃんとあそびたい",
	["tianzhen"]="天真",
	["#tianzhen_prohibit"]="天真",
	[":tianzhen"]="<b>锁定技</b>，你的锦囊牌均被视为无懈可击，锦囊牌对你无效。你被翻面后立刻翻回来。你的体力上限不会减至3以下。你不会失去【天真】【迷幻】【梦幻】。你体力高于0时不会死亡。",
	["#tianzhenc"]="%from的【天真】被触发，对%from使用的%arg无效",
	["#tianzhenb"]="%from的【天真】被触发，%from将武将翻回正面",
	["#tianzhenx"]="%from的【天真】被触发，%from将体力上限恢复至3点",
	["mihuan"]="迷幻",
	["mihuan_card"]="迷幻",
	["mihuan_start_card"]="迷幻",
	[":mihuan"]="出牌阶段，你可以选择选择1项：选择任意张锦囊牌，令一名当前体力不少于所选牌数的角色失去等量的体力，然后将这些锦囊牌交给他；或者你可以选择任意张锦囊牌，令一名失去体力不低于所选牌数的角色恢复等量的体力，然后弃置这些锦囊牌并且你获得等量“幻”标记。一阶段限对一个角色使用一次。每1个“幻”标记可以令你在回合结束摸1张牌",
	["#mihuanx"]="%from的【迷幻】发动",
	["@mihuanrecover"]="请选择迷幻恢复的目标",
	["@mihuanlose"]="请选择迷幻流失体力的目标",
	["~mihuan"]="选择1名合理的角色->点击确定",
	["@fantasy"]="幻",
	["menghuan_card"]="梦幻",
	["menghuan"]="梦幻",
	["lose"]="失去体力",
	["recover"]="恢复体力",
	[":menghuan"]="每当你即将失去1点体力，你可以做1次选择，1：获得1个角色全部的装备和手牌，然后必须分配牌给之直到其的手牌数达到其当前体力，若获得的牌的数量少于给出的牌的数量，你防止1点体力流失。2：从其他角色的牌区(手牌，装备区和判定区)内选1张牌获得。任何角色即将受到伤害时，你可以自减1点体力防止此次伤害，若这个角色不为你，你需先弃置1枚“幻”标记。",
	["mhlihun"]="获得1个角色所有的装备和手牌",
	["mhguixin"]="获得其他角色区域内各1张牌",
	["#beforedamage"]="%to即将受到来自%from的伤害",
	["#menghuan"]="%from发动了【梦幻】，防止了%to即将受到的伤害。",
	["#menghuanx"]="%from从%to获得的牌少于给出的牌，%from少失去了1点体力",
	["designer:TCX04"]="Nutari",
	["illustrator:TCX04"]="狗神煌",
}

--アリス

TCX05=sgs.General(extension, "TCX05", "god", "1", false,true)

blackS=sgs.CreateTriggerSkill{
	name="blackS",
	events={sgs.CardUsed,sgs.CardResponsed,sgs.CardEffected},
	frequency=sgs.Skill_Frequent,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.CardEffected then
			local effect=data:toCardEffect()
			if not (effect.card:isBlack() and effect.to:hasSkill("blackS")) then return false end
			if not room:askForSkillInvoke(player,"blackS") then return false end
			local playerx=room:askForPlayerChosen(player,room:getOtherPlayers(player),"blackS")
			if playerx:isNude() or playerx:getHp()>player:getHp() then
				room:loseHp(playerx)
			elseif not playerx:isNude() then
				room:askForDiscard(playerx,"blackS",1,1,false,true)
			end
		end
		local card=nil
		if event==sgs.CardUsed then card=data:toCardUse().card
		elseif event==sgs.CardResponsed then card=data:toResponsed().m_card
		end
		if card and card:isBlack() and player:hasSkill("blackS") then
			if not room:askForSkillInvoke(player,"blackS") then return false end
			local playerx=room:askForPlayerChosen(player,room:getOtherPlayers(player),"blackS")
			if playerx:isNude() or playerx:getHp()>player:getHp() then
				room:loseHp(playerx)
			elseif not playerx:isNude() then
				room:askForDiscard(playerx,"blackS",1,1,false,true)
			end
		end
	end,
}

getDeadNum=function(room)
	local x=0
	for _,p in sgs.qlist(room:getPlayers()) do
		if p:isDead() or p:getMark("@soul")>0 then x=x+1 end
	end
	if x==0 and room:alivePlayerCount()==2 then x=1 end
	return x
end

soul=sgs.CreateTriggerSkill{
	name="soul",
	events={sgs.Predamage,sgs.DamageForseen,sgs.DamageInflicted,sgs.PostHpReduced,sgs.MaxHpChanged},
	frequency=sgs.Skill_Compulsory,
	priority=5,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local damage=data:toDamage()
		if (event==sgs.Predamage or event==sgs.DamageForseen and (damage.transfer or damage.chain)) and damage.to:hasSkill(self:objectName()) then
			if damage.to:getHp()>1 then return false end
			local judge=sgs.JudgeStruct()
			judge.who=damage.to
			judge.good=false
			judge.pattern=sgs.QRegExp("(Peach|GodSalvation):(.*):(.*)")
			judge.play_animation=true
			judge.reason=self:objectName()
			room:judge(judge)
			if judge:isGood() then
				local log=sgs.LogMessage()
				log.from=damage.to
				log.type="#soulgood"
				room:sendLog(log)
				return true
			end
		end
		if event==sgs.DamageForseen and damage.from:hasSkill(self:objectName()) and damage.to:objectName()~=damage.from:objectName() then
			if damage.from:getHp()>1 or damage.to:getMark("@soul")>0 then return false end
			local judge=sgs.JudgeStruct()
			judge.who=damage.from
			judge.good=true
			judge.pattern=sgs.QRegExp("(.*):(spade|club):([AJQK])")
			judge.reason=self:objectName()
			judge.play_animation=true
			room:judge(judge)
			if judge:isGood() then
				local log=sgs.LogMessage()
				log.from=player
				log.to:append(damage.to)
				log.type="#soulbad"
				room:sendLog(log)
				room:killPlayer(damage.to,damage)
				return true
			end
		end
		if event==sgs.DamageInflicted and damage.to:hasSkill(self:objectName()) then
			if getDeadNum(room)==0 then
				local log=sgs.LogMessage()
				log.from=damage.to
				log.type="#soulxx"
				room:sendLog(log)
				return true
			end
			if damage.damage<=getDeadNum(player) then return false end
			damage.damage=getDeadNum(room)
			data:setValue(damage)
			local log=sgs.LogMessage()
			log.from=damage.to
			log.type="#soulx"
			room:sendLog(log)
			return false
		end
		if (event==sgs.PostHpReduced and player:getHp()<1) or (event==sgs.MaxHpChanged and player:getMaxHp()<1) then
			if player:hasSkill(self:objectName()) then
				local log=sgs.LogMessage()
				log.from=player
				log.type="#soulxxx"
				room:sendLog(log)
				if player:getMaxHp()<1 then room:setPlayerProperty(player,"maxhp",sgs.QVariant(1)) end
				room:setPlayerProperty(player,"hp",sgs.QVariant(1))
				return true
			end
		end
	end
}

deathking_card=sgs.CreateSkillCard{
	name="deathking_card",
	will_throw=false,
	target_fixed=false,
	filter=function(self,targets,to_select)
		if to_select:getMark("@soul")==0 then return false end
		return true
	end,
	on_use=function(self,room,source,targets)
		local damage=sgs.DamageStruct()
		damage.from=source
		for i=1,#targets,1 do
			room:killPlayer(targets[i],damage)
		end
	end,
}

deathking_vs=sgs.CreateViewAsSkill{
	name="deathking",
	n=0,
	view_as=function()
		local acard=deathking_card:clone()
		acard:setSkillName("deathking")
		return acard
	end,
}

deathking=sgs.CreateTriggerSkill{
	name="deathking",
	events={sgs.TurnStart,sgs.Death,sgs.BuryVictim,sgs.Dying,sgs.MaxHpChanged,sgs.GameOverJudge,sgs.CardEffected},
	priority=4,
	frequency=sgs.Skill_NotFrequent,
	view_as_skill=deathking_vs,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.GameOverJudge and not player:hasSkill("deathking") and player:getRole()=="lord" then
			local allsouls=true
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if not (p:getMark("@soul")>0 or p:hasSkill("deathking")) then allsouls=false break end
			end
			if allsouls then
				local arisu=room:findPlayerBySkillName("deathking")
				room:gameOver(arisu:objectName())
				return true
			end	
		end
		if event==sgs.GameOverJudge and player:hasSkill("deathking") then
			if not room:askForSkillInvoke(player,"deathking",data) then return false end
			local players=sgs.SPlayerList()
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("@soul")>0 then
					players:append(p)
				end
			end
			if players:isEmpty() then return end
			local playerx=room:askForPlayerChosen(player,players,"deathking")
			room:killPlayer(playerx)
			room:revivePlayer(player)
			room:setPlayerProperty(player,"maxhp",sgs.QVariant(1))
			room:setPlayerProperty(player,"hp",sgs.QVariant(1))
			return true
		end
		if event==sgs.BuryVictim and player:isAlive() then
			return true
		end
		if event==sgs.CardEffected and player:getMark("@soul")>0 then
			local effect=data:toCardEffect()
			if effect.card:isKindOf("BasicCard") or effect.card:isKindOf("TrickCard") then
				return true
			end	
		end
		local arisu=room:findPlayerBySkillName("deathking")
		if not arisu then return false end		
		if event==sgs.Death and data:toDeath().who:objectName()==player:objectName() and player:objectName()~=arisu:objectName() then
			if player:getMark("@soul")>0 or not room:askForSkillInvoke(arisu,"deathking",data) then return false end
			room:revivePlayer(player)
			room:setPlayerProperty(player,"maxhp",sgs.QVariant(1))
			room:setPlayerProperty(player,"hp",sgs.QVariant(1))
			if arisu:getRole()=="lord" then
				room:setPlayerProperty(player,"role",sgs.QVariant("loyalist"))
			else
				room:setPlayerProperty(player,"role",sgs.QVariant(arisu:getRole()))
			end
			local skills={}
			local skilllist=""
			for _,skill in sgs.qlist(player:getVisibleSkillList()) do
				table.insert(skills,skill:objectName())
			end
			while #skills>0 do
				skilllist=""
				for var,sk in ipairs(skills) do
					if var==#skills then skilllist=skilllist..sk.."+".."cancel" break end
					skilllist=skilllist..sk.."+"
				end
				local skillx=room:askForChoice(arisu,"deathking",skilllist)
				if skillx~="cancel" then
					room:acquireSkill(arisu,skillx)
					room:detachSkillFromPlayer(player,skillx)
				else
					break
				end
				skills={}
				for _,skill in sgs.qlist(player:getVisibleSkillList()) do
					table.insert(skills,skill:objectName())
				end
			end
			for _,skill in sgs.qlist(player:getVisibleSkillList()) do
				room:detachSkillFromPlayer(player,skill:objectName())
			end
			player:gainMark("@soul")
			return true
		end
		if event==sgs.TurnStart and player:getMark("@soul")>0 then
			local log=sgs.LogMessage()
			log.from=arisu
			log.to:append(player)
			log.type="#deathking"
			room:sendLog(log)
			arisu:gainAnExtraTurn()
			return true
		end
		if (event==sgs.Dying and player:getMark("@soul")>0 and player:objectName()==data:toDying().who:objectName()) or (event==sgs.MaxHpChanged and player:getMark("@soul")>0) then
			room:setPlayerProperty(player,"maxhp",sgs.QVariant(1))
			room:setPlayerProperty(player,"hp",sgs.QVariant(1))
			return true
		end
	end,
}

TCX05:addSkill(blackS)
TCX05:addSkill(soul)
TCX05:addSkill(deathking)

sgs.LoadTranslationTable{
	["TCX05"]="☆アリス",
	["#TCX05"]="死者の王",
	["~TCX05"]="ありえない！ぼくは死んでなんでありえない！",
	["blackS"]="ドＳの黒",
	[":blackS"]="你每使用、打出一张黑色牌或者黑色牌对你生效前时，可以令一个没有牌的或者体力高于你的角色失去1点体力，或者一个体力不高于你的角色弃置1张牌",
	["soul"]="死魂",
	[":soul"]="<b>锁定技</b>，你防止超过场上死亡和亡魂人数之和的伤害（1v1的情况下为1），并且不会因为流失体力和体力上限致死。当你体力为1时:你即将对其他存活角色造成伤害时，你需判定，若为黑色A,J,Q,K，其立刻死亡，你即将受到伤害时，你需判定，若不为桃和桃园结义，则伤害无效。",
	["#soulbad"]="%from的【死魂】触发，%to即死",
	["#soulgood"]="%from的【死魂】触发，即将受到的伤害无效",
	["#soulx"]="%from的【死魂】触发，受到的伤害降至%arg点",
	["#soulxx"]="%from的【死魂】触发，受到的伤害降至0点所以无效",
	["#soulxxx"]="%from的【死魂】触发，不会因为流失体力或上限濒死",
	["deathking"]="死灵之王",
	["deathking_card"]="死灵之王",
	["deathking_vs"]="死灵之王",
	[":deathking"]="当其他角色死亡时，你可以将其复活并将其转为和你同一势力，然后你获得其任意数个技能，其丧失所有技能并降低体力上限至1，称为亡魂。亡魂不会受到基础牌或者锦囊牌的效果也不会因为体力或者体力上限降至0而死亡。当其回合开始时，你开始一个额外的回合，然后他跳过他的回合。当你死亡时，你可以令一个亡魂死亡来让你存活。你的出牌阶段可以杀死任意数量的亡魂",
	["#deathking"]="%from的【死灵之王】发动，%to跳过他的回合让%from开始一个额外的回合",
	["@soul"]="死魂",
	["designer:TCX05"]="Nutari",
	["illustrator:TCX05"]="てぃんくる",
}

--☆マギール

TCX06=sgs.General(extension, "TCX06", "god", "5", false,true)

mowang_distance=sgs.CreateDistanceSkill{
	name="#mowang_distance",
	correct_func=function(self,from,to)
		if from:hasSkill("mowang") then
			return -100
		end
		if to:hasSkill("mowang") then
			return 1
		end
	end,
}

mowang=sgs.CreateTriggerSkill{
	name="mowang",
	events={sgs.Predamage,sgs.EventAcquireSkill},
	frequency=sgs.Skill_Compulsory,
	priority=4,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.EventAcquireSkill and data:toString()==self:objectName() then
			room:acquireSkill(player,"#mowang_distance")
		end
		local damage=data:toDamage()
		if event==sgs.Predamage and damage.from:hasSkill(self:objectName()) then
			if damage.to:isNude() then
				damage.damage=damage.damage+1
				data:setValue(damage)
				local log=sgs.LogMessage()
				log.from=player
				log.to:append(damage.to)
				log.type="#mowang"
				room:sendLog(log)
				return false
			else
				local cdid=room:askForCardChosen(player,damage.to,"he","mowang")
				local log=sgs.LogMessage()
				log.from=player
				log.to:append(damage.to)
				log.type="#mowangx"
				room:sendLog(log)
				room:moveCardTo(sgs.Sanguosha:getCard(cdid),player,sgs.Player_PlaceHand,false)
			end
		end
	end,
}

sinve=sgs.CreateTriggerSkill{
	name="sinve",
	events={sgs.Damaged},
	frequency=sgs.Skill_Compulsory,
	priority=4,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local damage=data:toDamage()
		if damage.to:hasSkill(self:objectName()) then
			local log=sgs.LogMessage()
			log.from=player
			log.type="#sinve"
			room:sendLog(log)
			player:drawCards(1)
			if damage.from and not damage.from:isNude() then
				local log=sgs.LogMessage()
				log.from=player
				log.to:append(damage.from)
				log.type="#sinvea"
				room:sendLog(log)
				local cdid=room:askForCardChosen(player,damage.from,"he","sinve")
				room:moveCardTo(sgs.Sanguosha:getCard(cdid),player,sgs.Player_PlaceHand,false)
			else
				local target=room:askForPlayerChosen(player,room:getOtherPlayers(player),"sinve")
				local damagex=sgs.DamageStruct()
				damagex.damage=1
				damagex.nature=sgs.DamageStruct_Thunder
				damagex.from=player
				damagex.to=target
				local log=sgs.LogMessage()
				log.from=player
				log.to:append(target)
				log.type="#sinveax"
				room:sendLog(log)
				room:damage(damagex)
			end
			if damage.card and damage.card:getEffectiveId()~=-1 then
				local log=sgs.LogMessage()
				log.from=player
				log.arg=damage.card:objectName()
				log.type="#sinveb"
				room:sendLog(log)
				room:obtainCard(player,damage.card)
			else
				local target=room:askForPlayerChosen(player,room:getOtherPlayers(player),"sinve")
				local damagex=sgs.DamageStruct()
				damagex.damage=1
				damagex.nature=sgs.DamageStruct_Thunder
				damagex.from=player
				damagex.to=target
				local log=sgs.LogMessage()
				log.from=player
				log.type="#sinvebx"
				room:sendLog(log)
				room:damage(damagex)
			end
		end
	end,
}

cansha=sgs.CreateTriggerSkill{
	name="cansha",
	events={sgs.EventPhaseStart},
	frequency=sgs.Skill_Compulsory,
	priority=4,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local magiru=room:findPlayerBySkillName("cansha")
		if not magiru then return end
		if player:getPhase()==sgs.Player_Finish and player:isWounded() then
			local log=sgs.LogMessage()
			log.from=magiru
			log.to:append(player)
			log.type="#canshax"
			room:sendLog(log)
			room:loseHp(player)
		end
	end,
}

bumie=sgs.CreateTriggerSkill{
	name="bumie",
	events={sgs.DamageDone,sgs.Dying},
	frequency=sgs.Skill_Compulsory,
	priority=4,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local damage=data:toDamage()
		if event==sgs.DamageDone and damage.to:hasSkill(self:objectName()) then
			if damage.damage>1 then
				damage.damage=1
				data:setValue(damage)
				local log=sgs.LogMessage()
				log.from=player
				log.type="#bumie"
				room:sendLog(log)
				return false
			end
		end
		if event==sgs.Dying and data:toDying().who:objectName()==player:objectName() and player:hasSkill(self:objectName()) then
			local recover=sgs.RecoverStruct()
			recover.who=player
			recover.recover=1
			local log=sgs.LogMessage()
			log.from=player
			log.type="#bumiex"
			room:sendLog(log)
			for _,p in sgs.qlist(room:getAllPlayers()) do
				room:showAllCards(p)
				for _,card in sgs.qlist(p:getHandcards()) do
					if card:getSuit()==sgs.Card_Spade or card:getSuit()==sgs.Card_Heart then
						room:throwCard(card,p,player)
						room:recover(player,recover)
						local log=sgs.LogMessage()
						log.from=player
						log.arg=card:objectName()
						log.type="#bumiexx"
						room:sendLog(log)
					end
				end
				room:getThread():delay(500)
				room:broadcastInvoke("clearAG")
			end
		end
	end,
}

TCX06:addSkill(mowang_distance)
TCX06:addSkill(mowang)
TCX06:addSkill(sinve)
TCX06:addSkill(cansha)
TCX06:addSkill(bumie)

sgs.LoadTranslationTable{
	["TCX06"]="☆マギール",
	["#TCX06"]="魔王",
	["~TCX06"]="．．．．．．ふ。……完敗だよ、桜野。私は……負けた",
	["#mowang_distance"]="魔王",
	["mowang"]="魔王",
	[":mowang"]="<b>锁定技</b>，你与其他角色计算距离时始终为1，其他角色与你计算距离时始终+1。你对其他角色造成伤害前，若其无牌，则伤害+1，否则你获得其一张牌",
	["#mowang"]="%from的【魔王】发动，对没有牌的%to造成了1点额外伤害",
	["#mowangx"]="%from的【魔王】发动，抽取%to一张牌",
	["sinve"]="肆虐",
	[":sinve"]="<b>锁定技</b>，当你受到伤害时，从牌堆摸1张牌，然后从伤害的来源处获得1张牌，然后获得造成伤害的牌。若伤害没有来源或者没有伤害的牌，你需选择场上一名你以外的角色，对其造成1点雷电伤害",
	["#sinve"]="%from的【肆虐】发动，摸了1张牌",
	["#sinvea"]="%from的【肆虐】发动，获得了%to的1张牌",
	["#sinveax"]="%from的【肆虐】发动，因为没有伤害来源（或者伤害来源没有牌）所以将对%to造成1点雷电伤害",
	["#sinveb"]="%from的【肆虐】发动，收回了造成伤害的牌%arg",
	["#sinvebx"]="%from的【肆虐】发动，因为没有伤害的牌所以将对%to造成1点雷电伤害",
	["cansha"]="残杀",
	[":cansha"]="<b>锁定技</b>，任何角色回合结束时，若你在场并且其已受伤，则其失去1点体力。",
	["#cansha"]="%from的【残杀】发动",
	["#canshax"]="%from的【残杀】发动，受伤的%to失去1点体力",
	["bumie"]="不灭",
	[":bumie"]="<b>锁定技</b>，你防止多于1点的伤害。当你濒死时，展示所有角色的手牌，然后其中每有一张黑桃或者红桃，你恢复1点体力。然后弃置所有展示的黑桃或红桃牌",
	["#bumie"]="%from的【不灭】发动，阻止了多余的伤害",
	["#bumiex"]="%from的【不灭】发动，将展示所有角色的手牌",
	["#bumiexx"]="%from的【不灭】展示了一张黑桃/红桃牌，将恢复1点体力",
	["designer:TCX06"]="Nutari",
	["illustrator:TCX06"]="狗神煌",
}

TCX07=sgs.General(extension,"TCX07","forbidden","1",true,true)

death=sgs.CreateTriggerSkill{
	name="death",
	events={sgs.DamageForseen,sgs.Predamage,sgs.HpLost,sgs.MaxHpChanged},
	frequency=sgs.Skill_Compulsory,
	priority=4,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if player:getMaxHp()<1 then
			room:setPlayerProperty(player,"maxhp",sgs.QVariant(1))
			room:setPlayerProperty(player,"hp",sgs.QVariant(1))
		end
		local playerx=room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName())
		room:killPlayer(playerx)
		return true
	end,
}

TCX07:addSkill(death)

sgs.LoadTranslationTable{
	["forbidden"]="禁",
	["TCX07"]="☆残響死滅",
	["#TCX07"]="Echo Of Death",
	["death"]="死",
	[":death"]="<b>锁定技</b>，当你即将造成、受到伤害，失去体力或者体力上限变化时，你立刻令一名你以外的任意角色死亡，然后该效果无效。",
	["designer:TCX07"]="Nutari",
}

--☆天宮さくら

TCA00=sgs.General(extension,"TCA00","forbidden","1",false,true)

isenemy=function(player,target)
	if (player:getRole()=="lord" or player:getRole()=="loyalist") and (target:getRole()=="rebel" or target:getRole()=="renegade") then
		return true
	end
	if player:getRole()=="renegade" then
		return true
	end
	if player:getRole()=="rebel" and target:getRole()~="rebel" then
		return true
	end
	return false
end

destroy=sgs.CreateTriggerSkill{
	name="destroy",
	events={sgs.GameStart,sgs.TurnStart},
	frequency=sgs.Skill_Limited,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local sakura=room:findPlayerBySkillName(self:objectName())
		if sakura and event==sgs.GameStart then
			if sakura:getMark("@god")==0 then sakura:gainMark("@god") end
		end
		if sakura and sakura:getMark("@god")>0 and event==sgs.TurnStart then
			if not room:askForSkillInvoke(sakura,self:objectName()) then return end
			sakura:loseMark("@god")
			for _,p in sgs.qlist(room:getOtherPlayers(sakura)) do
				room:broadcastProperty(p,"role")
				if isenemy(sakura,p) then
					p:gainMark("@destroy")
					for _,skill in sgs.qlist(p:getVisibleSkillList()) do
						room:detachSkillFromPlayer(p,skill:objectName())
					end
					room:setPlayerProperty(p,"maxhp",sgs.QVariant(1))
					p:throwAllHandCardsAndEquips()
				end
			end
		end
		if event==sgs.TurnStart and player:getMark("@destroy")>0 then
			local log=sgs.LogMessage()
			log.type="#destroyx"
			log.to:append(player)
			room:sendLog(log)
			return true
		end
	end,
}

immortal=sgs.CreateTriggerSkill{
	name="immortal",
	events={sgs.GameOverJudge,sgs.BuryVictim,sgs.EventLoseSkill},
	frequency=sgs.Skill_Compulsory,
	priority=10,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.GameOverJudge then
			if player:hasSkill("immortal") then
				room:revivePlayer(player)
				room:setPlayerProperty(player,"maxhp",sgs.QVariant(1))
				room:setPlayerProperty(player,"hp",sgs.QVariant(1))
				return true
			end
		elseif event==sgs.BuryVictim and player:isAlive() then
			return true
		elseif event==sgs.EventLoseSkill and (player:hasSkill("immortal") or data:toString()=="immortal") then
			room:acquireSkill(player,data:toString())
		end	
	end,
}

TCA00:addSkill(destroy)
TCA00:addSkill(immortal)

sgs.LoadTranslationTable{
	["TCA00"]="☆天宮さくら",
	["#TCA00"]="死神",
	["destroy"]="毁灭",
	[":destroy"]="<b>限定技</b>，任何角色回合开始时，你可以令其他角色说出其身份，然后所有与你敌对的角色，其失去所有的武将技能，将体力上限调整至1，弃置所有的牌，然后永远跳过其的回合。",
	["@god"]="神",
	["@destroy"]="毁灭",
	["#destroyx"]="%to被【毁灭】，跳过了他的回合",
	["immortal"]="不朽",
	[":immortal"]="<b>锁定技</b>，当你即将死亡时，立刻复活并将体力及上限恢复至1点。你不会失去你拥有的技能。",
	["designer:TCA00"]="Nutari",
	["illustrator:TCA00"]="てぃんくる",
}

--☆天宮みずき


TCA01=sgs.General(extension, "TCA01", "god", "5", false,true)

tcfengyintable={skills={},player}
tcfengyin=sgs.CreateTriggerSkill{
	name="tcfengyin",
	events={sgs.Predamage,sgs.DamageForseen,sgs.EventPhaseStart,sgs.BuryVictim},
	priority=4,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local mizuki=room:findPlayerBySkillName(self:objectName())
		if mizuki and (event==sgs.Predamage or event==sgs.DamageForseen and (data:toDamage().transfer or data:toDamage().chain)) then
			local damage=data:toDamage()
			if (damage.from:objectName()==mizuki:objectName() and damage.to:getMark("@forbidden")==0 or damage.to:objectName()==mizuki:objectName() and damage.from and damage.from:getMark("@forbidden")==0 )and damage.from:objectName()~=damage.to:objectName() and room:askForSkillInvoke(mizuki,self:objectName(),data) then
				room:broadcastSkillInvoke("tcfengyin")
				local target
				if damage.from:objectName()==mizuki:objectName() then
					target=damage.to
				else
					target=damage.from
				end	
				local tmp={skills={},player}
				tmp.player=target
				for _,skill in sgs.qlist(target:getVisibleSkillList()) do
					if not (skill:isLordSkill() and not target:isLord()) then
						table.insert(tmp.skills,skill:objectName())
						room:detachSkillFromPlayer(target,skill:objectName())
					end
				end
				table.insert(tcfengyintable,tmp)
				target:gainMark("@forbidden")
			end
		end
		if (event==sgs.EventPhaseStart and mizuki:getPhase()==sgs.Player_Start) or (event==sgs.BuryVictim and player:objectName()==mizuki:objectName()) then
			for _,tmp in ipairs(tcfengyintable) do
				local p=tmp.player
				if p:isAlive() then
					for _,skillname in ipairs(tmp.skills) do
						room:acquireSkill(p,skillname)
					end
					p:loseMark("@forbidden")
				end
			end
			for i=1,#tcfengyintable,1 do
				table.remove(tcfengyintable)
			end
		end
	end,
}

shenghua=sgs.CreateTriggerSkill{
	name="shenghua",
	events={sgs.HpChanged,sgs.DrawNCards},
	frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.HpChanged then
			local x=player:getHp()
			room:setPlayerProperty(player,"maxhp",sgs.QVariant(math.max(1,x)))
			if x<=4 and not player:hasSkill("shengnv") then room:acquireSkill(player,"shengnv") end
			if x<=3 and not player:hasSkill("tianshi") then room:acquireSkill(player,"tianshi") end
			if x<=2 and not player:hasSkill("shenquan") then room:acquireSkill(player,"shenquan") end
			if x<=1 and not player:hasSkill("shenwu") then room:acquireSkill(player,"shenwu") end
			if x<=4 then room:broadcastSkillInvoke("shenghua",5-x) end
		else
			local x=data:toInt()
			i=math.max(0,5-player:getHp())
			if i>4 then i=4 end
			data:setValue(x+i)
			return
		end	
	end,
}

shengnv=sgs.CreateTriggerSkill{
	name="shengnv",
	events={sgs.DamageDone,sgs.EventPhaseStart,sgs.CardEffected},
	frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.DamageDone then
			local damage=data:toDamage()
			if damage.from:distanceTo(player)>1 then
				local log=sgs.LogMessage()
				log.type="#shengnv"
				log.from=player
				log.to:append(damage.from)
				room:sendLog(log)
				room:broadcastSkillInvoke(self:objectName())
				return true
			end
		end
		if event==sgs.CardEffected then
			local effect=data:toCardEffect()
			if effect.from:distanceTo(player)>1 and (effect.card:isNDTrick() or effect.card:isKindOf("Slash"))then
				local log=sgs.LogMessage()
				log.type="#shengnve"
				log.from=player
				log.to:append(effect.from)
				log.arg=effect.card:objectName()
				room:sendLog(log)
				room:broadcastSkillInvoke(self:objectName())
				return true
			end
		end
		if event==sgs.EventPhaseStart and (player:getPhase()==sgs.Player_Discard or player:getPhase()==sgs.Player_Judge) then
			local log=sgs.LogMessage()
			log.type="#shengnvx"
			log.arg=player:getPhaseString()
			log.from=player
			room:sendLog(log)
			return true
		end
	end,
}

tianshi=sgs.CreateTriggerSkill{
	name="tianshi",
	events={sgs.Predamage,sgs.PreHpReduced,sgs.DamageForseen},
	frequency=sgs.Skill_Compulsory,
	priority=3,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local damage=data:toDamage()
		if event==sgs.Predamage then
			if damage.nature~=sgs.DamageStruct_Thunder then
				local log=sgs.LogMessage()
				log.type="#tianshi"
				log.from=player
				room:sendLog(log)
				damage.nature=sgs.DamageStruct_Thunder
			end
			local log=sgs.LogMessage()
			log.type="#tianshix"
			log.from=player
			room:sendLog(log)
			damage.damage=damage.damage+1
			data:setValue(damage)
			room:broadcastSkillInvoke(self:objectName(),1)
		end
		if event==sgs.DamageForseen then
			if damage.nature==sgs.DamageStruct_Thunder then
				local log=sgs.LogMessage()
				log.type="#tianshixx"
				log.from=player
				room:sendLog(log)
				room:broadcastSkillInvoke(self:objectName(),2)
				return true
			end
		elseif event==sgs.PreHpReduced then
			if damage.damage<=2 then damage.damage=damage.damage-1 else damage.damage=1 end
			local log=sgs.LogMessage()
			log.type="#tianshiax"
			log.arg=damage.damage
			log.from=player
			room:sendLog(log)
			room:broadcastSkillInvoke(self:objectName(),2)
			if damage.damage==0 then return true else data:setValue(damage) end
			return false
		end
	end,
}

shenquan_distance=sgs.CreateDistanceSkill{
	name="#shenquan_distance",
	correct_func=function(self,from,to)
		if from:hasSkill("shenquan") then
			return -100
		end
		if to:hasSkill("shenquan") and not to:getDefensiveHorse() then
			return 1
		end
	end,
}

shenquan=sgs.CreateTriggerSkill{
	name="shenquan",
	events={sgs.SlashProceed,sgs.CardUsed},
	frequency=sgs.Skill_Compulsory,
	priority=3,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.SlashProceed then
			local effect=data:toSlashEffect()
			local log=sgs.LogMessage()
			log.type="#shenquan"
			log.from=player
			log.to:append(effect.to)
			room:sendLog(log)
			room:broadcastSkillInvoke(self:objectName())
			room:slashResult(effect,nil)
			return true
		end
		if event==sgs.CardUsed then
			local use=data:toCardUse()
			if use.card:isKindOf("Slash") then
				for _,p in sgs.qlist(use.to) do
					p:addMark("qinggang")
				end
			end
		end
	end,
}

shenwu=sgs.CreateTriggerSkill{
	name="shenwu",
	events={sgs.HpChanged,sgs.MaxHpChanged},
	frequency=sgs.Skill_Compulsory,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local mizuki=room:findPlayerBySkillName(self:objectName())
		if not mizuki then return end
		if event==sgs.HpChanged and player:objectName()~=mizuki:objectName() and player:getMark("@soul")==0 then
			local log=sgs.LogMessage()
			log.type="#shenwu"
			log.from=mizuki
			log.arg=math.max(0,player:getHp())
			log.to:append(player)
			room:sendLog(log)
			room:setPlayerProperty(player,"maxhp",sgs.QVariant(math.max(0,player:getHp())))
			room:broadcastSkillInvoke(self:objectName())
			if player:getHp()<=0 then room:killPlayer(player) end
		end
		if event==sgs.MaxHpChanged and player:objectName()==mizuki:objectName() then
			if mizuki:getMaxHp()<1 then
				room:setPlayerProperty(mizuki,"maxhp",sgs.QVariant(1))
				room:setPlayerProperty(mizuki,"hp",sgs.QVariant(1))
			end
		end
	end,
}

local skill=sgs.Sanguosha:getSkill("shengnv")
if not skill then
        local skillList=sgs.SkillList()
        skillList:append(shengnv)
        sgs.Sanguosha:addSkills(skillList)
end

local skill=sgs.Sanguosha:getSkill("tianshi")
if not skill then
        local skillList=sgs.SkillList()
        skillList:append(tianshi)
        sgs.Sanguosha:addSkills(skillList)
end

local skill=sgs.Sanguosha:getSkill("shenquan")
if not skill then
        local skillList=sgs.SkillList()
        skillList:append(shenquan)
        sgs.Sanguosha:addSkills(skillList)
end

local skill=sgs.Sanguosha:getSkill("shenwu")
if not skill then
        local skillList=sgs.SkillList()
        skillList:append(shenwu)
        sgs.Sanguosha:addSkills(skillList)
end

TCA01:addSkill(tcfengyin)
TCA01:addSkill(shenghua)
TCA01:addSkill(shenquan_distance)

sgs.LoadTranslationTable{
	["TCA01"]="☆天宮みずき",
	["#TCA01"]="死神の妹",
	["~TCA01"]="あ、お姉さま",
	["tcfengyin"]="封印",
	[":tcfengyin"]="你即将对其他角色造成伤害前或者你即将受到其他角色伤害前，可以移除其所有武将技能。被此法移除的武将技能，在你下回合回合开始或者你死亡时全部返回",
	["#tcfengyin"]="你可以弃置一张牌（包括装备）封印%src的技能",
	["$tcfengyin1"]="动不了的感觉如何？",
	["$tcfengyin2"]="太弱了。",
	["@forbidden"]="禁",
	["shenghua"]="升华",
	[":shenghua"]="<b>锁定技</b>，你的体力变化时，你将体力上限减至和体力相同的数值(最小为1)。当你的体力不高于特定数值时，分别获得如下技能：\
	体力不高于4时：圣女：<b>锁定技</b>，离你距离1以上的角色不能对你造成伤害且【杀】和非延时锦囊对你无效,你跳过判定和弃牌阶段\
	体力不高于3时：天使：<b>锁定技</b>，你即将造成的伤害均视为雷电伤害并且伤害+1。雷电伤害对你无效，你受到的伤害均-1且不大于1\
	体力不高于2时：神权：<b>锁定技</b>，你的【杀】无视防具且不能被躲闪。你与其他角色计算距离时始终为1，其他角色与你计算距离时始终+1（不能和+1马叠加）\
	体力不高于1时：神无：<b>锁定技</b>，除你以外的角色体力变动时，其体力上限立刻变动至与其体力相同（为0则即死），你的体力上限不小于1\
	\
	此外，每从升华获得一个技能，摸牌阶段多摸一张牌",
	["$shenghua1"]="我的新招怎样",
	["$shenghua2"]="我还能更强哦",
	["$shenghua3"]="是时候拿出真本事了",
	["$shenghua4"]="逼我到这步还是头一次",
	["shengnv"]="圣女",
	[":shengnv"]="<b>锁定技</b>，离你距离1以上的角色不能对你造成伤害且【杀】和非延时锦囊对你无效，你跳过判定和弃牌阶段",
	["$shengnv"]="胆小鬼，别逃了",
	["#shengnv"]="%from的【圣女】被触发，%to对其造成的伤害无效",
	["#shengnve"]="%from的【圣女】被触发，%to对其使用的的%arg无效",
	["#shengnvx"]="%from的【圣女】被触发，%from跳过%arg阶段",
	["tianshi"]="天使",
	[":tianshi"]="<b>锁定技</b>，你即将造成的伤害均视为雷电伤害并且伤害+1。雷电伤害对你无效，你受到的伤害均-1且不大于1",
	["$tianshi1"]="痛了吧",
	["$tianshi2"]="才不怕你们了",
	["#tianshi"]="%from的【天使】被触发，其造成的伤害视为雷电伤害",
	["#tianshix"]="%from的【天使】被触发，其造成的伤害+1",
	["#tianshixx"]="%from的【天使】被触发，其即将受到的雷电伤害无效",
	["#tianshiax"]="%from的【天使】被触发，其即将受到的伤害减少至%arg点",
	["#shenquan_distance"]="神权",
	["shenquan"]="神权",
	["$shenquan"]="嘿嘿，无路可退了吧",
	[":shenquan"]="<b>锁定技</b>，你的【杀】无视防具且不能被躲闪。你与其他角色计算距离时始终为1，其他角色与你计算距离时始终+1（不能和+1马叠加）",
	["#shenquan"]="%from的【神权】被触发，对%to使用的【杀】不能被躲闪",
	["shenwu"]="神无",
	[":shenwu"]="<b>锁定技</b>，除你以外的角色体力变动时，其体力上限立刻变动至与其体力相同（为0则即死），你的体力上限不小于1",
	["$shenwu"]="结束吧",
	["#shenwu"]="%from的【神无】被触发，%to的体力上限降低至了%arg点",
	["#shenwux"]="%from的【神无】被触发，失去体力的效果对%from无效",
	["designer:TCA01"]="Nutari",
	["cv:TCA01"]="Nutari",
	["illustrator:TCA01"]="てぃんくる",
}

--八雲小雪

TCA02=sgs.General(extension,"TCA02","god","3",false)

yuliao_card=sgs.CreateSkillCard{
	name="yuliao_card",
	will_throw=true,
	target_fixed=false,
	filter=function(self,targets,to_select)
		return #targets<1
	end,
	on_use=function(self,room,source,targets)
		local target=targets[1]
		local choice="draw"
		if target:isWounded() then choice=choice.."+recoverhp" end
		if not target:getJudgingArea():isEmpty() then choice=choice.."+recyclerjudge" end
		if not target:faceUp() or target:isChained() then choice=choice.."+ylturnover" end
		if choice~="draw" then
			choice=room:askForChoice(target,"yuliao",choice)
		end
		if choice=="draw" then
			target:drawCards(2)
		elseif choice=="recoverhp" then
			local recover=sgs.RecoverStruct()
			recover.who=source
			room:recover(target,recover)
		elseif choice=="recyclerjudge" then
			for _,cd in sgs.qlist(target:getJudgingArea()) do
				target:obtainCard(cd)
			end
		elseif choice=="ylturnover" then
			if not target:faceUp() then target:turnOver() end
			if target:isChained() then room:setPlayerProperty(target,"chained",sgs.QVariant(false)) end
		end	
		room:setPlayerFlag(source,"yuliaoused")
	end,
}

yuliao_vs=sgs.CreateViewAsSkill{
	name="yuliao",
	n=1,
	view_filter=function()
		return true
	end,
	view_as=function(self,cards)
		if #cards==1 then
			local acard=yuliao_card:clone()
			acard:addSubcard(cards[1]:getId())
			acard:setSkillName("yuliao")
			return acard
		end
	end,
	enabled_at_play=function()
		return not sgs.Self:hasFlag("yuliaoused")
	end,
}

yuliao=sgs.CreateTriggerSkill{
	name="yuliao",
	events=sgs.EventPhaseEnd,
	view_as_skill=yuliao_vs,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if player:getPhase()==sgs.Player_Play then
			room:setPlayerFlag(player,"-yuliaoused")
		end
	end,
}

huiguang=sgs.CreateTriggerSkill{
	name="huiguang",
	events=sgs.Dying,
	priority=3,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local koyuki=room:findPlayerBySkillName(self:objectName())
		if koyuki and not koyuki:isNude() and event==sgs.Dying then
			local dying=data:toDying()
			if dying.who:isDead() then return end
			local recover=sgs.RecoverStruct()
			recover.who=koyuki
			recover.recover=0
			while dying.who:getHp()<1 and player:objectName()==dying.who:objectName() and not koyuki:isNude() do
				if not room:askForCard(koyuki,".|.|.|.|.","@huiguang:"..dying.who:objectName(),data,sgs.Card_MethodDiscard,player) then break end
				recover.recover=recover.recover+1
				room:recover(dying.who,recover)
			end
		end
	end,
}

bizhan=sgs.CreateTriggerSkill{
	name="bizhan",
	events={sgs.PreHpRecover,sgs.CardsMoveOneTime,sgs.PreHpReduced,sgs.EventPhaseStart},
	frequency=sgs.Skill_Compulsory,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.PreHpRecover then
			local recover=data:toRecover()
			if recover.who:hasSkill(self:objectName()) then
				player:gainMark("@shield")
			end
		end
		if event==sgs.PreHpReduced and data:toDamage().to:getMark("@shield")>0 then
			local damage=data:toDamage()
			local log=sgs.LogMessage()
			log.from=damage.to
			log.type="#bizhan"
			if damage.damage>damage.to:getMark("@shield") then
				log.arg=damage.to:getMark("@shield")
				room:sendLog(log)
				local x=damage.to:getMark("@shield")
				damage.to:loseAllMarks("@shield")
				if damage.from and x>1 then
					local damagex=sgs.DamageStruct()
					damagex.damage=1
					damagex.nature=damage.nature
					damagex.to=damage.from
					damagex.from=nil
					room:damage(damagex)
				end
				damage.damage=damage.damage-x
				data:setValue(damage)
				damage.to:loseAllMarks("@shield")
				return false
			else
				log.arg=damage.damage
				room:sendLog(log)
				damage.to:loseAllMarks("@shield")
				if damage.from and damage.damage>1 then
					local damagex=sgs.DamageStruct()
					damagex.damage=1
					damagex.nature=damage.nature
					damagex.to=damage.from
					damagex.from=nil
					room:damage(damagex)
				end
				return true
			end
		end
	end,
}

buji=sgs.CreateTriggerSkill{
	name="buji",
	events=sgs.EventPhaseStart,
	frequency=sgs.Skill_Frequent,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if player:getPhase()==sgs.Player_Finish  then
			local x=player:getMaxHp()-player:getHandcardNum()
			if x>0 and room:askForSkillInvoke(player,self:objectName())  then
				local idlist=room:getNCards(x)
				room:fillAG(idlist)
				room:getThread():delay(1000)
				local basiclist=sgs.IntList()
				local unbasiclist=sgs.IntList()
				for _,id in sgs.qlist(idlist) do
					local card=sgs.Sanguosha:getCard(id)
					if card:isKindOf("BasicCard") then basiclist:append(id) else unbasiclist:append(id) end
				end
				if not basiclist:isEmpty() then
					local move=sgs.CardsMoveStruct()
					move.card_ids=basiclist
					move.to=player
					move.to_place=sgs.Player_PlaceHand
					room:moveCardsAtomic(move,true)
				end
				if not unbasiclist:isEmpty() then
					local choice=room:askForChoice(player,self:objectName(),"qizhi+zhuanjiao")
					if choice=="qizhi" then
						for _,id in sgs.list(unbasiclist) do
							room:throwCard(id,player)
						end										
					else
						local players=sgs.SPlayerList()
						local x=100
						for _,p in sgs.list(room:getOtherPlayers(player)) do
							if p:getHandcardNum()<x then x=p:getHandcardNum() end
						end
						for _,p in sgs.list(room:getOtherPlayers(player)) do
							if p:getHandcardNum()==x then players:append(p) end
						end
						local target=room:askForPlayerChosen(player,players,self:objectName())
						local move=sgs.CardsMoveStruct()
						move.card_ids=unbasiclist
						move.to=target
						move.to_place=sgs.Player_PlaceHand
						room:moveCardsAtomic(move,true)
					end
				end
				room:broadcastInvoke("clearAG")
			end
		end
	end,
}

TCA02:addSkill(yuliao)
TCA02:addSkill(huiguang)
TCA02:addSkill(bizhan)
TCA02:addSkill(buji)

sgs.LoadTranslationTable{
	["TCA02"]="八神小雪",
	["#TCA02"]="超医者",
	["~TCA02"]="やるじゃないか",
	["yuliao_card"]="愈疗",
	["yuliao"]="愈疗",
	[":yuliao"]="出牌阶段，你可以弃置一张卡并选择一名角色。该角色可以选择以下之1：摸2张牌/恢复1点体力/收回判定区内所有的牌/重置并翻至正面朝上",
	["recoverhp"]="恢复1点体力",
	["recyclerjudge"]="回收判定区",
	["ylturnover"]="重置并翻回正面",
	["huiguang"]="回光",
	[":huiguang"]="任何角色濒死时，你可以弃置一张牌，恢复其体力1点。此效果可以一直发动直到目标体力高于0，连续对同一名角色发动的场合，每一次都会比上一次多恢复1点体力",
	["@huiguang"]="你可以弃置一张牌对%src发动回光",
	["bizhan"]="避战",
	[":bizhan"]="<b>锁定技</b>，你每恢复任何角色一次体力，其获得1枚“盾”标记。盾标记可以吸收目标接下来受到的一次伤害（1枚盾标记吸收1点无论吸收多少都全部移除），当盾吸收伤害时，若实际吸收的伤害超过1点，则伤害来源（若存在）会受到1点同属性的伤害",
	["#bizhan"]="%from的盾标记吸收了即将受到的%arg点伤害",
	["#bizhanx"]="%from的【避战】触发",
	["@shield"]="盾",
	["buji"]="补给",
	[":buji"]="回合结束阶段的开始，若你的手牌数少于你的体力上限，则你可以展示牌堆顶的X张牌（X为你的体力上限-你的手牌数），然后你拿走其中的基础牌，对于其中的非基础牌，你可以选择以下两项中的一项：将这些非基础牌置入弃牌堆；或者将这些牌交给场上除你手牌数最少的一名角色",
	["designer:TCA02"]="Nutari",
	["illustrator:TCA02"]="てぃんくる",
}

--天宮ひかり

TCA03=sgs.General(extension,"TCA03","god","3",false)

pianyi_card=sgs.CreateSkillCard{
	name="pianyi_card",
	will_throw=true,
	target_fixed=false,
	filter=function(self,targets,to_select)
		return #targets==0 and to_select:hasFlag("pianyiable")
	end,
	on_use=function(self,room,source,targets)
		local value=sgs.QVariant()
		value:setValue(targets[1])
		room:setTag("pianyitarget",value)
		for _,p in sgs.qlist(room:getAllPlayers()) do
			room:setPlayerFlag(p,"-pianyiable")
		end
	end,
}

pianyi_vs=sgs.CreateViewAsSkill{
	name="pianyi",
	n=1,
	view_filter=function(self,selected,to_select)
		return to_select:isKindOf("BasicCard")
	end,
	view_as=function(self,cards)
		if #cards==1 then
			local acard=pianyi_card:clone()
			acard:setSkillName("pianyi")
			acard:addSubcard(cards[1]:getId())
			return acard
		end
	end,
	enabled_at_play=function()
		return false
	end,
}

pianyi=sgs.CreateTriggerSkill{
	name="pianyi",
	events={sgs.DamageInflicted,sgs.DamageComplete},
	frequency=sgs.Skill_Frequent,
	view_as_skill=pianyi_vs,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local damage=data:toDamage()
		local hikari=room:findPlayerBySkillName(self:objectName())
		if not hikari then return  end
		if event==sgs.DamageInflicted and not player:hasFlag("pianyi")then
			local log=sgs.LogMessage()
			log.from=damage.from
			log.to:append(damage.to)
			log.type="#beforedamage"
			room:sendLog(log)
			for _,p in sgs.qlist(room:getOtherPlayers(damage.to)) do
				if damage.to:inMyAttackRange(p) then
					room:setPlayerFlag(p,"pianyiable")
				end
			end
			local basic=false
			for _,card in sgs.qlist(hikari:getHandcards()) do
				if card:isKindOf("BasicCard") then basic=true break end
			end
			if basic and room:askForSkillInvoke(hikari,self:objectName(),data) and room:askForUseCard(hikari,"@@pianyi","@pianyi") then
				local target=room:getTag("pianyitarget"):toPlayer()
				room:removeTag("pianyitarget")
				room:setPlayerFlag(target,"pianyi")
				local damagex=damage
				damagex.to=target
				damagex.transfer=true
				room:damage(damagex)
				return true
			end
			for _,p in sgs.qlist(room:getAllPlayers()) do
				room:setPlayerFlag(p,"-pianyiable")
			end
		end
		if event==sgs.DamageComplete then
			if damage.to:hasFlag("pianyi") then
				room:setPlayerFlag(damage.to,"-pianyi")
				if damage.from and not damage.from:isNude() and damage.from:objectName()~=damage.to:objectName() then
					local cdid=room:askForCardChosen(damage.to,damage.from,"he","pianyi")
					room:moveCardTo(sgs.Sanguosha:getCard(cdid),damage.to,sgs.Player_PlaceHand,false)
				else
					damage.to:drawCards(1)
				end
			end
		end
	end,
}

tongshi=sgs.CreateTriggerSkill{
	name="tongshi",
	events=sgs.EventPhaseStart,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if player:getPhase()==sgs.Player_Start then
			if not room:askForSkillInvoke(player,self:objectName()) then return end
			local choice=room:askForChoice(player,self:objectName(),"draw+discard")
			if choice=="draw" then
				for _,p in sgs.qlist(room:getAllPlayers()) do
					p:drawCards(1)
				end
			else
				for _,p in sgs.qlist(room:getAllPlayers()) do
					if not p:isNude() then room:askForDiscard(p,self:objectName(),1,1,false,true) end
				end
			end
		end
	end,
}

niliu=sgs.CreateTriggerSkill{
	name="niliu",
	events=sgs.EventPhaseStart,
	frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if player:getPhase()==sgs.Player_Finish then
			room:setPlayerProperty(player,"maxhp",sgs.QVariant(player:getMaxHp()+1))
			player:drawCards(player:getLostHp())
			local flag=true
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if player:getMaxHp()<=p:getMaxHp() then flag=false break end
			end
			if flag then
				room:setPlayerProperty(player,"maxhp",sgs.QVariant(3))
			end	
		end
	end,
}

niliu_max=sgs.CreateMaxCardsSkill{
	name="#niliu_max",
	extra_func=function(self,player)
		if player:hasSkill("niliu") then
			return math.max(0,player:getLostHp()-player:getHp())
		end
	end,
}

niliu_distance=sgs.CreateDistanceSkill{
	name="#niliu_distance",
	correct_func=function(self,from,to)
		if from:hasSkill("niliu") then
			return -from:getLostHp()
		end
	end,
}


lianxie_card=sgs.CreateSkillCard{
	name="lianxie_card",
	will_throw=false,
	target_fixed=false,
	filter=function(self,targets,to_select)
		local slash=sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
		local lianxietargets=sgs.PlayerList()
		for _,p in ipairs(targets) do
			lianxietargets:append(p)
		end	
		return slash:targetFilter(lianxietargets,to_select,sgs.Self)
	end,
	on_use=function(self,room,source,targets)
		local meidos=sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(source)) do
			if p:hasSkill("lianxie") then meidos:append(p) end
		end
		if meidos:isEmpty() then return false end
		local tohelp=sgs.QVariant()
		tohelp:setValue(source)
		for _,meido in sgs.qlist(meidos) do
			room:setPlayerFlag(meido,"lianxie")
			local slash=room:askForCard(meido,"slash","@lianxieslash:"..source:objectName(),tohelp,sgs.Card_MethodResponse,source)
			room:setPlayerFlag(meido,"-lianxie")
			if slash then
				slash:setSkillName("lianxie")
				local use=sgs.CardUseStruct()
				use.card=slash
				use.from=source
				for _,target in ipairs(targets) do
					use.to:append(target)
				end
				room:useCard(use,true)
				return
			end
		end
		room:setPlayerFlag(source,"lianxieend")
	end,
}

lianxie_vs=sgs.CreateViewAsSkill{
	name="lianxie",
	n=0,
	view_as=function()
		local acard=lianxie_card:clone()
		acard:setSkillName("lianxie")
		return acard
	end,
	enabled_at_play=function()
		local slash=sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
		return not sgs.Self:isCardLimited(slash,sgs.Card_MethodUse) and sgs.Self:canSlashWithoutCrossbow() or ((sgs.Self:getWeapon()) and (sgs.Self:getWeapon():getClassName()=="Crossbow"))
	end,
}

lianxie=sgs.CreateTriggerSkill{
	name="lianxie",
	events={sgs.PreHpRecover,sgs.CardAsked,sgs.Damaged,sgs.GameStart},
	view_as_skill=lianxie_vs,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.CardAsked then
			if player:hasFlag("lianxie") then return end
			local pattern=data:toString()
			if pattern~="jink" and pattern~="slash" then return end
			local meidos=sgs.SPlayerList()
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasSkill("lianxie") then meidos:append(p) end
			end
			if meidos:isEmpty() or not room:askForSkillInvoke(player,"lianxie",data) then return end
			tohelp=sgs.QVariant()
			tohelp:setValue(player)
			for _,meido in sgs.qlist(meidos) do
				room:setPlayerFlag(meido,"lianxie")
				local card=room:askForCard(meido,pattern,"@lianxie"..pattern..":"..player:objectName(),tohelp,sgs.Card_MethodResponse,player)
				if card then
					room:setPlayerFlag(meido,"-lianxie")
					card:setSkillName("lianxie")
					room:provide(card)
					return true
				end
				room:setPlayerFlag(meido,"-lianxie")
			end
		end
		if event==sgs.PreHpRecover then
			local recover=data:toRecover()
			tohelp=sgs.QVariant()
			tohelp:setValue(player)
			if recover.who:hasSkill("lianxie") and recover.who:objectName()~=player:objectName() and room:askForSkillInvoke(recover.who,"lianxie",tohelp) then
				recover.recover=recover.recover+1
				data:setValue(recover)
				return false
			end
		end
		if event==sgs.Damaged then
			local damage=data:toDamage()
			local meidos=sgs.SPlayerList()
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasSkill("lianxie") then meidos:append(p) end
			end
			if meidos:isEmpty() or player:isDead() or not room:askForSkillInvoke(player,"lianxie",data) then return end
			for _,meido in sgs.qlist(meidos) do
				meido:drawCards(damage.damage)
			end
		end
	end,
}

TCA03:addSkill(pianyi)
TCA03:addSkill(tongshi)
TCA03:addSkill(niliu)
TCA03:addSkill(niliu_max)
TCA03:addSkill(niliu_distance)
TCA03:addSkill(lianxie)

sgs.LoadTranslationTable{
	["TCA03"]="天宮ひかり",
	["#TCA03"]="天宮家の白",
	["~TCA03"]="ひかり、負けじゃだ",
	["pianyi_card"]="偏移",
	["pianyi"]="偏移",
	[":pianyi"]="任何角色受到伤害之前，你可以弃一张基础牌将效果转移至其射程内其他玩家（非受伤害者）的身上。然后转移目标抽伤害来源1张牌，若没有伤害来源或者伤害来源没有牌或者伤害来源和转移目标相同，其摸1张牌。",
	["@pianyi"]="你可以偏移该伤害至其射程内的一名角色上",
	["~pianyi"]="选1张手牌->点击其射程内的一名角色->点击确定",
	["tongshi"]="同势",
	[":tongshi"]="你回合开始阶段的开始，你可以选择其中1项：所有角色各摸1张牌/所有角色各弃置1张牌。",
	["#niliu_distance"]="流势",
	["niliu"]="逆流",
	[":niliu"]="<b>锁定技</b>，你的手牌上限为你已失去的体力和你当前体力中的大者，你与其他角色计算距离时始终-x，x为你已失去的体力。你回合结束阶段开始，你增加1点体力上限，然后你摸x张牌，x为你已失去的体力。若此时你为全场体力上限最高者（仅有一人），你体力上限减少至3点。",
	["lianxie_card"]="连携",
	["lianxie"]="连携",
	[":lianxie"]="对于所以有该技能的角色：每当其中一名角色需要出杀或者闪时，其他角色均可以替他出杀或者闪。每当其中一名角色受到伤害时，其可以让其他角色摸x张牌,x为伤害量。其中每个角色使其他角色恢复体力时，可以额外恢复1点体力。",
	["lianxie:jink"]="是否发动【连携】让其他人为你出闪",
	["lianxie:slash"]="是否发动【连携】让其他人为你出杀",
	["@lianxieslash"]="你可以帮%src出杀",
	["@lianxiejink"]="你可以帮%src出闪",
	["designer:TCA03"]="Nutari",
	["illustrator:TCA03"]="てぃんくる",
}

--天宮ひなた

TCA04=sgs.General(extension,"TCA04","god","3",false)

fuying_card=sgs.CreateSkillCard{
	name="fuying_card",
	will_throw=false,
	target_fixed=false,
	filter=function(self,targets,to_select)
		return #targets<2
	end,
	feasible=function(self,targets)
		return #targets==2
	end,
	on_use=function(self,room,source,targets)
		lasttargets={}
		for _,p in sgs.qlist(room:getAllPlayers()) do
			if p:getMark("@similar")>0 then p:loseMark("@similar") table.insert(lasttargets,p) end
		end
		if #lasttargets==2 then
			room:setFixedDistance(lasttargets[1],lasttargets[2],-1)
			room:setFixedDistance(lasttargets[2],lasttargets[1],-1)
		end
		room:setFixedDistance(targets[1],targets[2],1)
		room:setFixedDistance(targets[2],targets[1],1)
		targets[1]:gainMark("@similar")
		targets[2]:gainMark("@similar")
	end,
}

fuying_vs=sgs.CreateViewAsSkill{
	name="fuying",
	n=0,
	view_as=function()
		return fuying_card:clone()
	end,
	enabled_at_play=function()
		return false
	end,
}

fuying=sgs.CreateTriggerSkill{
	name="fuying",
	view_as_skill=fuying_vs,
	events={sgs.GameStart,sgs.EventPhaseStart,sgs.BuryVictim,sgs.EventLoseSkill,sgs.Damaged,sgs.HpLost,sgs.PreHpReduced,sgs.HpChanged,sgs.Dying},
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local hinata=room:findPlayerBySkillName(self:objectName())
		if event==sgs.BuryVictim and player:hasSkill(self:objectName()) or event==sgs.EventLoseSkill and data:toString()==self:objectName() then
			targets={}
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("@similar")>0 then p:loseMark("@similar") table.insert(targets,p) end
			end
			if #targets==2 then
				room:setFixedDistance(targets[1],targets[2],-1)
				room:setFixedDistance(targets[2],targets[1],-1)
			end
		end
		if (event==sgs.EventPhaseStart and player:getPhase()==sgs.Player_Start or event==sgs.GameStart)and player:hasSkill(self:objectName())then
			room:askForUseCard(player,"@@fuying","@fuying")
		end
		if (event==sgs.PreHpReduced or event==sgs.HpLost) and player:getMark("@similar")>0 and not player:hasFlag("fuying") then
			if event==sgs.PreHpReduced then
				local damage=data:toDamage()
				if damage.to:hasFlag("yanliu") and damage.from and damage.from:hasFlag("yanliusource") then return end
			end	
			local other
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getMark("@similar")>0 then
					other=p
					break
				end
			end
			if not other then return end
			local log=sgs.LogMessage()
			log.from=player
			log.to:append(other)
			log.type="#fuying"
			room:sendLog(log)
			if event==sgs.PreHpReduced then
				local value=sgs.QVariant()
				value:setValue(other)
				room:setTag("fuyingother",value)
				room:setTag("fuyingdamage",data)
			end
			if event==sgs.HpLost then
				local x=data:toInt()
				local value=sgs.QVariant()
				value:setValue(other)
				room:setTag("fuyingother",value)
				room:setTag("fuyinglost",sgs.QVariant(x))
			end
			return false
		end
		if event==sgs.HpChanged then
			local other=room:getTag("fuyingother"):toPlayer()
			local x=room:getTag("fuyinglost"):toInt()
			if other and x>0 then
				room:removeTag("fuyingother")				
				room:removeTag("fuyinglost")
				room:setPlayerFlag(other,"fuying")
				room:loseHp(other,x)
				room:setPlayerFlag(other,"-fuying")				
			end	
		end
		if event==sgs.Damaged then
			local damage=room:getTag("fuyingdamage"):toDamage()
			local other=room:getTag("fuyingother"):toPlayer()
			if other and damage then
				room:removeTag("fuyingother")
				room:removeTag("fuyingdamage")
				damage.to=other
				damage.transfer=true
				damage.chain=true
				local chain=false
				if damage.nature~=sgs.DamageStruct_Normal and other:isChained() then chain=true end
				room:setPlayerFlag(other,"fuying")
				room:damage(damage)
				room:setPlayerFlag(other,"-fuying")
				if chain and other:isAlive() then room:setPlayerProperty(other,"chained",sgs.QVariant(true)) end
			end
		end
		if event==sgs.Dying and data:toDying().who:getMark("@similar")>0 then
			for _,p in sgs.qlist(room:getOtherPlayers(data:toDying().who)) do
				if p:getMark("@similar")>0 then
					other=p
					break
				end
			end
			if other then
				data:toDying().who:loseMark("@similar")
				other:loseMark("@similar")
				room:setFixedDistance(data:toDying().who,other,-1)
				room:setFixedDistance(other,data:toDying().who,-1)				
			end
		end
	end,
}

liuzhuan_card=sgs.CreateSkillCard{
	name="liuzhuan_card",
	filter=function(self,targets,to_select)
		if #targets>0 then return false end
		if sgs.Self:hasFlag("liuzhuan1") then
			return to_select:isWounded() and sgs.Self:objectName()~=to_select:objectName()
		else
			return sgs.Self:objectName()~=to_select:objectName()
		end
	end,
	on_use=function(self,room,source,targets)
		if source:hasFlag("liuzhuan1") then
			room:setPlayerFlag(source,"-liuzhuan1")
			local recover=sgs.RecoverStruct()
			recover.who=source
			recover.recover=1
			room:recover(targets[1],recover,true)					
		else
			room:setPlayerFlag(source,"-liuzhuan2")			
			local damage=sgs.DamageStruct()
			damage.from=source
			damage.damage=1
			damage.to=targets[1]
			room:damage(damage)
		end
	end,			
}
	

liuzhuan_vs=sgs.CreateViewAsSkill{
	name="liuzhuan",
	n=0;
	view_as=function(self,cards)
		return liuzhuan_card:clone()
	end,
	enabled_at_play=function()
		return false
	end,	
}

liuzhuan=sgs.CreateTriggerSkill{
	name="liuzhuan",
	events={sgs.Damaged,sgs.HpRecover},
	frequency=sgs.Skill_NotFrequent,
	view_as_skill=liuzhuan_vs,
	priority=-1,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.Damaged then
			room:setPlayerFlag(player,"liuzhuan1")
			room:askForUseCard(player,"@@liuzhuan","@liuzhuan1",1)
			room:setPlayerFlag(player,"-liuzhuan1")
		else
			room:setPlayerFlag(player,"liuzhuan2")
			room:askForUseCard(player,"@@liuzhuan","@liuzhuan2",2)
			room:setPlayerFlag(player,"-liuzhuan2")
		end	
	end,
}

niansui_card=sgs.CreateSkillCard{
	name="niansui_card",
	target_fixed=false,
	filter=function(self,targets,to_select)
		return #targets==0 and to_select:getMark("@broken")>0
	end,
	on_use=function(self,room,source,targets)
		targets[1]:loseMark("@broken")
		local recover=sgs.RecoverStruct()
		recover.who=source
		room:recover(source,recover)
	end,
}

niansui_vs=sgs.CreateViewAsSkill{
	name="niansui",
	n=0,
	view_as=function()
		return niansui_card:clone()
	end,
}	

niansui=sgs.CreateTriggerSkill{
	name="niansui",
	events={sgs.Dying,sgs.BuryVictim,sgs.PreHpRecover},
	frequency=sgs.Skill_NotFrequent,
	view_as_skill=niansui_vs,
	can_trigger=function()
		return true
	end,	
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local hinata=room:findPlayerBySkillName("niansui")
		if event==sgs.Dying then
			if player:objectName()~=data:toDying().who:objectName() then return end
			if player:objectName()==hinata:objectName() then return end
			if not room:askForSkillInvoke(hinata,"niansui",data) then return end
			player:gainMark("@broken")
			if player:getMark("@broken")>=3 then
				local log=sgs.LogMessage()
				log.from=hinata
				log.to:append(player)
				log.type="#niansui"
				room:sendLog(log)
				room:killPlayer(player)
			end
		end
		if event==sgs.PreHpRecover and player:getMark("@broken")>0 then
			local rec=data:toRecover()
			if rec.recover>player:getLostHp()-player:getMark("@broken") then
				local log=sgs.LogMessage()
				log.from=hinata
				log.to:append(player)
				log.type="#niansuixx"
				room:sendLog(log)
				rec.recover=math.max(0,player:getLostHp()-player:getMark("@broken"))
				if rec.recover==0 then return true else data:setValue(rec) return false end
			end			
		end
		if event==sgs.BuryVictim and player:getMark("@broken")>0 and hinata then
			local log=sgs.LogMessage()
			log.from=hinata
			log.to:append(player)
			log.type="#niansuix"
			room:sendLog(log)
			local recover=sgs.RecoverStruct()
			recover.who=player
			recover.recover=player:getMark("@broken")
			room:recover(hinata,recover)
		end
		if event==sgs.BuryVictim and player:objectName()==hinata:objectName() then
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("@broken")>0 then
					p:loseAllMarks("@broken")
				end
			end
		end	
	end,
}

TCA04:addSkill(fuying)
TCA04:addSkill(liuzhuan)
TCA04:addSkill(niansui)
TCA04:addSkill("lianxie")

sgs.LoadTranslationTable{
	["TCA04"]="天宮ひなた",
	["#TCA04"]="天宮家の蒼",
	["~TCA04"]="ひなた、退場",
	["fuying_card"]="附影",
	["fuying"]="附影",
	[":fuying"]="游戏开始和你回合开始阶段，你可以选择2名角色，令其互相之间距离为1，当其中一方受到伤害或者失去体力时，令一方受到同样的影响（附影的伤害不会触发本身也不会触发连环）。附影的连接效果持续到其中的一方进入濒死状态（导致濒死的伤害或者体力流失依旧会被复制）或者你重新选择附影的对象。",
	["@fuying"]="你可以将两名角色附影",
	["~fuying"]="选择2名不同的角色->点击确定",
	["#fuying"]="%to被%from【附影】，%to会受到同样效果的影响",
	["@similar"]="同位",
	["liuzhuan"]="流转",
	["liuzhuan_card"]="流转",
	[":liuzhuan"]="每当你受到一次伤害后，你可以恢复任意一名其他角色一点体力。每当你恢复一次体力，你可以对任意一名角色造成一点伤害。",
	["@liuzhuan1"]="你可以恢复任意一名角色1点体力",
	["~liuzhuan1"]="选择一名已受伤的角色->点击确定",
	["@liuzhuan2"]="你可以对任意一名其他角色造成1点伤害",
	["~liuzhuan2"]="选择一名其他角色->点击确定",
	["#niansui_distance"]="碾碎",
	["niansui_card"]="碾碎",
	["niansui"]="碾碎",
	[":niansui"]="每当一名角色进入濒死状态时，你可以将一枚破碎标记置于其面前，目标恢复体力时，体力不会超过其最大生命减去其破碎标记数的量。当一个角色获得第3枚破碎标记时，其立刻死亡。任何带有破碎标记的角色死亡时，其令你恢复等同于破碎标记数的体力。出牌阶段内，你可以移除其他角色面前的1枚破碎标记，然后你恢复1点体力。",
	["#niansui"]="%from的【碾碎】触发，%to即死",
	["#niansuix"]="%from的【碾碎】触发",
	["#niansuixx"]="%from的【碾碎】触发，%to的体力恢复被吸收",
	["@broken"]="破碎",
	["designer:TCA04"]="Nutari",
	["illustrator:TCA04"]="てぃんくる",
}

--天宮かがみ

TCA05=sgs.General(extension,"TCA05","god","3",false)

huixiang=sgs.CreateTriggerSkill{
	name="huixiang",
	events={sgs.CardUsed,sgs.EventPhaseChanging},
	frequency=sgs.Skill_Frequent,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.CardUsed then
			local use=data:toCardUse()
			local kagami=room:findPlayerBySkillName(self:objectName())
			if not kagami or not use.card:isNDTrick() or kagami:objectName()==player:objectName() then return false end
			local card
			local x=0
			if use.card:isRed() then
				for _,cd in sgs.qlist(kagami:getCards("he")) do
					if cd:isRed() and (cd:isKindOf("BasicCard") or cd:isKindOf("EquipCard")) then x=x+1 end
				end
				if x>0 then
					card=room:askForCard(kagami,"BasicCard,EquipCard|.|.|.|red","@huixiang:"..player:objectName(),data,sgs.Card_MethodDiscard,player)
				end
			elseif use.card:isBlack() then
				for _,cd in sgs.qlist(kagami:getCards("he")) do
					if cd:isBlack() and (cd:isKindOf("BasicCard") or cd:isKindOf("EquipCard")) then x=x+1 end
				end
				if x>0 then
					card=room:askForCard(kagami,"BasicCard,EquipCard|.|.|.|black","@huixiang:"..player:objectName(),data,sgs.Card_MethodDiscard,player)
				end
			end
			if card then
				kagami:obtainCard(use.card)
				return true
			else
				player:gainMark("@silent")
				room:setPlayerCardLimitation(player,"use,response","TrickCard",false)
			end
		end	
		if event==sgs.EventPhaseChanging then
			local change=data:toPhaseChange()
			if change.to==sgs.Player_Finish and player:getMark("@silent")>0 then
				player:loseAllMarks("@silent")
				room:removePlayerCardLimitation(player,"use,response","TrickCard")
			end
		end			
	end,
}

zaoyin=sgs.CreateTriggerSkill{
	name="zaoyin",
	events=sgs.CardUsed,
	frequency=sgs.Skill_Frequent,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local use=data:toCardUse()
		if not use.card:isNDTrick() or not room:askForSkillInvoke(player,self:objectName(),data) then return end
		local playerx=room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName())
		local judge=sgs.JudgeStruct()
		judge.who=playerx
		judge.reason=self:objectName()
		judge.good=true
		if use.card:isRed() then
			judge.pattern=sgs.QRegExp("(.*):(heart|diamond):(.*)")
		elseif use.card:isBlack() then
			judge.pattern=sgs.QRegExp("(.*):(spade|club):(.*)")
		else
			judge.pattern=sgs.QRegExp("(.*):(.*):(.*)")
			judge.good=false
		end
		judge.play_animation=true
		room:judge(judge)
		if judge:isGood() then
			player:drawCards(1)
		else
			local damage=sgs.DamageStruct()
			damage.from=player
			damage.to=playerx
			if judge.card:isRed() then damage.nature=sgs.DamageStruct_Fire else damage.nature=sgs.DamageStruct_Thunder end
			damage.damage=1
			room:damage(damage)
		end
	end,
}

tiaohe=sgs.CreateProhibitSkill{
	name="tiaohe",
	is_prohibited=function(self,from,to,card)
		if to:hasSkill("tiaohe") and from:distanceTo(to)>1 then
			return card:isKindOf("Slash")
		end
	end,
}
	
tiaohetarget=sgs.CreateTargetModSkill{
	name="#tiaohetarget",
	pattern="TrickCard",
	distance_limit_func=function(self,from,card)
		if from:hasSkill("tiaohe") then
			return 1000
		end
	end,
}	
	
TCA05:addSkill(huixiang)
TCA05:addSkill(zaoyin)
TCA05:addSkill(tiaohe)
TCA05:addSkill(tiaohetarget)
TCA05:addSkill("lianxie")

sgs.LoadTranslationTable{
	["TCA05"]="天宮かがみ",
	["#TCA05"]="天宮家の黒",
	["~TCA05"]="かがみはここまでだ",
	["huixiang"]="回响",
	[":huixiang"]="其他角色使用非延时锦囊时，你可以弃置一张同颜色的基础或者装备牌，然后你获得该锦囊并使该锦囊无效。若不如此做，则其在其回合结束前，无法使用和打出任何锦囊牌\
	注：无懈可击的场合，你可以收回无懈可击，但是其依旧生效",
	["@huixiang"]="你可以弃置一张同颜色的基础或者装备牌获得%src的锦囊牌",
	["zaoyin"]="噪音",
	[":zaoyin"]="每当你使用一张非延时锦囊，在结算前，你可以令一名其他角色判定，若判定牌的颜色和该锦囊牌不同，则其受到你对其造成的1点火焰/雷电伤害，伤害类型由判定牌花色决定（红色：火焰；黑色：雷电），否则你摸1张牌",
	["tiaohe"]="调和",
	[":tiaohe"]="<b>锁定技</b>，你使用锦囊时没有距离限制。与你计算距离大于1的角色无法对你使用杀。",
	["@silent"]="静默",
	["designer:TCA05"]="Nutari",
	["illustrator:TCA05"]="てぃんくる",
}

--天宮はるか

TCA06=sgs.General(extension,"TCA06","god","3",false)

shijing=sgs.CreateTriggerSkill{
	name="shijing",
	events={sgs.DrawNCards},
	frequency=sgs.Skill_Compulsory,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local haruka=room:findPlayerBySkillName(self:objectName())
		if not haruka or player:objectName()==haruka:objectName() then return end
		local x=data:toInt()
		if player:getHp()<haruka:getHp() then 
			x=x+1
			data:setValue(x)
			local log=sgs.LogMessage()
			log.from=haruka
			log.to:append(player)
			log.type="#shijinga"
			room:sendLog(log)
		elseif player:getHp()>haruka:getHp() then
			x=x-1
			data:setValue(x)
			local log=sgs.LogMessage()
			log.from=haruka
			log.to:append(player)
			log.type="#shijingb"
			room:sendLog(log)
		end	
		return false
	end,
}

huanxing=sgs.CreateTriggerSkill{
	name="huanxing",
	events={sgs.Predamage,sgs.DamageForseen,sgs.CardsMoveOneTime,sgs.PreCardUsed},
	priority=4,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local damage=data:toDamage()
		if (event==sgs.Predamage or event==sgs.DamageForseen and (damage.transfer or damage.chain))and damage.from and damage.from:hasSkill(self:objectName()) then
			local victim=sgs.QVariant()
			victim:setValue(damage.to)
			if damage.to:isKongcheng() or not room:askForSkillInvoke(player,self:objectName(),victim) then return end
			if damage.to:getHandcardNum()==1 then
				room:askForDiscard(damage.to,self:objectName(),1,1)
			else
				room:askForDiscard(damage.to,self:objectName(),2,2)
			end
			return true
		end
		local haruka=room:findPlayerBySkillName(self:objectName())
		if not haruka then return end
		if event==sgs.PreCardUsed then
			local use=data:toCardUse()
			if (use.card:isKindOf("Peach") or use.card:isKindOf("Analeptic")) then
				local dying=false
				if use.from:hasFlag("dying") then dying=true end
				for _,p in sgs.qlist(use.to) do
					if p:hasFlag("dying") then dying=true end
				end	
				if dying then room:setPlayerFlag(use.from,"userecover") end
			end	
		end
		if event==sgs.CardsMoveOneTime then
			local move=data:toMoveOneTime()
			if move.from and move.from:objectName()==player:objectName() and move.from_places:contains(sgs.Player_PlaceHand) and player:isKongcheng() then
				if player:hasFlag("userecover") then 
					room:setPlayerFlag(player,"-userecover") 
					room:setPlayerFlag(player,"huanxinglag") 
					return
				end
				local victim=sgs.QVariant()
				victim:setValue(player)
				if player:objectName()==haruka:objectName() or not room:askForSkillInvoke(haruka,self:objectName(),victim) then return end
				local damage=sgs.DamageStruct()
				damage.damage=1
				damage.from=nil
				damage.to=player
				damage.nature=sgs.DamageStruct_Thunder
				room:damage(damage)
			end
		end
	end
}

huanxinglag=sgs.CreateTriggerSkill{
	name="#huanxinglag",
	priority=-1,
	events=sgs.AskForPeachesDone,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local haruka=room:findPlayerBySkillName("huanxing")
		if not haruka then return end		
		for _,p in sgs.qlist(room:getAllPlayers()) do
			if p:hasFlag("userecover") then room:setPlayerFlag(p,"-userecover") end
			if p:hasFlag("huanxinglag") then
				room:setPlayerFlag(p,"-huanxinglag")
				local victim=sgs.QVariant()
				victim:setValue(p)
				if p:objectName()==haruka:objectName() or not room:askForSkillInvoke(haruka,"huanxing",victim) then return end
				local damage=sgs.DamageStruct()
				damage.damage=1
				damage.from=nil
				damage.to=p
				damage.nature=sgs.DamageStruct_Thunder
				room:damage(damage)
			end
		end
	end
}

luanxu_distance=sgs.CreateDistanceSkill{
	name="#luanxu_distance",
	correct_func=function(self,from,to)
		if from:hasSkill("luanxu") and from:getHp()<to:getHp() then
			return from:getHp()-to:getHp()
		elseif to:hasSkill("luanxu") and to:getHp()<from:getHp() then
			return from:getHp()-to:getHp()
		end
	end
}

luanxu=sgs.CreateTriggerSkill{
	name="luanxu",
	events={sgs.EventPhaseChanging},
	frequency=sgs.Skill_Compulsory,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local haruka=room:findPlayerBySkillName(self:objectName())
		if not haruka then return end
		local change=data:toPhaseChange()
		if change.to==sgs.Player_Finish and player:getHp()>haruka:getHp() and player:getHandcardNum()>haruka:getHandcardNum() and haruka:distanceTo(player)<=1 then
			haruka:gainMark("@time")
		end
		if change.to==sgs.Player_NotActive and haruka:getMark("@time")>0 then
			haruka:loseMark("@time")
			haruka:gainAnExtraTurn()
		end
	end,
}

TCA06:addSkill(shijing)
TCA06:addSkill(huanxing)
TCA06:addSkill(huanxinglag)
TCA06:addSkill(luanxu_distance)
TCA06:addSkill(luanxu)
TCA06:addSkill("lianxie")

sgs.LoadTranslationTable{
	["TCA06"]="天宮はるか",
	["#TCA06"]="天宮家の赤",
	["~TCA06"]="はるかもだめです",
	["shijing"]="时境",
	[":shijing"]="<b>锁定技</b>，任何其他角色在摸牌阶段摸牌时，若其体力小于你，则其多摸1张牌；若其体力多于你，则其少摸一张牌",
	["#shijinga"]="%from的【时境】触发，%to多摸了一张牌",
	["#shijingb"]="%from的【时境】触发，%to少摸了一张牌",
	["huanxing"]="缓刑",
	[":huanxing"]="你对有手牌的目标造成伤害前，你可以防止该伤害，改为令目标弃置2张手牌（不足则全弃）。你在场时，若其他角色失去最后一张手牌后，你可以令其受到没有来源的1点雷电伤害\
	注：若使用牌之后空城，则在其牌效果完结后才能判定缓刑（防止程序BUG）",
	["luanxu"]="乱序",
	[":luanxu"]="<b>锁定技</b>，任何你距离1以内的角色回合结束时，若其手牌数和体力均高于你，你立刻开始一个额外的回合。你与其他角色计算距离时，若其体力高于你，在你与其计算距离时-x，其他角色与你计算距离时，若其体力高于你，则其与你计算距离时+x，x为你与其体力的差值。",
	["@time"]="时间",
	["designer:TCA06"]="Nutari",
	["illustrator:TCA06"]="てぃんくる",
}

--☆神楽縁

TCA07=sgs.General(extension,"TCA07","god","3",false,true)

wanbei_max=sgs.CreateMaxCardsSkill{
	name="#wanbei_max",
	extra_func=function(self,player)
		local x=0
		if player:hasSkill("wanbei") then
			for _,p in sgs.qlist(player:getSiblings()) do
				x=x+p:getHandcardNum()
			end
		end
		return x
	end,
}

wanbei=sgs.CreateTriggerSkill{
	name="wanbei",
	events={sgs.CardDrawing,sgs.CardsMoveOneTime},
	frequency=sgs.Skill_Frequent,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local yukari=room:findPlayerBySkillName(self:objectName())
		if not yukari then return end
		if event==sgs.CardDrawing then
			if player:objectName()~=yukari:objectName() then
				room:setPlayerFlag(yukari,"wanbei")
			end
		else
			if yukari:hasFlag("wanbei") then
				room:setPlayerFlag(yukari,"-wanbei")
				if  room:askForSkillInvoke(yukari,self:objectName()) then yukari:drawCards(1) end
			end
		end
	end
}

saochu=sgs.CreateTriggerSkill{
	name="saochu",
	events={sgs.CardsMoving},
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()		
		local yukari=room:findPlayerBySkillName(self:objectName())
		if not yukari then return end
		local move=data:toMoveOneTime()
		if move.to_place==sgs.Player_PlaceHand and move.to:objectName()==player:objectName() and player:objectName()~=yukari:objectName() then
			for _,id in sgs.qlist(move.card_ids) do
				local card=sgs.Sanguosha:getCard(id)
				room:showCard(player,id,yukari)
				if room:askForCard(yukari,".|"..card:getSuitString().."|.|.|.","@saochu:"..player:objectName(),data,sgs.Card_MethodDiscard,player) then
					room:moveCardTo(card,yukari,sgs.Player_PlaceHand,true)
				end
			end
		end		
	end,
}

mizong_card=sgs.CreateSkillCard{
	name="mizong_card",
	will_throw=true,
	target_fixed=false,
	filter=function(self,targets,to_select)
		return to_select:hasFlag("mizongable") and #targets==0
	end,
	on_use=function(self,room,source,targets)
		local value=sgs.QVariant()
		value:setValue(targets[1])
		room:setTag("mizongtarget",value)
	end,
}

mizong_vs=sgs.CreateViewAsSkill{
	name="mizong",
	n=1,
	view_filter=function()
		return true
	end,
	view_as=function(self,cards)
		if #cards==1 then
			local acard=mizong_card:clone()
			acard:addSubcard(cards[1]:getId())
			acard:setSkillName("mizong")
			return acard
		end
	end,
	enabled_at_play=function()
		return false
	end,
}

mizong=sgs.CreateTriggerSkill{
	name="mizong",
	events=sgs.TargetConfirming,
	view_as_skill=mizong_vs,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local yukari=room:findPlayerBySkillName(self:objectName())
		if not yukari then return end
		local use=data:toCardUse()
		if not (use.card:isKindOf("Slash") or use.card:isKindOf("Duel")) or use.from:objectName()==yukari:objectName() then return end
		for _,p in sgs.qlist(room:getAllPlayers()) do
			if not use.from:isProhibited(p,use.card) then room:setPlayerFlag(p,"mizongable") end
		end
		if room:askForUseCard(yukari,"@@mizong","@mizong:"..use.from:objectName()..":"..player:objectName()..":"..use.card:objectName()) then
			local target=room:getTag("mizongtarget"):toPlayer()
			room:removeTag("mizongtarget")
			use.to:append(target)
			use.to:removeOne(player)
			data:setValue(use)
		end
		for _,p in sgs.qlist(room:getAllPlayers()) do
			room:setPlayerFlag(p,"-mizongable")
		end
		return false
	end,
}

TCA07:addSkill(wanbei_max)
TCA07:addSkill(wanbei)
TCA07:addSkill(saochu)
TCA07:addSkill(mizong)
TCA07:addSkill("lianxie")

sgs.LoadTranslationTable{
	["TCA07"]="☆神楽縁",
	["#TCA07"]="さくらのメイド長",
	["~TCA07"]="さくらさま、あたしもご奉仕しません",
	["wanbei"]="完备",
	[":wanbei"]="其他角色从牌堆摸牌结束时，你可以摸1张牌。你的手牌上限始终+x，x为场上其他角色的手牌数之和",
	["saochu"]="扫除",
	[":saochu"]="除你以外的角色在除从牌堆摸牌外每获得一张手牌，其向你展示这张牌。然后你可以弃置1张同花色的牌获得这张牌",
	["@saochu"]="你可以弃置1张同花色的牌获得%src刚刚获得的牌",
	["mizong_card"]="迷踪",
	["mizong"]="迷踪",
	[":mizong"]="除你以外的角色在使用杀和决斗时，在其指定目标后，你可以弃置一张牌，将目标转移给一个合理的角色（无视距离）\
	注：可以指定使用者本人",
	["@mizong"]="你可以弃置一张牌（包括装备）转移%src对%dest使用的%arg的目标",
	["~mizong"]="选择1张牌->选择一名角色->点击确定",
	["designer:TCA07"]="Nutari",
	["illustrator:TCA07"]="てぃんくる",
}

--☆天宮ゆめみ

TCA08=sgs.General(extension,"TCA08","god","3",false,true)

tianyun=sgs.CreateTriggerSkill{
	name="tianyun",
	events={sgs.StartJudge,sgs.DamageForseen},
	priority=1,
	frequency=sgs.Skill_NotFrequent,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.StartJudge then
			local judge=data:toJudge()
			if judge.who:hasSkill(self:objectName()) then
				judge.pattern=sgs.QRegExp("(.*):(.*):(.*)")
				judge.good=true
				data:setValue(judge)
			else
				local yumemi=room:findPlayerBySkillName(self:objectName())
				if yumemi and room:askForSkillInvoke(yumemi,self:objectName(),data) then
					local choice=room:askForChoice(yumemi,self:objectName(),"good+bad")
					judge.pattern=sgs.QRegExp("(.*):(.*):(.*)")
					local log=sgs.LogMessage()
					log.from=yumemi
					log.to:append(judge.who)
					log.arg=judge.reason
					if choice=="good" then
						log.type="#tianyung"
						room:sendLog(log)
						judge.good=true
					else
						log.type="#tianyunb"
						room:sendLog(log)
						judge.good=false
					end
					data:setValue(judge)
				end
			end
			return false
		else
			local damage=data:toDamage()
			if not damage.from and damage.to:hasSkill(self:objectName()) then
				local log=sgs.LogMessage()
				log.from=player
				log.type="#tianyun"
				room:sendLog(log)
				return true
			end
		end
	end
}

minglun_card=sgs.CreateSkillCard{
	name="minglun_card",
	will_throw=false,
	target_fixed=false,
	filter=function(self,targets,to_select)
		return #targets==0 and to_select:objectName()~=sgs.Self:objectName()
	end,
	on_use=function(self,room,source,targets)
		local good
		if targets[1]:isKongcheng() then
			good=true
			room:throwCard(self,source)
		elseif source:pindian(targets[1],"minglun",sgs.Sanguosha:getCard(self:getEffectiveId())) then
			good=true
		else
			good=false
		end
		if good then
			targets[1]:gainMark("@wheel")
		end			
	end,
}

minglun_vs=sgs.CreateViewAsSkill{
	name="minglun",
	n=1,
	view_filter=function(self,selected,to_select)
		return not to_select:isEquipped()
	end,
	view_as=function(self,cards)
		if #cards==1 then
			local acard=minglun_card:clone()
			acard:addSubcard(cards[1]:getId())
			return acard
		end
	end,
	enabled_at_play=function()
		return false
	end,
}

minglunpindian=sgs.CreateTriggerSkill{
	name="#minglunpindian",
	events=sgs.Pindian,
	priority=-1,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local pindian=data:toPindian()
		if pindian.reason=="minglun" and pindian.from:hasSkill("minglun") then
			if pindian.from_card:getNumber()<=pindian.to_card:getNumber() then
				room:obtainCard(pindian.to,pindian.from_card:getEffectiveId())
				room:obtainCard(pindian.to,pindian.to_card:getEffectiveId())
			end
		end
	end
}

minglun=sgs.CreateTriggerSkill{
	name="minglun",
	view_as_skill=minglun_vs,
	events={sgs.BuryVictim,sgs.CardsMoveOneTime,sgs.Dying,sgs.EventPhaseChanging,sgs.PreHpRecover,sgs.DamageForseen},
	priority=2,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local yumemi=room:findPlayerBySkillName(self:objectName())		
		local target
		for _,p in sgs.qlist(room:getAllPlayers()) do
			if p:getMark("@wheel")>0 then target=p break end
		end
		if player:hasSkill(self:objectName()) and event==sgs.BuryVictim then
			if target then target:loseMark("@wheel") end
		end
		if player:hasSkill(self:objectName()) and event==sgs.EventPhaseChanging and data:toPhaseChange().to==sgs.Player_Play and not player:isSkipped(sgs.Player_Play) and not target then
			room:askForUseCard(player,"@@minglun","@minglun")
		end
		if event==sgs.EventPhaseChanging and yumemi:getMark("wheel")>0 then
			yumemi:drawCards(yumemi:getMark("wheel"))
			yumemi:setMark("wheel",0)
		end	
		if event==sgs.Dying and data:toDying().who:getMark("@wheel")>0 then
			data:toDying().who:loseMark("@wheel")
		end
		if event==sgs.CardsMoveOneTime then
			local move=data:toMoveOneTime()
			local x=move.card_ids:length()
			if x>=1 then
				if move.to_place==sgs.Player_PlaceHand and move.to and move.to:getMark("@wheel")>0 and move.to:objectName()==player:objectName() then
					local log=sgs.LogMessage()
					log.from=yumemi
					log.arg=x
					log.type="#minglund"
					room:sendLog(log)
					if yumemi:getPhase()==sgs.Player_Discard then yumemi:setMark("wheel",yumemi:getMark("wheel")+x) else yumemi:drawCards(x) end
				end
				if (not move.to or move.to:objectName()~=move.from:objectName()) and move.from and move.from:objectName()==player:objectName() and move.from:hasSkill(self:objectName()) and (move.from_places:contains(sgs.Player_PlaceHand)or move.from_places:contains(sgs.Player_PlaceEquip)) and target and not target:isNude() then
					local log=sgs.LogMessage()
					log.from=yumemi
					log.to:append(target)
					log.arg=math.min(x,target:getCards("he"):length())
					log.type="#mingluns"
					room:sendLog(log)
					if x>=target:getCards("he"):length() then
						target:throwAllHandCardsAndEquips()
					else
						room:askForDiscard(target,self:objectName(),x,x,false,true)
					end
				end
			end
		end
		if event==sgs.PreHpRecover and player:getMark("@wheel")>0 then
			local recover=data:toRecover()
			local log=sgs.LogMessage()
			log.from=yumemi
			log.to:append(player)
			log.type="#minglunr"
			room:sendLog(log)
			room:recover(yumemi,recover)
			return true
		end
		if event==sgs.DamageForseen and player:hasSkill(self:objectName()) and target then
			local damage=data:toDamage()
			damage.to=target
			damage.transfer=true
			local log=sgs.LogMessage()
			log.from=yumemi
			log.to:append(target)
			log.type="#minglunx"
			room:sendLog(log)
			room:damage(damage)
			return true
		end
	end,
}

hunhuo=sgs.CreateTriggerSkill{
	name="hunhuo",
	events={sgs.GameOverJudge,sgs.BuryVictim},
	frequency=sgs.Skill_Wake,
	priority=4,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.GameOverJudge and player:hasSkill(self:objectName()) and player:getMark("hunhuo")==0 then
			room:revivePlayer(player)
			player:gainMark("hunhuo")
			player:gainMark("@waked")
			room:setPlayerProperty(player,"maxhp",sgs.QVariant(1))
			room:setPlayerProperty(player,"hp",sgs.QVariant(1))
			player:throwAllHandCardsAndEquips()
			room:acquireSkill(player,"tcfengyin")
			room:acquireSkill(player,"shengnv")
			if player:isChained() then room:setPlayerProperty(player, "chained", sgs.QVariant(false)) end
			if not player:faceUp() then player:turnOver() end
			player:drawCards(4)
			local damage=sgs.DamageStruct()
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				damage.nature=sgs.DamageStruct_Fire
				damage.damage=1
				damage.to=p
				room:damage(damage)
				p:throwAllHandCardsAndEquips()
			end
			room:askForUseCard(player,"@@minglun","@minglun")
			return true
		end
		if event==sgs.BuryVictim and player:isAlive() and player:hasSkill(self:objectName()) then
			return true
		end	
	end,
}

TCA08:addSkill(tianyun)
TCA08:addSkill(minglun)
TCA08:addSkill(minglunpindian)
TCA08:addSkill(hunhuo)

sgs.LoadTranslationTable{
	["TCA08"]="☆天宮ゆめみ",
	["#TCA08"]="無限可能の少女",
	["~TCA08"]="さくらさん、みずきさん、あたしもおわりだ",
	["tianyun"]="天运",
	[":tianyun"]="你的判定始终为好。其他角色判定时，无论判定牌时什么，你可以令判定结果为好或者不好。你不会受到没有来源的伤害",
	["#tianyun"]="%from的【天运】触发，伤害无效",
	["good"]="好",
	["bad"]="坏",
	["#tianyung"]="%from发动了【天运】，%to的%arg判定结果确定为好",
	["#tianyunb"]="%from发动了【天运】，%to的%arg判定结果确定为坏",
	["minglun_card"]="命轮",
	["minglun"]="命轮",
	[":minglun"]="你出牌阶段开始前，你可以与一名其他角色拼点（若目标没有牌算你赢），若你赢，则获得以下效果直到目标濒死：你即将受到的伤害由目标承受，目标即将获得的体力恢复由你承受，目标每获得一次牌，你摸同样数量的牌，你每失去一次牌，目标弃置同样数量的牌（不足全弃，没有不弃）；若你没赢，对方获得双方的拼点牌。当有人承受命轮效果时你不能发动此拼点。",
	["@minglun"]="你可以发动命轮",
	["~minglun"]="选择一张手牌->选择一名其他角色->点击确定",
	["#minglund"]="%from的【命轮】触发",
	["#mingluns"]="%from的【命轮】触发",
	["#minglunr"]="%from的【命轮】触发，%to的恢复效果转移至%from",
	["#minglunx"]="%from的【命轮】触发，%from即将受到的伤害转移至%to",
	["@wheel"]="命轮",
	["hunhuo"]="魂火",
	[":hunhuo"]="<b>觉醒技</b>，当你濒死求桃后依旧濒死时，你将体力和上限调整至1点，弃置所有手牌和装备并摸4张牌，重置并翻至正面朝上，然后获得【封印】【圣女】，然后所有其他角色受到1点没有来源的火焰伤害并弃置所有手牌与装备，然后你可以立刻发动一次命轮的拼点。",
	["designer:TCA08"]="Nutari",
	["illustrator:TCA08"]="てぃんくる",
}


--天宮ふたば＆天宮ななみ

TCA09=sgs.General(extension,"TCA09","god","3",false)

chiyan=sgs.CreateFilterSkill{
	name="chiyan",
	view_filter=function(self,to_select)
		return to_select:isKindOf("Slash") and not to_select:isKindOf("NatureSlash")
	end,
	view_as=function(self,card)
		local slash=sgs.Sanguosha:cloneCard("fire_slash",card:getSuit(),card:getNumber())
		local acard=sgs.Sanguosha:getWrappedCard(card:getId())
		acard:takeOver(slash)
		acard:setSkillName(self:objectName())
		return acard
	end,
}

chiyan_trigger=sgs.CreateTriggerSkill{
	name="#chiyan_trigger",
	events={sgs.Predamage,sgs.DamageInflicted,sgs.DamageForseen},
	frequency=sgs.Skill_Compulsory,
	priority=2.5,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local damage=data:toDamage()
		if event==sgs.Predamage or event==sgs.DamageForseen then
			if damage.nature==sgs.DamageStruct_Normal and damage.from:hasSkill("chiyan") then
				damage.nature=sgs.DamageStruct_Fire
				data:setValue(damage)
				room:broadcastSkillInvoke("chiyan")
				local log=sgs.LogMessage()
				log.from=damage.from
				log.type="#chiyan"
				room:sendLog(log)
			end
			return false
		end
		if event==sgs.DamageInflicted and damage.nature==sgs.DamageStruct_Fire and player:hasSkill("chiyan") then
			room:broadcastSkillInvoke("chiyan")
			local log=sgs.LogMessage()
			log.from=player
			log.type="#chiyanx"
			room:sendLog(log)
			local x=math.min(damage.damage,player:getLostHp())
			local y=damage.damage-x
			if x>0 then
				local recover=sgs.RecoverStruct()
				recover.recover=x
				recover.who=damage.from
				room:recover(player,recover)
			end
			if y>0 then
				player:drawCards(y)
			end
			return true
		end
	end,
}

yanliu_card=sgs.CreateSkillCard{
	name="yanliu_card",
	will_throw=true,
	handling_method=sgs.Card_MethodDiscard,
	filter=function(self,targets,to_select)
		return to_select:hasFlag("yanliuable") and not to_select:hasFlag("yanliutarget")
	end,
	feasible=function(self,targets)
		return #targets>0 or (sgs.Self:hasFlag("candiscardequip"))
	end,
	on_use=function(self,room,source,targets)
		if #targets==0 then
			local target
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:hasFlag("yanliutarget") then
					target=p
					break
				end
			end
			local move=sgs.CardsMoveStruct()
			local reason=sgs.CardMoveReason()
			reason.m_reason=sgs.CardMoveReason_S_REASON_DISMANTLE
			reason.m_skillName="yanliu"
			reason.m_player=source:objectName()
			move.reason=reason
			for _,card in sgs.qlist(target:getEquips()) do
				move.card_ids:append(card:getEffectiveId())
			end
			move.from=target
			move.from_place=sgs.Player_PlaceEquip
			move.to_place=sgs.Player_DiscardPile
			room:moveCardsAtomic(move,true)
		else
			for i=1,#targets,1 do
				room:setPlayerFlag(targets[i],"yanliu")
			end
		end
	end,
}	
	

yanliu_vs=sgs.CreateViewAsSkill{
	name="yanliu",
	n=1,
	view_filter=function(self,selected,to_select)
		return to_select:isRed()
	end,
	view_as=function(self,cards)
		if #cards>0 then
			local acard=yanliu_card:clone()
			acard:addSubcard(cards[1]:getId())
			return acard
		end
	end,
	enabled_at_play=function()
		return false
	end,
}	

yanliu=sgs.CreateTriggerSkill{
	name="yanliu",
	events={sgs.Damaged,sgs.PreHpReduced},
	view_as_skill=yanliu_vs,
	priority=-1,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local damage=data:toDamage()
		local futako=room:findPlayerBySkillName("yanliu")
		if event==sgs.PreHpReduced and damage.nature==sgs.DamageStruct_Fire and futako and not (futako:hasFlag("yanliusource") and damage.to:hasFlag("yanliu")) and not futako:isNude() then
			local usable=false
			for _,p in sgs.qlist(room:getOtherPlayers(damage.to)) do
				if damage.to:distanceTo(p)<=1 then
					room:setPlayerFlag(p,"yanliuable")
					usable=true
				end
			end
			if not damage.to:getEquips():isEmpty() then
				room:setPlayerFlag(futako,"candiscardequip")
				room:setPlayerFlag(damage.to,"yanliutarget")
				usable=true
			end
			if usable then room:askForUseCard(futako,"@@yanliu","@yanliu:"..damage.to:objectName()) end
			room:setPlayerFlag(futako,"-candiscardequip")
			room:setPlayerFlag(damage.to,"-yanliutarget")
			for _,p in sgs.qlist(room:getOtherPlayers(damage.to)) do
				room:setPlayerFlag(p,"-yanliuable")
			end
		end
		if event==sgs.Damaged and futako and not futako:hasFlag("yanliusource") then
			room:setPlayerFlag(futako,"yanliusource")
			local x=damage.damage
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:hasFlag("yanliu") then
					local exdamage=damage
					exdamage.damage=x
					exdamage.to=p
					exdamage.chain=true
					exdamage.transfer=true
					exdamage.from=futako
					local chain=damage.to:isChained()
					local log=sgs.LogMessage()
					log.from=futako
					log.to:append(exdamage.to)
					log.type="#yanliu"
					room:sendLog(log)
					room:damage(exdamage)
					if chain then room:setPlayerProperty(damage.to,"chained",sgs.QVariant(true)) end
					room:setPlayerFlag(p,"-yanliu")
				end
			end
			room:setPlayerFlag(futako,"-yanliusource")
		end
	end,
}

liushui_vs=sgs.CreateViewAsSkill{
	name="liushui",
	n=1,
	view_filter=function(self,selected,to_select)
		return to_select:isBlack()
	end,
	view_as=function(self,cards)
		if #cards==1 then
			local acard=sgs.Sanguosha:cloneCard("iron_chain",cards[1]:getSuit(),cards[1]:getNumber())
			acard:addSubcard(cards[1]:getId())
			acard:setSkillName("liushui")
			return acard
		end
	end,
}

liushui=sgs.CreateTriggerSkill{
	name="liushui",
	events={sgs.CardsMoveOneTime,sgs.EventPhaseStart},
	view_as_skill=liushui_vs,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.CardsMoveOneTime then
			local move=data:toMoveOneTime()
			if not move.from or move.reason.m_skillName=="shijie" or not player:hasSkill("liushui") then return end
			if move.from:objectName()==player:objectName() and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) and player:objectName()~=room:getCurrent():objectName() and (not move.to or move.to:objectName()~=player:objectName()) then
				local log=sgs.LogMessage()
				log.from=player
				log.type="#liushui"
				room:sendLog(log)
				player:drawCards(move.card_ids:length())
			end
		elseif player:getPhase()==sgs.Player_Judge and player:hasSkill("liushui") then
			local cards=player:getJudgingArea()
			if cards:length()>0 then
				local log=sgs.LogMessage()
				log.from=player
				log.type="#liushuix"
				room:sendLog(log)
				for _,cd in sgs.qlist(cards) do
					player:obtainCard(cd)
				end
			end
		end
	end,
}

TCA09:addSkill(chiyan)
TCA09:addSkill(chiyan_trigger)
TCA09:addSkill(liushui)
TCA09:addSkill(yanliu)

sgs.LoadTranslationTable{
	["TCA09"]="ふたば＆ななみ",
	["#TCA09"]="天宮家の炎と水のふたこ",
	["~TCA09"]="ふたりでも足りないか",
	["chiyan"]="炽焰",
	[":chiyan"]="<b>锁定技</b>，你的无属性杀均视为火杀。你即将造成的无属性伤害均视为火焰伤害。你即将受到的每1点火焰伤害会恢复你1点体力（溢出的体力恢复每1点你摸1张牌）然后你防止该伤害",
	["#chiyan"]="%from的【炽焰】触发，即将造成的伤害视为火焰伤害",
	["#chiyans"]="%from的【炽焰】触发，%to即将受到的火焰伤害来源视为%from",
	["#chiyanx"]="%from的【炽焰】触发，防止了该次伤害",
	["yanliu_card"]="炎流",
	["yanliu"]="炎流",
	[":yanliu"]="任何角色受到火焰伤害时，你可以弃置一张红色牌，然后选择1项：弃置其装备区的所有牌；或对其距离1以内任意名其他角色造成同样的伤害，扩散的伤害不能再次触发此效果，也不会触发连环",
	["@yanliu"]="你可以弃置1张红色牌对%src发动炎流",
	["~yanliu"]="选择若干张红色牌->选择若干的角色（或者不选）->点击确定",
	["#yanliu"]="%from的【炎流】被触发，伤害扩散至%to",
	["expanddamage"]="延展伤害",
	["discardequips"]="弃置装备",
	["liushui"]="流水",
	[":liushui"]="你可以把一张黑色牌当作【铁索连环】来使用或者重铸。你回合外每失去1张牌立刻摸1张牌。你判定阶段的开始收回判定区所有的牌",
	["#liushui"]="%from的【流水】触发",
	["#liushuix"]="%from的【流水】触发，收回了判定区的牌。",
	["designer:TCA09"]="Nutari",
	["illustrator:TCA09"]="てぃんくる",
}

--月見とばり

TCA10=sgs.General(extension,"TCA10","god","3",false)

fengwutarget=sgs.CreateTargetModSkill{
	name="#fengwutarget",
	distance_limit_func=function(self,from,card)
		if from:hasSkill("fengwu") and not from:getWeapon() then
			return from:getHandcardNum()
		end
	end,
}

fengwu_card=sgs.CreateSkillCard{
	name="fengwu_card",
	will_throw=false,
	target_fixed=false,
	filter=function(self,targets,to_select)
		return #targets==0 and to_select:hasFlag("fengwuable")
	end,
	on_use=function(self,room,source,targets)
		for _,p in sgs.qlist(room:getAllPlayers()) do
			room:setPlayerFlag(p,"-fengwuable")
		end	
		local card=room:getTag("fengwucard"):toCard()
		local use=sgs.CardUseStruct()
		use.from=source
		use.to:append(targets[1])
		use.card=card
		room:useCard(use,false)
	end,
}

fengwu_vs=sgs.CreateViewAsSkill{
	name="fengwu",
	n=0,
	view_as=function()
		return fengwu_card:clone()
	end,
	enabled_at_play=function()
		return false
	end,
}

fengwu=sgs.CreateTriggerSkill{
	name="fengwu",
	view_as_skill=fengwu_vs,
	events={sgs.SlashMissed,sgs.CardFinished},
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.SlashMissed then
			local effect=data:toSlashEffect()
			local card=effect.slash
			room:setPlayerFlag(effect.to,"fengwuused")
			if not room:getTag("fengwucard"):toCard() then
				local value=sgs.QVariant()
				value:setValue(card)
				room:setTag("fengwucard",value)
			end
			local empty=true
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if player:canSlash(p,card) and not p:hasFlag("fengwuused") then
					room:setPlayerFlag(p,"fengwuable")
					empty=false
				end
			end
			if empty then return end
			room:askForUseCard(player,"@@fengwu","@fengwu")
		end
		if event==sgs.CardFinished then
			if room:getTag("fengwucard"):toCard() and room:getTag("fengwucard"):toCard():getEffectiveId()==data:toCardUse().card:getEffectiveId() then
				for _,p in sgs.qlist(room:getAllPlayers()) do
					room:setPlayerFlag(p,"-fengwuused")
					room:setPlayerFlag(p,"-fengwuable")
				end
				room:removeTag("fengwucard")
			end	
		end
	end,
}

xinyanpattern=""
xinyan_vs=sgs.CreateViewAsSkill{
	name="xinyan",
	n=1,
	view_filter=function(self,selected,to_select)
		if to_select:isEquipped() then return false end
		if xinyanpattern=="slash" then return to_select:isRed() end
		if xinyanpattern=="jink" then return to_select:isBlack() end
	end,
	view_as=function(self,cards)
		if #cards==1 then
			local acard=sgs.Sanguosha:cloneCard(xinyanpattern,cards[1]:getSuit(),cards[1]:getNumber())
			acard:addSubcard(cards[1]:getId())
			acard:setSkillName("xinyan")
			return acard
		end
	end,
	enabled_at_play=function()
		xinyanpattern="slash"
		return sgs.Self:canSlashWithoutCrossbow() or ((sgs.Self:getWeapon()) and (sgs.Self:getWeapon():getClassName()=="Crossbow"))
	end,
	enabled_at_response=function(self,player,pattern)
		if pattern=="jink" or pattern=="slash" then
			xinyanpattern=pattern
			return true
		end
	end,
}

xinyan=sgs.CreateTriggerSkill{
	name="xinyan",
	events={sgs.CardResponsed,sgs.CardUsed},
	view_as_skill=xinyan_vs,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.CardResponsed then
			local responsed=data:toResponsed()
			if responsed.m_card:isKindOf("Jink") or responsed.m_card:isKindOf("Slash") then
				local choice="draw"
				local victim=sgs.QVariant()
				victim:setValue(responsed.m_who)
				if not responsed.m_who:isNude() then choice=room:askForChoice(player,"xinyan","draw+discard",victim) end
				if choice=="draw" then
					player:drawCards(1)
				else
					local id=room:askForCardChosen(player,responsed.m_who,"he","xinyan")
					room:throwCard(id,responsed.who,player)
				end	
			end
		elseif event==sgs.CardUsed then
			local use=data:toCardUse()
			if use.card:isKindOf("Slash") then
				for _,p in sgs.qlist(use.to) do
					local choice="draw"
					local victim=sgs.QVariant()
					victim:setValue(p)
					if not p:isNude() then choice=room:askForChoice(player,"xinyan","draw+discard",victim) end
					if choice=="draw" then
						player:drawCards(1)
					else
						local id=room:askForCardChosen(player,p,"he","xinyan")
						room:throwCard(id,p,player)
					end	
				end
			end
		end
	end,
}

xuying=sgs.CreateTriggerSkill{
	name="xuying",
	events=sgs.CardEffected,
	priority=5,
	can_trigger=function()
		return true
	end,	
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local effect=data:toCardEffect()
		if effect.to:hasSkill(self:objectName()) and effect.card:isNDTrick() and effect.from:objectName()~=effect.to:objectName() and room:askForSkillInvoke(effect.to,self:objectName(),data) then
			local judge=sgs.JudgeStruct()
			judge.who=effect.to
			judge.good=true
			judge.pattern=sgs.QRegExp("(.*):("..effect.card:getSuitString().."):(.*)")
			judge.play_animation=true
			room:judge(judge)
			if judge:isGood() then
				local reward=true
				if (effect.card:isKindOf("Dismantlement") or effect.card:isKindOf("Snatch")) and effect.from:isAllNude() then reward=false 
				elseif effect.card:isKindOf("FireAttack") and effect.from:isKongcheng() then  reward=false 
				elseif effect.card:isKindOf("Collateral") and not effect.from:getWeapon() then  reward=false 
				end
				if reward then
					effect.to=effect.from
					effect.from=player
					data:setValue(effect)
					return false
				else
					return true
				end	
			else
				effect.to:obtainCard(judge.card)
			end	
		end
	end,
}
				
TCA10:addSkill(fengwutarget)
TCA10:addSkill(fengwu)
TCA10:addSkill(xinyan)
TCA10:addSkill(xuying)

sgs.LoadTranslationTable{
	["TCA10"]="月見とばり",
	["#TCA10"]="風の影",
	["~TCA10"]="風も死んじゃった",
	["fengwu_card"]="风舞",
	["fengwu"]="风舞",
	[":fengwu"]="当你没有装备武器时，你的攻击距离+x，x为你的手牌数。你的【杀】被躲闪后，你可以选择一名你射程内的其他角色，视为对其使用了这张【杀】。该效果同一张杀不能对同一个目标使用第二次。",
	["@fengwu"]="你可以发动风舞对另一个角色出杀",
	["~fengwu"]="选择一名其他角色->点击确定",
	["xinyan"]="心眼",
	[":xinyan"]="你可以把你红色的手牌当作杀，黑色手牌当作闪来打出或者使用。每当你使用或者打出一张【杀】或者【闪】，你可以选择以下两项中的一项：弃置目标一张牌；或者摸一张牌",
	["xuying"]="虚影",
	[":xuying"]="其他角色非延时锦囊对你生效前，你可以做一次判定，若判定牌花色与该锦囊牌花色相同，则该锦囊对你无效，并在合理的情况下视为你对来源发动了锦囊效果；否则你收回判定牌",
	["designer:TCA10"]="Nutari",
	["illustrator:TCA10"]="てぃんくる",	
}

--夢アリス

TCA11=sgs.General(extension,"TCA11","god","1",false,true)

mengjing=sgs.CreateTriggerSkill{
	name="mengjing",
	events={sgs.Dying,sgs.MaxHpChanged,sgs.PreHpLost,sgs.GameStart,sgs.DamageForseen,sgs.Predamage,sgs.CardEffected},
	priority=4.5,
	frequency=sgs.Skill_Compulsory,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.GameStart and player:hasSkill(self:objectName()) then
			player:gainMark("@dream",3)
		end
		if event==sgs.Dying and data:toDying().who:getMark("@dream")>0 and data:toDying().who:getHp()<1 then
			data:toDying().who:loseMark("@dream")
			data:toDying().who:gainMark("@dreamland")
			local recover=sgs.RecoverStruct()
			recover.who=data:toDying().who
			recover.recover=data:toDying().who:getMaxHp()-data:toDying().who:getHp()
			room:recover(data:toDying().who,recover)
			--room:setPlayerProperty(player,"hp",sgs.QVariant(player:getMaxHp()))
			return true
		end
		if event==sgs.MaxHpChanged and player:GetMaxHp()<1 and player:getMark("@dream")>0 then
			player:loseMark("@dream")
			player:gainMark("@dreamland")			
			room:setPlayerProperty(player,"maxhp",sgs.QVariant(1))
			local recover=sgs.RecoverStruct()
			recover.who=player
			recover.recover=player:getMaxHp()-player:getHp()
			room:recover(player,recover)
		--	room:setPlayerProperty(player,"hp",sgs.QVariant(player:getMaxHp()))
			return true
		end
		if event==sgs.Predamage or event==sgs.DamageForseen then
			local damage=data:toDamage()
			if damage.to:getMark("@dreamland")>0 or damage.from:getMark("@dreamland")>0 then return true end
		end
		if event==sgs.CardEffected and player:getMark("@dreamland")>0 then
			local effect=data:toCardEffect()
			if effect.card:isKindOf("BasicCard") or effect.card:isKindOf("TrickCard") then return true end
		end
		if event==sgs.PreHpLost and player:getMark("@dreamland")>0 then return true end
	end,
}

manbu=sgs.CreateTriggerSkill{
	name="manbu",
	events=sgs.CardsMoveOneTime,
	frequency=sgs.Skill_Frequent,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local move=data:toMoveOneTime()
		if move.from:objectName()==player:objectName() and player:getMark("@dreamland")>0 and (move.from_places:contains(sgs.Player_PlaceEquip) or move.from_places:contains(sgs.Player_PlaceHand)) and (not move.to or move.to:objectName()~=player:objectName()) then
			if room:askForSkillInvoke(player,self:objectName(),data) then
				local target=room:askForPlayerChosen(player,room:getAllPlayers(),self:objectName())
				room:loseHp(target,player:getMaxHp())
			end
		end
	end,
}

mengxing=sgs.CreateTriggerSkill{
	name="mengxing",
	events=sgs.BuryVictim,
	frequency=sgs.Skill_Compulsory,
	priority=1,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local arisu
		for _,p in sgs.qlist(room:getAllPlayers()) do
			if p:getMark("@dreamland")>0 then arisu=p break end
		end
		if not arisu then return end
		if player:objectName()~=arisu:objectName() then
			room:setPlayerProperty(arisu,"maxhp",sgs.QVariant(arisu:getMaxHp()+1))
			local recover=sgs.RecoverStruct()
			recover.who=arisu
			recover.recover=arisu:getMaxHp()-arisu:getHp()
			room:recover(arisu,recover)

			room:setPlayerFlag(arisu,"-dying")
			local skills={}
			local skilllist=""
			for _,skill in sgs.qlist(player:getVisibleSkillList()) do
				if not arisu:hasSkill(skill:objectName()) and not(skill:isLordSkill() or skill:getFrequency() == sgs.Skill_Limited
				or skill:getFrequency() == sgs.Skill_Wake) then
				table.insert(skills,skill:objectName())
				end
			end
			for var,sk in ipairs(skills) do
				if var==#skills then skilllist=skilllist..sk break end
				skilllist=skilllist..sk.."+"
			end
			local skill_name= room:askForChoice(arisu,"mengxing",skilllist)
			local skillx=sgs.Sanguosha:getSkill(skill_name)
			room:acquireSkill(arisu,skill_name)
			for _,skill in sgs.qlist(player:getVisibleSkillList()) do
				room:attachSkillToPlayer(player,skill:objectName())
			end 			
			arisu:loseMark("@dreamland")
			for _,p in sgs.qlist(room:getOtherPlayers(arisu)) do
				if not p:isNude() then
					local card_id = room:askForCardChosen(arisu, p, "he", "mengxing")
					room:moveCardTo(sgs.Sanguosha:getCard(card_id), arisu, sgs.Player_PlaceHand,false)
				end
			end
		end
	end,
}

TCA11:addSkill(mengjing)
TCA11:addSkill(manbu)
TCA11:addSkill(mengxing)

sgs.LoadTranslationTable{
	["TCA11"]="夢アリス",
	["#TCA11"]="夢の国のアリス",
	["~TCA11"]="夢は終わりだ",
	["mengjing"]="梦境",
	[":mengjing"]="<b>锁定技</b>，游戏开始时你获得3枚梦标记。每当你濒死或者体力上限不足1时，你移除1枚梦标记并将体力恢复至上限（若体力上限不足1则恢复至1点）。并使你进入“梦境”，处于“梦境”中时，你防止所有造成和受到的伤害，防止基础和锦囊牌对你的效果，防止你体力流失。",
	["@dream"]="梦",
	["@dreamland"]="梦境",
	["manbu"]="漫步",
	[":manbu"]="当你处于“梦境”中时，每当你失去1次牌，可以令任意一名玩家失去x点体力，x为你体力上限。",
	["mengxing"]="梦醒",
	[":mengxing"]="<b>锁定技</b>，每当任意一名其他玩家死亡时，若你处于“梦境”，你增加1点体力上限并将体力恢复至上限，获得其一个武将技能（非限定技，主公技，觉醒技），移除“梦境”状态并获得其他角色各1张牌。",
	["designer:TCA11"]="Nutari",
	["illustrator:TCA11"]="てぃんくる",
}

TCA12=sgs.General(extension,"TCA12","god","3",false)

jiaoji=sgs.CreateTriggerSkill{
	name="jiaoji",
	events={sgs.CardEffected,sgs.CardUsed,sgs.EventPhaseChanging},
	can_trigger=function()
		return true
	end,	
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.CardEffected then
			local effect=data:toCardEffect()
			if not player:faceUp() and effect.card:isNDTrick() and player:hasSkill("jiaoji") then
				local log=sgs.LogMessage()
				log.type="#jiaoji"
				log.from=player
				log.arg=effect.card:objectName()
				room:sendLog(log)
				return true				
			end
		end
		local chihiro=room:findPlayerBySkillName(self:objectName())
		if event==sgs.CardUsed and chihiro then
			local use=data:toCardUse()
			if use.card:isNDTrick() and not use.card:isKindOf("Nullification") and chihiro:faceUp() and use.from:objectName()~=chihiro:objectName() and room:askForSkillInvoke(chihiro,self:objectName(),data) then
				chihiro:turnOver()
				chihiro:obtainCard(use.card)
				return true
			end
		end
		if event==sgs.EventPhaseChanging and data:toPhaseChange().to==sgs.Player_NotActive and not player:hasSkill(self:objectName()) and not chihiro:faceUp() then
			local basic=false
			for _,card in sgs.qlist(chihiro:getHandcards()) do
				if card:isKindOf("BasicCard") then basic=true break end
			end
			if not basic then return end
			local card=room:askForCard(chihiro,"BasicCard","@jiaoji:"..player:objectName(),data,sgs.Card_MethodNone,player)
			if card then
				room:moveCardTo(card,player,sgs.Player_PlaceHand,true)
				chihiro:turnOver()
			end	
		end	
	end,
}

dianxing=sgs.CreateTriggerSkill{
	name="dianxing",
	frequency=sgs.Skill_Compulsory,
	priority=5,
	events={sgs.Dying,sgs.CardsMoveOneTime,sgs.Predamage},
	can_trigger=function()
		return true
	end,	
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.Dying then
			if data:toDying().who:hasSkill(self:objectName()) and player:objectName()==data:toDying().who:objectName() then
				local log=sgs.LogMessage()
				log.from=data:toDying().who
				log.type="#dianxinga"
				room:sendLog(log)
				for _,p in sgs.qlist(room:getOtherPlayers(data:toDying().who)) do
					local card=room:askForCard(p,".|.|.|hand|red","@dianxing:"..data:toDying().who:objectName(),data,sgs.Card_MethodNone,data:toDying().who)
					if card then
						room:moveCardTo(card,data:toDying().who,sgs.Player_PlaceHand,false)
					else	
						local damage=sgs.DamageStruct()
						damage.to=p
						damage.nature=sgs.DamageStruct_Thunder
						damage.chain=true
						room:damage(damage)
					end	
				end
			elseif player:objectName()==data:toDying().who:objectName() and not player:hasSkill(self:objectName()) then
				local chihiro=room:findPlayerBySkillName("dianxing")
				if not chihiro then return end
				local log=sgs.LogMessage()
				log.from=chihiro
				log.type="#dianxingx"
				room:sendLog(log)
				chihiro:drawCards(1)
			end		
		end
		if event==sgs.CardsMoveOneTime then
			local move=data:toMoveOneTime()
			if move.from and move.from:objectName()==player:objectName() and move.from_places:contains(sgs.Player_PlaceHand) and player:isKongcheng() and player:hasSkill(self:objectName()) then
				local log=sgs.LogMessage()
				log.from=player
				log.type="#dianxingb"
				room:sendLog(log)
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					local card=room:askForCard(p,".|.|.|hand|red","@dianxing:"..player:objectName(),data,sgs.Card_MethodNone,player)
					if card then
						room:moveCardTo(card,player,sgs.Player_PlaceHand,false)
					else	
						local damage=sgs.DamageStruct()
						damage.to=p
						damage.nature=sgs.DamageStruct_Thunder
						damage.chain=true
						room:damage(damage)
					end
				end
			end	
		end
		if event==sgs.Predamage and player:hasSkill(self:objectName()) then
			local damage=data:toDamage()
			if damage.nature~=sgs.DamageStruct_Thunder then
				local log=sgs.LogMessage()
				log.from=player
				log.type="#dianxing"
				room:sendLog(log)
				damage.nature=sgs.DamageStruct_Thunder
				data:setValue(damage)
				return false
			end
		end
	end,
}

chaodao=sgs.CreateTriggerSkill{
	name="chaodao",
	frequency=sgs.Skill_Compulsory,
	events={sgs.PreHpReduced},
	priority=2,
	can_trigger=function()
		return true
	end,	
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.PreHpReduced then
			local damage=data:toDamage()
			if room:findPlayerBySkillName("chaodao") and damage.nature==sgs.DamageStruct_Thunder  and damage.to:isChained() then
				room:setPlayerFlag(damage.to,"chaodao")
			end
			if damage.to:hasSkill(self:objectName()) and (damage.chain or damage.transfer) then
				local log=sgs.LogMessage()
				log.from=damage.to
				log.type="#chaodao"
				room:sendLog(log)
				return true
			end
		end
	end,
}

chaodao_complete=sgs.CreateTriggerSkill{
	name="#chaodao_complete",
	priority=-1,
	events=sgs.DamageComplete,
	can_trigger=function()
		return true
	end,	
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local damage=data:toDamage()
		if event==sgs.DamageComplete and damage.to:hasFlag("chaodao") then
			room:setPlayerFlag(damage.to,"-chaodao")
			room:setPlayerProperty(damage.to,"chained",sgs.QVariant(true))
		end
	end,
}	

TCA12:addSkill(jiaoji)
TCA12:addSkill(dianxing)
TCA12:addSkill(chaodao)
TCA12:addSkill(chaodao_complete)

sgs.LoadTranslationTable{
	["TCA12"]="白鳥千尋",
	["#TCA12"]="チョウ電流",
	["~TCA12"]="ヤッフ",
	["jiaoji"]="狡计",
	[":jiaoji"]="在其他角色使用非延时锦囊（除无懈可击）时，若你武将牌正面朝上，你可以将你的武将牌翻面，然后收回该锦囊并防止该锦囊全部的效果。任何其他角色回合结束后，若你武将牌背面朝上，你可以交给其一张基础牌，然后将你的武将牌翻面。当你武将牌背面朝上时，你防止非延时锦囊对你的效果。",
	["#jiaoji"]="%from的【狡计】触发，防止了%arg对其的效果",
	["@jiaoji"]="你可以交给%src一张基础牌将武将翻回正面",
	["dianxing"]="电刑",
	[":dianxing"]="<b>锁定技</b>，你造成的伤害始终带有雷属性。当你失去最后一张手牌或者进入濒死时，其他角色依次选择一项：交给你一张红色手牌；或受到1点没有来源的雷属性伤害，该伤害不会随铁索连环传导。你在场时，除你以外的角色进入濒死状态时，你摸1张牌。",
	["#dianxing"]="%from的【电刑】触发，即将造成的伤害为雷电伤害",
	["#dianxingx"]="%from的【电刑】触发",
	["#dianxinga"]="%from进入濒死，触发了【电刑】",
	["#dianxingb"]="%from失去了最后一张手牌，触发了【电刑】",
	["@dianxing"]="请交给%src一张红色手牌，否则受到一点属性伤害",
	["chaodao"]="超导",
	[":chaodao"]="<b>锁定技</b>，你在场时，任何处于连环状态的角色受到雷属性伤害后，将其武将牌横置。你不会受到传导或者转移的伤害。",
	["#chaodao"]="%from的【超导】触发，防止了此次伤害",
	["designer:TCA12"]="Nutari",
	["illustrator:TCA12"]="てぃんくる",	
}

TCA13=sgs.General(extension,"TCA13","forbidden","1",false,true)

createpattern=""
create_card=sgs.CreateSkillCard{
	name="create_card",
	target_fixed=true,
	on_use=function(self,room,source)
		if createpattern=="" then
			local cardtype=room:askForChoice(source,"create","BasicCard+TrickCard")
			if cardtype=="BasicCard" then
				local choices="slash+fire_slash+thunder_slash"
				if not source:hasFlag("drank") then choices=choices.."+analeptic" end
				if source:isWounded() then choices=choices.."+peach" end
				choices=choices.."+cancel"
				createpattern=room:askForChoice(source,"create",choices)
			else
				local cardlist=""
				for _,cd in ipairs(moxingtrick) do
					cardlist=cardlist..cd.."+"
				end
				cardlist=cardlist.."cancel"
				createpattern=room:askForChoice(source,"create",cardlist)
			end	
			if createpattern=="cancel" then return end
		end	
		room:setPlayerFlag(source,"create")
		room:askForUseCard(source,"@@create","@create:"..createpattern)
		room:setPlayerFlag(source,"-create")
		createpattern=""		
	end,
}

create=sgs.CreateViewAsSkill{
	name="create",
	view_as=function()
		if not sgs.Self:hasFlag("create") and createpattern=="" then
			return create_card:clone()
		else
			local acard=sgs.Sanguosha:cloneCard(createpattern,sgs.Card_NoSuit,0)
			acard:setSkillName("create")
			return acard
		end
	end,
	enabled_at_play=function()
		createpattern=""
		return true
	end,
	enabled_at_response=function(self,player,pattern)
		if pattern=="slash" or pattern=="nullification" or pattern=="jink" then
			createpattern=pattern
			return true
		elseif string.find(pattern,"peach") then
			createpattern="peach"
			return true
		end		
		return pattern=="@@create"		
	end,
	enabled_at_nullification=function()
		createpattern="nullification"
		return true
	end,
}

createtarget=sgs.CreateTargetModSkill{
	name="#createtarget",
	pattern="BasicCard,TrickCard",
	residue_func=function(self,from,card)
		if from:hasSkill("create")  then
			return 1000
		end
	end,
	distance_limit_func=function(self,from,card)
		if from:hasSkill("create") then
			return 1000
		end
	end,
	extra_target_func=function(self,from,card)
		if from:hasSkill("create") and not card:isKindOf("DelayTrick") then
			return 1000
		end
	end,
}

TCA13:addSkill(create)
TCA13:addSkill(createtarget)
TCA13:addSkill("immortal")

sgs.LoadTranslationTable{
	["TCA13"]="☆天宮ゼロ",
	["#TCA13"]="創世主",
	["create_card"]="创世",
	["create"]="创世",
	["@create"]="你使用了%src，请选择目标",
	["~create"]="选择该牌合理的目标",
	[":create"]="你需要使用或者打出任何基础牌或者非延时锦囊时，可以视为你使用了你需要的牌。你使用基础牌和锦囊牌时，不受使用数量，距离和目标数量的限制\
	注：目标数量限制只适用于需要选择特定目标的基础和非延时锦囊",
	["designer:TCA13"]="Nutari",
	["illustrator:TCA13"]="てぃんくる",	
}

--榊ほのみ

TCA14=sgs.General(extension,"TCA14","god","3",false)

tchuozhong=sgs.CreateTriggerSkill{
	name="tchuozhong",
	events={sgs.DamageInflicted},
	frequency=sgs.Skill_Compulsory,	
	priority=-3,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local damage=data:toDamage()
		if player:isKongcheng() then			
			local log=sgs.LogMessage()
			log.from=player
			log.type="#tchuozhong"
			room:sendLog(log)
			player:drawCards(damage.damage)
			return true
		else
			if damage.damage>player:getHandcardNum() then
				damage.damage=player:getHandcardNum()
				player:throwAllHandCards()
				data:setValue(damage)
				local log=sgs.LogMessage()
				log.from=player
				log.type="#tchuozhong"
				room:sendLog(log)
				return false
			else
				room:askForDiscard(player,"tchuozhong",damage.damage,damage.damage)
			end
		end	
	end,
}

fenhui=sgs.CreateTriggerSkill{
	name="fenhui",
	events=sgs.CardsMoveOneTime,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local move=data:toMoveOneTime()
		local honomi=room:findPlayerBySkillName(self:objectName())
		if not honomi or player:objectName()~=honomi:objectName() then return end
		if move.from:objectName()==honomi:objectName() and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip) or move.from_places:contains(sgs.Player_PlaceDelayedTrick)) then
			if room:getCurrent():objectName()==honomi:objectName() then return end
			local current=room:getCurrent()		
			if not room:askForSkillInvoke(honomi,self:objectName(),data) then return end
			local x=move.card_ids:length()
			if (move.from_places:contains(sgs.Player_PlaceHand)) then
				for  i=1,move.card_ids:length(),1 do
					if current:isKongcheng() then
						local damage=sgs.DamageStruct()
						damage.nature=sgs.DamageStruct_Fire
						damage.from=honomi
						damage.to=current
						damage.damage=x
						room:damage(damage)
					else
						local id=room:askForCardChosen(honomi,current,"h","fenhui")
						local reason=sgs.CardMoveReason()
						reason.m_reason=sgs.CardMoveReason_S_REASON_DISMANTLE
						reason.m_player=honomi:objectName()
						reason.m_skillName="fenhui"
						room:moveCardTo(sgs.Sanguosha:getCard(id),nil,sgs.Player_DiscardPile,reason,true)
						x=x-1
					end
				end	
			elseif (move.from_places:contains(sgs.Player_PlaceEquip)) then
				for  i=1,move.card_ids:length(),1 do
					if current:getEquips():isEmpty() then
						local damage=sgs.DamageStruct()
						damage.nature=sgs.DamageStruct_Fire
						damage.from=honomi
						damage.to=current
						damage.damage=x
						room:damage(damage)
					else
						local id=room:askForCardChosen(honomi,current,"e","fenhui")
						local reason=sgs.CardMoveReason()
						reason.m_reason=sgs.CardMoveReason_S_REASON_DISMANTLE
						reason.m_player=honomi:objectName()
						reason.m_skillName="fenhui"
						room:moveCardTo(sgs.Sanguosha:getCard(id),nil,sgs.Player_DiscardPile,reason,true)
						x=x-1
					end
				end	
			else
				for  i=1,move.card_ids:length(),1 do
					if current:getCards("j"):isEmpty() then
						local damage=sgs.DamageStruct()
						damage.nature=sgs.DamageStruct_Fire
						damage.from=honomi
						damage.to=current
						damage.damage=x
						room:damage(damage)
					else
						local id=room:askForCardChosen(honomi,current,"j","fenhui")
						local reason=sgs.CardMoveReason()
						reason.m_reason=sgs.CardMoveReason_S_REASON_DISMANTLE
						reason.m_player=honomi:objectName()
						reason.m_skillName="fenhui"
						room:moveCardTo(sgs.Sanguosha:getCard(id),nil,sgs.Player_DiscardPile,reason,true)
						x=x-1
					end
				end
			end	
		end
	end,
}

tcyuyan_card=sgs.CreateSkillCard{
	name="tcyuyan_card",
	filter=function(self,targets,to_select)
		if #targets>sgs.Self:getLostHp() then return false end
		return to_select:objectName()~=sgs.Self:objectName()
	end,
	on_use=function(self,room,source,targets)		
		local damage=sgs.DamageStruct()
		damage.from=source
		damage.nature=sgs.DamageStruct_Fire
		local basedamage=1
		local flag=true
		for _,card in sgs.qlist(source:getHandcards()) do
			if card:isBlack() then flag=false break end
		end
		source:throwAllHandCards()
		if flag and not source:isWounded() then basedamage=basedamage+1 end
		for _,target in ipairs(targets) do
			damage.damage=basedamage
			damage.to=target
			room:damage(damage)
		end
		if flag and source:isWounded() then
			local recover=sgs.RecoverStruct()
			recover.who=source
			room:recover(source,recover)
		end	
		room:setPlayerFlag(source,"tcyuyanuse")
	end,	
}

tcyuyan_vs=sgs.CreateViewAsSkill{
	name="tcyuyan",
	n=0,
	view_as=function(self,cards)
		return tcyuyan_card:clone()
	end,
	enabled_at_play=function()
		return not sgs.Self:hasFlag("tcyuyanuse") and not sgs.Self:isKongcheng()
	end,	
}

tcyuyan=sgs.CreateTriggerSkill{
	name="tcyuyan",
	view_as_skill=tcyuyan_vs,
	events=sgs.EventPhaseEnd,
	on_trigger=function(self,event,player,data)
		if player:getPhase()==sgs.Player_Play then
			room:setPlayerFlag(player,"-tcyuyanuse")
		end
	end,
}

TCA14:addSkill(tchuozhong)
TCA14:addSkill(fenhui)
TCA14:addSkill(tcyuyan)

sgs.LoadTranslationTable{
	["TCA14"]="榊ほのみ",
	["#TCA14"]="混乱の火",
	["tchuozhong"]="火种",
	[":tchuozhong"]="<b>锁定技</b>，当你没有手牌时，你防止你即将受到的伤害并摸去与伤害量等同的手牌。当你有手牌时，你受到的伤害会不会超过你的手牌数，并且你需弃置与伤害量等同的手牌。",
	["#tchuozhong"]="%from的火种被触发",
	["fenhui"]="焚毁",
	[":fenhui"]="其他角色的回合内，若你失去了一次手牌、装备区、判定区的牌，则每有一张你可以弃置当前角色相同区域内的一张牌。若对应区域内无牌可弃，每少弃置一张你对其造成1点火焰伤害",
	["tcyuyan_card"]="狱焰",
	["tcyuyan"]="狱焰",
	[":tcyuyan"]="出牌阶段，你可以弃置你所有的手牌（至少一张），对最多x+1名其他角色造成一点火焰伤害，x为你已失去的体力值。若手牌均为红色，你恢复1点体力（体力满的情况下令此伤害+1）。一阶段限一次",
	["designer:TCA14"]="Nutari",
	["illustrator:TCA14"]="てぃんくる",	
}	

--☆泉かれい

TCA15=sgs.General(extension,"TCA15","god","3",false,true)

donggu=sgs.CreateTriggerSkill{
	name="donggu",
	events={sgs.Damaged,sgs.TurnStart},
	frequency=sgs.Skill_Compulsory,	
	priority=5,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.Damaged then
			local damage=data:toDamage()
			if (damage.from and damage.from:hasSkill(self:objectName()) or damage.to:hasSkill(self:objectName())) and damage.from:objectName()~=damage.to:objectName() then
				local target
				if damage.from:hasSkill(self:objectName()) then 
					target=damage.to
				else
					target=damage.from
				end
				if target:getMark("@frozen")==0 and target:isAlive() then target:gainMark("@frozen") end
			end
		else
			if player:getMark("@frozen")>0 then
				local log=sgs.LogMessage()
				log.from=player
				log.type="#donggu"
				room:sendLog(log)
				player:loseAllMarks("@frozen")
				return true
			end
		end
	end,
}

jihan_card=sgs.CreateSkillCard{
	name="jihan_card",
	filter=function(self,targets,to_select,player)
		return #targets==0 and to_select:objectName()~=player:objectName()
	end,
	on_use=function(self,room,source,targets)
		local damage=sgs.DamageStruct()
		damage.from=source
		damage.to=targets[1]
		room:damage(damage)
		local recover=sgs.RecoverStruct()
		recover.who=source
		room:recover(source,recover)		
	end,
}

jihan_vs=sgs.CreateViewAsSkill{
	name="jihan",
	n=1,
	view_filter=function(self,selected,to_select)
		return to_select:isBlack()
	end,
	view_as=function(self,cards)
		if #cards>0 then
			local acard=jihan_card:clone()
			acard:addSubcard(cards[1]:getId())
			return acard
		end
	end,
	enabled_at_play=function()
		return sgs.Self:isWounded()
	end,
}	

jihan=sgs.CreateTriggerSkill{
	name="jihan",
	events=sgs.Dying,
	view_as_skill=jihan_vs,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if player:objectName()==data:toDying().who:objectName() then
			room:askForUseCard(player,"@@jihan","@jihan")
		end	
	end,		
}

fengxue=sgs.CreateTriggerSkill{
	name="fengxue",
	events=sgs.EventPhaseStart,
	can_trigger=function(self,player)
		return not player:hasSkill(self:objectName()) and player:getMark("@frozen")==0
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if player:getPhase()==sgs.Player_Finish then
			local karei=room:findPlayerBySkillName(self:objectName())
			if not karei or not room:askForSkillInvoke(karei,self:objectName(),data) then return end
			local card=room:askForCard(player,".|.|.|hand|black","@fengxue:"..karei:objectName(),data,sgs.Card_MethodNone,karei)
			if card then
				room:moveCardTo(card,karei,sgs.Player_PlaceHand,true)
			else
				if player:getMark("@frozen")==0 then player:gainMark("@frozen") end
			end
		end	
	end,
}

TCA15:addSkill(donggu)
TCA15:addSkill(jihan)
TCA15:addSkill(fengxue)

sgs.LoadTranslationTable{
	["TCA15"]="☆泉かれい",
	["#TCA15"]="氷の心",
	["donggu"]="冻骨",
	[":donggu"]="<b>锁定技</b>，每当你造成或受到伤害时，你将受伤害者或伤害来源“冰冻”，处于“冰冻”的角色将跳过其下一个回合。",
	["@frozen"]="冰冻",
	["#donggu"]="%from被冰冻，跳过了其的回合",
	["jihan"]="饥寒",
	[":jihan"]="出牌阶段，若你已受伤，则你可以弃置一张黑色牌，对一名其他角色造成1点伤害并恢复自己1点体力。当你进入濒死状态时，也可以如此做。",
	["jihan_card"]="饥寒",
	["@jihan"]="你可以发动饥寒",
	["~jihan"]="选择一张黑色牌->选择一名其他角色->点击确定",
	["fengxue"]="风雪",
	[":fengxue"]="其他角色回合结束阶段开始时，你可以令其交给你一张黑色手牌，若其不交，则将其“冰冻”。不能对已处于“冰冻”的角色使用",
	["@fengxue"]="请交给%src一张黑色手牌，否则你将被冰冻",
	["designer:TCA15"]="Nutari",
	["illustrator:TCA15"]="てぃんくる",	
}	
