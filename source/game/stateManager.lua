--- Manager and helper class for managing game states.
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

-- pd constants
local pd <const> = playdate

-- constants
local GAME_STATE_MAX_LENGTH <const> = 50
local GAME_IDLE_UPDATE_SPEED <const> = 2
local GAME_REWIND_RES <const> = 4

-- globals
StateManager = {}

-- locals
local this = {}
local function initLocalDefaults()
  this.currentStatePos = 1
  this.gameStateMap = setmetatable({}, { __mode = "k" })
  this.gameStateTimer = nil
  this.gamePauseState = nil
  this.crankMovingState = false
end

--- Accessor for the games paused state.
-- Depending on the argument provided, it will either return the
-- current paused state or it will set the new state.
--
-- @param val Value of the paused state, can be nil
-- @return boolean result of the game paused state
function StateManager.isPaused(val)
  if val ~= nil then this.gamePauseState = val end
  return this.gamePauseState
end

--- Accessor for the games crank moving state.
-- Depending on the argument provided, it will either return the
-- current crank moving state or it will set the new state.
--
-- @param val Value of the crank moving state, can be nil
-- @return boolean result of the crank moving state
function StateManager.isCrankMoving(val)
  if val ~= nil then this.crankMovingState = val end
  return this.crankMovingState
end

--- Saves the current state of the game.
-- Once per snake movement, various states from different managers
-- are saved by the state manager in a special state table.
-- The maximum number states cannot exceed GAME_STATE_MAX_LENGTH.
-- Any new saved states exceeding this number will force the state
-- table to remove the oldest state out.
local function saveGameState()
  local state = {}
  state[1] = input.last
  state[2] = FoodManager.saveGameState()
  state[3] = BodyManager.saveGameState()
  state[4] = UiManager.saveGameState()
  state[5] = SoundManager.saveGameState()

  table.insert(this.gameStateMap, 1, state)
  if #this.gameStateMap == GAME_STATE_MAX_LENGTH + 1 then
    this.gameStateMap[#this.gameStateMap] = nil
    table.remove(this.gameStateMap, #this.gameStateMap)
  end
end

--- Loads a paticular state of the game.
-- When the player is rewinding the game with the rotatation of
-- the crank, certain states from the special state table will be
-- loaded back into different managers responsible for different
-- parts of the game. The state is not "applied" until the player
-- resumes the game. See StateManager.resume()
local function loadGameState()
  local crankDiff = pd.getCrankTicks(GAME_REWIND_RES)
  if StateManager.isCrankMoving() and crankDiff ~= 0 then
    this.currentStatePos -= crankDiff

    if this.currentStatePos < 1 then
      this.currentStatePos = 1
    elseif this.currentStatePos > #this.gameStateMap then
      this.currentStatePos = #this.gameStateMap
    end

    local state = this.gameStateMap[this.currentStatePos]

    input.next = state[1]
    FoodManager.loadGameState(state[2])
    BodyManager.loadGameState(state[3])
    UiManager.loadGameState(state[4])
    SoundManager.playGameState(state[5], crankDiff < 0)
  end
end

--- Resumes the game from a paticular state.
-- As the player is cranking through the saved game states,
-- when they decide the state they wish to resume, the function
-- call will discard the states dissregarded by the player.
-- The function will also trigger various game manager functions
-- in order to resume the game.
function StateManager.resume()
  if this.currentStatePos > 1 then
    for i = this.currentStatePos, 1, -1 do
      FoodManager.saveFutureState(this.gameStateMap[1][2])
      this.gameStateMap[1] = nil
      table.remove(this.gameStateMap, 1)
    end
    collectgarbage()

    this.currentStatePos = 1
    StateManager.isPaused(false)
    StateManager.isCrankMoving(false)
    BodyManager.stopHitBlinker()
    UiManager.stopRewindBlinker()
    UiManager.decRewindLimit()
    UiManager.startMultiplierTimer()
  end
end

--- The main function that controls the flow of the game.
-- The update function triggered by the game state frame timer is
-- triggered every GAME_IDLE_UPDATE_SPEED number of frames. When
-- triggered, a state of the game is saved and the next movement
-- of the snake is calculated and moved based on the users inputs.
-- The user can trigger a forced update of the game state if
-- correct directional buttons are pressed.
--
-- @param timer the timer used to trigger this function, not used
-- @param forcedUpdate boolean, if the function call was forced
function StateManager.update(timer, forcedUpdate)
  if not StateManager.isPaused() then
    saveGameState()
    BodyManager.calcNextHeadPos()
    BodyManager.moveSnake()
  else
    loadGameState()
  end

  if forcedUpdate then
    this.gameStateTimer:reset()
  end
end

function StateManager.setup()
  initLocalDefaults()
  this.gameStateTimer = pd.frameTimer.new(GAME_IDLE_UPDATE_SPEED)
  this.gameStateTimer.timerEndedCallback = StateManager.update
  this.gameStateTimer.repeats = true
end

function StateManager.newGame()
  StateManager.isPaused(false)
  this.gameStateTimer:reset()
end

function StateManager.teardown()
  this.gameStateTimer:remove()
  Util.clearTable(this)
end
