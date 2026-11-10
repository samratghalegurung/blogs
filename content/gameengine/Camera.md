+++
date = '2026-11-09T11:14:11+05:45'
draft = false
title = 'Camera'
slug = 'Camera'
description = 'Starting a from-scratch game engine series in Odin: goals, architecture, and the libraries we will use.'
tags = ['odin', 'game-engine', 'opengl']
categories = ['Game Engine']
series = ['Creating a Game Engine']
weight = 2
+++

## Writing the Draw library

Rendering is the most important part of the engine and also prone to cause performance issue. So we will deal with it first. A game engine will render many types of shapes and textures in arbitrary part of the code. We want to provide simple functions where it can draw shapes and texture of specific color, size and in specific position.

### Box2d 
Since our engine will heavily rely on the box2d library, we will be rendering box2d's shapes and bodies. For rapid prototyping games you want to render shapes and colors first and then put textures on it as textures takes time to work on.
Conveniently for us the box2d's sample code has great [example](https://github.com/erincatto/box2d/blob/main/samples/draw.c) of doing just that. Box2d also exposes a function [b2.DebugDraw](https://box2d.org/documentation/structb2_debug_draw.html), which will call our draw libraries function after we configure it.  
Since the code is written in C we will have to rewrite it in odin. 
Even tho it will be heavily used by box2d, we will use the same library for rendering ImGUI, fonts etc.

API usage sketch for draw
```odin
import t2d_draw "./Tiny2D/Draw"

draw : t2d_draw.Draw


main :: proc(){

  // initiliaize windows and opengl
  // -- 
  window := glfw.CreateWinodw(...)
  
  //Initilize draw, initializes shaders, data strctures for shapes and textures etc.
  t2d_draw.init(&draw)
  
  for !glfw.WindowShouldClose(window)
  {
	  //push things to draw with relevant information
	  t2d_draw.append_circle(&draw.circles, t2d.Circle{
		  radius = 20,
		  position = 2, 2
	  })
	  
	  t2d_draw.append_rectangle(&draw.rectangles, t2d.Rectangle{
		  size = 20, 20,
		  position = 2, 2
	  })
	  
	  t2d_draw.append_textures(&draw.textures, r2d_draw.TextureDraw{
		  id = texture1
		  size = 20, 20
		  position = 20, 20
	  )
	  
	  //Clears the data and calls opengl to draw the elements
	  t2d_draw.flush(&draw)
	  
	  glfw.SwapBuffers()
  }
}
```
### let's start programming!
Create a folder with the name of the engine call is "Tiny2D" for now, this is where the main engine code will reside, now create a new folder called "draw" inside the Tiny2D folder.

Create a file named draw.odin in the draw folder. 

*draw/draw.odin*
```odin
package draw

CameraType :: enum
{
	BOX_2D,
	ORTHO, //Rotation and zoom doesn't matter here, useful for things like imgui
}

Camera :: struct
{
	center         : [2]f32,
	width, height  : i32,
	zoom, rotation : f32,
	type           : CameraType,
}

RGBA8 :: [4]u8

Rot :: struct
{
	c, s : f32, //cosine and sine
}

Transform :: struct
{
	p: [2]f32,
	q: Rot,
}


```

### Camera
We don't want to just write the game code using the screen coordinate as screen size will differ on different resolution and scale,  so we draw everything relative to and according to the camera.
Each level or game could have it's own camera, if you want to draw just on the screen coordinate you can set the zoom =1 and width and height of the camera as screen's resolution.

Camera coordination can also be referred as world coordination as box2d uses it.

Now let's create functions related to camera. 

```odin
camera_reset_view :: proc(
	camera : ^Camera
){
	camera.center = {0, 0}
	camera.zoom = 1
}

camera_init :: proc() -> Camera 
{
	c : Camera = {
		width    = 1920,
		height   = 1080,
		zoom     = 1,
		center   = {1920/2, 1080/2}
	}
	camera_reset_view(&c)
	return c
}

//Takes in a vector that is screen's pixel coordinate and converts it to world's coordinate (according to the camera)
camera_convert_screen_to_world_64 :: proc(
	cam : ^Camera,
	ps : [2]f64,
	) -> [2]f32 {

	ps_32 :[2]f32= {f32(ps.x), f32(ps.y)}
	return camera_convert_screen_to_world_32(cam, ps_32)
}

camera_convert_screen_to_world_32 :: proc(
	cam : ^Camera,
	ps : [2]f32,
	) -> [2]f32 {

	ps :[2]f32= {f32(ps.x), f32(ps.y)}

	w := f32(cam.width)
	h := f32(cam.height)
	
	//Get normalized coordinates to the camera's width and height
	u := ps.x / w
	v := (h - ps.y) / h


	ratio := w / h
	extents : [2]f32 = {cam.zoom * ratio, cam.zoom}

	lower := cam.center - extents
	upper := cam.center + extents

	pw : [2]f32 = {
		(1.0 - u) * lower.x + u * upper.x,
		(1.0 - v) * lower.y + v * upper.y,
	}
	return pw
}

camera_convert_screen_to_world  :: proc
{
	camera_convert_screen_to_world_32,
	camera_convert_screen_to_world_64
}

camera_convert_world_to_screen :: proc(
	cam : ^Camera,
	pw : [2]f32,
	) -> [2]f32
{
	cam := cam
	pw := pw

	w := f32(cam.width)
	h := f32(cam.height)

	switch cam.rotation {
		case 1 ..= 90, 180 ..= 270:
		pw = swizzle(pw, 1, 0)
		pw.y = -pw.y
	}
	ratio := w / h

	extents : [2]f32 = {cam.zoom * ratio, cam.zoom}

	rotated_pw := pw
	lower := cam.center - extents
	upper := cam.center + extents


	u := (rotated_pw.x - lower.x) / (upper.x - lower.x)
	v := (rotated_pw.y - lower.y) / (upper.y - lower.y)

	ps : [2]f32 = {u * w, (1.0 - v) * h}
	return ps
}
```


Here we've created functions to convert from screen coordinate to world coordinate and vice versa. We normalize the input points into u/v coordinates in between 0 and 1. Then we multiply it with the camera's or screen's bounds.



