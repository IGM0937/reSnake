--- Utility class used to control the game's end screen.
-- See DEV_NOTES on game screen file make up.
--
-- reSnake - Copyright (C) 2022 - TNMM
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program. If not, see <https://www.gnu.org/licenses/>.

-- pd constants
local pd <const> = playdate
local gfx <const> = pd.graphics
local datastore <const> = pd.datastore
local keyboard <const> = pd.keyboard

-- constants
local GAMEOVER <const> = "gameover"
local CONFIRM <const> = "confirm"
local HIGHSCORE <const> = "highscore"

-- global
EndScreen = {}
EndScreen.name = "screen.gameover"
EndScreen.isRetrySelected = nil
EndScreen.isMenuSelected = nil

-- locals
local this = {}
local function initLocalDefaults(score)
  this.endScore = score
  this.playerName = ""
  this.currentPanel = nil
  this.panelList = {}
  this.scoreMap = {}
  this.gameoverText = nil
  this.signNameLabel = nil
  this.signEditLabel = nil
  this.skipNextLabel = nil
  this.leaderboardList = nil
  this.leaderboardTable = nil
  this.scrollCrankLabel = nil
  this.tableScroll = 3
  this.inLeaderboard = false
end

--- Reads Playdate's internal datastore to fetch leaderboard data.
-- It performs a nil check just incase no leaderboard data is found.
local function loadLeaderboardScoreMap()
  this.scoreMap = datastore.read() or {}
end

