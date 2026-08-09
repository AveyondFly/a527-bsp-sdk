Author:
Allwinner GPU Team
zhengwanyu@allwinnertech.com

1.概述
本文用于说明在Wayland图显系统上使用mali ddk库构建opengles和vulkan,请用户在使用前务必详细阅读本文档

2.wayland 图显系统

显示系统背景说明：
Linux显示系统最早的是fbdev，实现了framebuffer到显示器的映射，最为简单。
但是随着时代发展，出现了HDMI这样复杂的接口，这些接口需要设置分辨率模式，因此fbdev就不适用了，fbdev仅适合LCD这样的分辨率固定的接口。

KMS的出现就可以比较好解决HDMI等这种需要设置分辨率接口的问题，另外KMS在buffer管理方面重新设计，在图形buffer的管理上面更加灵活；
KMS系统使用了基于DRM-GEM实现的GBM来进行buffer的申请和buffer queue的管理，应用(APP)可以直接操作DRM显示驱动送显。
KMS也是比较比较简单的显示系统，特别适合应用场景简单的方案，因为KMS需要APP自己去操作显示驱动送显，因此，系统中可以同时支持的有送显需求的APP是有限的，
而且不同APP之间要事先约定好送显的图层，否则就会出现送显冲突。所以才说，这种系统只能支持简单场景的方案，比如游戏模拟器方案，整个方案仅有游戏模拟器这一个APP需要送显。

为了支持多APP的方案，就必须要考虑将各个APP送显的buffer进行合成的问题，因为显示控制器能同时承载的图层是有限的，必须要考虑将一部分的图层使用GPU合成一个图层之后再送显。
因此，引入了compositor(合成器)的概念，像wayland/X11这样的模块，最核心的功能就是compositor。它们作为一个service运行在后台，随时接收APP下发的图层，它们负责决定将哪些
图层直接发送到显示控制器的哪个图层通道，哪些图层使用gpu进行合成。 只有这样，才能支持起多个APP同时送显的方案。


2.1.opengles的构建:
相关库:
libEGL.so -> libEGL.so.1
libEGL.so.1 -> libEGL.so.1.4.0
libEGL.so.1.4.0
libgbm.so -> libgbm.so.1
libgbm.so.1 -> libgbm.so.1.0.0
libgbm.so.1.0.0
libGLESv1_CM.so -> libGLESv1_CM.so.1
libGLESv1_CM.so.1 -> libGLESv1_CM.so.1.1.0
libGLESv1_CM.so.1.1.0
libGLESv2.so -> libGLESv2.so.2            //虽然名字为2.0，但是同时包含了3.x和2.x的功能，这个命名是业内通用做法
libGLESv2.so.2 -> libGLESv2.so.2.1.0
libGLESv2.so.2.1.0
libmali.so -> libmali.so.0
libmali.so.0 -> libmali.so.0.32.0
libmali.so.0.32.0
libwayland-egl.so -> libwayland-egl.so.1
libwayland-egl.so.1 -> libwayland-egl.so.1.0.0
libwayland-egl.so.1.0.0


打开buildroot相关配置：
AW_PACKAGE_GPU_UM_PUB=y
AW_PACKAGE_GPU_UM_PUB_DEFAULT_WAYLAND=y


2.2.vulakn的构建:
相关库：
libmali.so -> libmali.so.0              //vulkan的真正实现是在libmali.so里面，libvulkan.so只是一个加载器，libvulkan.so会dlopen libmali.so
libmali.so.0 -> libmali.so.0.32.0
libmali.so.0.32.0
libvulkan.so -> libvulkan.so.1          //预先编译好的vulkan loader，可以使用预先编译好的，也可以使用buildroot自带的
libvulkan.so.1 -> libvulkan.so.1.3.296
libvulkan.so.1.3.296
libVkLayer_window_system_integration.so //vulkan wsi layer, 需要插入vulkan loader中，用于vulkan送显

2.2.1. vulkan loader
vulkan的构建有一些不一样，vulkan APP不是直接访问Mali ddk，而是先访问vulkan loader，
再通过vulkan loader访问mali ddk.

vulkan APP ---> vulkan loader(libvulkan.so) ---> vulkan ICD (gpu DDK, 即libmali.so)

