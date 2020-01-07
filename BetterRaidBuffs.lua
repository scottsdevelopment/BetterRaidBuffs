function ExCompactUnitFrame_UpdateBuffs(frame)
    if ( not frame.buffFrames or not frame.optionTable.displayBuffs ) then
        CompactUnitFrame_HideAllBuffs(frame);
        return;
    end
    
    local index = 1;
    local frameNum = 1;
    local filter = nil;
    local buffName = nil;
    repeat
        buffName = UnitBuff(frame.displayedUnit, index, filter);
        if ( buffName ~= nil ) then
            if ( ExCompactUnitFrame_UtilShouldDisplayBuff(frame.displayedUnit, index, filter) and not CompactUnitFrame_UtilIsBossAura(frame.displayedUnit, index, filter, true) ) then
                local buffFrame = frame.buffFrames[frameNum];
                if ( buffFrame == nil ) then
                    buffFrame = CreateCompactBuffTemplate(frame)
                    SetBuffFramePosition(frame)
                end
                
                ExCompactUnitFrame_UtilSetBuff(buffFrame, frame.displayedUnit, index, filter);
                frameNum = frameNum + 1;
            end
        else
            break;
        end
        index = index + 1;
    until( buffName == nil );
    for i=frameNum, #frame.buffFrames do
        local buffFrame = frame.buffFrames[i];
        buffFrame:Hide();
    end
end

--Utility Functions
function ExCompactUnitFrame_UtilShouldDisplayBuff(unit, index, filter)
    local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId, canApplyAura = UnitBuff(unit, index, filter);
    
    local hasCustom, alwaysShowMine, showForMySpec = SpellGetVisibilityInfo(spellId, UnitAffectingCombat("player") and "RAID_INCOMBAT" or "RAID_OUTOFCOMBAT");
    
    if ( hasCustom ) then
        return showForMySpec or (alwaysShowMine and (unitCaster == "player" or unitCaster == "pet" or unitCaster == "vehicle"));
    else
        return canApplyAura and not SpellIsSelfBuff(spellId);
    end
end

function CreateCompactBuffTemplate(parent)
    buffFrame = CreateFrame("Button", "CompactBuffTemplate", parent, "CompactAuraTemplate");
    
    if ( not parent.buffFrames ) then
        parent.buffFrames = {};
    end
    tinsert(parent.buffFrames, buffFrame);
    buffFrame:RegisterForClicks("LeftButtonDown", "RightButtonUp");
    
    
    buffFrame:SetScript("OnUpdate", function(self)
            if ( GameTooltip:IsOwned(self) ) then
                GameTooltip:SetUnitBuff(self:GetParent().displayedUnit, self:GetID());
            end            
    end)
    
    buffFrame:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0);
            GameTooltip:SetUnitBuff(self:GetParent().displayedUnit, self:GetID());
    end)
    
    buffFrame:SetScript("OnLeave", function(self)
            GameTooltip:Hide();
    end)
    
    return buffFrame;
end

function SetBuffFramePosition(frame)
    local NATIVE_UNIT_FRAME_HEIGHT = 36;
    local NATIVE_UNIT_FRAME_WIDTH = 72;
    local CUF_AURA_BOTTOM_OFFSET = 2;
    local options = DefaultCompactUnitFrameSetupOptions;
    local componentScale = min(options.height / NATIVE_UNIT_FRAME_HEIGHT, options.width / NATIVE_UNIT_FRAME_WIDTH);
    local buffSize = 11 * componentScale;
    local powerBarHeight = 8;
    local powerBarUsedHeight = options.displayPowerBar and powerBarHeight or 0;
    
    local buffPos, buffRelativePoint, buffOffset = "BOTTOMRIGHT", "BOTTOMLEFT", CUF_AURA_BOTTOM_OFFSET + powerBarUsedHeight;
    frame.buffFrames[1]:ClearAllPoints();
    frame.buffFrames[1]:SetPoint(buffPos, frame, "BOTTOMRIGHT", -3, buffOffset);
    local y = 0
    for i=1, #frame.buffFrames do
        if ( i > 1 ) then
            
            if ( i > frame.maxBuffs ) then
                buffPost, buffRelativePoint = "TOPLEFT", "TOPRIGHT"
                row = math.floor( i / frame.maxBuffs ) 
                pos = i % frame.maxBuffs
                y = row*frame.maxBuffs - (frame.maxBuffs - pos)
            else
                y = i - 1
            end
            
            frame.buffFrames[i]:ClearAllPoints();
            frame.buffFrames[i]:SetPoint(buffPos, frame.buffFrames[y], buffRelativePoint, 0, 0);
        end
        frame.buffFrames[i]:SetSize(buffSize, buffSize);
    end
end

function ExCompactUnitFrame_UtilSetBuff(buffFrame, unit, index, filter)
    local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId, canApplyAura = UnitBuff(unit, index, filter);
    buffFrame.icon:SetTexture(icon);
    local rank = GetSpellRankById(spellId)
    
    CreateRankText(buffFrame, rank)
    
    if ( count > 1 ) then
        local countText = count;
        if ( count >= 100 ) then
            countText = BUFF_STACKS_OVERFLOW;
        end
        buffFrame.count:Show();
        buffFrame.count:SetText(countText);
    else
        buffFrame.count:Hide();
    end
    buffFrame:SetID(index);
    local enabled = expirationTime and expirationTime ~= 0;
    if enabled then
        local startTime = expirationTime - duration;
        CooldownFrame_Set(buffFrame.cooldown, startTime, duration, true);
    else
        CooldownFrame_Clear(buffFrame.cooldown);
    end
    buffFrame:Show();
end

function GetSpellRankById(spellId)
    if spellId == nil then return nil end
    local spellSubtext = GetSpellSubtext(spellId)
    if spellSubtext == nil then return nil end
    rank = string.match(spellSubtext, "%d+")
    return rank
end

function CreateRankText(frame, rank)
    if frame.rank == nil then
        frame.rank = frame:CreateFontString("rank","OVERLAY") 
        frame.rank:SetFontObject(Number12Font_o1)
        frame.rank:SetTextColor(1,1,1,.75)
        frame.rank:SetPoint("CENTER",0,0)
    end
    if (rank ~= nil) then
        frame.rank:SetText(rank);
    else
        frame.rank:SetText("");
        frame.rank:Hide();
    end

end

hooksecurefunc("CompactUnitFrame_UpdateBuffs", ExCompactUnitFrame_UpdateBuffs);