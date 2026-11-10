
+++
date = '2026-11-09'
draft = false
title = 'Creating Window'
slug = 'Creating Window And Some Basic Concepts'
tags = ['odin', 'game-engine', 'opengl']
categories = ['Game Engine']
series = ['Creating a Game Engine']
weight = 1
+++

# Creating Window And Some Basic Concepts

Every operating system exposes their own windowing system, windows has Win32 API, linux has X11 and Wayland and each differs enough so that each case. It will take a lot of code to handle each case differently.  
Libraries like glfw and SDL provides easier way to create and manage windows. They also provide apis to handle input and events. 
Using the OS's API directly would give you more control over the window and might be more performant but we are keeping it simple here.

What we are actually saying to the OS is, "We want you to create a window on your windowing system and give it's handle to me".  

You can refer to [HandmadeHero's Code](https://yakvi.github.io/handmade-hero-notes/html/day2.html) if you want to use win32 API.
We will be using OpenGL for all the rendering, that will require us to create opengl context and attach it to our window, glfw provides a function glfw.MakeContextCurrent which does exactly that.

You can find a basic glfw windows creation example [here](https://pkg.odin-lang.org/examples/glfw/window).  

```odin
package glfw_window

import "core:fmt"
import "vendor:glfw"
import gl "vendor:OpenGL"

WIDTH  	:: 1600
HEIGHT 	:: 900
TITLE 	:: "My Window!"

// @note You might need to lower this to 3.3 depending on how old your graphics card is.
GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 5

main :: proc() {
	if !bool(glfw.Init()) {
		fmt.eprintln("GLFW has failed to load.")
		return
	}
	window_handle := glfw.CreateWindow(WIDTH, HEIGHT, TITLE, nil, nil)
	defer glfw.Terminate()
	defer glfw.DestroyWindow(window_handle)
	if window_handle == nil {
		fmt.eprintln("GLFW has failed to load the window.")
		return
	}
	// Load OpenGL context or the "state" of OpenGL.
	glfw.MakeContextCurrent(window_handle)
	// Load OpenGL function pointers with the specficed OpenGL major and minor version.
	gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address)
	for !glfw.WindowShouldClose(window_handle) {
		// Process all incoming events like keyboard press, window resize, and etc.
		glfw.PollEvents()
		gl.ClearColor(0.5, 0.0, 1.0, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)
		glfw.SwapBuffers(window_handle)
	}
}
```

Let's talk briefly over the code, it's alright if you don't understand it right away we'll tackle it in depth later.

glfw.Init() initializes the library, glfw.CreateWindow creates window but also creates the required opengl context at the backend. 

gl.load_up_to tries to load all the functions that are defined in the OpenGL specification from the OSes graphics driver. it takes in major and minor version as first two argument but the last argument is a function. glfw has a function called gl.set_proc_address, we just pass the function to the function.

The gl.load_up_to function basically calls this set_proc address function for every OpenGL specified functions to load. If we look at the gl_set_proc_address's definition, we can see that it calls GetProcAddress which is a Win32 function who's documentation you can see [here](https://learn.microsoft.com/en-us/cpp/build/getprocaddress?view=msvc-170)

```odin
gl_set_proc_address :: proc(p: rawptr, name: cstring) {
	(^rawptr)(p)^ = GetProcAddress(name)
}
```

### The game loop
A game/game engine is a continuous program that should run till we close it manually. One of the simplest way to achieve this behavior is by creating a loop that runs until certain input is received to close the loop,  after that the game is supposed to to close. 
There are also other ways of doing this like event driven approach, but this is the only way I have written game code my whole life.

#### FPS and more on game loop
Frame Rate or Frames Per Second(FPS) is important this in game programming, it is basically the number of times the loop ran in a second. This number has massive impact on the gameplay and also can be taken as sign of performance of the game. 

 A game with very less code that runs per frame might get FPS of 1000+ which will also be bad. There needs to be way of having precise control of the FPS. 

We also have to understand the the monitor itself has limitation on how many FPS it can handle, older monitors have 60fps and newer monitors have up to 200, So if we run our loop on 1000 fps on 200 fps monitor it will miss 800 of those frame from displaying. 

There are many ways to solve this, we can calculate how much each frame should take i.e for 60 FPS, 1/60 = 0.016 seconds, and at the end of the loop we calculate how much of the 0.016 time is remaining and sleep for that time.
That's exactly how handmade hero does it [here](https://yakvi.github.io/handmade-hero-notes/html/day10.html). A lot of interesting topics like RDTSC are explored here. 
But there is another simpler way we can achieve it by using VSYNC. Since we will be using gpu and opengl to render, GPU has mechanism to wait till next draw according to the monitor's framerate. Which means we just have to turn it on using 
```odin
glfw.SwapInterval(1)
```
. 

### Buffers and rendering
When rendering we don't directly draw to a screen, especially while using rendering libraries like OpenGL, OpenGL has something called framebuffer, it's just a memory chunk that is stored in the GPU, where the pixels get actually written, when when we get to the end of the frame, the GPU puts it on the screen. If you wanna know more about it check out this [link](https://learnopengl.com/Advanced-OpenGL/Framebuffers) from **learnopengl**.  
These framebuffers can be used to solve alot of problems like manipulating textures, merging multiple game screens, applying shaders etc.

