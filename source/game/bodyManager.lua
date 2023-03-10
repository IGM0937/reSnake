--- Manager and helper class for managing the snake body.
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

import "game/body"

-- pd constants
local pd <const> = playdate
local gfx <const> = pd.graphics
local ani <const> = gfx.animation

-- constants
local HIT_ANI_BLINK_MILLI <const> = 500
local START_BODY_LENGTH <const> = 5
local START_HEAD_X <const> = 7
local START_HEAD_Y <const> = 8

-- globals
BodyManager = {}
BodyManager.headImages = {}
BodyManager.torsoImages = {}
BodyManager.tailImages = {}

-- locals
local this = {}
local function initLocalDefaults()
  this.snakeBody = {}
  this.headImagesIndex = {}
  this.nextHeadX = nil
  this.nextHeadY = nil
  this.hitBlinker = nil
  this.hitBlinkerState = true
end

--- Calculates the next position of the snake head.
-- The function utilises the current position of the snake head
-- and the most recent direction button press to calculate where
-- the snake head should go next.
-- See DEV_NOTES on snake movement.
function BodyManager.calcNextHeadPos()
  this.nextHeadX, this.nextHeadY = this.snakeBody[1]:getPosition()
  if Input.next == pd.kButtonUp then
    Input.last = pd.kButtonUp
    this.nextHeadY -= Arena.step()
  elseif Input.next == pd.kButtonRight then
    Input.last = pd.kButtonRight
    this.nextHeadX += Arena.step()
  elseif Input.next == pd.kButtonDown then
    Input.last = pd.kButtonDown
    this.nextHeadY += Arena.step()
  elseif Input.next == pd.kButtonLeft then
    Input.last = pd.kButtonLeft
    this.nextHeadX -= Arena.step()
  end

  if this.nextHeadX < (Arena.minX() * Arena.step()) then
    this.nextHeadX = Arena.maxX() * Arena.step()
  elseif this.nextHeadX > (Arena.maxX() * Arena.step()) then
    this.nextHeadX = Arena.minX() * Arena.step()
  elseif this.nextHeadY < (Arena.minY() * Arena.step()) then
    this.nextHeadY = Arena.maxY() * Arena.step()
  elseif this.nextHeadY > (Arena.maxY() * Arena.step()) then
    this.nextHeadY = Arena.minY() * Arena.step()
  end
end

