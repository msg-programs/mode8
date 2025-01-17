const mach = @import("mach");
const gpu = mach.gpu;
const m8 = @import("../root.zig");
const con = m8.hardware.constants;
const reg = m8.hardware.registers;
const mem = m8.hardware.memory;
const bsp = m8.bsp;
const std = @import("std");
const Buffer = @import("./buffer.zig").Buffer;
const BufferParams = @import("./buffer.zig").BufferParams;

pub var texture: *gpu.Texture = undefined;
pub var texture_view: *gpu.TextureView = undefined;
var compute_pipeline: *gpu.ComputePipeline = undefined;
var output_bind_group: *gpu.BindGroup = undefined;
var memory_bind_group: *gpu.BindGroup = undefined;
var rendering_bind_group: *gpu.BindGroup = undefined;

var gcm_buffer: Buffer = undefined;
var tgm_buffer: Buffer = undefined;
var tam_buffer: Buffer = undefined;
var ogm_buffer: Buffer = undefined;
var oam_buffer: Buffer = undefined;

var setting_buffer: Buffer = undefined;
var bgxform_buffer: Buffer = undefined;
var window_buffer: Buffer = undefined;

pub fn init(core: *mach.Core.Mod) void {
    const generic_compute = BufferParams.genericCompute();
    gcm_buffer = Buffer.init(core, 0, con.GCM_SZE_BYT, "GCM", generic_compute);
    tgm_buffer = Buffer.init(core, 1, con.TGM_SZE_BYT, "TGM", generic_compute);
    tam_buffer = Buffer.init(core, 2, con.TAM_SZE_BYT, "TAM", generic_compute);
    ogm_buffer = Buffer.init(core, 3, con.OGM_SZE_BYT, "OGM", generic_compute);
    oam_buffer = Buffer.init(core, 4, con.OAM_SZE_BYT, "OAM", generic_compute);

    const comp_buffer_size = 4 * 8;
    const bgxf_buffer_size = ((con.DMA_NUM * con.BG_NUM) * 4 * 8) + (2 * 2 * con.DMA_NUM) + 4;
    const window_buffer_size = (con.DMA_NUM * con.WINDOW_NUM) * 2 + 4 + 4 + 4;

    setting_buffer = Buffer.init(core, 0, comp_buffer_size, "Settings", generic_compute);
    bgxform_buffer = Buffer.init(core, 1, bgxf_buffer_size, "BG transform + CMath", generic_compute);
    window_buffer = Buffer.init(core, 2, window_buffer_size, "Windows", generic_compute);

    setupTexture(core);
    setupPipeline(core);
    setupBindGroups(core);
}

pub fn deinit() void {
    texture.release();
    texture_view.release();
    compute_pipeline.release();
    output_bind_group.release();
    memory_bind_group.release();
    rendering_bind_group.release();

    gcm_buffer.release();
    tgm_buffer.release();
    tam_buffer.release();
    ogm_buffer.release();
    oam_buffer.release();

    setting_buffer.release();
    bgxform_buffer.release();
    window_buffer.release();
}

fn setupPipeline(core: *mach.Core.Mod) void {
    const ppu_module = core.state().device.createShaderModuleWGSL("ppu.wgsl", @embedFile("ppu.wgsl"));
    defer ppu_module.release();

    const output_group = core.state().device.createBindGroupLayout(
        &gpu.BindGroupLayout.Descriptor.init(.{
            .label = "Quad texture",
            .entries = &.{
                gpu.BindGroupLayout.Entry.storageTexture(0, .{ .compute = true }, .write_only, .rgba8_unorm, .dimension_2d),
            },
        }),
    );
    defer output_group.release();

    const memory_group = core.state().device.createBindGroupLayout(
        &gpu.BindGroupLayout.Descriptor.init(.{
            .label = "Memory",
            .entries = &.{
                gcm_buffer.getBindGroupLayoutEntry(),
                tgm_buffer.getBindGroupLayoutEntry(),
                tam_buffer.getBindGroupLayoutEntry(),
                ogm_buffer.getBindGroupLayoutEntry(),
                oam_buffer.getBindGroupLayoutEntry(),
            },
        }),
    );
    defer memory_group.release();

    const rendering_group = core.state().device.createBindGroupLayout(
        &gpu.BindGroupLayout.Descriptor.init(.{
            .label = "Rendering",
            .entries = &.{
                setting_buffer.getBindGroupLayoutEntry(),
                bgxform_buffer.getBindGroupLayoutEntry(),
                window_buffer.getBindGroupLayoutEntry(),
            },
        }),
    );
    defer rendering_group.release();

    const pipeline_layout = core.state().device.createPipelineLayout(
        &gpu.PipelineLayout.Descriptor.init(.{
            .bind_group_layouts = &.{
                output_group,
                memory_group,
                rendering_group,
            },
        }),
    );
    defer pipeline_layout.release();

    compute_pipeline = core.state().device.createComputePipeline(&.{
        .compute = gpu.ProgrammableStageDescriptor.init(.{
            .module = ppu_module,
            .entry_point = "main",
        }),
        .layout = pipeline_layout,
    });
}

