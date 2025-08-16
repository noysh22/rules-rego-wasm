"""Module extension and repository rules to fetch OPA and register toolchains."""

def _opa_toolchains_repo_impl(repository_ctx):
    toolchains_build = """
package(default_visibility = ["//visibility:public"])

platform(
    name = "linux_amd64",
    constraint_values = [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
    ],
)

platform(
    name = "macos_arm64",
    constraint_values = [
        "@platforms//os:macos",
        "@platforms//cpu:arm64",
    ],
)

load("@rules_rego_wasm//:toolchain.bzl", "opa_toolchain")

opa_toolchain(
    name = "tc_linux_amd64",
    opa = "@rules_rego_wasm_opa_linux_amd64//:opa_bin",
)

opa_toolchain(
    name = "tc_macos_arm64",
    opa = "@rules_rego_wasm_opa_macos_arm64//:opa_bin",
)

toolchain(
    name = "linux_amd64_toolchain",
    toolchain = ":tc_linux_amd64",
    toolchain_type = "@rules_rego_wasm//:opa_toolchain_type",
    target_settings = [],
    exec_compatible_with = ["@platforms//os:linux", "@platforms//cpu:x86_64"],
)

toolchain(
    name = "macos_arm64_toolchain",
    toolchain = ":tc_macos_arm64",
    toolchain_type = "@rules_rego_wasm//:opa_toolchain_type",
    target_settings = [],
    exec_compatible_with = ["@platforms//os:macos", "@platforms//cpu:arm64"],
)

alias(name = "all", actual = ":macos_arm64_toolchain")
"""
    repository_ctx.file("BUILD.bazel", content = toolchains_build)

_opa_toolchains_repo = repository_rule(
    implementation = _opa_toolchains_repo_impl,
)

def _opa_binary_repo_impl(repository_ctx):
    repository_ctx.file("BUILD.bazel", content = "package(default_visibility = [\"//visibility:public\"])\nsh_binary(name=\"opa_bin\", srcs=[\"opa\"])\n")
    repository_ctx.download(
        url = repository_ctx.attr.url,
        output = "opa",
        sha256 = repository_ctx.attr.sha256,
        executable = True,
    )

opa_binary_repo = repository_rule(
    implementation = _opa_binary_repo_impl,
    attrs = {
        "url": attr.string(mandatory = True),
        "sha256": attr.string(mandatory = True),
    },
)

def _opa_impl(module_ctx):
    # Default OPA version; tags can override in the future
    version = "v1.7.1"
    for mod in getattr(module_ctx, "modules", []):
        for t in getattr(mod.tags, "tool", []):
            if t.version:
                version = t.version

    mac_url = "https://openpolicyagent.org/downloads/%s/opa_darwin_arm64_static" % version
    linux_url = "https://openpolicyagent.org/downloads/%s/opa_linux_amd64_static" % version

    # Generate repos
    _opa_toolchains_repo(
        name = "rules_rego_wasm_toolchains",
    )

    opa_binary_repo(
        name = "rules_rego_wasm_opa_macos_arm64",
        url = mac_url,
        sha256 = "fe2a14b6ba7f587caeb62ef93ef62d1e713776a6e470f4e87326468a8ecfbfbd",
    )

    opa_binary_repo(
        name = "rules_rego_wasm_opa_linux_amd64",
        url = linux_url,
        sha256 = "86cf5e8d189f5d56cc2b05a7920b557c61338aa088334ad2fb3f6de0ec931f04",
    )

opa = module_extension(
    implementation = _opa_impl,
    tag_classes = {
        "tool": tag_class(attrs = {"version": attr.string()}),
    },
)
