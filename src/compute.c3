module nogfx_learning::compute;
import nogfx, std::thread, std::time;
import std::io;

const char[] COMPUTE_SPIRV = $embed("shader/compute.comp.spv");

Device* device;
GpuHeap upload;

struct Root @align(16) {
	float* in_buf;
	float* out_buf;
	uint count;
}

fn void* gpu_address(void* cpu) => upload.gpu + ((char*)cpu - upload.cpu);

fn void compute_main() {
	device = nogfx::create_device({
		.desired_compute_queue_count = 1
	})!!;
	defer device.destroy();

	io::printfn("Using %s", device.caps.device_name);

	Pso* pso = device.create_compute_pso({
		.code = COMPUTE_SPIRV,
		.threadgroup_size = {64, 1, 1}
	})!!;
	defer pso.destroy();

	upload = device.create_gpu_heap(64 * 1024 * 1024, CPU_VISIBLE)!!;
	defer upload.destroy();
	ArenaAllocator gpu_mem;
	gpu_mem.init(upload.cpu[..upload.size]);

	const sz BUF_SIZE = 10000;
	float[] in_buf = alloc::alloc_array(&gpu_mem, float, BUF_SIZE);
	float[] out_buf = alloc::alloc_array(&gpu_mem, float, BUF_SIZE);

	for(sz i = 0; i < in_buf.len; i++) {
		in_buf[i] = i;
	}

	Root* root = alloc::new(&gpu_mem, Root, {
		.in_buf = gpu_address(in_buf),
		.out_buf = gpu_address(out_buf),
		.count = BUF_SIZE
	});

	CommandPool *command_pool = device.create_command_pool()!!;
	defer command_pool.destroy();
	TimelineSemaphore* timeline = device.create_timeline_semaphore()!!;
	defer timeline.destroy();

	ulong index = 1;
	// while(true)
	{
		command_pool.reset();
		CommandBuffer* cmd = command_pool.begin_commands()!!;
		
		// cmd.barrier(
		// 	(Stage){.compute}, (Access){.shader_write, .shader_read},
		// 	(Stage){.compute}, (Access){.shader_write, .shader_read}
		// );

		cmd.bind_pso(pso);
		cmd.dispatch(gpu_address(root), { .x = (BUF_SIZE + 63) / 64, .y = 1, .z = 1 });
		// cmd.barrier(
		// 	(Stage){.compute}, {},
		// 	(Stage){.host}, (Access){.host_read}
		// );

		cmd.end();
		TimelinePoint point = {timeline, index};
		device.submit({
			.commands = {cmd},
			.completion = point
		});
		point.wait();
		index += 1;
	}

	for(sz i = 0; i < out_buf.len; i++) {
		if(out_buf[i] != (float)i * 2.0f) {
			io::printfn("Should be %s, got %s", (float)i * 2.0f, out_buf[i]);
			return;
		}
	}
	io::printn("Success");
}