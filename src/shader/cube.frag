#version 460
#extension GL_EXT_descriptor_heap : require

layout(location = 0) in vec2 uv;
layout(location = 1) in vec3 frag_position;
layout(location = 0) out vec4 result;

// Sampler array aliased to the sampler heap
layout(descriptor_heap) uniform sampler heapSampler[];

// Different image arrays aliased to the image heap
layout(descriptor_heap) uniform texture2D heapTexture2D[];

void main()
{
	vec3 normal = normalize(cross(dFdx(frag_position), dFdy(frag_position)));
	float light = max(0.0, dot(vec3(0.424, 0.566, 0.707), normal));
	vec4 texel = texture(sampler2D(heapTexture2D[0], heapSampler[0]), uv);

	result = vec4(light * texel.rgb, texel.a);
	// result = vec4(light * uv, 1, 1);
}
