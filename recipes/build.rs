use std::env;
use std::fs;
use std::io::Result;

macro_rules! shadowed_str {
    ($var:ident, $val:expr) => {
        let $var = $val;
        let $var = $var.as_str();
    }
}

macro_rules! resolve_path {
    ($rel_path:expr) => (fs::canonicalize($rel_path).unwrap().into_os_string().into_string().unwrap());
}

macro_rules! dyn_concat {
    ($root:expr, $file:expr) => (format!("{}/{}", $root, $file));
}

#[cfg(target_arch = "x86_64")]
fn cook_prelude() -> Result<()> {
    shadowed_str!(prelude_dir, resolve_path!("src/kernel/arch/x86_64/prelude"));

    println!("cargo:rerun-if-changed={}", prelude_dir);

    cc::Build::new().file(dyn_concat!(prelude_dir, "/main.s"))
                    .flag(dyn_concat!("-I", prelude_dir).as_str())
                    .compile("arch_x86_64");

    Ok(())
}

fn main() -> Result<()> {
    println!("cargo:rustc-env=TARGET={}", env::var("TARGET").unwrap());

    println!("cargo:rerun-if-changed={}", resolve_path!("cfg"));

    cook_prelude()?;

    Ok(())
}
