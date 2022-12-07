--- Manager and helper class for managing the food (apple).
-- See DEV_NOTES on manager file make up.
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

import "game/food"

-- globals
FoodManager = {}

-- locals
local this = {}
local function initLocalDefaults()
  this.food = Food()
  this.futureStates = setmetatable({}, { __mode = "k" })
end

local function randomiseFoodPosition()
  local newX, newY = nil, nil

  repeat
    newX = Arena.step() * math.random(Arena.minX(), Arena.maxX())
    newY = Arena.step() * math.random(Arena.minY(), Arena.maxY())
  until not BodyManager.overlappingWithSnakeBody(newX, newY)

  return newX, newY
end

--- Moves the food randomly within the arena.
-- The function will first go thought the table of saved
-- food positions that the game saved from a rewind, but
-- if there are no saves or the next food position is invalid
-- (it intersects with a body) then it will choose a new position
-- at random until it does not intersect with the snake body.
function FoodManager.moveFood()
  if #this.futureStates == 0 then
    this.food:moveTo(randomiseFoodPosition())
  elseif #this.futureStates == 1 then
    Util.clearTable(this.futureStates)
    this.food:moveTo(randomiseFoodPosition())
  else
    local nextState = this.futureStates[2]
    local newX, newY = nextState.x, nextState.y
    table.remove(this.futureStates, 1)

    if not BodyManager.overlappingWithSnakeBody(newX, newY) then
      this.food:moveTo(newX, newY)
    else
      this.food:moveTo(randomiseFoodPosition())
      Util.clearTable(this.futureStates)
    end
  end
end

--- Calculates if the food is near the snake's head.
-- The function is used to switch head images when the
-- snake's head is close to the food item.
--
-- @param headX x position of the snake part, usually head
-- @param headY y position of the snake part, usually head
-- @return boolean result if food is near snake head
function FoodManager.isNearBy(headX, headY)
  if headX ~= this.food.x and headY ~= this.food.y then
    return false
  elseif headX == this.food.x then
    if (headY + Arena.step()) == this.food.y then return true -- above
    elseif (headY - Arena.step()) == this.food.y then return true -- below
    else return false end
  elseif headY == this.food.y then
    if (headX + Arena.step()) == this.food.x then return true -- right
    elseif (headX - Arena.step()) == this.food.x then return true -- left
    else return false end
  end
end

--- Saves the future food positions.
-- These positions are saved so that food items don't have
-- to be randomised and gives the game the extra edge for those
-- who remember the next food positions.
function FoodManager.saveFutureState(state)
  local last = this.futureStates[1]
  if last == nil then
    table.insert(this.futureStates, 1, state)
  elseif last.x ~= state.x or last.y ~= state.y then
    table.insert(this.futureStates, 1, state)
  end
end

function FoodManager.saveGameState()
  return { x = this.food.x, y = this.food.y }
end

function FoodManager.loadGameState(state)
  this.food:moveTo(state.x, state.y)
end

function FoodManager.setup()
  initLocalDefaults()
end

function FoodManager.newGame()
  FoodManager.moveFood()
  Util.clearTable(this.futureStates)
end

function FoodManager.teardown()
  Util.clearTable(this)
end
