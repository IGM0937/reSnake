--- Utility class used to control the game's tutorial screen.
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

-- global
TutorialScreen = {}
TutorialScreen.name = "screen.tutorial"
TutorialScreen.isFinished = nil

-- locals
local this = {}
local function initLocalDefaults()
  this.titleText = nil
  this.titleDiv = nil
  this.tutorialTextCommon = nil
  this.pageNavCommon = nil
  this.buttonBCommon = nil
  this.buttonACommon = nil
  this.panelNo = nil
  this.panelList = {}
end

function createCommonComponents()
  this.titleText = gfx.sprite.new()
  this.titleText.draw = function()
    gfx.drawText("*Tutorial*", 0, 0)
  end
  this.titleText:setCenter(0.5, 0.5)
  this.titleText:setSize(60, 20)
  this.titleText:moveTo(50, 20)
  this.titleText:add()

  local divImg = gfx.image.new(380, 2, gfx.kColorBlack)
  this.titleDiv = gfx.sprite.new(divImg)
  this.titleDiv:moveTo(200, 30)
  this.titleDiv:add()

  this.tutorialTextCommon = gfx.sprite.new()
  this.tutorialTextCommon:setCenter(0.5, 0.5)
  this.tutorialTextCommon:setSize(360, 140)
  this.tutorialTextCommon:moveTo(200, 120)
  this.tutorialTextCommon:setVisible(false)
  this.tutorialTextCommon:add()

  this.pageNavCommon = gfx.sprite.new()
  this.pageNavCommon:setCenter(0.5, 0.5)
  this.pageNavCommon:setSize(80, 20)
  this.pageNavCommon:moveTo(60, 220)
  this.pageNavCommon:setVisible(false)
  this.pageNavCommon:add()

  this.buttonBCommon = gfx.sprite.new()
  this.buttonBCommon:setCenter(0.5, 0.5)
  this.buttonBCommon:setSize(80, 20)
  this.buttonBCommon:moveTo(260, 220)
  this.buttonBCommon:setVisible(false)
  this.buttonBCommon:add()

  this.buttonACommon = gfx.sprite.new()
  this.buttonACommon:setCenter(0.5, 0.5)
  this.buttonACommon:setSize(80, 20)
  this.buttonACommon:moveTo(360, 220)
  this.buttonACommon:setVisible(false)
  this.buttonACommon:add()
end