--- Moves the snake and resolves collisions
-- The function has the following phases:
-- 1. It fetches the snakes tail and moves it to the position of the new head.
-- 2. Performs collision detection to see if the new head position is viable.
-- 2a. If so, then it will fix the snake images so that the snake looks corrent.
-- 2b. If not, then revert the snake tail back to it's position and pause the game.
-- 3. If games is paused, then alter the games states appropriatly, otherwise carry on.
-- See DEV_NOTES on snake movement.
-- 
-- Additionally, a couple of fixes were introduced as part of v1.0.1, due to
-- 'sprite:copy()' being broken in 1.13.2:
-- 1. The "other" sprite comparison should be using "collision.other:isa(Food)", but
-- class name is not being copied over correctly.
-- 2. Copying of object attributes was also not working, so snapshot functionality
-- and to be added to complete the full copy of the desired body object.
function BodyManager.moveSnake()
  local prevTailX, prevTailY = this.snakeBody[#this.snakeBody]:getPosition()
  local collisions, count = nil, nil

  -- for collision check
  this.snakeBody[#this.snakeBody]:setCollisionsEnabled(false)
  this.snakeBody[#this.snakeBody]:moveTo(this.nextHeadX, this.nextHeadY)
  this.snakeBody[#this.snakeBody]:setCollisionsEnabled(true)
  this.snakeBody[1]:setCollisionsEnabled(false) -- exclude neck
  this.snakeBody[2]:setCollisionsEnabled(true) -- include 'old' neck

  _, _, collisions, count = this.snakeBody[#this.snakeBody]:checkCollisions(this.nextHeadX, this.nextHeadY)

  if count > 0 then
    for _, collision in ipairs(collisions) do
      if collision.other.className == "Food" then
        -- food eaten, do the following
        FoodManager.moveFood()
        UiManager.updateScore()
        UiManager.incMultiplier()

        if UiManager.decGrowCount() == 0 then
          -- if it's time to grow snake body, grow a new tail
          UiManager.resetGrowCount()
          local bodyPart = this.snakeBody[#this.snakeBody - 1]
          local bodyPartSnapshot = bodyPart:saveSnapshot()
          local copyBodyPart = bodyPart:copy()
          copyBodyPart:loadSnapshot(bodyPartSnapshot)
          copyBodyPart:setTailImage()
          table.insert(this.snakeBody, #this.snakeBody - 1, copyBodyPart)
          SoundManager.bodySizeIncrease(false, UiManager.getMultiplier())
        else
          SoundManager.eatFood(false, UiManager.getMultiplier())
        end
      elseif collision.other.className == "Body" then
        -- body hit, revert snake positions and pause the game
        this.snakeBody[#this.snakeBody]:setCollisionsEnabled(false)
        this.snakeBody[#this.snakeBody]:moveTo(prevTailX, prevTailY)
        this.snakeBody[#this.snakeBody]:setCollisionsEnabled(true)
        this.snakeBody[1]:setCollisionsEnabled(true) -- include head
        this.snakeBody[2]:setCollisionsEnabled(false) -- exclude 'pre-collision' neck

        StateManager.isPaused(true)
      end
    end
  end

  -- if paused, it means there is a body hit
  if StateManager.isPaused() then
    if not UiManager.canRewind() then
      -- if player cannot rewind, game is over
      GameScreen.isGameRunning = false
    else
      SoundManager.bodyHit()
      UiManager.startScreenShake()
      UiManager.startRewindBlinker()
      UiManager.stopMultiplierTimer()
      UiManager.halfMultiplier()
      this.hitBlinker:startLoop()
      collectgarbage()
    end
  else
    -- correct the snakeBody table after collision checks
    local bodyPart = this.snakeBody[#this.snakeBody]
    table.remove(this.snakeBody, #this.snakeBody)
    table.insert(this.snakeBody, 1, bodyPart)

    -- is food near by
    local nearBy = FoodManager.isNearBy(this.snakeBody[1]:getPosition())

    -- set a new image for head
    this.snakeBody[1]:setHeadImage(Input.last, nearBy)

    -- set a new image for neck
    local torsoDirection = this.snakeBody[3].direction
    local headDirection = this.snakeBody[1].direction
    this.snakeBody[2]:setTorsoNeckImage(torsoDirection, headDirection)

    -- set a new image for tail
    this.snakeBody[#this.snakeBody]:setTailImage()
  end
end

function BodyManager.saveGameState()
  local state = {}
  for i = 1, #this.snakeBody, 1 do
    state[i] = this.snakeBody[i]:saveSnapshot()
  end
  return state
end

function BodyManager.loadGameState(state)
  local min = math.min(#this.snakeBody, #state)
  for i = 1, min, 1 do
    this.snakeBody[i]:loadSnapshot(state[i])
  end

  if #state > #this.snakeBody then
    local s = state[#state]
    local addition = Body(s.x, s.y, s.direction, s.image)
    this.snakeBody[#this.snakeBody + 1] = addition
  elseif #state < #this.snakeBody then
    this.snakeBody[#this.snakeBody]:remove()
    this.snakeBody[#this.snakeBody] = nil
  end
end

--- Check that a given arena position is overlaying with the snake body.
-- Function used when food gets moved to a new location, checking that
-- it is a valida placement.
--
-- @param x arena x position of the object to check
-- @param y arena y position of the object to check
-- @return boolean result if given arena position is overlaping
function BodyManager.overlappingWithSnakeBody(x, y)
  for i = 1, #this.snakeBody, 1 do
    local bodyX, bodyY = this.snakeBody[i]:getPosition()
    if x == bodyX and y == bodyY then return true end
  end
  return false
end

--- Update function for the hot animation blinker.
-- This function switches between the snakes normal head and
-- the head that indicates the body hit. If the animation is not
-- running it will exit the function. If the crank is moving,
-- then it will stop the animation before exiting the function.
function BodyManager.updateHitBlinker()
  if not this.hitBlinker.running then
    return
  elseif StateManager.isCrankMoving() then
    BodyManager.stopHitBlinker()
    return
  end

  this.hitBlinker:update()

  if this.hitBlinker.on == this.hitBlinkerState then return
  else this.hitBlinkerState = this.hitBlinker.on end

  local index = this.headImagesIndex[this.snakeBody[1]:getImage()]
  if this.hitBlinkerState then
    this.snakeBody[1]:setImage(BodyManager.headImages[index - 1])
  else
    this.snakeBody[1]:setImage(BodyManager.headImages[index + 1])
  end
end

--- Stops the blinker animation.
function BodyManager.stopHitBlinker()
  this.hitBlinker:stop()
  this.hitBlinkerState = true
end

function BodyManager.setup()
  initLocalDefaults()

  local headImagesTable = gfx.imagetable.new("game/images/head")
  for i = 1, #headImagesTable do
    BodyManager.headImages[i] = headImagesTable[i]
    this.headImagesIndex[headImagesTable[i]] = i
  end

  local torsoImagesTable = gfx.imagetable.new("game/images/torso")
  for i = 1, #torsoImagesTable do
    BodyManager.torsoImages[i] = torsoImagesTable[i]
  end

  local tailImagesTable = gfx.imagetable.new("game/images/tail")
  for i = 1, #tailImagesTable do
    BodyManager.tailImages[i] = tailImagesTable[i]
  end

  this.hitBlinker = ani.blinker.new()
  this.hitBlinker.onDuration = HIT_ANI_BLINK_MILLI
  this.hitBlinker.offDuration = HIT_ANI_BLINK_MILLI
end

function BodyManager.newGame()
  for i = 1, #this.snakeBody, 1 do
    this.snakeBody[i]:remove()
  end
  this.snakeBody = {}
  collectgarbage()

  local headStartX = START_HEAD_X * Arena.step()
  local headStartY = START_HEAD_Y * Arena.step()

  for i = 1, START_BODY_LENGTH, 1 do
    local image = nil
    if i == 1 then
      image = BodyManager.headImages[1]
    elseif i == START_BODY_LENGTH then
      image = BodyManager.tailImages[3]
    else
      image = BodyManager.torsoImages[1]
    end

    local x = headStartX - (Arena.step() * i)
    this.snakeBody[i] = Body(x, headStartY, Input.last, image)
  end

  BodyManager.stopHitBlinker()
end

function BodyManager.teardown()
  this.hitBlinker:remove()
  Util.clearTable(BodyManager.headImages)
  Util.clearTable(BodyManager.torsoImages)
  Util.clearTable(BodyManager.tailImages)
  Util.clearTable(this)
end
