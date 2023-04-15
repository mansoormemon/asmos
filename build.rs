use std::env::consts::ARCH;
use std::fs;
use std::io::Result;

macro_rules! shadowed_str {
    ($var:ident, $val:expr) => {
        let $var = $val;
        let $var = $var.as_str();
    }
}

macro_rules! abs_path {
    ($rel_path:expr) => (fs::canonicalize($rel_path).unwrap().into_os_string().into_string().unwrap());
}

macro_rules! resolve_path {
    ($file:expr) => (abs_path!(format!("{}/{}/{}", ROOT_DIR, ARCH, $file)));
}

macro_rules! dyn_concat {
    ($root:expr, $file:expr) => (format!("{}/{}", $root, $file));
}

const ROOT_DIR: &str = "src/kernel/arch";

fn compile_assembly_code() -> Result<()> {
    shadowed_str!(cfg_dir, resolve_path!("cfg"));
    shadowed_str!(naked_dir, resolve_path!("naked"));

    println!("cargo:rerun-if-changed={}", cfg_dir);
    println!("cargo:rerun-if-changed={}", naked_dir);

    cc::Build::new().file(dyn_concat!(naked_dir, "/prelude.s"))
                    .flag(dyn_concat!("-I", naked_dir).as_str())
                    .compile(ARCH);

    Ok(())
}

fn main() -> Result<()> {
    compile_assembly_code()?;

    Ok(())
}
