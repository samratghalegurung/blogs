
+++
date = '2026-11-09T10:14:11+05:45'
draft = false
title = 'Library Structure'
slug = 'Library Structure'
tags = ['odin', 'game-engine', 'opengl']
categories = ['Game Engine']
series = ['Creating a Game Engine']
weight = 1
+++


In this chapter I want to discuss about how we should structure our engine code. 
A game engine is as we discussed earlier is just a collection of libraries to be used together. Which means that we need to structure our code as a libraries rather than a program. 
I want the user of the engine to be able to write their own code and on top of the library code.
Most importantly I want the user to **control the game loop**. 

Here is how I want the engine API to be consumed, and user's code to be structured.
```odin
package main

import "shared:engine"

//Define user's entity and game structures according to their requirement

Entity :: struct 
{
  using e : engine.Entity,
  name    : string
  //___ user's additional entity attributes
}

Game :: struct 
{
  using e : engine.Game
  entities : [dynamic]Entity
  //___ user's additional game attributes
}

main :: proc()
{
   // initialize game and engine
   game : Game
   engine_state : engine.State
   
   //engine initializes graphics loads textures, levels etc.
   engine.engine_init(&state)
   
   game_init(&game)
   
   for !engine.window_should_close(&state)
   {
	//Engine handles input simulates world 
	//Draws imgui handles edits etc
	engine.update(&state, &game)
	
	game_update(&state, &game)
	
	//Engine draws 
	engine.end(&state)
   }
}
```


Writing code in this way where the user explicitly calls the engine library code rather than engine doing all the things at once allows us to create more modular code. A user can decide to write certain part of the engine code themselves or just use the low level apis of the engine like the draw library. 

What this means for us writing the engine code is we write functions to be used by the user, in a package. The usage code and library code will be separate. 

One of the things I want to achieve using this engine is to create small game prototypes with as less code as possible and the above code seems relatively small. 
### Smaller libraries
In the next chapters we will start working on the Draw library which will be responsible for all the rendering and related shaders and data structures. We will be able to create software just using the libraries. 