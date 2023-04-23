use std::env::consts::ARCH;
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
    ($a:expr, $b:expr) => (format!("{}/{}", $a, $b));
}

fn compile_assembly_code() -> Result<()> {
    shadowed_str!(naked_dir, resolve_path!("src/naked"));

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
