use crate::config;
use crate::engine;
use std::mem;

const ROTATION_INTERVAL_MS: i32 = 1800 * 1000; // 30 minutes

struct ScopedFd(libc::c_int);

impl Drop for ScopedFd {
    fn drop(&mut self) {
        if self.0 >= 0 {
            unsafe {
                libc::close(self.0);
            }
        }
    }
}

pub fn run_daemon() -> Result<(), String> {
    // Initial restoration or random pick on service start
    let current = config::get_current_wallpaper();
    let mut restored = false;

    if let Some(ref path) = current {
        if path.is_file() {
            if let Ok(()) = engine::apply_wallpaper(path) {
                restored = true;
            }
        }
    }

    if !restored {
        if let Err(e) = engine::switch_next(false) {
            eprintln!("wallpaper-manager: initial pick warning: {}", e);
        }
    }

    // Set up Linux signalfd for SIGUSR1, SIGTERM, SIGINT
    let sfd = unsafe {
        let mut mask: libc::sigset_t = mem::zeroed();
        libc::sigemptyset(&mut mask);
        libc::sigaddset(&mut mask, libc::SIGUSR1);
        libc::sigaddset(&mut mask, libc::SIGTERM);
        libc::sigaddset(&mut mask, libc::SIGINT);

        if libc::sigprocmask(libc::SIG_BLOCK, &mask, std::ptr::null_mut()) < 0 {
            return Err("Failed to set sigprocmask".to_string());
        }

        let fd = libc::signalfd(-1, &mask, libc::SFD_NONBLOCK | libc::SFD_CLOEXEC);
        if fd < 0 {
            return Err("Failed to create signalfd".to_string());
        }
        ScopedFd(fd)
    };

    println!("wallpaper-manager: daemon running (30 min rotation cycle)");

    loop {
        let mut pfd = libc::pollfd {
            fd: sfd.0,
            events: libc::POLLIN,
            revents: 0,
        };

        let ret = unsafe { libc::poll(&mut pfd, 1, ROTATION_INTERVAL_MS) };

        if ret == 0 {
            // 30-minute timeout expired: pick and apply next wallpaper
            if let Err(e) = engine::switch_next(false) {
                eprintln!("wallpaper-manager: rotation error: {}", e);
            }
        } else if ret > 0 {
            if (pfd.revents & libc::POLLIN) != 0 {
                let mut info: libc::signalfd_siginfo = unsafe { mem::zeroed() };
                let bytes = unsafe {
                    libc::read(
                        sfd.0,
                        &mut info as *mut _ as *mut libc::c_void,
                        mem::size_of::<libc::signalfd_siginfo>(),
                    )
                };

                if bytes as usize == mem::size_of::<libc::signalfd_siginfo>() {
                    match info.ssi_signo as i32 {
                        libc::SIGUSR1 => {
                            // Manual change occurred elsewhere; reset 30-minute interval
                            continue;
                        }
                        libc::SIGTERM | libc::SIGINT => {
                            println!("wallpaper-manager: shutting down cleanly on signal");
                            break;
                        }
                        _ => {}
                    }
                }
            }
        } else {
            let err = std::io::Error::last_os_error();
            if err.raw_os_error() != Some(libc::EINTR) {
                eprintln!("wallpaper-manager: poll warning: {}", err);
                std::thread::sleep(std::time::Duration::from_secs(1));
            }
        }
    }

    Ok(())
}
