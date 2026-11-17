
+++
date = '2026-11-10T14:09:11+05:45'
draft = false
title = 'Draw, Capsules'
slug = 'Draw, Capsules'
description = 'Starting a from-scratch game engine series in Odin: goals, architecture, and the libraries we will use.'
tags = ['odin', 'game-engine', 'opengl']
categories = ['Game Engine']
series = ['Creating a Game Engine']
weight = 2
+++

Now let's continue the draw for other shapes.

## Solid Capsules


/draw/draw.odin

```odin

//
//--Points code--

Rot :: struct
{
	c : f32,
	s : f32,
}

Transform :: struct
{
	p : [2]f32,
	q : Rot
}


CapsuleData :: struct 
{
	transform      : Transform,
	radius, length : f32, 
	rgba           : RGBA8
}


SolidCapsules :: struct
{
	capsules     : [dynamic]CapsuleData,
	vao, program : u32,
	vbo          : [2]u32,
	uniforms     : gl.Uniforms,
}

solid_capsules_create :: proc(
	capsule : ^SolidCapsules
	) {

	capsule.program, _ = gl.load_shaders_source(
		#load("shaders/solid_capsule.vs"),
		#load("shaders/solid_capsule.fs"),
		)
	check_opengl()

	capsule.uniforms = gl.get_uniforms_from_program(capsule.program)

	//batch_size := i32(len(capsules))
	batch_size : i32 = 512


	vertex_attribute : u32 = 0
	transform_instance : u32 = 1
	radius_instance : u32 = 2
	length_instance : u32 = 3
	color_instance : u32 = 4

	gl.GenVertexArrays(1, &capsule.vao)
	gl.GenBuffers(2, &capsule.vbo[0])

	gl.BindVertexArray(capsule.vao)

	gl.EnableVertexAttribArray(vertex_attribute)
	gl.EnableVertexAttribArray(transform_instance)
	gl.EnableVertexAttribArray(radius_instance)
	gl.EnableVertexAttribArray(length_instance)
	gl.EnableVertexAttribArray(color_instance)

	//Vertex buffer for single quad. The vertex shader expands it to a tight
	//oriented box, so the unit quad is exact.
	a : f32 = 1.0

	vertices : [][2]f32 = {
		{-a, -a},
		{a, -a},
		{-a, a},
		{a, -a},
		{a, a},
		{-a, a},
	}

	gl.BindBuffer(gl.ARRAY_BUFFER, capsule.vbo[0])
	gl.BufferData(
		gl.ARRAY_BUFFER,
		size_of([2]f32) * 6,
		&vertices[0],
		gl.STATIC_DRAW,
		)
	gl.VertexAttribPointer(vertex_attribute, 2, gl.FLOAT, gl.FALSE, 0, 0)

	//
	gl.BindBuffer(gl.ARRAY_BUFFER, capsule.vbo[1])
	gl.BufferData(
		gl.ARRAY_BUFFER,
		int(batch_size * size_of(CapsuleData)),
		nil,
		gl.DYNAMIC_DRAW,
		)

	gl.VertexAttribPointer(
		transform_instance,
		4,
		gl.FLOAT,
		gl.FALSE,
		size_of(CapsuleData),
		offset_of(CapsuleData, transform),
		)
	gl.VertexAttribPointer(
		radius_instance,
		1,
		gl.FLOAT,
		gl.FALSE,
		size_of(CapsuleData),
		offset_of(CapsuleData, radius),
		)
	gl.VertexAttribPointer(
		length_instance,
		1,
		gl.FLOAT,
		gl.FALSE,
		size_of(CapsuleData),
		offset_of(CapsuleData, length),
		)
	gl.VertexAttribPointer(
		color_instance,
		4,
		gl.UNSIGNED_BYTE,
		gl.TRUE,
		size_of(CapsuleData),
		offset_of(CapsuleData, rgba),
		)

	gl.VertexAttribDivisor(transform_instance, 1)
	gl.VertexAttribDivisor(radius_instance, 1)
	gl.VertexAttribDivisor(length_instance, 1)
	gl.VertexAttribDivisor(color_instance, 1)

	check_opengl()

	//Cleanup
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	gl.BindVertexArray(0)
}


solid_capsules_add :: proc(
	capsule : ^SolidCapsules,
	p1, p2 : [2]f32,
	radius : f32,
	rgba : RGBA8,
	) {
	d := p2 - p1

	length := math.sqrt(d.x * d.x + d.y * d.y)
	if length < 0.001 do return

	axis := d / length

	transform : Transform = {
		p = 0.5 * (p1 + p2),
		q = {c = axis.x, s = axis.y},
	}

	append(&capsule.capsules, CapsuleData{transform, radius, length, rgba})
}


solid_capsules_flush :: proc(capsule : ^SolidCapsules, cam : ^Camera) {
	count := i32(len(capsule.capsules))

	if count == 0 do return

	gl.UseProgram(capsule.program)

	proj := camera_build_project_matrix(cam, 0.2)

	gl.UniformMatrix4fv(
		capsule.uniforms["projectionMatrix"].location,
		1,
		gl.FALSE,
		&proj[0][0],
		)
	gl.Uniform1f(
		capsule.uniforms["pixelScale"].location,
		camera_pixel_scale(cam),
		)

	gl.BindVertexArray(capsule.vao)

	gl.BindBuffer(gl.ARRAY_BUFFER, capsule.vbo[1])
	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

	gl.BufferData(
		gl.ARRAY_BUFFER,
		int(count * size_of(CapsuleData)),
		raw_data(capsule.capsules[:]),
		gl.DYNAMIC_DRAW,
		)
	gl.DrawArraysInstanced(gl.TRIANGLES, 0, 6, count)

	gl.Disable(gl.BLEND)
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	gl.BindVertexArray(0)
	gl.UseProgram(0)

	clear(&capsule.capsules)
}

```

## Shaders
/draw/shaders/solid_capsule.vs

```glsl
// SPDX-FileCopyrightText: 2024 Erin Catto
// SPDX-License-Identifier: MIT

#version 330

uniform mat4 projectionMatrix;
uniform float pixelScale;

layout(location=0) in vec2 v_localPosition;
layout(location=1) in vec4 v_instanceTransform;
layout(location=2) in float v_instanceRadius;
layout(location=3) in float v_instanceLength;
layout(location=4) in vec4 v_instanceColor;

out vec2 f_position;
out vec4 f_color;
out float f_length;
out float f_radius;
out float f_thickness;

void main()
{
    f_color = v_instanceColor;
    float radius = v_instanceRadius;
    float length = v_instanceLength;
    // A few pixels of padding so the silhouette can be anti-aliased. This is
    // much smaller than the old 10% + square-quad overdraw for long capsules.
    float pad = 3.0 / pixelScale;
    // Tight oriented box around the capsule (not a square).
    float half_length = 0.5 * length;
    vec2 extents = vec2(half_length + radius + pad, radius + pad);
    // Local position in world units; the fragment SDF works in the same space.
    f_position  = v_localPosition * extents;
    f_length    = length;
    f_radius    = radius;
    f_thickness = pad;
    float x = v_instanceTransform.x;
    float y = v_instanceTransform.y;
    float c = v_instanceTransform.z;
    float s = v_instanceTransform.w;
    vec2 p = f_position;
    p = vec2((c * p.x - s * p.y) + x, (s * p.x + c * p.y) + y);
    gl_Position = projectionMatrix * vec4(p, 0.0, 1.0);
}
```

