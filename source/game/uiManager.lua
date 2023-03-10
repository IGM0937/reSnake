--- Manager and helper class for managing game ui.
-- See DEV_NOTES on manager file make up.
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
local ani <const> = gfx.animation

-- constants
local MULTI_RESET_MILLI <const> = 2000
local REWIND_BLINK_MILLI <const> = 500
local GROW_LIMIT <const> = 3
local REWIND_LIMIT <const> = 3
local ARENA_STEP <const> = 16
local ARENA_MIN_X <const>, ARENA_MAX_X <const> = 1, 24
local ARENA_MIN_Y <const>, ARENA_MAX_Y <const> = 2, 14
local SHAKE_AMOUNT <const> = 10
local REWIND_ANI <const> = "rewind"
local RESUME_ANI <const> = "resume"
local REWIND_ANI_MAP <const> = { RESUME_ANI, REWIND_ANI }

-- globals
UiManager = {}
Arena = {
  step = function() return ARENA_STEP end,
  minX = function() return ARENA_MIN_X end,
  maxX = function() return ARENA_MAX_X end,
  minY = function() return ARENA_MIN_Y end,
  maxY = function() return ARENA_MAX_Y end
}

-- locals
local this = {}
local function initLocalDefaults()
  -- arena
  this.wallVerLeft = nil
  this.wallVerRight = nil
  this.wallVerTop = nil
  this.wallVerBottom = nil
  -- hud
  this.score = 0
  this.multiplier = 1
  this.multiplierResetTimer = nil
  this.scoreSprite = nil
  this.growCount = nil
  this.growCountSprite = nil
  this.rewindLimit = nil
  this.rewindLimitSprite = nil
  this.crankAlertSprite = nil
  this.resumeAlertSprite = nil
  this.rewindAlertIndex = 1
  this.rewindBlinker = nil
  this.rewindBlinkerState = false
  -- shake
  this.shakeAmount = 0
  this.shameOngoing = false
end

--- Creates the 4 walls of the game arena.
local function createWalls()
  local wallVerImg = gfx.image.new(2, 212, gfx.kColorBlack)
  local wallHorImg = gfx.image.new(388, 2, gfx.kColorBlack)

  this.wallVerLeft = gfx.sprite.new(wallVerImg)
  this.wallVerLeft:moveTo(7, 128)
  this.wallVerLeft:add()

  this.wallVerRight = gfx.sprite.new(wallVerImg)
  this.wallVerRight:moveTo(393, 128)
  this.wallVerRight:add()

  this.wallVerTop = gfx.sprite.new(wallHorImg)
  this.wallVerTop:moveTo(200, 23)
  this.wallVerTop:add()

  this.wallVerBottom = gfx.sprite.new(wallHorImg)
  this.wallVerBottom:moveTo(200, 233)
  this.wallVerBottom:add()
end

--- Creates the score ui.
local function createScore()
  this.scoreSprite = gfx.sprite.new()
  this.scoreSprite.draw = function()
    local val = "*Score*: " .. tostring(this.score)
    if this.multiplier ~= 1 then
      val = val .. " (x" .. tostring(this.multiplier) .. ")"
    end
    gfx.drawText(val, 0, 0)
  end
  this.scoreSprite:setCenter(0, 0)
  this.scoreSprite:setSize(200, 20)
  this.scoreSprite:moveTo(7, 4)
  this.scoreSprite:add()
end

--- Updates the score.
-- The function increases the score based on the multipler.
function UiManager.updateScore()
  this.score = this.score + (1 * this.multiplier)
  this.scoreSprite:markDirty()
end

--- Clears/resets the score.
local function resetScoreAndMultiplier()
  this.score = 0
  this.multiplier = 1
  this.scoreSprite:markDirty()
end

--- Gets the score.
-- The function is used at the end of the game, which is
-- why it's called "get final score".
function UiManager.getFinalScore()
  return this.score
end

