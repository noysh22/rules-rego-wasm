"""Rules for compiling Rego policies to WebAssembly (WASM)."""

load("//:toolchain.bzl", "opa_toolchain_type")

def _rego_to_wasm_impl(ctx):
    toolchain = ctx.toolchains[opa_toolchain_type]
    opa = toolchain.opa

    # Collect input files: prefer srcs if provided, fall back to single src for backwards compatibility
    inputs = []
    if hasattr(ctx.attr, "srcs") and ctx.files.srcs:
        inputs = ctx.files.srcs
    elif getattr(ctx.file, "src", None) != None:
        inputs = [ctx.file.src]

    if len(inputs) == 0:
        fail("rego_to_wasm: provide at least one input in 'srcs' (or legacy 'src').")

    # Ensure at least one .rego module is present to compile to WASM
    has_rego = any([f.path.endswith(".rego") for f in inputs])
    if not has_rego:
        fail("rego_to_wasm: at least one .rego file is required among inputs.")

    wasm_output = ctx.actions.declare_file(ctx.attr.name + ".wasm")
    bundle_output = ctx.actions.declare_file(ctx.attr.name + "_bundle.tar.gz")

    # Determine entrypoint (default provided by attribute)
    entrypoint = ctx.attr.entrypoint

    # Arguments: <opa_path> <entrypoint> <wasm_output> <bundle_output> <input_files...>
    args = [opa.path, entrypoint, wasm_output.path, bundle_output.path] + [f.path for f in inputs]

    ctx.actions.run(
        inputs = inputs,
        outputs = [wasm_output, bundle_output],
        executable = ctx.executable._compile_script,
        arguments = args,
        tools = [opa],
        mnemonic = "RegoToWasm",
        progress_message = "Compiling Rego to WASM (%d files) entrypoint=%s" % (len(inputs), entrypoint),
    )

    return [DefaultInfo(files = depset([wasm_output, bundle_output]))]

rego_to_wasm = rule(
    implementation = _rego_to_wasm_impl,
    attrs = {
        # Legacy single-source attribute (optional for backwards compatibility)
        "src": attr.label(allow_single_file = [".rego"]),
        # New multi-source attribute supporting .rego (modules) and .json/.yaml/.yml (data)
        "srcs": attr.label_list(allow_files = [".rego", ".json", ".yaml", ".yml"]),
        # Configurable entrypoint (default: policy/allow)
        "entrypoint": attr.string(default = "policy/allow"),
        "_compile_script": attr.label(
            default = Label("//rego:rego_to_wasm_script"),
            executable = True,
            cfg = "exec",
        ),
    },
    toolchains = [opa_toolchain_type],
    doc = "Compiles Rego policy modules to WASM and includes JSON/YAML data into the bundle.",
)
