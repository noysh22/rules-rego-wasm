"""Rules for compiling Rego policies to WebAssembly (WASM)."""

load("//:toolchain.bzl", "opa_toolchain_type")

def _rego_to_wasm_impl(ctx):
    toolchain = ctx.toolchains[opa_toolchain_type]
    opa = toolchain.opa

    input_file = ctx.file.src
    wasm_output = ctx.actions.declare_file(ctx.attr.name + ".wasm")
    bundle_output = ctx.actions.declare_file(ctx.attr.name + "_bundle.tar.gz")

    ctx.actions.run(
        inputs = [input_file],
        outputs = [wasm_output, bundle_output],
        executable = ctx.executable._compile_script,
        arguments = [opa.path, input_file.path, wasm_output.path, bundle_output.path],
        tools = [opa],
        mnemonic = "RegoToWasm",
        progress_message = "Compiling Rego to WASM: %s" % input_file.short_path,
    )

    return [DefaultInfo(files = depset([wasm_output, bundle_output]))]

rego_to_wasm = rule(
    implementation = _rego_to_wasm_impl,
    attrs = {
        "src": attr.label(allow_single_file = [".rego"], mandatory = True),
        "_compile_script": attr.label(
            default = Label("//rego:rego_to_wasm_script"),
            executable = True,
            cfg = "exec",
        ),
    },
    toolchains = [opa_toolchain_type],
    doc = "Compiles a Rego file to WASM and keeps both WASM and bundle files.",
)
