--- Playdate object to represent a body part of the snake.
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

class('Body').extends(gfx.sprite)

--- Body constructor.
-- Creates the body part of the snake, given it's position,
-- direction and the image for the part. Direction is used
-- specifically for the neck (body part right behind the head)
-- and the head itself.
--
-- @param x x position
-- @param y y position
-- @param direction body direction
-- @param image Playdate image object
-- @return collision type
function Body:init(x, y, direction, image)
  self.direction = direction
  self:setImage(image)
  self:setCollideRect(0, 0, self:getSize())
  self:moveTo(x, y)
  self:add()

  self.collisionResponse = function(body, other)
    if other:isa(Food) then
      return gfx.sprite.kCollisionTypeOverlap
    elseif other:isa(Body) then
      return gfx.sprite.kCollisionTypeFreeze
    end
  end
end

--- Sets the image for the snake head.
-- Updates the body part with a specific image of head.
-- The specific image to be used is based on the direction of
-- the body part and if the month is supposed to be opened.
--
-- @param val direction of the body part (typically input.last)
-- @param openMouth boolean, true if head is adjacent to the food
-- object (default false)
function Body:setHeadImage(val, openMouth)
  self.direction = val
  if val == pd.kButtonUp then
    if not openMouth then
      self:setImage(BodyManager.headImages[13])
    else
      self:setImage(BodyManager.headImages[15])
    end
  elseif val == pd.kButtonRight then
    if not openMouth then
      self:setImage(BodyManager.headImages[1])
    else
      self:setImage(BodyManager.headImages[3])
    end
  elseif val == pd.kButtonDown then
    if not openMouth then
      self:setImage(BodyManager.headImages[5])
    else
      self:setImage(BodyManager.headImages[7])
    end
  elseif val == pd.kButtonLeft then
    if not openMouth then
      self:setImage(BodyManager.headImages[9])
    else
      self:setImage(BodyManager.headImages[11])
    end
  end
end

--- Sets the image for the snake tail.
-- The method does no set the direction of the tail.
-- It will utilise the existing direction of the object.
function Body:setTailImage()
  if self.direction == pd.kButtonUp then
    self:setImage(BodyManager.tailImages[2])
  elseif self.direction == pd.kButtonRight then
    self:setImage(BodyManager.tailImages[3])
  elseif self.direction == pd.kButtonDown then
    self:setImage(BodyManager.tailImages[4])
  elseif self.direction == pd.kButtonLeft then
    self:setImage(BodyManager.tailImages[1])
  end
end

--- Sets the image for the snake neck or torso.
-- Due to the way snakes body moves and is rendered, this
-- body part is first set as a neck and then when the next neck
-- is being set, this part theoretically will become part of
-- the torso. The image won't be changed again util the body
-- part becomes the tail.
--
-- The next image is selected based on the direction of the head
-- and first part of the torso behind the neck.
--
-- @param prev previous snake body part (torso)
-- @param next next snake body part (head)
function Body:setTorsoNeckImage(prev, next)
  self.direction = next
  if prev == pd.kButtonDown then
    if next == pd.kButtonRight then
      self:setImage(BodyManager.torsoImages[3])
    elseif next == pd.kButtonLeft then
      self:setImage(BodyManager.torsoImages[6])
    else
      self:setImage(BodyManager.torsoImages[2])
    end
  elseif prev == pd.kButtonLeft then
    if next == pd.kButtonDown then
      self:setImage(BodyManager.torsoImages[4])
    elseif next == pd.kButtonUp then
      self:setImage(BodyManager.torsoImages[3])
    else
      self:setImage(BodyManager.torsoImages[1])
    end
  elseif prev == pd.kButtonUp then
    if next == pd.kButtonLeft then
      self:setImage(BodyManager.torsoImages[5])
    elseif next == pd.kButtonRight then
      self:setImage(BodyManager.torsoImages[4])
    else
      self:setImage(BodyManager.torsoImages[2])
    end
  elseif prev == pd.kButtonRight then
    if next == pd.kButtonUp then
      self:setImage(BodyManager.torsoImages[6])
    elseif next == pd.kButtonDown then
      self:setImage(BodyManager.torsoImages[5])
    else
      self:setImage(BodyManager.torsoImages[1])
    end
  end
end

--- Creates a snapshot of the current body part.
-- Snapshots are used to store basic inforamtion about the
-- body part so that it can be saved in the game state map.
-- See DEV_NOTES for more information on performance tuning.
function Body:saveSnapshot()
  return {
    x = self.x, y = self.y,
    direction = self.direction,
    image = self:getImage()
  }
end

--- Alters the body part based on a provided snapshot.
-- Any alterations to the body part are applied immediately
-- on the next update.
--
-- @param snapshot basic information for the body part
function Body:loadSnapshot(snapshot)
  self:moveTo(snapshot.x, snapshot.y)
  self.direction = snapshot.direction
  self:setImage(snapshot.image)
end
