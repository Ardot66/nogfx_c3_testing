#version 460
#extension GL_EXT_buffer_reference : require
#extension GL_EXT_scalar_block_layout : require

struct Vertex { vec4 position; vec2 uv; };
layout(buffer_reference, scalar) readonly buffer Vertices { Vertex values[]; };
layout(set = 0, binding = 0, scalar) uniform Root { mat4 transform; Vertices vertices;} root;

layout(location = 0) out vec2 uv;
layout(location = 1) out vec3 frag_position;

void main()
{
	Vertex vertex = root.vertices.values[gl_VertexIndex];
	vec4 clip_position = root.transform * vertex.position;
	// vec4 clip_position = vertex.position;

	gl_Position = clip_position;
	uv = vertex.uv;
	frag_position = clip_position.xyz;
}