--- Main class.
-- Contains the main event loop from Playdate SDK
-- along with the setup and control of the games screens.
--
-- The check tables are used to check what happens each frame
-- to the game and whether or not it should switch screens.
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

import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/frameTimer"
import "CoreLibs/crank"
import "CoreLibs/keyboard"
import "CoreLibs/ui"
import "CoreLibs/animator"
import "CoreLibs/animation"
import "CoreLibs/easing"

import "screens/menuScreen"
import "screens/tutorialScreen"
import "screens/gameScreen"
import "screens/endScreen"

import "game/soundManager"

import "util"

-- pd constants
local pd <const> = playdate
local gfx <const> = pd.graphics

-- constants
local GAME_REFRESH_RATE <const> = 24

-- local
local currentScreen = nil
local screenStateChecks = {
  [MenuScreen.name] = function ()
    if MenuScreen.hasGameSelected then
      MenuScreen:exit()
      GameScreen:enter()
      currentScreen = GameScreen.name
    elseif MenuScreen.isTutorialSelected then
      MenuScreen:exit()
      TutorialScreen:enter()
      currentScreen = TutorialScreen.name
    end
  end,
  [TutorialScreen.name] = function ()
    if TutorialScreen.isFinished then
      TutorialScreen:exit()
      GameScreen:enter()
      currentScreen = GameScreen.name
    end
  end,
  [GameScreen.name] = function ()
    if not GameScreen.isGameRunning then
      GameScreen:exit()
      EndScreen.enter(GameScreen.finalScore)
      currentScreen = EndScreen.name
    end
  end,
  [EndScreen.name] = function ()
    if EndScreen.isRetrySelected then
      EndScreen:exit()
      GameScreen:enter()
      currentScreen = GameScreen.name
    elseif EndScreen.isMenuSelected then
      EndScreen:exit()
      MenuScreen:enter()
      currentScreen = MenuScreen.name
    end
  end
}
local screenUpdateChecks = {
  [MenuScreen.name] = function ()
    MenuScreen.update()
  end,
  [TutorialScreen.name] = function ()
    -- do nothing
  end,
  [GameScreen.name] = function ()
    GameScreen.update()
  end,
  [EndScreen.name] = function ()
    -- do nothing
  end
}

--- Main function that starts the game.
--
-- It sets the games refresh rate, type of garbage collection
-- and initiallises the sound manager alongside the starting
-- game screen, the menu screens.
local function main()
  pd.display.setRefreshRate(GAME_REFRESH_RATE)

  collectgarbage("incremental")
  pd.gameWillPause = function()
    collectgarbage()
  end

  SoundManager.init()
  MenuScreen:enter()
  currentScreen = MenuScreen.name
end

function pd.update()
  pd.timer.updateTimers()
  pd.frameTimer.updateTimers()
  gfx.sprite.update()
  SoundManager.update()

  screenStateChecks[currentScreen]()
  screenUpdateChecks[currentScreen]()
end

main()
