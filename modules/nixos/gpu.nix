{
  # AMD iGPU + NVIDIA dGPU (PRIME offload)
  hardware.graphics.enable = true;

  hardware.amdgpu.opencl.enable = true;
  # Load amdgpu early so the console font isn't reset
  hardware.amdgpu.initrd.enable = true;

  services.xserver.videoDrivers = [
    "amdgpu"
    "nvidia"
  ];

  hardware.nvidia = {
    powerManagement.enable = true;
    open = false;
    nvidiaSettings = false;
    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;
      amdgpuBusId = "PCI:5:0:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  environment.variables.VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json";
}
