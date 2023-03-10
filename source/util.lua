--- Utility file.
-- Contains functions that are useful in the whole game.
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

-- globals
Util = {}

--- Custom ternary function.
-- Used to help consolidate code for easier readability.
-- Inline turnery functions like this can be found in languages like Java:
-- (result = cond ? trueStatement : falseStatement)
--
-- @param cond Conditional statment that results in a boolean
-- @param T result if the conditional statement is true
-- @param F result if the conditional statement is false
function Util.ternary(cond, T, F)
    if cond then return T else return F end
end

--- Clears the specified table.
-- Clears the table of values. Used when redesignating the table
-- without removing the metadata or when cleaning out "this" table.
--
-- @param tableValue the table to be cleared
function Util.clearTable(tableValue)
    for _, _ in ipairs(tableValue) do
        table.remove(tableValue, 1)
    end
end