--- Creates a timer for the game's multiplier
-- The timer is set at MULTI_RESET_MILLI and when triggered,
-- the players multiplier would be lost. Increase in score,
-- will reset the multiplier score.
local function createMultiplierTimer()
  this.multiplierResetTimer = pd.timer.new(MULTI_RESET_MILLI)
  this.multiplierResetTimer.repeats = true
  this.multiplierResetTimer.timerEndedCallback = function()
    if UiManager.getMultiplier() > 1 then
      UiManager.halfMultiplier()
      SoundManager.multiplierLost()
    end
  end
end

--- Starts the multiplier timer.
-- This function gets used when the timer has stopped.
-- Does not require calling when the timer has been just
-- newlly created.
function UiManager.startMultiplierTimer()
  this.multiplierResetTimer:start()
end

--- Stops the multiplier timer.
-- Used when the game has been paused.
function UiManager.stopMultiplierTimer()
  this.multiplierResetTimer:pause()
  this.multiplierResetTimer:reset()
end

--- Gets the current multiplier.
function UiManager.getMultiplier()
  return this.multiplier
end

--- Increases the current multiplier by 1.
function UiManager.incMultiplier()
  this.multiplier = this.multiplier + 1
  this.scoreSprite:markDirty()
  this.multiplierResetTimer:reset()
end

--- Halfs the multiplier, rounded down.
function UiManager.halfMultiplier()
  this.multiplier = math.floor(this.multiplier / 2)
  if this.multiplier < 1 then this.multiplier = 1 end
  this.scoreSprite:markDirty()
end

--- Creates the grow counter ui
local function createGrowCouter()
  this.growCountSprite = gfx.sprite.new()
  this.growCountSprite.draw = function()
    gfx.drawText("*Grow* in " .. tostring(this.growCount), 0, 0)
  end
  this.growCountSprite:setCenter(0, 0)
  this.growCountSprite:setSize(70, 20)
  this.growCountSprite:moveTo(235, 4)
  this.growCountSprite:add()
end

--- Decreases the grow counter by 1.
-- Called every time the snake eats the food.
function UiManager.decGrowCount()
  this.growCount -= 1
  this.growCountSprite:markDirty()
  return this.growCount
end

--- Clears/resets the grow counter.
-- Called when game is started or restarted.
function UiManager.resetGrowCount()
  this.growCount = GROW_LIMIT
  this.growCountSprite:markDirty()
end

--- Creates the rewind limit counter ui.
local function createRewindLimit()
  this.rewindLimitSprite = gfx.sprite.new()
  this.rewindLimitSprite.draw = function()
    gfx.drawText("*Rewind*: " .. tostring(this.rewindLimit), 0, 0)
  end
  this.rewindLimitSprite:setCenter(0, 0)
  this.rewindLimitSprite:setSize(70, 20)
  this.rewindLimitSprite:moveTo(322, 4)
  this.rewindLimitSprite:add()
end

--- Decreases the rewind limit by 1.
-- Typically called when snake hits it's own body.
function UiManager.decRewindLimit()
  this.rewindLimit -= 1
  this.rewindLimitSprite:markDirty()
  return this.rewindLimit
end

--- Clears/resets the rewind limit counter.
-- Called when game is started or restarted.
local function resetRewindLimit()
  this.rewindLimit = REWIND_LIMIT
  this.rewindLimitSprite:markDirty()
end

--- Returns a boolean if a player can rewind.
-- Typically used to indicate if the game is over.
function UiManager.canRewind()
  return this.rewindLimit > 0
end

--- Creates the crank alert sprite.
-- The alert indicates to the player that they can
-- use the crank to rewind to different game states.
local function createCrankAlert()
  local rewindAlertImg = gfx.image.new("game/images/rewindAlert.png")
  this.crankAlertSprite = gfx.sprite.new(rewindAlertImg)
  this.crankAlertSprite:setCenter(0, 0)
  this.crankAlertSprite:setZIndex(1)
  this.crankAlertSprite:moveTo(225, 210)
  this.crankAlertSprite:add()
  this.crankAlertSprite:setVisible(false)
end

--- Creates the resume alert sprite.
-- The alert indicates to the player that they can
-- press the "a" button to resume from the player's
-- chosen game state.
local function createResumeAlert()
  local resumeAlertImg = gfx.image.new("game/images/resumeAlert.png")
  this.resumeAlertSprite = gfx.sprite.new(resumeAlertImg)
  this.resumeAlertSprite:setCenter(0, 0)
  this.resumeAlertSprite:setZIndex(1)
  this.resumeAlertSprite:moveTo(225, 210)
  this.resumeAlertSprite:add()
  this.resumeAlertSprite:setVisible(false)
