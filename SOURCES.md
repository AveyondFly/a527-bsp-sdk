# Tina AIOT V1.4.6 source pins (product-aiot-stable / cubie-aiot-v1.4.6)

| Component | Upstream | Branch | Commit |
|-----------|----------|--------|--------|
| Kernel base | gitlab.com/tina5.0_aiot/lichee/linux-5.15 | product-aiot-stable | 29b9538ca88c62406c61f0677c68a6fe724a52bf |
| BSP | github.com/radxa/allwinner-bsp | cubie-aiot-v1.4.6 | 2045a3ca2a01f088c0314dc924bda59d154e363e |
| Device config | gitlab.com/tina5.0_aiot/lichee/device/config/a527 | product-aiot-stable | (branch tip at import) |
| libgpu (mali-g57) | gitlab.com/tina5.0_aiot/product/linux/external/libgpu | product-aiot-stable | 7db4f5018bcaae220d8cf40af42171d74c26915d |

Layout:
- `kernel/` — lichee/linux-5.15 with `bsp/` merged (same as Tina SDK build tree)
- `device/` — A527 board DTS, defconfigs, BoardConfig.mk
- `libgpu/mali-g57/` — Mali-G57 DDK userspace (wayland/gbm/vulkan)
