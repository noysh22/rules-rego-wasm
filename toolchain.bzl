"""Toolchain definitions and types for exposing the OPA binary to rules."""

def _opa_toolchain_impl(ctx):
    # Provide the executable file for OPA on the toolchain to simplify usage.
    return [platform_common.ToolchainInfo(opa = ctx.executable.opa)]

opa_toolchain = rule(
    implementation = _opa_toolchain_impl,
    attrs = {
        "opa": attr.label(executable = True, cfg = "exec", allow_files = True),
    },
    toolchains = [],
)

# Bazel expects toolchain types to be provided as string labels in rule.toolchains and when indexing ctx.toolchains.
opa_toolchain_type = "//:opa_toolchain_type"
