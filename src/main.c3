module nogfx_learning;
import std::gfx, std::io, std::time, nogfx;
import std::math;
import std::thread;

const char[*] TRIANGLE_VERTEX = $embed("shader/triangle.vert.spv");
const char[*] TRIANGLE_FRAGMENT = $embed("shader/triangle.frag.spv");

alias Mat4 = Matrix4x4 {float};
struct CubeVertex {
	float[<4>] position;
	float[<2>] uv;
}

struct CubeRoot @align(16) {
	Mat4 transform;
	CubeVertex* vertices;
}

const float RADIANS_PER_FRAME = 0.5f * math::PI / 180.0f;

const CubeVertex[] CUBE_VERTICES = {
	{ .position = { .x = -1.0f, .y = -1.0f, .z = -1.0f, .w = 1.0f }, .uv = { .x = 0.0f, .y = 1.0f } },
	{ .position = { .x = -1.0f, .y = -1.0f, .z = 1.0f, .w = 1.0f }, .uv = { .x = 1.0f, .y = 1.0f } },
	{ .position = { .x = -1.0f, .y = 1.0f, .z = 1.0f, .w = 1.0f }, .uv = { .x = 1.0f, .y = 0.0f } },
	{ .position = { .x = -1.0f, .y = 1.0f, .z = -1.0f, .w = 1.0f }, .uv = { .x = 0.0f, .y = 0.0f } },

	{ .position = { .x = -1.0f, .y = -1.0f, .z = -1.0f, .w = 1.0f }, .uv = { .x = 1.0f, .y = 1.0f } },
	{ .position = { .x = -1.0f, .y = 1.0f, .z = -1.0f, .w = 1.0f }, .uv = { .x = 1.0f, .y = 0.0f } },
	{ .position = { .x = 1.0f, .y = 1.0f, .z = -1.0f, .w = 1.0f }, .uv = { .x = 0.0f, .y = 0.0f } },
	{ .position = { .x = 1.0f, .y = -1.0f, .z = -1.0f, .w = 1.0f }, .uv = { .x = 0.0f, .y = 1.0f } },

	{ .position = { .x = -1.0f, .y = -1.0f, .z = -1.0f, .w = 1.0f }, .uv = { .x = 1.0f, .y = 0.0f } },
	{ .position = { .x = 1.0f, .y = -1.0f, .z = -1.0f, .w = 1.0f }, .uv = { .x = 1.0f, .y = 1.0f } },
	{ .position = { .x = 1.0f, .y = -1.0f, .z = 1.0f, .w = 1.0f }, .uv = { .x = 0.0f, .y = 1.0f } },
	{ .position = { .x = -1.0f, .y = -1.0f, .z = 1.0f, .w = 1.0f }, .uv = { .x = 0.0f, .y = 0.0f } },

	{ .position = { .x = -1.0f, .y = 1.0f, .z = -1.0f, .w = 1.0f }, .uv = { .x = 1.0f, .y = 0.0f } },
	{ .position = { .x = -1.0f, .y = 1.0f, .z = 1.0f, .w = 1.0f }, .uv = { .x = 0.0f, .y = 0.0f } },
	{ .position = { .x = 1.0f, .y = 1.0f, .z = 1.0f, .w = 1.0f }, .uv = { .x = 0.0f, .y = 1.0f } },
	{ .position = { .x = 1.0f, .y = 1.0f, .z = -1.0f, .w = 1.0f }, .uv = { .x = 1.0f, .y = 1.0f } },

	{ .position = { .x = 1.0f, .y = 1.0f, .z = -1.0f, .w = 1.0f }, .uv = { .x = 1.0f, .y = 0.0f } },
	{ .position = { .x = 1.0f, .y = 1.0f, .z = 1.0f, .w = 1.0f }, .uv = { .x = 0.0f, .y = 0.0f } },
	{ .position = { .x = 1.0f, .y = -1.0f, .z = 1.0f, .w = 1.0f }, .uv = { .x = 0.0f, .y = 1.0f } },
	{ .position = { .x = 1.0f, .y = -1.0f, .z = -1.0f, .w = 1.0f }, .uv = { .x = 1.0f, .y = 1.0f } },

	{ .position = { .x = -1.0f, .y = -1.0f, .z = 1.0f, .w = 1.0f }, .uv = { .x = 0.0f, .y = 1.0f } },
	{ .position = { .x = 1.0f, .y = -1.0f, .z = 1.0f, .w = 1.0f }, .uv = { .x = 1.0f, .y = 1.0f } },
	{ .position = { .x = 1.0f, .y = 1.0f, .z = 1.0f, .w = 1.0f }, .uv = { .x = 1.0f, .y = 0.0f } },
	{ .position = { .x = -1.0f, .y = 1.0f, .z = 1.0f, .w = 1.0f }, .uv = { .x = 0.0f, .y = 0.0f } },
};