end

--- The rewind blinker update function.
-- The function is used to cycle through the different states
-- of the overall alerting system that comprises of the 2
-- alert sprites, with 3rd being blank.
-- The loop of showing one sprite, then nothing, then the other
-- sprite, then back again is coded in REWIND_ANI_MAP.
function UiManager.updateRewindBlinker()
  if not this.rewindBlinker.running then return end

  this.rewindBlinker:update()

  if this.rewindBlinker.on == this.rewindBlinkerState then return
  else this.rewindBlinkerState = this.rewindBlinker.on end

  if this.rewindBlinkerState then
    this.rewindAlertIndex += 1
    if this.rewindAlertIndex > #REWIND_ANI_MAP then
      this.rewindAlertIndex = 1
    end

    local index = REWIND_ANI_MAP[this.rewindAlertIndex]

    if index == REWIND_ANI then
      this.crankAlertSprite:setVisible(true)
      this.resumeAlertSprite:setVisible(false)
    elseif index == RESUME_ANI then
      this.crankAlertSprite:setVisible(false)
      this.resumeAlertSprite:setVisible(true)
    end
  else
    this.crankAlertSprite:setVisible(false)
    this.resumeAlertSprite:setVisible(false)
  end
end

--- Creates the rewind blinker animation.
-- The blinker is used to trigger the "coordinator" at a rate of
-- ALERT_PULSE_MILLI to switch to the next cycle of the alert state.
local function createRewindBlinker()
  this.rewindBlinker = ani.blinker.new()
  this.rewindBlinker.onDuration = REWIND_BLINK_MILLI
  this.rewindBlinker.offDuration = REWIND_BLINK_MILLI
end

--- Starts the rewind blinker.
function UiManager.startRewindBlinker()
  this.rewindBlinker:startLoop()
end

--- Stops the rewind blinker.
-- This blanks the alert so it is not shown on screen.
function UiManager.stopRewindBlinker()
  this.rewindBlinker:stop()
  this.crankAlertSprite:setVisible(false)
  this.resumeAlertSprite:setVisible(false)
  this.rewindBlinkerState = false
end

function UiManager.saveGameState()
  return { this.score, this.growCount }
end

function UiManager.loadGameState(state)
  this.score = state[1]
  this.scoreSprite:markDirty()
  this.growCount = state[2]
  this.growCountSprite:markDirty()
end

--- Starts the screen shake.
-- Typically started when the snake hits it's own body.
function UiManager.startScreenShake()
  this.shakeOngoing = true
  this.shakeAmount = SHAKE_AMOUNT
end

--- Updates the state of the screen shake.
-- This method is triggered from the main Playdate update loop.
function UiManager.updateScreenShake()
  if this.shakeOngoing then
    if this.shakeAmount > 0 then
      local shakeAngle = math.random() * math.pi * 2
      local shakeX = math.floor(math.cos(shakeAngle)) * this.shakeAmount
      local shakeY = math.floor(math.sin(shakeAngle)) * this.shakeAmount
      this.shakeAmount -= 1

      pd.display.setOffset(shakeX, shakeY)
    else
      this.shakeOngoing = false
      pd.display.setOffset(0, 0)
    end
  end
end

function UiManager.setup()
  initLocalDefaults()
  createWalls()
  createScore()
  createMultiplierTimer()
  createGrowCouter()
  createRewindLimit()
  createCrankAlert()
  createResumeAlert()
  createRewindBlinker()
end

function UiManager.newGame()
  resetScoreAndMultiplier()
  resetRewindLimit()
  UiManager.resetGrowCount()
  UiManager.stopRewindBlinker()
  UiManager.stopMultiplierTimer()
  UiManager.startMultiplierTimer()
end

function UiManager.teardown()
  -- all sprites will be removed in game screen exit function
  this.multiplierResetTimer:remove()
  this.rewindBlinker:remove()
  Util.clearTable(this)
end