--- One of functions used to create a single panel.
-- All relevant spirtes for this panel will be stored
-- in a table and returned to be stored in a larger
-- table to be used to switch between these panels.
-- See, goToPanel(int)
local function createPanel1()
  local spritesList = {}

  local tutorialText = this.tutorialTextCommon:copy()
  tutorialText.draw = function()
    local text = "This is your standard game of snake game\n" ..
        "you know and love!\n\n" ..
        "Press *A* or the *directional* buttons to read the\n" ..
        "rest of the tutorial. Press *B* to start the game."
    gfx.drawText(text, 0, 0)
  end
  table.insert(spritesList, tutorialText)

  local pageNav = this.pageNavCommon:copy()
  pageNav.draw = function()
    gfx.drawText("Page *1/" .. tostring(#this.panelList) .. "*", 0, 0)
  end
  table.insert(spritesList, pageNav)

  local startText = this.buttonBCommon:copy()
  startText.draw = function()
    gfx.drawText("Ⓑ *Start*", 0, 0)
  end
  table.insert(spritesList, startText)

  local nextText = this.buttonACommon:copy()
  nextText.draw = function()
    gfx.drawText("Ⓐ *Next*", 0, 0)
  end
  table.insert(spritesList, nextText)

  return spritesList
end

local function createPanel2()
  local spritesList = {}

  local tutorialText = this.tutorialTextCommon:copy()
  tutorialText.draw = function()
    local text = "Eat the apple to *score points*.\n\n" ..
        "Every 3rd apple *increases the snake size*.\n\n" ..
        "Every apple *increases your multiplier* for even\n" ..
        "more points!\n\n" ..
        "Be quick, otherwise you will *lose the multiplier*."
    gfx.drawText(text, 0, 0)
  end
  table.insert(spritesList, tutorialText)

  local pageNav = this.pageNavCommon:copy()
  pageNav.draw = function()
    gfx.drawText("Page *2/" .. tostring(#this.panelList) .. "*", 0, 0)
  end
  table.insert(spritesList, pageNav)

  local startText = this.buttonBCommon:copy()
  startText.draw = function()
    gfx.drawText("Ⓑ *Start*", 0, 0)
  end
  table.insert(spritesList, startText)

  local nextText = this.buttonACommon:copy()
  nextText.draw = function()
    gfx.drawText("Ⓐ *Next*", 0, 0)
  end
  table.insert(spritesList, nextText)

  return spritesList
end

local function createPanel3()
  local spritesList = {}

  local tutorialText = this.tutorialTextCommon:copy()
  tutorialText.draw = function()
    local text = "Here is the *twist*! If you make a mistake, you\n" ..
        "can *rewind time* using the *crank!* To resume\n" ..
        "the game at the desired time, press *A*.\n\n" ..
        "You will have 3 chances to rewind before the\n" ..
        "*game ends*!"
    gfx.drawText(text, 0, 0)
  end
  table.insert(spritesList, tutorialText)

  local pageNav = this.pageNavCommon:copy()
  pageNav.draw = function()
    gfx.drawText("Page *3/" .. tostring(#this.panelList) .. "*", 0, 0)
  end
  table.insert(spritesList, pageNav)

  local startText = this.buttonBCommon:copy()
  startText.draw = function()
    gfx.drawText("Ⓑ *Start*", 0, 0)
  end
  table.insert(spritesList, startText)

  local nextText = this.buttonACommon:copy()
  nextText.draw = function()
    gfx.drawText("Ⓐ *Next*", 0, 0)
  end
  table.insert(spritesList, nextText)

  return spritesList
end

local function createPanel4()
  local spritesList = {}

  local tutorialText = this.tutorialTextCommon:copy()
  tutorialText.draw = function()
    local text = "Couple of more things!\n\n" ..
        "*1.* The arena wraps around itself. Use it to\nyour advantage!\n\n" ..
        "*2.* Use the menu button if you want to retry\nor end your run early."
    gfx.drawText(text, 0, 0)
  end
  table.insert(spritesList, tutorialText)

  local pageNav = this.pageNavCommon:copy()
  pageNav.draw = function()
    gfx.drawText("Page *4/" .. tostring(#this.panelList) .. "*", 0, 0)
  end
  table.insert(spritesList, pageNav)

  local startText = this.buttonBCommon:copy()
  startText.draw = function()
    gfx.drawText("Ⓑ *Start*", 0, 0)
  end
  table.insert(spritesList, startText)

  local nextText = this.buttonACommon:copy()
  nextText.draw = function()
    gfx.drawText("Ⓐ *Next*", 0, 0)
  end
  table.insert(spritesList, nextText)

  return spritesList
end

local function createPanel5()
  local spritesList = {}

  local tutorialText = this.tutorialTextCommon:copy()
  tutorialText.draw = function()
    local text = "Have fun and may the *best high score win!*\n\n" ..
        "Press *A* to start."
    gfx.drawText(text, 0, 0)
  end
  table.insert(spritesList, tutorialText)

  local pageNav = this.pageNavCommon:copy()
  pageNav.draw = function()
    gfx.drawText("Page *5/" .. tostring(#this.panelList) .. "*", 0, 0)
  end
  table.insert(spritesList, pageNav)

  local startText = this.buttonACommon:copy()
  startText.draw = function()
    gfx.drawText("Ⓐ *Start*", 0, 0)
  end
  table.insert(spritesList, startText)

  return spritesList
end

--- Used to switch between panels of the tutorial screen.
-- It utilises the bigger table of sprite table for each
-- panel. It hides the old panel's sprites and shows the
-- the new panel's sprites before it sets the current
-- visable panel number.
local function goToPanel(nextPanelNo)
  if this.panelNo ~= nil then
    local oldSprites = this.panelList[this.panelNo]
      for j = 1, #oldSprites, 1 do
        oldSprites[j]:setVisible(false)
      end
  end

  local newSprites = this.panelList[nextPanelNo]
  for j = 1, #newSprites, 1 do
    newSprites[j]:setVisible(true)
  end

  this.panelNo = nextPanelNo
end

local function nextPanel()
  if this.panelNo < #this.panelList then
    goToPanel(this.panelNo + 1)
  end
end

local function prevPanel()
  if this.panelNo > 1 then
    goToPanel(this.panelNo - 1)
  end
end

--- Inputs used for this game's tutorial screen
local tutorialInputHandlers = {
  AButtonDown = function()
    if this.panelNo == #this.panelList then
      TutorialScreen.isFinished = true
    else
      goToPanel(this.panelNo + 1)
    end
  end,
  BButtonDown = function()
    if this.panelNo < #this.panelList then
      TutorialScreen.isFinished = true
    end
  end,
  rightButtonDown = function() nextPanel() end,
  leftButtonDown = function() prevPanel() end,
  downButtonDown = function() nextPanel() end,
  upButtonDown = function() prevPanel() end
}

function TutorialScreen.enter()
  initLocalDefaults()
  createCommonComponents()

  table.insert(this.panelList, createPanel1())
  table.insert(this.panelList, createPanel2())
  table.insert(this.panelList, createPanel3())
  table.insert(this.panelList, createPanel4())
  table.insert(this.panelList, createPanel5())

  goToPanel(1)
  TutorialScreen.isFinished = false
  pd.inputHandlers.push(tutorialInputHandlers)
end

function TutorialScreen.exit()
  Util.clearTable(this)
  gfx.sprite.removeAll()
  pd.inputHandlers.pop()
  collectgarbage()
end
