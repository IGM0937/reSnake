# Developer Notes

- [Developer Notes](#developer-notes)
  - [Overview](#overview)
  - [Why reSnake?](#why-resnake)
  - [Design](#design)
    - [Screens](#screens)
      - [Common screen methods](#common-screen-methods)
    - [Panels](#panels)
      - [Common panel methods](#common-panel-methods)
    - [Game managers](#game-managers)
      - [Common manager methods](#common-manager-methods)
      - [Sound Manager](#sound-manager)
  - [Implementation Details](#implementation-details)
    - [Snake Movement](#snake-movement)
    - [Score and Multiplier](#score-and-multiplier)
    - [Sound effects](#sound-effects)
    - [Screen Shake](#screen-shake)
    - [Rewind](#rewind)
    - [Leaderboard](#leaderboard)
    - [Global variable calls](#global-variable-calls)
    - [Localised variables](#localised-variables)
    - [Garbage collection](#garbage-collection)
  - [Conclusion](#conclusion)

## Overview

The following file has been written up as an extended form of documentation and commentary to the comments found in each of the game's files. This is used to give an idea and/or extra information to the curious as to the decisions made in the design and implementation of the game.

Whilst I'm at it, something that is already mentioned in the contributing file of the repo (`CONTRIBUTING.md`). Alongside the code, my designs might also have potentially questionable, non-standardised or non-conventional practices and implementations.

If you're finding these to be so bad and bordering on criminal, I'd love the hear the feedback.

## Why reSnake?

It a short sentence, I wanted this to be kept simple.

To me, the classical game of snake is simple and something that I personally enjoyed to play in all parts of life.

In a more complicated answer, the whole project has been created as an exercise into the use of the Playdate games console and its software development kit (SDK). It was something I had been interested in for a while, and given my limited time on personal projects that I'm able to dedicate, I wanted to make sure it was something simple and relatively straight forward.

My main objective, aside from completing the development of the game was to also "just complete a project". One of the many pieces of advice I heard about personal software projects in general, but especially in game design.

It was also a good opportunity to expand my knowledge of programming languages, with Lua being one that I have never come across in my daily work life. The language itself fully compiled into C and the SDK comes with C libraries as well, so hopefully it will give me a chance to learn C as well (eventually).

As a small aside, a small note about the season one game, Snak.

At the time I was developing this game, I was aware that the game existed. Even whist it was advertised as one of the season one games, I tried to stay spoiler free so that I'm able to experience the season as a player for myself.

Having said that, I didn't know anything else beyond that. How does it play, what is the primary gameplay loop, what makes it unique and so on. I started this small project the second Playdate SDK was open to the public and by the time I got my Playdate device, I was focused on finishing this project.

Even still at the time of this writing, I still know very little and having been avoiding any information on Snak.

As I never wanted to compete or be price competitive for this small project anyway, my intentions stay the same as described earlier in this section.

## Design

The following sections discuss some of the design choices made. If any of the sections don't make sense or require more explanation, again I'd love the hear the feedback.

### Screens

When the game was originally prototyped and whist I was still getting my bearings around the SDK, I originally written the game all in a single file. The game would simply start when the game was loaded into the Playdate Simulator.

Eventually once I needed to create things like the tutorial pages or leaderboard sections to the game, there was a requirement for different areas of the game to be sectioned off into their own files.

I am not very good at any actual UI/UX design, so that in itself had to be kept simple. However as a backend developer, I was able to leverage some of my understanding of the SDK I have built up so far (and quite frankly, my levels of OCD when it comes to "clean code") to create a selection of "game screens" that the main event loop will be looping around in order to make it look it's swapping or moving around different parts of the game.

The following code is modified from version v1.0 of the game:

``` lua
function playdate.update()
  -- playdate's update methods
  playdate.timer.updateTimers()
  playdate.frameTimer.updateTimers()
  playdate.graphics.sprite.update()

  -- custom sound manager update
  SoundManager.update()

  -- custom check tables, executed every frame
  screenStateChecks[currentScreen]()
  screenUpdateChecks[currentScreen]()
end
```

Fortunately for me, the SDK provides some handy libraries and functions that make it easy for me to update timers and sprites without having to directly reference them in the main update loop. I am able to simply create and `add()` game assets else where in my project and have them all updated in single line of code in the main update loop.

This is an update list that I constantly manipulate every time I switch back and forth between these screens. If I'm moving from the menu to the tutorial screens, I can remove all the sprites from the menu and add all the sprites of the tutorial.

The `screenStateChecks[currentScreen]()` table call executes a function based on the which current screen is being used (the table key being the current screen name of the game). This used to be a long if-else statement, but in hopes to introduce performance improvements, these have been moved to a simple key accessible table of functions.

```lua
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
  ...
}
```

As an example of one of the functions, it simply performs checks on the menu screen to see if any of the states have changed to trigger an exit of that screen and entrance of any other screen.

In this example, if the player presses the A button on the menu screen, it will trigger the start of the game. This means that the menu's timers and sprites are removed (via the `MenuScreen:exit()`) and the game screens assets are going to be loaded in (via the `GameScreen:enter()`).

Finally the current screen name variable will change, so that the next cycle of the Playdate update function will trigger a different part of the `screenStateChecks` table.

A similar check also exists for the updates required on that screen, but a majority of the updates happen via the already mentioned timers and sprite ready made update methods.

On this note, it's time to move onto a couple of common functions that exist within a typical game screen file:

#### Common screen methods

- **Screen`:enter()`**
  
  Function used to setup the screen's variables, sprites, timers and other assets. Typically called when first entering or showing the screen via user input.

- **Screen`:exit()`**

  Function used to clean up all of the screen's assets out of memory. Typically called when the assets on-screen are no longer relevant and don't need to be shown on scree. Also called in preparation for another screen's enter function call.

- **Screen`:update()`**

  Function used to call specific asset update functions.

  Typically not required, as SDK sprites and timers have a globally accessible asset table that are automatically updated every frame. This in-turn is used for edge case functions that require access to the main update loop, but are otherwise only used when certain screens are active.
  
  Anything inside of this function that needs to be called once every frame, such as animation timers, will be executed from this function.

  The other reason for the existence of this function instead of putting such logic in the main update loop would be for performance reasons. There should not be an instance where, for example, animation functions specific to one screen being called every frame thought the whole game.

  >NOTE: I could have potentially used frame timers eliminate the need for these frame specific updates and have these created during enter or exit functions, however that would be something to maybe explore later.

### Panels

In certain scenarios where "screens" are effectively a collection of other screens to display on screen, for example the pages of the tutorial screen, here I use the term "panels" to differentiate between other areas of the same screen. To reiterate on the same point using a previous example, panels are used to differentiate the between different pages of the tutorial.

In other scenarios, the panels are organised differently in the manner that suits the current screen.

This small section discusses some variations on these panels:

#### Common panel methods

- **Static panels**

  There is no real definition of a panel here, but is otherwise just a screen that has static UI elements, with the snake moving inside this game arena.
  
  In places like this, there would not be a need to specifically create a panel, as the screen itself is what the players see.

- **Long panel with scrolling**

  In a similar fashion here again, there is only one theoretical panel that needs to be shown on this screen.
  
  This particular variant where the "panel" is bigger then the view of the screen, the panel has to be moved around using the closest thing the SDK has to camera controls, `setDrawOffset()` function.

- **Paged panels**

  This variant is the type that really utilises the idea of multiple panels existing within a single screen.
  
  In this variant, as game switches to this screen, all of the panels (and groups of it's assets) are initiated, saved into a panels table and hidden from the player. Upon a specific player action, such as pressing a directional button, a panel can be "swapped out" by having one panels assets hidden and another shown, mimicking the illusion of a page turn.

  The tutorial screen has a good example of this use.

- **Linked panels**

  In principle it is exactly the same as the paged panels, without having a clear determined path of what panel comes next.

  In this variant, the players inputs drive the change in panel more so then the pages, as users decisions may affect what screen comes next.

  The use of this can be seen in the end screen and can also be seen in the input map used for that screen.

### Game managers

In a game that contains a lot of sprites, be it the snakes body or the walls of the arena, no meaningful sprite is in the game is controlled individually or independently from the rest of pack.

These sprites are most likely being controlled in groups using managers.

The most obvious manager in the game is the body manager, responsible for managing the snake body. For example, if the snake moves across the screen, the manager has the logic to ensure that every part of the snake's body is moved correctly and that the body sprite images are correctly set in order to complete the illusion of snake movement.

More on this in the [snake movement](#snake-movement) section.

#### Common manager methods

- **Manager`:setup()`**

  Function used to setup the assets that the manager will be working with.

- **Manager`:newGame()`**

  Function used to initiate variable defaults required to start a new game.

  The reason this is separate from the setup function is because the player has the ability to reset the game via a menu option. Having the function isolated makes the game start and restart more manageable (pun intended).

- **Manager`:teardown()`**

  Function used to clean up the manager's assets. This is typically triggered during the exit function of the game.

Most of the managers in this game are specific to the gameplay and specific to the game screen. The only exception is the sound manager, which is used throughout the game application.

As already mentioned, managers will also have logic that is specific to the group of sprites or functions that it manages. These functions will be globally available anywhere in the application via the name declaration of the manager.

Here are some examples:

```lua
BodyManager.calcNextHeadPos()
StateManager.isCrankMoving()
UiManager.updateScore()
```

Another reason for this type of grouping is to improve function searching performance in Lua.

More on this in the [global class calls](#global-class-calls) section.

#### Sound Manager

Unlike other managers, the sound manager does not run on a specific screen, but runs during the whole duration of the game.

On top of the other common methods, this  manager also contains a couple of specific methods:

1. **`SoundManager.init()`**, used to start the Playdate's Audio Runtime.
2. **`SoundManager.update()`**, required to be executed during the main update function.

The function **`teardown()`** does not exist in the manager as the teardown of the manager is not required. The clean up in theory happens during the closure or exit of the game already handled by the Playdate OS.

## Implementation Details

During the creation of the game, there have been some note worthy features, implementations or weird tricks that I wanted to highlight.

### Snake Movement

Initially like any other snake game, the creation of the snake itself can be pretty simple. A snake can be made out of smaller parts that are stored in an array of some kind (in case of Lua, a integer indexed table). This is how the snake is implemented in this game, with the head and tail ends of the array representing the head and tail of the snake respectively. It's only the illusion of the images that make the snake look like a single continuous object.

For the snake to move, you can create a loop that iterates through the array, moving the head of the snake in the desired direction and then moving the rest of the snake body to the location of the previous body part. In essence, moving every snake part along one at a time.

The issue with this approach is as the snake gets bigger the iteration of the array would be also getting longer as well, making the snake move more difficult to perform with every frame and in turn tanking the performance of the game in the process.

Upon closer inspection of the overall snake movement, it can be observed that with every completed move of the snake, only the head and the tail are moved, whilst the rest of the body appears to be static. This could be have been aided by the fact that the simple art of the snake's body doesn't have any distinct features, so even if the iteration loop was so perfectly tuned, you would only ever simply see the resulting head and tail move.

So to improve the time complexity of the snake movement currently sitting at `O(n)`, the logic had been changed to:

1. Take the tail and move it ahead of the snake's head to indicate the next location of the head.
2. Perform collision detection of the new location of the moved tail to see if it's a valid location.
3. If location is valid:
    1. Change the sprite image of the tail to be the new head of the snake.
    2. Use the directional inputs of the player to determine to the orientation of the new head.
    3. Use the same inputs to determine the sprite image of the snake's "neck" (previously the head).
    4. Change the sprite image of the new tail.
4. If location is invalid:
    1. Move the snake tail back to the original location
    2. Pause the game and do whatever is required to indicate a crash.

Performing the snake movement in this manner ensures that the snake can move in `O(1)` time complexity regardless of the size of the snake.

Some additional steps had to be included in order to make the SDK play nicely with the logic described above, but those could be found in the logic itself, sound in `BodyManager.moveSnake()`.

### Score and Multiplier

In many cases, this could be considered the hardest part of the game to design even if it is simple to implement.

The game of snake is very recognisable and most of the players that play the game for the first time understood the mechanics of the game pretty quickly, but understanding the scoring was tricker to explain intuitively.

To solve for this I had added:
1. Tutorial screens to explain the scoring system.
2. Added sounds to the multiplier to indicate every higher multipliers.
3. Added a sound for the division of the multiplier.

When it comes to the idea of scoring, I decided to keep it simple by having the score increase by 1 every time the snake eats the apple and the multiplier would increase the jump in score for every apple eaten in quick succession.

>Note on food/apple: I interchange between the terms "food" and "apple" quite frequently. They are the same thing and I hope it's obvious.

Initially, I had a multiplier timer that ticks down every 3 seconds and resets every time the snake eats the apple. If that timer is ever allowed to be run down, the multiplier would have been completely lost and reset to 1.

This on the side was a good length of time in conjunction with the snake movement, as it was just enough time for the head of the snake reach about 50-60% of the screen. If the player was the reach every corner of the screen quickly enough to not loose out on the multiplier, the player was forced to used the wrapped arena to get to the apple as quickly as possible. The wrapped nature of the area also gave the players additional complexity of needing to check the other side of the screen to ensure that the snake wouldn't just collide with the snake body on the other side of the arena.

Whist this was a handy little gameplay loop, after some play testing the feedback that I received is that it was very difficult to get to the higher scores for the novices.

I improved on this by only halving the multiplier (rounded down) instead of resetting the score. This gave players more of an incentive to keep up the multiplier and to chase the higher multipliers as it meant that they wouldn't be completely demoralised by the complete loss of their multiplier and gave those players more of an incentive to "pick themselves up" an carry on playing.

In future iterations of the game, it might be interesting to see if it is possible to save the state of the multiplier too and how that would change the game for the players. Would players try to intentionally crash or rewind the game to preserve the multiplier?

### Sound effects

Sound was unfortunately the last item on my ever expanding to-do list. Besides the art, sound effects and music are my other weaknesses when it comes to solo game design.

Fortunately for me Panic had a small sounds and songs editor for [Pulp](https://play.date/dev/#cardPulp), the small browser based game creation tool. With it also came the Pulp Audio Realtime engine that I ended up using to play any sound effects that I had designed in this user friendly web editor.

As described in the [score and multiplier](#score-and-multiplier) section, the sound effects created were mostly created to indicate to the player what was happening without then needing to worry about looking at all elements of the UI, other than the score and how many times they had left to rewind.

All of the sounds that exist in this game are:
  - Eating (increase in tone for an ever higher multiplier)
  - Growth (similar to eating sounds with an extra tone, with an ever higher multiplier)
  - Eating in reverse (played during the rewind game state)
  - Growth in reverse (played during the rewind game state)
  - Hit/Crash into the snake body
  - Good end of the game, with score that landed you on the leaderboard
  - Bad end of the game, with a score of 0 or a score that landed you outside the leaderboard threshold

### Screen Shake

Whist it gives the hit a bit more of an impact, the implementation was not too difficult to pull of.

Having said that, this idea and the detailed implementation was not done by me, but was taken from a more seasoned developer SquidGodDev ([YouTube](https://www.youtube.com/@SquidGodDev), [GitHub](https://github.com/SquidGodDev), [Itch.io](https://squidgod.itch.io/)). 

The implementation detail can be more specifically explained in his [video](https://youtu.be/BG-pbLrY3ro?t=896) and my implementation can be found in `UiManager.startScreenShake` and `UiManager.updateScreenShake()`:

```lua
function UiManager.startScreenShake()
  this.shakeOngoing = true
  this.shakeAmount = SHAKE_AMOUNT
end


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
```

The maths part of the implementation was borrowed but unlike the video, my implementation relied on the use of `this.shakeOngoing` boolean variable to work out if the screen shake should be performed, with the function being called once a frame due the the `GameScreen.update()` calls. The `this.shakeAmount` (also borrowed) simply determines the severity of the shake and is reduced every time the update function is called. Once it hits 0 shame amount, it means that the shake has stopped/ended.

### Rewind

The minute I saw the crank and wanted to make the snake game, I had to introduce a rewind mechanic.

One of my favourite games are the Prince of Persia series. Having played the early DOS versions and then discovering the Sands of Time trilogy of games in the early 2000's, I fell in love with the rewind mechanic and how it changed gameplay.

Whilst the rewind mechanic was not fully fleshed out (for example, could I allow the player to just rewind at any time rather then just at the time that they crashed the snake into itself?), I decided to keep it simple and use the rewind mechanic as a form of a lives system.

Instead of giving the player the standard 3 lives, I would instead give them 3 opportunities to avoid ending the game.

The implementation of this mechanic could be found in `StateManager`:

>The following code has been simplified for explanation purposes.

```lua
local function saveGameState()
  local state = {}
  state[1] = input.last
  state[2] = FoodManager.saveGameState()
  state[3] = BodyManager.saveGameState()
  state[4] = UiManager.saveGameState()
  state[5] = SoundManager.saveGameState()

  table.insert(this.gameStateMap, 1, state)
end

local function loadGameState()
    local state = this.gameStateMap[this.currentStatePos]

    input.next = state[1]
    FoodManager.loadGameState(state[2])
    BodyManager.loadGameState(state[3])
    UiManager.loadGameState(state[4])
    SoundManager.playGameState(state[5])
  end
end

function StateManager.resume()
    this.currentStatePos = 1
    StateManager.isPaused(false)
    UiManager.decRewindLimit()
  end
end
```

In this implementation, the game saves the state to the necessary elements (input, apple position, snake position and so on) every time the snake moves. This is the basis of the rewind mechanic, in which every state is saved into a game state table to be utilised during the rewind phase to show the player previous states of the game. The lookup of these states will be dictated by the movement of the crank that changes the current state position. Once the player was happy with the chosen state, the resume function will be used to resume the game.

During the development of the game, when I didn't have the Playdate device on hand, I ended up using a considerable amount of memory saving every Sprite object that was available for the snake body. These objects would be very heavy, bulky and would contain a lot of unnecessary information about the snakes body parts that ultimately would never be used in the rewind mechanic.

With this implementation of the rewind mechanic, I was easily using 7 MB of the available 16MB RAM after 5 minutes of playing and running out of memory not long after. With garbage collection kicking in too late, performance hits would have been very visible to the player in the form of stutters and long game pauses.

To avoid the strain on the RAM, I had created another way of changing the snake's body parts in the form of snapshots.

```lua
function Body:saveSnapshot()
  return {
    x = self.x, y = self.y,
    direction = self.direction,
    image = self:getImage()
  }
end

function Body:loadSnapshot(snapshot)
  self:moveTo(snapshot.x, snapshot.y)
  self.direction = snapshot.direction
  self:setImage(snapshot.image)
end
```

The object itself would still be created using the `init()` function of the sprite, but instead of creating lots of accessors for each of the properties that I cared about, I simply combined all of them into function calls for both saving and loading of the snapshots. The save function would be used to save the current "snapshot" of the body part, whist loading would be utilised for applying of the saved snapshot.

This drastically reduced the amount of memory used to save the state of the snake as a whole. Whist the increase in snake size would still increase the usage of memory, the overall usage was reduced by a factor of 8 when other performance optimisations were also accounted for.

### Leaderboard

Ideally the leaderboard would be global or linked online in some way, but due to the lack of SDK support for network connectivity, the leaderboard had been reduced to top 25 for local play.

The leaderboard functionality is also the only bit of functionality that utilises Playdate's onboard storage in order to preserve the leaderboard between different executions of the game, whilst other variables would naturally be reset every time the game has been restarted.

### Global variable calls

During the early days of development, I had utilised Lua's global variables a lot, especially when the game was all written under a single file.

However upon separating the game and screen elements, I had slowly started to learn how global variables were stored and accessed by the language.

>Note on file separation: I have very quickly worked out that the Playdate compiler `pdc` ended up doing a lot of the heavy lifting with importing files throughout the repository into a single `.pdz` file found in the resulting `.pdx` container. The resulting container would also copy over the folders which would look rather odd as they may now look empty, but the compiler has removed the files once it managed to combine all of them into a single `.pdz` file. Some may see this as unnecessary and actual game designers, like *Gregory Kogos* of Omaze from season one set of games, ended up writing the whole of their game in one file. Again, I'm too tied up in code structure for my own liking.

Further reading had lead me to understand that accessing these global variables could be expensive. Even if the Lua language in itself is very fast, unnecessarily polluting the main global variables table can be costly in the long run. Whilst your average desktop CPU might not have any issues with this, the Playdate does not share the same computational power, and was ultimately something that I had to optimise.

This forum post by *Fenris_Wolf* on [Lua variables and function scope: Writing efficient Lua (global vs local)](https://theindiestone.com/forums/index.php?/topic/22812-lua-variables-and-function-scope-writing-efficient-lua-global-vs-local/) is one of a few articles that best explains how to optimise variables for more efficient code. Using this particular technique, I have been able to reduce the number of variables being assigned the global table and in turn improving global search access of such variables.

With this in mind, I had decided that all non-object lives, such as managers and screen, will all contain a single table of the same file name and would contain all variables and functions that require to be called outside of the file. Everything else that would only be accessed within the file would bare the local keyword. In essence, this would be my version of private and public variables.

Here is one example found in the game:

```lua
GameScreen = {
  name = "screen.game",
  isGameRunning = false,
  finalScore = 123,
  enter(),
  update(),
  exit()
}
```

In this globally accessible table, any part of the game is able to see these variables or execute any of these functions. What makes this better then just, for example having a variable `gameScreenName`, is that it would be yet another variable on the large global table of accessible variables that the language would have to skip over in the search for the global variables it's actually trying to find. This would in turn waste computing cycles.

By grouping all of the relevant variables together, it will effectively create a partition of variables that are a lot easier to find.

This could be best summarised by saying, if you wanted to search up a phone number of a business, it would be better if you just looked in a phone book that contained business numbers then a larger book that contained all phone numbers.

The additional bonus here is that it also reads nicely. By reading the variable `GameScreen.name` or function `BodyManager.saveGameState()` you know which function or you are calling, especially if there are multiple implementations.

### Localised variables

In addition to the globalised variables, I had also created a `this` table in every file that contained a set of localised files.

Whist this is not necessary and would not provide any performance benefits, it does bring a benefit to cleaning up variables when they are not needed.

In other parts of the dev notes I have already discussed the idea behind creating specific functions that clean up the screen of assets no longer required. This also includes variables that are now easier to clean up with the reset of the `this` table to be an empty table.

This in turn minimises the use of the available memory and was one of the major changes to the game that helped improve memory usage.

### Garbage collection

The final part of optimisation utilised in the game comes from the [incremental garbage collection](https://www.lua.org/manual/5.4/manual.html#pdf-collectgarbage) found in Lua 5.4.

The incremental garbage collection provides the developer with finer control of when the language should perform garbage collection and for how long to execute that process. This in combination of [weak tables](https://www.lua.org/pil/17.html), you can create efficient tables that clean themselves up, instead of the default behaviour of tables never being garbage collected. This was another reason for introducing the variable `this` in the [localised variables](#localised-variables) (again, even if not strictly required).

As the table representation of the game states constantly changing with every snake move, cleaning up of that table programmatically can only do so much. Adding in garbage collection with combination with weak tables in strategic places can help clean up memory.

Weak tables used in the game are defined like this:

```lua
this.gameStateMap = setmetatable({}, { __mode = "k" })
```

Here are some places garbage collection is performed:
- When the game is paused, as the player hit itself.
- When the game is paused, via the menu button.
- When a new game has been started or restarted.
- When the game is about to be resumed.
- When the game screens are switched via the exit functions.

In addition to this, I have also implemented additional functions to help clean up code, which can be found in the `util.lua` file.

The common thing between all of these particular locations is that the screen is mostly static or has minimal movement or animation. This makes it ideal to perform garbage collection, as any collection that may result in dropped or reduced frames will not be as perceivable as compared to when the snake is moving or when the game is actually played. 

## Conclusion

Thank you for reading.

If you have any questions, corrections or clarifications that you would like to highlight, please see the contributions markdown file found in the root of the project for more information.

Thanks,
Igor.

Copyright (c) 2022 TNMM