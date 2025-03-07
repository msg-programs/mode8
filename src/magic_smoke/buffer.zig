const mach = @import("mach");
const gpu = mach.gpu;
const m8 = @import("../root.zig");
const con = m8.hardware.constants;

pub const Buffer = struct {
    binding: u32,
    size: u32,
    params: BufferParams,
    buffer: *gpu.Buffer,

    pub fn init(window: anytype, binding: u32, size: u32, name: ?[*:0]const u8, params: BufferParams) Buffer {
        return Buffer{
            .binding = binding,
            .size = size,
            .params = params,
            .buffer = window.device.createBuffer(&gpu.Buffer.Descriptor{
                .label = name,
                .mapped_at_creation = params.mapped_at_creation,
                .usage = params.usage_flags,
                .size = size,
            }),
        };
    }

    pub fn getBindGroupLayoutEntry(self: Buffer) gpu.BindGroupLayout.Entry {
        return gpu.BindGroupLayout.Entry.initBuffer(self.binding, self.params.visibility, self.params.binding_type, false, self.size);
    }

    pub fn getBindGroupEntry(self: Buffer) gpu.BindGroup.Entry {
        return gpu.BindGroup.Entry.initBuffer(self.binding, self.buffer, 0, self.size, 1);
    }

    pub fn write(self: Buffer, window: anytype, offs_bytes: u64, data_slice: anytype) void {
        window.queue.writeBuffer(self.buffer, offs_bytes, data_slice);
    }

    pub fn release(self: Buffer) void {
        self.buffer.release();
    }
};

pub const BufferParams = struct {
    mapped_at_creation: gpu.Bool32,
    usage_flags: gpu.Buffer.UsageFlags,
    visibility: gpu.ShaderStageFlags,
    binding_type: gpu.Buffer.BindingType,

    pub fn genericCompute() BufferParams {
        return BufferParams{
            .mapped_at_creation = .false,
            .usage_flags = .{
                .storage = true,
                .copy_dst = true,
            },
            .visibility = .{
                .compute = true,
            },
            .binding_type = .read_only_storage,
        };
    }

    pub fn genericUniform() BufferParams {
        return BufferParams{
            .mapped_at_creation = .false,
            .usage_flags = .{
                .uniform = true,
                .copy_dst = true,
            },
            .visibility = .{
                .compute = true,
            },
            .binding_type = .uniform,
        };
    }
};