const ushort[] CUBE_INDICES = {
	0, 1, 2, 2, 3, 0,
	4, 5, 6, 6, 7, 4,
	8, 9, 10, 10, 11, 8,
	12, 13, 14, 14, 15, 12,
	16, 17, 18, 18, 19, 16,
	20, 21, 22, 22, 23, 20,
};

struct Vertex
{
	float[<4>] position;
	float[<4>] color;
}

struct DrawRoot
{
	Vertex* vertices;
}

struct FrameData
{
	DrawRoot root @align(16);
	Vertex[6] vertices @align(16);
}

const uint FRAMES = 2;

Device* device;
GpuHeap upload;
ArenaAllocator gpu_mem;
TextureHeap tex_heap;
CommandPool*[FRAMES] pools;
TimelineSemaphore* timeline;
ulong timeline_start;
ulong frame_count;
Pso* pso;

Texture* depth;
ulong depth_offset;
RenderView* depth_render_view;
uint[<2>] depth_extent;

Mat4 view;
CubeVertex[] vertex_allocation;
ushort[] index_allocation;
CubeRoot[] roots;

TextureDescriptorHeap* texture_descriptor_heap;
SamplerDescriptorHeap* sampler_descriptor_heap;

fn void* gpu_address(void* cpu) => upload.gpu + ((char*)cpu - upload.cpu);

fn void draw(GfxWindow* win, GfxRect rect)
{
	ulong frame = frame_count + 1;
	if (frame > FRAMES)
	{
		TimelinePoint previous = { timeline, timeline_start + frame - FRAMES };
		previous.wait();
	}
	CommandPool* pool = pools[frame % FRAMES];
	pool.reset();
	CommandBuffer* cmd = pool.begin_commands()!!;
	SwapchainFrame target = cmd.acquire();
	if (!target.render_view || target.extent.x == 0 || target.extent.y == 0) return;

	// Window resize?
	if(target.extent.x != depth_extent.x || target.extent.y != depth_extent.y) {
		if(depth) {
			(TimelinePoint){timeline, timeline_start + frame - 1}.wait();
		}

		if(depth != null) {
			depth_render_view.destroy();
			depth.destroy();
		}
		TextureDesc tex_desc = {
			.extent = {...target.extent, 1},
			.format = D32_FLOAT,
			.usage = {.depth_stencil_attachment},
		};
		depth = device.create_texture(tex_desc, tex_heap, depth_offset)!!;
		cmd.initialize_texture(depth);
		depth_render_view = depth.create_render_view()!!;
		depth_extent = {target.extent.x, target.extent.y};
	}

	cmd.set_texture_descriptor_heap(texture_descriptor_heap);
	cmd.set_sampler_descriptor_heap(sampler_descriptor_heap);

	cmd.barrier(
		(Stage){.depth_stencil_tests}, (Access){.depth_stencil_write},
		(Stage){.depth_stencil_tests}, (Access){.depth_stencil_write},
	);

	cmd.begin_render_pass({
		.colors = {{
			.render_view = target.render_view,
			.load = CLEAR,
			.clear = {.x = 0.2f, .y = 0.2f, .z = 0.2f, .w = 0.2f }
		}},
		.depth = {
			.render_view = depth_render_view,
			.load = CLEAR,
			.store = DISCARD,
			.clear = 1.0f,
		}
	});

	cmd.set_depth_stencil({.depth_test = true, .depth_write = true});
	cmd.bind_pso(pso);

	Mat4 projection = matrix::perspective(
		45.0f * math::PI / 180.0f, 
		(float)target.extent.x / (float)target.extent.y,
		0.1f,
		100.0f,
	);
	projection.m11 *= -1;

	CubeRoot* root = &roots[frame % FRAMES];
	root.vertices = gpu_address(vertex_allocation.ptr);
	root.transform = projection * view * matrix::IDENTITY4.rotate_y(RADIANS_PER_FRAME * (float)frame_count);

	cmd.draw_indexed(
		gpu_address(root),
		{gpu_address(index_allocation.ptr), index_allocation.len * ushort::size},
		UINT16,
		index_allocation.len
	);

	cmd.end_render_pass();
	cmd.end();

	frame_count = frame;
	device.submit_and_present({ .commands = { cmd }, .completion = { timeline, timeline_start + frame } });
}

