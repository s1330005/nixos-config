// Print GPU utilization (%) once per second for eww's deflisten.
// Prefers a discrete GPU (NVIDIA via NVML, then AMD) and falls back to the AMD iGPU.
// libnvidia-ml is dlopen'ed so the binary builds without the NVIDIA headers/libs.
use std::ffi::{c_char, c_int, c_uint, c_ulong, c_void};
use std::fs::{self, File};
use std::io::Write;
use std::mem::transmute;
use std::os::fd::AsRawFd;
use std::path::PathBuf;
use std::process::exit;
use std::ptr::null_mut;
use std::thread::sleep;
use std::time::Duration;

const RTLD_NOW: c_int = 2;

// From libdrm's amdgpu_drm.h
const DRM_IOCTL_AMDGPU_INFO: c_ulong = 0x40206445;
const AMDGPU_INFO_DEV_INFO: u32 = 0x16;
const AMDGPU_IDS_FLAGS_FUSION: u64 = 0x1;
const DEV_INFO_IDS_FLAGS_INDEX: usize = 136 / 8; // offsetof(drm_amdgpu_info_device, ids_flags)

extern "C" {
    fn dlopen(filename: *const c_char, flags: c_int) -> *mut c_void;
    fn dlsym(handle: *mut c_void, symbol: *const c_char) -> *mut c_void;
    fn ioctl(fd: c_int, request: c_ulong, ...) -> c_int;
}

type NvmlDevice = *mut c_void;

#[repr(C)]
#[derive(Default)]
struct NvmlUtilization {
    gpu: c_uint,
    memory: c_uint,
}

type InitFn = unsafe extern "C" fn() -> c_int;
type GetHandleFn = unsafe extern "C" fn(c_uint, *mut NvmlDevice) -> c_int;
type GetUtilFn = unsafe extern "C" fn(NvmlDevice, *mut NvmlUtilization) -> c_int;

#[repr(C)]
struct DrmAmdgpuInfo {
    return_pointer: u64,
    return_size: u32,
    query: u32,
    _query_args: [u32; 4],
}

enum Gpu {
    Nvml { get_util: GetUtilFn, dev: NvmlDevice },
    Sysfs(PathBuf),
}

impl Gpu {
    fn busy_percent(&self) -> u32 {
        match self {
            Gpu::Nvml { get_util, dev } => {
                let mut util = NvmlUtilization::default();
                if unsafe { get_util(*dev, &mut util) } == 0 { util.gpu } else { 0 }
            }
            // Reading fails while a runtime-suspended dGPU is idle
            Gpu::Sysfs(path) => fs::read_to_string(path).ok().and_then(|s| s.trim().parse().ok()).unwrap_or(0),
        }
    }
}

unsafe fn nvml() -> Option<Gpu> {
    let mut lib = dlopen(c"/run/opengl-driver/lib/libnvidia-ml.so.1".as_ptr(), RTLD_NOW);
    if lib.is_null() {
        lib = dlopen(c"libnvidia-ml.so.1".as_ptr(), RTLD_NOW);
    }
    if lib.is_null() {
        return None;
    }

    let init = dlsym(lib, c"nvmlInit_v2".as_ptr());
    let get_handle = dlsym(lib, c"nvmlDeviceGetHandleByIndex_v2".as_ptr());
    let get_util = dlsym(lib, c"nvmlDeviceGetUtilizationRates".as_ptr());
    if init.is_null() || get_handle.is_null() || get_util.is_null() {
        return None;
    }
    let init: InitFn = transmute(init);
    let get_handle: GetHandleFn = transmute(get_handle);

    let mut dev: NvmlDevice = null_mut();
    if init() != 0 || get_handle(0, &mut dev) != 0 {
        return None;
    }
    Some(Gpu::Nvml { get_util: transmute(get_util), dev })
}

fn amdgpu_is_apu(card: &PathBuf) -> Option<bool> {
    let render = fs::read_dir(card.join("device/drm"))
        .ok()?
        .filter_map(|e| e.ok())
        .map(|e| e.file_name().to_string_lossy().into_owned())
        .find(|n| n.starts_with("renderD"))?;
    let fd = File::options().read(true).write(true).open(format!("/dev/dri/{render}")).ok()?;

    let mut dev_info = [0u64; 56];
    let mut req = DrmAmdgpuInfo {
        return_pointer: dev_info.as_mut_ptr() as u64,
        return_size: size_of_val(&dev_info) as u32,
        query: AMDGPU_INFO_DEV_INFO,
        _query_args: [0; 4],
    };
    if unsafe { ioctl(fd.as_raw_fd(), DRM_IOCTL_AMDGPU_INFO, &mut req) } != 0 {
        return None;
    }
    Some(dev_info[DEV_INFO_IDS_FLAGS_INDEX] & AMDGPU_IDS_FLAGS_FUSION != 0)
}

// (gpu_busy_percent path, is_apu) for each amdgpu card
fn amdgpu_cards() -> Vec<(PathBuf, bool)> {
    let Ok(entries) = fs::read_dir("/sys/class/drm") else { return Vec::new() };
    let mut cards: Vec<PathBuf> = entries
        .filter_map(|e| e.ok())
        .filter(|e| {
            let name = e.file_name();
            let name = name.to_string_lossy();
            name.strip_prefix("card").is_some_and(|n| !n.is_empty() && n.bytes().all(|b| b.is_ascii_digit()))
        })
        .map(|e| e.path())
        .collect();
    cards.sort();

    cards
        .into_iter()
        .filter(|c| fs::read_link(c.join("device/driver")).is_ok_and(|d| d.ends_with("amdgpu")))
        .filter_map(|c| {
            let busy = c.join("device/gpu_busy_percent");
            let apu = amdgpu_is_apu(&c)?;
            busy.exists().then_some((busy, apu))
        })
        .collect()
}

fn main() {
    let gpu = unsafe { nvml() }.or_else(|| {
        let cards = amdgpu_cards();
        let pick = |apu: bool| cards.iter().find(|c| c.1 == apu).map(|c| Gpu::Sysfs(c.0.clone()));
        pick(false).or_else(|| pick(true))
    });
    let Some(gpu) = gpu else {
        eprintln!("eww-gpu: no supported GPU found");
        exit(1);
    };

    let mut out = std::io::stdout().lock();
    loop {
        let _ = writeln!(out, "{}", gpu.busy_percent());
        let _ = out.flush();
        sleep(Duration::from_secs(1));
    }
}
