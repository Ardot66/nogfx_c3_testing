module build_shaders;
import std::io;
import std::time;
import std::thread;
import libc;

fn int main(String[] args) {
	foreach(String dir : args[1..]) {
		if(!path::is_dir((Path)dir)) {
			io::printfn("Cannot build shaders in dir '%s', it does not exist", dir);
			return -1;
		}

		path::traverse((Path)dir, fn bool?(Path path, bool is_dir, any data) {
			if(is_dir) {
				return false;
			} else if(!path.ends_with(".frag") && !path.ends_with(".vert")) {
				return false;
			}

			@pool() {
				libc::system(string::tformat_zstr("glslang --target-env vulkan1.4 -o %s.spv %s", path, path));
			};

			return false;	
		}, null)!!;
	}

	return 0;
}