(1)这里的vulkan loader采用了第三方开源vulkan loader(https://github.com/KhronosGroup/Vulkan-Loader), 这是业界通用的做法.
buildroot这里用户可以自己选择是使用我们的GPU工程师预先编译好的libvulkan.so，也可以使用buildroot自带的(BR2_PACKAGE_VULKAN_LOADER=y)


(2)vulkan loader要想成功的找到并加载libmali.so，还需要一个json文件对libmali.so进行描述
mali_icd.json:
{
  "file_format_version" : "1.0.0",
  "ICD": {
      "library_path" : "/usr/lib/libmali.so",
      "api_version" : "1.2.0",
      "device_type" : "VK_DEVICE_TYPE_PHYSICAL_DEVICE"
  }
}

将mali_icd.json需要安装到固定目录:/usr/share/vulkan/icd.d/，这个操作我们在buildroot的mk文件里面做了，
用户仅需正常编译buildroot，此文件会自动安装

2.2.2. vulkan wsi layer
vulkan的构建还有一个特殊的地方，就是需要vulkan wsi layer用于送显.
vulkan的抽象做得颗粒度很小，以至于用于送显的代码，可以抽象出来做成跨平台的。
这里用的vulkan wsi layer使用的是第三方的开源代码(https://github.com/xMeM/vulkan-wsi-layer)，这也是业界通用的做法。

vulkan wsi layer可作为vulkan loader的一个层插入到vulkan loader中，配置方法:
vulkan wsi layer要想插入到vulkan loader中需要一个json文件对vulkan_wsi_layer进行描述
VkLayer_window_system_integration.json:
{
    "file_format_version" : "1.1.2",
    "layer" : {
        "name": "VK_LAYER_window_system_integration",
        "type": "GLOBAL",
        "library_path": "/usr/lib/libVkLayer_window_system_integration.so",
        "api_version": "1.2.191",
        "implementation_version": "1",
        "description": "Window system integration layer",
        "functions": {
            "vkNegotiateLoaderLayerInterfaceVersion": "wsi_layer_vkNegotiateLoaderLayerInterfaceVersion"
        },
        "instance_extensions": [
            {"name" : "VK_KHR_wayland_surface", "spec_version" : "6"},
            {"name" : "VK_KHR_surface", "spec_version" : "25"}
        ],
        "device_extensions": [
            {
                "name" : "VK_KHR_swapchain",
                "spec_version" : "70",
                "entrypoints": [
                    "vkGetPhysicalDeviceDisplayPropertiesKHR",
                    "vkGetPhysicalDeviceSurfaceCapabilitiesKHR",
                    "vkGetPhysicalDeviceDisplayProperties2KHR",
                    "vkGetPhysicalDeviceSurfaceFormatsKHR",
                    "vkGetPhysicalDeviceSurfacePresentModesKHR",
                    "vkGetPhysicalDeviceSurfaceSupportKHR",
                    "vkDestroySurfaceKHR",
                    "vkAcquireNextImageKHR",
                    "vkCreateSwapchainKHR",
                    "vkDestroySwapchainKHR",
                    "vkGetSwapchainImagesKHR",
                    "vkQueuePresentKHR",
                    "vkAcquireNextImage2KHR",
                    "vkCreateImage",
                    "vkBindImageMemory2",
                    "vkGetDeviceGroupPresentCapabilitiesKHR",
                    "vkGetDeviceGroupSurfacePresentModesKHR",
                    "vkGetPhysicalDevicePresentRectanglesKHR"
                ]
            }
        ],
        "enable_environment": {
            "ENABLE_WSI_LAYER": "1"
        },
        "disable_environment": {
            "DISABLE_WSI_LAYER": "1"
        }
    }
}

将VkLayer_window_system_integration.json需要安装到固定目录:/usr/share/vulkan/implicit_layer.d/，这个操作我们在buildroot的mk文件里面做了，
用户仅需正常编译buildroot，此文件会自动安装

另外，运行vulkan app之前，需要先设置环境变量export ENABLE_WSI_LAYER=1，这样vulkan loader才会加载vulkan_wsi_layer

3.demo使用方法
打开buildroot相关配置:
BR2_PACKAGE_VULKAN_LOADER=y (可选)
BR2_PACKAGE_GPU_DEMO=y      (包含了vulkan的测试demo，可选)

(1)运行wayland
export WESTON_AFBC_GBM_MODIFIERS=1
export XDG_RUNTIME_DIR="/tmp/wayland"
weston --backend=drm-backend.so --tty=1 &

(2)运行vulkan demo app
export XDG_RUNTIME_DIR="/tmp/wayland"
export ENABLE_WSI_LAYER=1
vulkan_triangle