--- Calculates if the player's final score is in the leaderboard table.
-- This is utilised to both give a player to add their name and to play
-- a positive sound via the sound manager as an audable indicator.
local function calculateIfInLeaderboard()
  if this.endScore == 0 then this.inLeaderboard = false
  elseif #this.scoreMap == 0 or #this.scoreMap < 25 then this.inLeaderboard = true
  else this.inLeaderboard = this.endScore > this.scoreMap[#this.scoreMap].score end
end

--- Saves the current leaderboard to the Playdate's internal datastore.
local function saveLeaderboardMap()
  table.insert(this.scoreMap, { name = this.playerName, score = this.endScore })
  table.sort(this.scoreMap, function(k1, k2) return k1.score > k2.score end)
  this.scoreMap = { table.unpack(this.scoreMap, 1, 25) }
  datastore.write(this.scoreMap)
end

--- Re-renders the game leaderboard.
-- This is used in a couple of places to re-render the leaderboard if
-- it has been altered based on whether or not the player has added
-- themselves to the leaderboard.
local function updateLeaderboardListAndTable()
  this.leaderboardList:setNumberOfRows(#this.scoreMap)
  function this.leaderboardList:drawCell(sect, row, col, selected, x, y, w, h)
    gfx.drawTextAligned(tostring(row), x, y, kTextAlignment.left)
    gfx.drawTextAligned(this.scoreMap[row].name, x + 70, y, kTextAlignment.left)
    gfx.drawTextAligned(tostring(this.scoreMap[row].score), x + 250, y, kTextAlignment.right)
  end

  this.leaderboardTable:markDirty()
end

local function createGameOverPanel()
  local spriteList = {}

  this.gameoverText = gfx.sprite.new()
  this.gameoverText.draw = function()
    local text = "*Game Over!*\n\nYour final score is " .. tostring(this.endScore)
    if this.inLeaderboard then text = text .. "\n\nYou are on the leaderboard!" end
    gfx.drawTextAligned(text, 150, 0, kTextAlignment.center)
  end
  this.gameoverText:setCenter(0.5, 0.5)
  this.gameoverText:setSize(300, 80)
  this.gameoverText:moveTo(200, 100)
  this.gameoverText:setVisible(false)
  this.gameoverText:add()
  table.insert(spriteList, this.gameoverText)

  if this.inLeaderboard then
    this.signNameLabel = gfx.sprite.new()
    this.signNameLabel.draw = function()
      local text = "*Name:* " .. tostring(keyboard.text)
      gfx.drawTextAligned(text, 150, 0, kTextAlignment.center)
    end
    this.signNameLabel:setCenter(0.5, 0.5)
    this.signNameLabel:setSize(300, 80)
    this.signNameLabel:moveTo(200, 180)
    this.signNameLabel:setVisible(false)
    this.signNameLabel:add()
    table.insert(spriteList, this.signNameLabel)

    this.signEditLabel = gfx.sprite.new()
    this.signEditLabel.draw = function()
      local text = nil
      if keyboard.text == "" then text = "Sign" else text = "Edit" end
      gfx.drawText("Ⓑ *" .. text .. "*", 0, 0)
    end
    this.signEditLabel:setCenter(0.5, 0.5)
    this.signEditLabel:setSize(80, 20)
    this.signEditLabel:moveTo(260, 220)
    this.signEditLabel:setVisible(false)
    this.signEditLabel:add()
    table.insert(spriteList, this.signEditLabel)
  end

  this.skipNextLabel = gfx.sprite.new()
  this.skipNextLabel.draw = function()
    local text = nil
    if not this.inLeaderboard then text = "Next"
    elseif keyboard.text == "" then text = "Skip"
    else text = "Next" end
    gfx.drawText("Ⓐ *" .. text .. "*", 0, 0)
  end
  this.skipNextLabel:setCenter(0.5, 0.5)
  this.skipNextLabel:setSize(80, 20)
  this.skipNextLabel:moveTo(360, 220)
  this.skipNextLabel:setVisible(false)
  this.skipNextLabel:add()
  table.insert(spriteList, this.skipNextLabel)

  return spriteList
end

local function createConfirmPanel()
  local spriteList = {}

  local questionText = gfx.sprite.new()
  questionText.draw = function()
    local text = "Are you sure you *don't*\nwant to be on the leaderboard?"
    gfx.drawTextAligned(text, 150, 0, kTextAlignment.center)
  end
  questionText:setCenter(0.5, 0.5)
  questionText:setSize(300, 50)
  questionText:moveTo(200, 120)
  questionText:setVisible(false)
  questionText:add()
  table.insert(spriteList, questionText)

  local noLabel = gfx.sprite.new()
  noLabel.draw = function()
    gfx.drawText("Ⓑ *No*", 0, 0)
  end
  noLabel:setCenter(0.5, 0.5)
  noLabel:setSize(80, 20)
  noLabel:moveTo(260, 220)
  noLabel:setVisible(false)
  noLabel:add()
  table.insert(spriteList, noLabel)

  local yesLabel = gfx.sprite.new()
  yesLabel.draw = function()
    gfx.drawText("Ⓐ *Yes*", 0, 0)
  end
  yesLabel:setCenter(0.5, 0.5)
  yesLabel:setSize(80, 20)
  yesLabel:moveTo(360, 220)
  yesLabel:setVisible(false)
  yesLabel:add()
  table.insert(spriteList, yesLabel)

  return spriteList
end

local function createHighsScorePanel()
  local spriteList = {}

  local leaderboardTitle = gfx.sprite.new()
  leaderboardTitle.draw = function()
    gfx.drawTextAligned("*Top 25 Leaderboard*", 100, 0, kTextAlignment.center)
  end
  leaderboardTitle:setCenter(0.5, 0.5)
  leaderboardTitle:setSize(200, 20)
  leaderboardTitle:moveTo(200, 25)
  leaderboardTitle:setVisible(false)
  leaderboardTitle:add()
  table.insert(spriteList, leaderboardTitle)

  local leaderboardHeader = gfx.sprite.new()
  leaderboardHeader.draw = function()
    gfx.drawText("*Pos.*", 0, 0, kTextAlignment.left)
    gfx.drawText("*Name*", 70, 0, kTextAlignment.left)
    gfx.drawText("*Score*", 207, 0, kTextAlignment.right)
  end
  leaderboardHeader:setCenter(0, 0)
  leaderboardHeader:setSize(260, 20)
  leaderboardHeader:moveTo(70, 45)
  leaderboardHeader:setVisible(false)
  leaderboardHeader:add()
  table.insert(spriteList, leaderboardHeader)

  this.leaderboardList = pd.ui.gridview.new(40, 20)
  this.leaderboardList:setCellPadding(0, 0, 0, 0)

  this.leaderboardTable = gfx.sprite.new()
  this.leaderboardTable.draw = function()
    this.leaderboardList:drawInRect(0, 0, 260, 120)
    this.leaderboardList:scrollToRow(this.tableScroll, false)
  end
  this.leaderboardTable:setCenter(0, 0)
  this.leaderboardTable:setSize(260, 120)
  this.leaderboardTable:moveTo(65, 75)
  this.leaderboardTable:setVisible(false)
  this.leaderboardTable:add()
  table.insert(spriteList, this.leaderboardTable)

  this.scrollCrankLabel = gfx.sprite.new()
  this.scrollCrankLabel.draw = function()
    if #this.scoreMap > 6 then
      gfx.drawText("*Scroll* ⬇️⬆️/🎣", 0, 0)
    end
  end
  this.scrollCrankLabel:setCenter(0.5, 0.5)
  this.scrollCrankLabel:setSize(120, 20)
  this.scrollCrankLabel:moveTo(80, 220)
  this.scrollCrankLabel:setVisible(false)
  this.scrollCrankLabel:add()
  table.insert(spriteList, this.scrollCrankLabel)

  local menuLabel = gfx.sprite.new()
  menuLabel.draw = function()
    gfx.drawText("Ⓑ *Menu*", 0, 0)
  end
  menuLabel:setCenter(0.5, 0.5)
  menuLabel:setSize(80, 20)
  menuLabel:moveTo(260, 220)
  menuLabel:setVisible(false)
  menuLabel:add()
  table.insert(spriteList, menuLabel)

  local retryLabel = gfx.sprite.new()
  retryLabel.draw = function()
    gfx.drawText("Ⓐ *Retry*", 0, 0)
  end
  retryLabel:setCenter(0.5, 0.5)
  retryLabel:setSize(80, 20)
  retryLabel:moveTo(360, 220)
  retryLabel:setVisible(false)
  retryLabel:add()
  table.insert(spriteList, retryLabel)

  return spriteList
end

--- Used to switch between panels of the end screen.
-- See tutorialScreen#goToPanel(int) for same description.
local function goToPanel(nextPanel)
  if this.currentPanel ~= nil then
    local oldSprites = this.panelList[this.currentPanel]
    for i = 1, #oldSprites, 1 do
      oldSprites[i]:setVisible(false)
    end
  end

  local newSprites = this.panelList[nextPanel]
  for i = 1, #newSprites, 1 do
    newSprites[i]:setVisible(true)
  end

  this.currentPanel = nextPanel
end

local function scrollLeaderboardUp()
  if this.tableScroll > 3 then this.tableScroll -= 1 end
  this.leaderboardTable:markDirty()
end

local function scrollLeaderboardDown()
  if this.tableScroll < (#this.scoreMap - 2) then this.tableScroll += 1 end
  this.leaderboardTable:markDirty()
end

--- Inputs used for this game's end screen
local endInputHandlers = {
  AButtonDown = function()
    if this.currentPanel == GAMEOVER then
      if not this.inLeaderboard then
        updateLeaderboardListAndTable()
        goToPanel(HIGHSCORE)
      elseif this.playerName == "" then
        goToPanel(CONFIRM)
      else
        saveLeaderboardMap()
        updateLeaderboardListAndTable()
        goToPanel(HIGHSCORE)
      end
    elseif this.currentPanel == CONFIRM then
      updateLeaderboardListAndTable()
      goToPanel(HIGHSCORE)
    elseif this.currentPanel == HIGHSCORE then
      EndScreen.isRetrySelected = true
    end
  end,
  BButtonDown = function()
    if this.currentPanel == GAMEOVER and this.inLeaderboard then
      if keyboard.isVisible() then keyboard.hide() else keyboard.show() end
    elseif this.currentPanel == CONFIRM then
      goToPanel(GAMEOVER)
    elseif this.currentPanel == HIGHSCORE then
      EndScreen.isMenuSelected = true
    end
  end,
  upButtonDown = function()
    if this.currentPanel == HIGHSCORE then scrollLeaderboardUp() end
  end,
  downButtonDown = function()
    if this.currentPanel == HIGHSCORE then scrollLeaderboardDown() end
  end,
  cranked = function(chn, acc)
    if this.currentPanel == HIGHSCORE then
      local tick = pd.getCrankTicks(6) * -1
      if tick == 1 then
        scrollLeaderboardUp()
      elseif tick == -1 then
        scrollLeaderboardDown()
      end
    end
  end
}

function EndScreen.enter(score)
  initLocalDefaults(score)
  loadLeaderboardScoreMap()
  calculateIfInLeaderboard()

  this.panelList[GAMEOVER] = createGameOverPanel()
  this.panelList[CONFIRM] = createConfirmPanel()
  this.panelList[HIGHSCORE] = createHighsScorePanel()

  goToPanel(GAMEOVER)
  SoundManager.endGame(this.inLeaderboard)

  EndScreen.isRetrySelected = false
  EndScreen.isMenuSelected = false

  local prevShiftX = pd.display.getWidth()
  keyboard.keyboardAnimatingCallback = function()
    local diffX = keyboard.left() - prevShiftX
    this.gameoverText:moveBy(diffX, 0)
    this.signNameLabel:moveBy(diffX, 0)
    this.signEditLabel:moveBy(diffX * -1, 0)
    this.skipNextLabel:moveBy(diffX * -1, 0)
    prevShiftX = keyboard.left()
  end
  keyboard.textChangedCallback = function()
    this.playerName = string.sub(keyboard.text, 1, 10)
    keyboard.text = this.playerName

    this.signNameLabel:markDirty()
    this.signEditLabel:markDirty()
    this.skipNextLabel:markDirty()
  end
  pd.inputHandlers.push(endInputHandlers)
end

function EndScreen.exit()
  Util.clearTable(this)
  keyboard.keyboardAnimatingCallback = nil
  keyboard.textChangedCallback = nil
  gfx.sprite:removeAll()
  pd.inputHandlers.pop()
  collectgarbage()
end
