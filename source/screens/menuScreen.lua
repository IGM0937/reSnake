--- Utility class used to control the game's menu screen.
-- See DEV_NOTES on game screen file make up.
--
-- reSnake - Copyright (C) 2022-2023 - TNMM
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
local ani <const> = gfx.animator
local ef <const> = pd.easingFunctions

-- constants
local SCREEN_OFFSET_TOP <const> = 0
local SCREEN_OFFSET_BOTTOM <const> = -810
local SCREEN_OFFSET_PLAY_CUTOFF <const> = -150
local SCREEN_OFFSET_TUTORIAL_CUTOFF <const> = -172
local SCREEN_SCROLL_RES <const> = 180
local SCROLL_DURATION <const> = 1000

-- global
MenuScreen = {}
MenuScreen.name = "screen.menu"
MenuScreen.hasGameSelected = nil
MenuScreen.isTutorialSelected = nil

local this = {}
local function initLocalDefaults()
  this.yScroll = 0
  this.goToTopAni = ani.new(1, 0, 0)
end

--- Starts scolling animation back up to the top.
-- Playdate SDK forces you to create a new animation
-- every time you want to scroll to the top, rather
-- than creating it once and then replaying it with
-- different parameters
local function startAniScrollToTop()
  this.goToTopAni = ani.new(SCROLL_DURATION, this.yScroll, SCREEN_OFFSET_TOP, ef.outCubic)
end

--- Inputs used for this game's menu screen
local menuInputHandlers = {
  AButtonDown = function()
    if this.goToTopAni:ended() then
      if this.yScroll > SCREEN_OFFSET_PLAY_CUTOFF then
        MenuScreen.hasGameSelected = true
      else
        startAniScrollToTop()
      end
    end
  end,
  BButtonDown = function()
    if this.goToTopAni:ended() then
      if this.yScroll > SCREEN_OFFSET_TUTORIAL_CUTOFF then
        MenuScreen.isTutorialSelected = true
      else
        startAniScrollToTop()
      end
    end
  end,
  cranked = function(chn, acc)
    if this.goToTopAni:ended() then
      this.yScroll -= pd.getCrankTicks(SCREEN_SCROLL_RES)

      if this.yScroll > SCREEN_OFFSET_TOP then
        this.yScroll = SCREEN_OFFSET_TOP
      elseif this.yScroll < SCREEN_OFFSET_BOTTOM then
        this.yScroll = SCREEN_OFFSET_BOTTOM
      end
      gfx.setDrawOffset(0, this.yScroll)
    end
  end
}

function MenuScreen.enter()
  initLocalDefaults()

  local titleImg = gfx.image.new("game/images/title.png")
  local title = gfx.sprite.new(titleImg)
  title:moveTo(200, 80)
  title:add()

  local startText = gfx.sprite.new()
  startText.draw = function()
    gfx.drawTextAligned("Ⓐ Play", 150, 0, kTextAlignment.center)
  end
  startText:setCenter(0.5, 0.5)
  startText:setSize(300, 20)
  startText:moveTo(200, 150)
  startText:add()

  local tutorialText = gfx.sprite.new()
  tutorialText.draw = function()
    gfx.drawTextAligned("Ⓑ Tutorial", 150, 0, kTextAlignment.center)
  end
  tutorialText:setCenter(0.5, 0.5)
  tutorialText:setSize(300, 20)
  tutorialText:moveTo(200, 180)
  tutorialText:add()

  local creditsText = gfx.sprite.new()
  creditsText.draw = function()
    gfx.drawTextAligned("🎣 Credits", 150, 0, kTextAlignment.center)
  end
  creditsText:setCenter(0.5, 0.5)
  creditsText:setSize(300, 20)
  creditsText:moveTo(200, 210)
  creditsText:add()

  local bpgLogoImg = gfx.image.new("game/images/grpLogo.png")
  local bpgLogo = gfx.sprite.new(bpgLogoImg)
  bpgLogo:moveTo(200, 390)
  bpgLogo:add()

  local creditsLicence = gfx.sprite.new()
  creditsLicence.draw = function()
    local text = "reSnake\n*v1.0.1*\n\n" ..
        "Created by\n*Igor Goran Macukat*\n\n" ..
        "Under the\n*GNU General Public License v3.0*\n\n" ..
        "Copyright © 2022-2023 TNMM"
    gfx.drawTextAligned(text, 150, 0, kTextAlignment.center)
  end
  creditsLicence:setCenter(0.5, 0.5)
  creditsLicence:setSize(300, 200)
  creditsLicence:moveTo(200, 655)
  creditsLicence:add()

  local uCodeBroImg = gfx.image.new("game/images/uCodeBro.png")
  local uCodeBro = gfx.sprite.new(uCodeBroImg)
  uCodeBro:setCenter(0.5, 0.5)
  uCodeBro:moveTo(120, 895)
  uCodeBro:add()

  local qrCodeImg = gfx.image.new("game/images/qrcode.png")
  local qrCode = gfx.sprite.new(qrCodeImg)
  qrCode:setCenter(0.5, 0.5)
  qrCode:moveTo(275, 895)
  qrCode:add()

  local conclusion = gfx.sprite.new()
  conclusion.draw = function()
    local text = "Feedback and contributions are all welcome.\n\n" ..
        "Ⓐ or Ⓑ to go back up!"
    gfx.drawTextAligned(text, 200, 0, kTextAlignment.center)
  end
  conclusion:setCenter(0.5, 0.5)
  conclusion:setSize(400, 60)
  conclusion:moveTo(200, 1005)
  conclusion:add()

  MenuScreen.isTutorialSelected = false
  MenuScreen.hasGameSelected = false
  pd.inputHandlers.push(menuInputHandlers)
end

--- Used to check the current value of the animation every frame.
-- This method is called from the main
-- event loop in main.lua file.
function MenuScreen.update()
  if not this.goToTopAni:ended() then
    this.yScroll = this.goToTopAni:currentValue()
    gfx.setDrawOffset(0, this.yScroll)
  end
end

function MenuScreen.exit()
  Util.clearTable(this)
  gfx.setDrawOffset(0, 0)
  gfx.sprite.removeAll()
  pd.inputHandlers.pop()
  collectgarbage()
end