fn int main()
{
	gfx::init("NoGraphicsAPI Vulkan Triangle", { .init_vulkan = true })!!;
	defer gfx::finalize();

	GfxWindow* win = gfx::create_window("NoGraphicsAPI Vulkan Triangle", 200, 200, 900, 600, {})!!;
	defer win.destroy();

	String[] exts = gfx::get_required_vulkan_extensions();
	ZString[] z_exts = mem::temp_array(ZString, exts.len);
	foreach (i, ext : exts) z_exts[i] = ext.zstr_tcopy();

	SurfaceProvider provider = {
		.required_extensions = z_exts,
		.user_data = win,
		.create_surface = fn ulong?(void* instance, void* data) {
			return (ulong)((GfxWindow*)data).create_vulkan_surface((std::gfx::VkInstance)instance);
		},
		.get_extent = fn Uint2(void* data) {
			GfxWindow* w = (GfxWindow*)data;
			GfxPoint p = w.get_size_in_pixels();
			if (p.x <= 0 || p.y <= 0) p = w.get_size();
			return { (uint)max(p.x, 0), (uint)max(p.y, 0) };
		},
	};

	device = nogfx::create_device({
		.surface_provider = provider,
		.swapchain_format = BGRA8_UNORM,
		.desired_swapchain_image_count = 3,
	})!!;
	defer device.destroy();
	io::printfn("Using %s", device.caps.device_name);


	pso = device.create_graphics_pso({
		.vertex = { .code = TRIANGLE_VERTEX[..] },
		.fragment = { .code = TRIANGLE_FRAGMENT[..] },
		.color_targets = { { .format = BGRA8_UNORM } },
		.depth_format = D32_FLOAT,
		.rasterization = {.cull = NONE},
	})!!;
	defer pso.destroy();

	upload = device.create_gpu_heap(64 * 1024 * 1024, CPU_VISIBLE)!!;
	defer upload.destroy();
	gpu_mem.init(upload.cpu[..upload.size]);

	// frame_ranges = {alloc::alloc_array(&gpu_mem, char, 4096), alloc::alloc_array(&gpu_mem, char, 4096)};
	vertex_allocation = alloc::alloc_array(&gpu_mem, CubeVertex, CUBE_VERTICES.len);
	vertex_allocation[..] = CUBE_VERTICES[..];

	index_allocation = alloc::alloc_array(&gpu_mem, ushort, CUBE_INDICES.len);
	index_allocation[..] = CUBE_INDICES[..];

	roots = alloc::alloc_array(&gpu_mem, CubeRoot, FRAMES);

	const char[] TEXTURE = $embed("lunarg_logo_256x256.rgba8");
	texture_descriptor_heap = device.create_texture_descriptor_heap(1)!!;
	defer texture_descriptor_heap.destroy();
	sampler_descriptor_heap = device.create_sampler_descriptor_heap(1)!!;
	defer sampler_descriptor_heap.destroy();
	tex_heap = device.create_texture_heap(256 * 1024 * 1024)!!;
	defer tex_heap.destroy();

	foreach (&p : pools) *p = device.create_command_pool()!!;
	defer foreach (p : pools) p.destroy();

	timeline = device.create_timeline_semaphore()!!;
	defer timeline.destroy();

	CommandBuffer* cmd = pools[0].begin_commands()!!;

	TextureDesc tex_desc = {
		.extent = {256, 256, 1},
		.format = RGBA8_SRGB,
		.usage = {.sampled, .transfer_destination},
	};
	Texture* tex = device.create_texture(tex_desc, tex_heap, 0)!!;
	depth_offset = (ulong)tex_desc.extent.x * tex_desc.extent.y;
	defer tex.destroy();
	cmd.initialize_texture(tex);

	texture_descriptor_heap.write(0, tex, SAMPLED);
	sampler_descriptor_heap.write(0, {
		.min_filter = NEAREST,
		.mag_filter = NEAREST,
		.address_u = CLAMP_TO_EDGE,
		.address_v = CLAMP_TO_EDGE,
	});

	{
		sz mark = gpu_mem.mark();
		defer gpu_mem.reset(mark);

		char[] temp_image = alloc::alloc_array(&gpu_mem, char, TEXTURE.len);
		temp_image[..] = TEXTURE[..];
		cmd.copy_memory_to_texture({gpu_address(temp_image.ptr), temp_image.len}, tex);
	}

	cmd.end();

	device.submit({
		.commands = {cmd},
		.completion = {timeline, 1},
	});

	TimelinePoint setup_done = {timeline, 1};
	setup_done.wait();
	timeline_start = 10;

	defer depth.destroy();
	defer depth_render_view.destroy();

	view = matrix::look_at({0, 3, 5}, {}, {0, 1, 0});

	win.set_repaint_callback(&draw);

	bool quit = false;
	while (!quit && !win.should_close())
	{
		while (try e = gfx::poll(win))
		{
			switch (e.type)
			{
				case WINDOW_CLOSE:
					quit = true;
				case KEY_PRESSED:
					if (e.key.value == ESCAPE) quit = true;
					if (e.key.value == F11 || e.key.value == F) win.set_fullscreen(!win.is_fullscreen());
				default:
					break;
			}
		}
		draw(win, {});
	}
	device.wait_idle();
	return 0;
}