fn setupBindGroups(core: *mach.Core.Mod) void {
    const output_bind_group_layout = compute_pipeline.getBindGroupLayout(0);
    defer output_bind_group_layout.release();
    const memory_bind_group_layout = compute_pipeline.getBindGroupLayout(1);
    defer memory_bind_group_layout.release();
    const rendering_bind_group_layout = compute_pipeline.getBindGroupLayout(2);
    defer rendering_bind_group_layout.release();

    output_bind_group = core.state().device.createBindGroup(
        &gpu.BindGroup.Descriptor.init(.{
            .label = "Quad texture",
            .layout = output_bind_group_layout,
            .entries = &.{
                gpu.BindGroup.Entry.textureView(0, texture_view),
            },
        }),
    );

    memory_bind_group = core.state().device.createBindGroup(
        &gpu.BindGroup.Descriptor.init(.{
            .label = "Memory",
            .layout = memory_bind_group_layout,
            .entries = &.{
                gcm_buffer.getBindGroupEntry(),
                tgm_buffer.getBindGroupEntry(),
                tam_buffer.getBindGroupEntry(),
                ogm_buffer.getBindGroupEntry(),
                oam_buffer.getBindGroupEntry(),
            },
        }),
    );
    rendering_bind_group = core.state().device.createBindGroup(
        &gpu.BindGroup.Descriptor.init(.{
            .label = "Rendering",
            .layout = rendering_bind_group_layout,
            .entries = &.{
                setting_buffer.getBindGroupEntry(),
                bgxform_buffer.getBindGroupEntry(),
                window_buffer.getBindGroupEntry(),
            },
        }),
    );
}

fn setupTexture(core: *mach.Core.Mod) void {
    texture = core.state().device.createTexture(&.{
        .size = .{
            .width = con.SCREEN_DIM_PIX,
            .height = con.SCREEN_DIM_PIX,
        },
        .format = .rgba8_unorm,
        .usage = .{
            .texture_binding = true,
            .storage_binding = true,
            .copy_dst = true,
            .render_attachment = true,
        },
    });

    texture_view = texture.createView(&gpu.TextureView.Descriptor{
        .format = .rgba8_unorm,
        .dimension = .dimension_2d,
    });
}

fn updateTAM() void {
    tam_buffer.write(0, mem.TAM[0..]);
}

fn updateTGM() void {
    tgm_buffer.write(0, mem.TGM[0..]);
}

fn updateOGM() void {
    ogm_buffer.write(0, mem.OGM[0..]);
}

fn updateOAM() void {
    oam_buffer.write(0, mem.OAM[0..]);
}

fn updateGCM() void {
    gcm_buffer.write(0, mem.GCM[0..]);
}

