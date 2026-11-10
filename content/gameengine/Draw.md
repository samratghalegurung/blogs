
+++
date = '2026-11-10T10:09:11+05:45'
draft = false
title = 'Draw'
slug = 'Draw'
description = 'Starting a from-scratch game engine series in Odin: goals, architecture, and the libraries we will use.'
tags = ['odin', 'game-engine', 'opengl']
categories = ['Game Engine']
series = ['Creating a Game Engine']
weight = 2
+++

Let's start drawing some shapes

*draw/draw.odin*
```odin

//..Camera code


PointData :: struct
{
	pos  : [2]f32,
	size : f32,
	rbga : RGBA8
} 

Point :: struct 
{
	vao, vbo, program : u32,
	uniforms          : gl.Uniforms,
	points            : [dynamic]PointData,
}

Draw :: struct 
{
	cam    : Camera,
	points : Point,
	
	//Other shapes
}

//..rough code

//Initialize, initialize shaders and arrays
points_create :: (point : ^Point) //

//Append point to points
points_add :: (point: ^Point, pos : [2]f32, size : f32, rgba : RGBA8)

//Call opengl draw for each point
points_flush  :: proc (point: ^Point)

//Clear all data from points
points_destroy :: proc (point: ^Point)
```
We will repeat the same pattern for all other shapes and textures. i.e ShapeData, Shape containing array of ShapeData and store it in Draw struct, then we will  create shape_create, shape_add, shape_flush  and destroy functions. 

We will also need to write vertex and fragment shaders for each shape, which we will initialize on it's create function. 

Here are the functions for points

draw/draw.odin
```odin

check_opengl :: proc() {
    err := gl.GetError()
    if err != gl.NO_ERROR {
        fmt.eprintf("OpenGL error = %d\n", err)
        assert(false)
    }
}

points_create :: proc(
    point : ^Point
){
	  vs : string = `
	  #version 330
	  uniform mat4 projectionMatrix;
	  layout(location = 0) in vec2 v_position;
	  layout(location = 1) in float v_size;
	  layout(location = 2) in vec4 v_color;
	  out vec4 f_color;
	  void main(void) {
		    f_color = v_color;
		    gl_Position = projectionMatrix * vec4(v_position, 0.0f, 1.0f);
		    gl_PointSize = v_size;
	  }
	  `
	  fs : string = `
        #version 330
        in vec4 f_color;
        out vec4 color;
        void main(void){
            color = f_color;
        }
	  `
	  point.program, _ = gl.load_shaders_source(vs, fs)
	  point.uniforms   = gl.get_uniforms_from_program(point.program)

	  vertex_attribute : u32 = 0
	  size_attribute : u32 = 1
	  color_attribute : u32 = 2

	  gl.GenVertexArrays(1, &point.vao)
	  gl.GenBuffers(1, &point.vbo)

	  gl.BindVertexArray(point.vao)
	  gl.EnableVertexAttribArray(vertex_attribute)
	  gl.EnableVertexAttribArray(size_attribute)
	  gl.EnableVertexAttribArray(color_attribute)

    //Vertex buffer
    gl.BindBuffer(gl.ARRAY_BUFFER, point.vbo)
    gl.BufferData(gl.ARRAY_BUFFER, 2048 * size_of(PointData), nil, gl.DYNAMIC_DRAW,)
    gl.VertexAttribPointer(vertex_attribute, 2, gl.FLOAT, gl.FALSE, size_of(PointData), offset_of(PointData, pos),)
    gl.VertexAttribPointer(size_attribute,   1, gl.FLOAT, gl.FALSE, size_of(PointData), offset_of(PointData, size),)
    gl.VertexAttribPointer(color_attribute,  4, gl.UNSIGNED_BYTE, gl.TRUE, size_of(PointData), offset_of(PointData, rgba),)

	  check_opengl()

	  gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	  gl.BindVertexArray(0)

}

points_destroy :: proc(
    point : ^Point
){
	  if point.vao != 0
    {
        gl.DeleteVertexArrays(1, &point.vao)
        gl.DeleteBuffers(1, &point.vbo)
        point.vao = 0
        point.vbo = 0
    }

	  if point.program != 0 {
		    gl.DeleteProgram(point.program)
		    point.program = 0
	  }
}

points_add :: proc(point : ^Point, v : [2]f32, size : f32, rgba : RGBA8) {
    append(&point.points, PointData{v, size, rgba})
}

//Flush means draw
points_flush :: proc(
    point : ^Point,
    cam   : ^Camera
) {
    count := i32(len(point.points))
    if count == 0 do return

	  gl.UseProgram(point.program)

	  proj := camera_build_project_matrix(cam, 0)

	  gl.UniformMatrix4fv(point.uniforms["projectionMatrix"].location, 1, gl.FALSE, &proj[0][0])

	  gl.BindVertexArray(point.vao)

	  gl.BindBuffer(gl.ARRAY_BUFFER, point.vbo)
	  gl.Enable(gl.PROGRAM_POINT_SIZE)

	  // Re-specifying the store orphans the previous contents, so the driver does
	  // not have to wait for the GPU to stop reading last frame's buffer.
	  gl.BufferData(
		    gl.ARRAY_BUFFER,
		    int(count * size_of(PointData)),
		    raw_data(point.points[:]),
		    gl.DYNAMIC_DRAW,
		)
	  gl.DrawArrays(gl.POINTS, 0, count)

	  gl.Disable(gl.PROGRAM_POINT_SIZE)
	  gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	  gl.BindVertexArray(0)
	  gl.UseProgram(0)
	  clear(&point.points)
}

```


Let's use it in a example code

Tiny2D/samples/example_draw/main.odin

```odin
package main

//The initial code is copied from the intro code

import "core:fmt"
import "vendor:glfw"
import gl "vendor:OpenGL"

import tiny_draw "../../draw"

WIDTH  :: 1600
HEIGHT :: 900
TITLE  :: "Draw Sample !"

draw : tiny_draw.Draw

GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 5

main :: proc()
{
    if !bool(glfw.Init())
    {
        fmt.eprintln("GLFW has failed to load.")
        return
    }


    window_handle := glfw.CreateWindow(WIDTH, HEIGHT, TITLE, nil, nil)

    defer glfw.Terminate()
    defer glfw.DestroyWindow(window_handle)

    if window_handle == nil {
        fmt.eprintln("GLFW has failed to load the window")
        return
    }

    glfw.MakeContextCurrent(window_handle)
    gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address)

    draw.cam = tiny_draw.camera_init()
    draw.cam.width = WIDTH
    draw.cam.height = HEIGHT
    draw.cam.type = .ORTHO

    tiny_draw.points_create(&draw.points)

    for !glfw.WindowShouldClose(window_handle){
        glfw.PollEvents()

        gl.ClearColor(0.5, 0.7, 0.4, 1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT)

        tiny_draw.points_add(&draw.points, {200, 200}, 20, {255, 255, 255, 255})

        tiny_draw.points_flush(&draw.points, &draw.cam)

        glfw.SwapBuffers(window_handle)
    }
}
```

We get the point rendering on the window!

![](/gameengine/Pasted%20image%2020261110144359.png)