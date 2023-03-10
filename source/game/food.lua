--- Playdate object to represent the food (apple).
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
local gfx <const> = playdate.graphics

class('Food').extends(gfx.sprite)

--- Food constructor.
-- Sets the image of food to the apple image and
-- sets the collision rectangle for collision detection.
function Food:init()
    self:setImage(gfx.image.new("game/images/food.png"))
    self:setCollideRect(0, 0, self:getSize())
    self:add()
end