fn updateSett() void {
    var data: [8]u32 = .{
        bsp.bits.sto4x8in32(
            reg.prio_remap,
            reg.fix_sub,
            reg.to_main,
            reg.to_sub,
        ),
        bsp.bits.sto4x8in32(
            bsp.bits.sto2x4in8(@truncate(reg.xscroll_do_dma), @truncate(reg.yscroll_do_dma)),
            bsp.bits.sto2x4in8(@truncate(reg.affine_x0_do_dma), @truncate(reg.affine_y0_do_dma)),
            bsp.bits.sto2x4in8(@truncate(reg.affine_a_do_dma), @truncate(reg.affine_b_do_dma)),
            bsp.bits.sto2x4in8(@truncate(reg.affine_c_do_dma), @truncate(reg.affine_d_do_dma)),
        ),
        bsp.bits.sto4x8in32(
            bsp.bits.sto2x4in8(@truncate(reg.dma_dir), @truncate(reg.dma_dir_ex)),
            bsp.bits.sto2x4in8(@truncate(reg.win_bounds_do_dma), 0),
            reg.fixcol_main_do_dma, // XXX wasteful smh
            reg.fixcol_sub_do_dma,
        ),
        bsp.bits.sto4x8in32(
            reg.mosiac[0],
            reg.mosiac[1],
            reg.oob_setting,
            0,
        ),
        bsp.bits.sto4x8in32(
            reg.bgsz[0],
            reg.bgsz[1],
            reg.bgsz[2],
            reg.bgsz[3],
        ),
        bsp.bits.sto4x8in32(
            reg.bgoffs[0],
            reg.bgoffs[1],
            reg.bgoffs[2],
            reg.bgoffs[3],
        ),
        bsp.bits.sto4x8in32(
            reg.oob_data[0][0],
            reg.oob_data[1][0],
            reg.oob_data[2][0],
            reg.oob_data[3][0],
        ),
        bsp.bits.sto4x8in32(
            reg.oob_data[0][1],
            reg.oob_data[1][1],
            reg.oob_data[2][1],
            reg.oob_data[3][1],
        ),
    };

    setting_buffer.write(0, data[0..]);
}

fn updateBGXForm() void {
    bgxform_buffer.write(con.DMA_NUM * con.BG_NUM * 4 * 0, reg.xscroll[0..]);
    bgxform_buffer.write(con.DMA_NUM * con.BG_NUM * 4 * 1, reg.yscroll[0..]);
    bgxform_buffer.write(con.DMA_NUM * con.BG_NUM * 4 * 2, reg.affine_x0[0..]);
    bgxform_buffer.write(con.DMA_NUM * con.BG_NUM * 4 * 3, reg.affine_y0[0..]);
    bgxform_buffer.write(con.DMA_NUM * con.BG_NUM * 4 * 4, reg.affine_a[0..]);
    bgxform_buffer.write(con.DMA_NUM * con.BG_NUM * 4 * 5, reg.affine_b[0..]);
    bgxform_buffer.write(con.DMA_NUM * con.BG_NUM * 4 * 6, reg.affine_c[0..]);
    bgxform_buffer.write(con.DMA_NUM * con.BG_NUM * 4 * 7, reg.affine_d[0..]);
    bgxform_buffer.write(con.DMA_NUM * con.BG_NUM * 4 * 8, reg.fixcol_main[0..]);
    bgxform_buffer.write((con.DMA_NUM * con.BG_NUM * 4 * 8) + (con.DMA_NUM * 2), reg.fixcol_sub[0..]);
    const d: [1]u32 = .{bsp.bits.sto4x8in32(
        reg.math_enable,
        reg.math_algo,
        reg.math_normalize,
        reg.debug,
    )};
    bgxform_buffer.write((con.DMA_NUM * con.BG_NUM * 4 * 8) + (con.DMA_NUM * 4), d[0..]);
}

fn updateWindow() void {
    var offs: u64 = 0;
    window_buffer.write(offs, reg.win_start[0..]);
    offs += (con.DMA_NUM * con.WINDOW_NUM);
    window_buffer.write(offs, reg.win_end[0..]);
    offs += (con.DMA_NUM * con.WINDOW_NUM);

    const data: [2]u32 = .{
        bsp.bits.sto4x8in32(
            reg.win_compose[0],
            reg.win_compose[1],
            reg.win_compose[2],
            0,
        ),
        bsp.bits.sto4x8in32(
            reg.win_to_main,
            reg.win_to_sub,
            reg.win_apply,
            0,
        ),
    };

    window_buffer.write(offs, data[0..]);
}

pub fn doComputePass(encoder: *gpu.CommandEncoder) void {
    updateGCM();
    updateTAM();
    updateTGM();
    updateOAM();
    updateOGM();
    updateSett();
    updateBGXForm();
    updateWindow();

    const pass = encoder.beginComputePass(null);
    defer pass.release();
    pass.setPipeline(compute_pipeline);
    pass.setBindGroup(0, output_bind_group, null);
    pass.setBindGroup(1, memory_bind_group, null);
    pass.setBindGroup(2, rendering_bind_group, null);
    pass.dispatchWorkgroups(16, 16, 1);
    pass.end();
}
