# rules-rego-wasm

Reusable Bazel rule to compile Rego policies to WebAssembly (WASM), packaged as a Bazel Module (bzlmod-only).

Features:
- rego_to_wasm rule: builds both the .wasm and the OPA bundle (.tar.gz)
- Toolchain-based OPA binary selection (macOS ARM64 and Linux AMD64 supported)
- Bazel Module extension to fetch OPA binaries
- Example policy and test
- GitHub Actions CI

Usage (consumer repo, MODULE.bazel):

module(name = "your_repo")

bazel_dep(name = "rules_rego_wasm", version = "0.1.0")

opa = use_extension("@rules_rego_wasm//:extensions.bzl", "opa")
opa.tool(version = "v1.7.1")
use_repo(opa,
    "rules_rego_wasm_opa_macos_arm64",
    "rules_rego_wasm_opa_linux_amd64",
    "rules_rego_wasm_toolchains",
)

# Register the toolchains created by the extension
register_toolchains("@rules_rego_wasm_toolchains//:all")

Then, in your BUILD file:

load("@rules_rego_wasm//rego:defs.bzl", "rego_to_wasm")

rego_to_wasm(
    name = "example_policy",
    src = "example.rego",
)

# This provides these outputs at analysis time:
# - example_policy.wasm
# - example_policy_bundle.tar.gz

OPA versions: set with opa.tool(version = "vX.Y.Z"). Supported platforms: macOS arm64, Linux amd64.

