--- Utility class used to control the game's game screen.
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

import "game/bodyManager"
import "game/foodManager"
import "game/stateManager"
import "game/uiManager"
import "game/soundManager"

-- pd constants
local pd <const> = playdate

-- globals
GameScreen = {}
GameScreen.name = "screen.game"
GameScreen.isGameRunning = nil
GameScreen.finalScore = nil
Input = {
  next = nil,
  last = nil
}

--- Function used to setup all of the game managers.
-- Setup is required in order to initialise all the
-- relevant elements before start of a new game.
local function setupGame()
  BodyManager.setup()
  FoodManager.setup()
  StateManager.setup()
  UiManager.setup()
  SoundManager.setup()
end

--- Function used to trigger the default values of
-- a brand new game.
--
-- The reason this function is seperated out from
-- setupGame() is because the game has the ability
-- to retry a run. The function can be called multiple
-- times without having to recreate basic game elements
-- such as timers, image tables, sounds and so on.
local function startNewGame()
  Input = {
    next = pd.kButtonRight,
    last = pd.kButtonRight
  }

  BodyManager.newGame()
  FoodManager.newGame()
  StateManager.newGame()
  UiManager.newGame()
  SoundManager.newGame()
end

--- Checks the state and input of the game.
-- Used to check if the game is not paused and if the 2
-- provided input arguments are not the last thing that was
-- inputed by the player. This stops the snake going back
-- on itself or forcefuly pushing itself forward.
--
-- @param input1 first input paramater to filter
-- @param input2 second input paramater to filter
-- @return boolean result showing if the input state is valid
local function validStateAndFilterInput(input1, input2)
  return not StateManager.isPaused()
      and Input.last ~= input1
      and Input.last ~= input2
end

--- Inputs used for this game's game screen.
-- Every input is validated against some state of the game,
-- especially the directional buttons, as it forces a screen
-- update for more snappier gameplay.
local gameInputHandlers = {
  upButtonDown = function()
    if validStateAndFilterInput(pd.kButtonDown, pd.kButtonUp) then
      Input.next = pd.kButtonUp
      StateManager.update(nil, true)
    end
  end,
  rightButtonDown = function()
    if validStateAndFilterInput(pd.kButtonLeft, pd.kButtonRight) then
      Input.next = pd.kButtonRight
      StateManager.update(nil, true)
    end
  end,
  downButtonDown = function()
    if validStateAndFilterInput(pd.kButtonUp, pd.kButtonDown) then
      Input.next = pd.kButtonDown
      StateManager.update(nil, true)
    end
  end,
  leftButtonDown = function()
    if validStateAndFilterInput(pd.kButtonRight, pd.kButtonLeft) then
      Input.next = pd.kButtonLeft
      StateManager.update(nil, true)
    end
  end,
  AButtonDown = function()
    if StateManager.isPaused() and StateManager.isCrankMoving() then
      StateManager.resume()
    end
  end,
  cranked = function(chn, acc)
    if StateManager.isPaused() and UiManager.canRewind() then
      StateManager.isCrankMoving(true)
    end
  end
}

--- Function used to remove all game elements.
-- This is typically executed before switching to end
-- game screen and is implemented by every manager.
local function teardownGame()
  BodyManager.teardown()
  FoodManager.teardown()
  StateManager.teardown()
  UiManager.teardown()
end

function GameScreen.enter()
  setupGame()
  startNewGame()
  GameScreen.isGameRunning = true
  GameScreen.finalScore = 0

  pd.inputHandlers.push(gameInputHandlers)
  pd.getSystemMenu():addMenuItem("retry", function()
    startNewGame()
  end)
  pd.getSystemMenu():addMenuItem("end run", function()
    GameScreen.isGameRunning = false
  end)
end

function GameScreen.update()
  BodyManager.updateHitBlinker()
  UiManager.updateScreenShake()
  UiManager.updateRewindBlinker()
end

function GameScreen.exit()
  GameScreen.isGameRunning = false
  GameScreen.finalScore = UiManager.getFinalScore()
  teardownGame()

  pd.inputHandlers.pop()
  pd.graphics.sprite:removeAll()
  pd.getSystemMenu():removeAllMenuItems()
  collectgarbage()
end
