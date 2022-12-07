--- Manager and helper class for managing game sound.
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

import "game/sound/pulp-audio"

-- pd constants
local snd <const> = pulp.audio

-- constants
local SND_MAX <const> = 25
local REV <const> = "-rev"
local EAT <const> = "eat-"
local INC <const> = "inc-"
local LST <const> = "lost"
local HIT <const> = "hit"
local EON <const> = "end-in-ldr"
local EOF <const> = "end-off-ldr"
local SOUND_PATH <const> = "game/sound/sounds.json"

-- globals
SoundManager = {}

-- locals
local this = {}
local function initLocalDefaults()
    this.currentReversableSound = nil
end

--- Plays the given sound effect.
-- Uses the playdates native pulp sound library to play the sound provided.
-- The reverse boolean parameter tacks on the reverse constant to the
-- end of the sound file to play the reverse variant of the sound.
-- This works due to the naming strategy of the sounds used.
-- Not all sounds are reversable and not checked here.
-- 
-- @param sound name of the sound to play
-- @param reverse boolean, if the sound provided should be reversed
local function playSFX(sound, reverse)
    if sound ~= nil then
        snd.playSound(sound .. Util.ternary(reverse, REV, ""))
    end
end

--- Plays the given sound effect.
-- This function is used specifically for those sound effects that
-- can be reversed but also be differentiated based on the games multiplier
-- at the time that the sound is played. Once played the reversed sound is
-- saved into a local variable in order to be saved as a game state.
--
-- @param sound name of the sound to play
-- @param reverse boolean, if the sound provided should be reversed
-- @param multi specific multiplier value to use, max SND_MAX
local function playRevMultiSound(soundType, reverse, multi)
    if multi == 1 then return end
    local sound = soundType .. tostring(Util.ternary(multi > SND_MAX, SND_MAX, multi))
    playSFX(sound, reverse)
    this.currentReversableSound = sound
end

--- Function called outside the manager to play eat food sound.
function SoundManager.eatFood(reverse, multiplier)
    playRevMultiSound(EAT, reverse, multiplier)
end

--- Function called outside the manager to play body size increase sound.
function SoundManager.bodySizeIncrease(reverse, multiplier)
    playRevMultiSound(INC, reverse, multiplier)
end

--- Function called outside the manager to play multiplier lost sound.
function SoundManager.multiplierLost()
    playSFX(LST, false)
end

--- Function called outside the manager to play body hit sound.
function SoundManager.bodyHit()
    playSFX(HIT, false)
end

--- Function called outside the manager to play end game sound.
-- The paramater of the function is used to determine if the player's
-- final score is good enough to be in the leaderboard. Depending on the
-- result, a different sound is played.
--
-- @param inLeaderboard boolean, if player is in leaderboard
function SoundManager.endGame(inLeaderboard)
    snd.playSound(Util.ternary(inLeaderboard, EON, EOF))
end

function SoundManager.saveGameState()
    local currentSound = this.currentReversableSound
    this.currentReversableSound = nil
    return currentSound
end

function SoundManager.playGameState(state, reverse)
    playSFX(state, reverse)
end

--- Initiates the Sound Manager.
-- The manager uses the native Playdate pulp audio library to play
-- the game sounds. The sounds played are coded into a JSON file with
-- various synth variable notations read by the audio library.
--
-- See "game/sound" folder for the library and Playdate Pulp audio
-- library online for more details.
function SoundManager.init()
    snd.init(nil, SOUND_PATH)
end

function SoundManager.update()
    snd.update()
end

function SoundManager.setup()
    initLocalDefaults()
end

function SoundManager.newGame()
    SoundManager.setup()
end
