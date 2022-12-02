# buildifier: disable=module-docstring
load("@location_discovery//:location_discovery.bzl", "host_platform")

def _host_platform_rule_impl(ctx):
    print("host platform 1 = %s" % host_platform)
    print("host platform 2 = %s" % ctx.attr.host_platform)

    print("ctx.fragments.platform.host_platform = %s" % ctx.fragments.platform.host_platform)
    print("ctx.host_fragments.platform.platform = %s" % ctx.host_fragments.platform.platform)

host_platform_rule = rule(
    implementation = _host_platform_rule_impl,
    attrs = {
        "host_platform": attr.string(mandatory = True),
    },
)

def host_platform_macro(name, **kwargs):
    host_platform_rule(
        name = name,
        host_platform = select({
            "//conditions:host_windows": "windows",
            "//conditions:host_linux": "linux",
            "//conditions:host_osx": "osx",
            "//conditions:default": "other",
        }),
        **kwargs
    )
