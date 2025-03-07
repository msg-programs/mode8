const mach = @import("mach");
const gpu = mach.gpu;
const ppup = @import("ppu_pipeline.zig");
const std = @import("std");

const Vertex = extern struct {
    pos: @Vector(2, f32),
    uv: @Vector(2, f32),
};

const vertices = [_]Vertex{
    .{ .pos = .{ -1, -1 }, .uv = .{ 1, 1 } },
    .{ .pos = .{ 1, -1 }, .uv = .{ 0, 1 } },
    .{ .pos = .{ 1, 1 }, .uv = .{ 0, 0 } },
    .{ .pos = .{ -1, 1 }, .uv = .{ 1, 0 } },
};

const index_data = [_]u32{ 0, 1, 2, 2, 3, 0 };

var render_pipeline: *gpu.RenderPipeline = undefined;
var vertex_buffer: *gpu.Buffer = undefined;
var index_buffer: *gpu.Buffer = undefined;
var bind_group: *gpu.BindGroup = undefined;

pub fn init(core: *mach.Core, window: mach.ObjectID) void {
    const win = core.windows.getValue(window);
    setupVertexBuffer(win);
    setupIndexBuffer(win);
    setupOutputPipeline(win);
    setupBindGroup(win);
}

pub fn deinit() void {
    render_pipeline.release();
    vertex_buffer.release();
    index_buffer.release();
    bind_group.release();
}

fn setupOutputPipeline(window: anytype) void {
    const vertex_attributes = [_]gpu.VertexAttribute{
        .{ .format = .float32x4, .offset = @offsetOf(Vertex, "pos"), .shader_location = 0 },
        .{ .format = .float32x2, .offset = @offsetOf(Vertex, "uv"), .shader_location = 1 },
    };

    const output_module = window.device.createShaderModuleWGSL("output.wgsl", @embedFile("output.wgsl"));
    defer output_module.release();

    const vertex_buffer_layout = gpu.VertexBufferLayout.init(.{
        .array_stride = @sizeOf(Vertex),
        .step_mode = .vertex,
        .attributes = &vertex_attributes,
    });

    const color_target = gpu.ColorTargetState{
        .format = window.framebuffer_format,
        .blend = &.{},
        .write_mask = gpu.ColorWriteMaskFlags.all,
    };

    const pipeline_descriptor = gpu.RenderPipeline.Descriptor{
        .fragment = &gpu.FragmentState.init(.{
            .module = output_module,
            .entry_point = "frag_main",
            .targets = &.{color_target},
        }),
        .vertex = gpu.VertexState.init(.{
            .module = output_module,
            .entry_point = "vertex_main",
            .buffers = &.{vertex_buffer_layout},
        }),
        .primitive = .{ .cull_mode = .back },
    };

    render_pipeline = window.device.createRenderPipeline(&pipeline_descriptor);
}

fn setupVertexBuffer(window: anytype) void {
    vertex_buffer = window.device.createBuffer(&.{
        .usage = .{ .vertex = true },
        .size = @sizeOf(Vertex) * vertices.len,
        .mapped_at_creation = .true,
    });
    const vertex_mapped = vertex_buffer.getMappedRange(Vertex, 0, vertices.len);
    defer vertex_buffer.unmap();
    @memcpy(vertex_mapped.?, vertices[0..]);
}

fn setupIndexBuffer(window: anytype) void {
    index_buffer = window.device.createBuffer(&.{
        .usage = .{ .index = true },
        .size = @sizeOf(u32) * index_data.len,
        .mapped_at_creation = .true,
    });
    const index_mapped = index_buffer.getMappedRange(u32, 0, index_data.len);
    defer index_buffer.unmap();
    @memcpy(index_mapped.?, index_data[0..]);
}

fn setupBindGroup(window: anytype) void {
    const sampler = window.device.createSampler(
        &.{
            .mag_filter = .nearest,
            .min_filter = .nearest,
        },
    );
    defer sampler.release();

    const bind_group_layout = render_pipeline.getBindGroupLayout(0);
    defer bind_group_layout.release();

    bind_group = window.device.createBindGroup(
        &gpu.BindGroup.Descriptor.init(.{
            .layout = bind_group_layout,
            .entries = &.{
                gpu.BindGroup.Entry.initSampler(0, sampler),
                gpu.BindGroup.Entry.initTextureView(1, ppup.texture_view),
            },
        }),
    );
}

pub fn doRenderPass(window: anytype, encoder: *gpu.CommandEncoder) void {
    const back_buffer_view = window.swap_chain.getCurrentTextureView().?;
    defer back_buffer_view.release();

    const color_attachment = gpu.RenderPassColorAttachment{
        .view = back_buffer_view,
        .clear_value = .{ .r = 0, .g = 0, .b = 0, .a = 1.0 },
        .load_op = .clear,
        .store_op = .store,
    };

    const pass = encoder.beginRenderPass(
        &gpu.RenderPassDescriptor.init(.{
            .color_attachments = &.{color_attachment},
        }),
    );
    defer pass.release();

    pass.setPipeline(render_pipeline);
    pass.setVertexBuffer(0, vertex_buffer, 0, @sizeOf(Vertex) * vertices.len);
    pass.setIndexBuffer(index_buffer, .uint32, 0, @sizeOf(u32) * index_data.len);
    pass.setBindGroup(0, bind_group, &.{});
    pass.drawIndexed(index_data.len, 1, 0, 0, 0);
    pass.end();
}
