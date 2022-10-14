# buildifier: disable=module-docstring
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

# system_python_path intentionally does not have quotes around the value as the value is already quoted.
_template = """
workspace_name = "%s"
workspace_real_path = "%s"
workspace_folder_name = "%s"
execroot_real_path = "%s"
output_user_root = "%s"
system_python_path = %s
hermetic_python_target = "%s"
host_platform = "%s"
location_discovery_workspace_path = "%s"
output_base = "%s"
external_folder = "%s"
""".strip()

def _string_or_none(param):
    if param:
        return '"' + str(param) + '"'
    return None

def is_host_windows(repository_ctx):
    return repository_ctx.os.name.lower().find("windows") != -1

def is_host_linux(repository_ctx):
    return repository_ctx.os.name.lower().find("linux") != -1

def is_host_osx(repository_ctx):
    return repository_ctx.os.name.lower().find("mac") != -1

def host_platform(repository_ctx):
    for platform in ["windows", "linux", "mac"]:
        if platform in repository_ctx.os.name.lower():
            return platform
    fail("Unexpected host platform name %s" % repository_ctx.os.name)

# buildifier: disable=function-docstring
def hermetic_python_target(repository_ctx):
    python_target_for_platform = {
        "windows": "@python_windows//:python.exe",
        "linux": "@python_linux//:python",
        "mac": "@python_osx//:python",
    }
    return python_target_for_platform[host_platform(repository_ctx)]

def _location_discovery_impl(repository_ctx):
    # print("repository_ctx.attr.workspace_real_path = %s" % repository_ctx.attr.workspace_real_path)

    # workspace_output_path = repository_ctx.path(repository_ctx.attr.workspace_output_path).dirname
    # print("workspace_output_path = %s" % workspace_output_path)

    # This is another option
    # str(repo_ctx.path(Label("@//:BUILD.bazel")))[:-12]

    repository_ctx.file("BUILD", executable = False)
    workspace_real_path = repository_ctx.attr.workspace_real_path  # C:/dev/bazel/blitz/repositories/tab_toolchains
    workspace_folder_name = paths.basename(workspace_real_path)  # tab_toolchains

    location_discovery_workspace_path = repository_ctx.path("@").dirname  # C:/_/gfkfwau2/external/location_discovery

    # C:/_/gfkfwau2/execroot/tab_toolchains
    execroot_real_path = paths.normalize(paths.join(str(location_discovery_workspace_path), "../../execroot", repository_ctx.attr.workspace_name))
    install_real_path = repository_ctx.attr.install_real_path
    output_user_root = paths.normalize(paths.join(install_real_path, "../.."))  # C:/_

    if is_host_windows(repository_ctx):
        python_executable_name = "python.exe"
    else:
        python_executable_name = "python3"
    system_python_path = repository_ctx.which(python_executable_name)

    external_folder = paths.normalize(paths.join(str(location_discovery_workspace_path), ".."))  # C:/_/gfkfwau2/external

    output_base = paths.normalize(paths.join(str(external_folder), ".."))  # C:/_/gfkfwau2

    repository_ctx.file(
        "location_discovery.bzl",
        executable = False,
        content = _template % (
            repository_ctx.attr.workspace_name,
            workspace_real_path,
            workspace_folder_name,
            execroot_real_path,
            output_user_root,
            _string_or_none(system_python_path),
            hermetic_python_target(repository_ctx),
            host_platform(repository_ctx),
            location_discovery_workspace_path,
            output_base,
            external_folder,
        ),
    )

location_discovery = repository_rule(
    implementation = _location_discovery_impl,
    local = True,
    attrs = {
        "workspace_name": attr.string(mandatory = True),
        "workspace_real_path": attr.string(mandatory = True),
        "install_real_path": attr.string(mandatory = True),
    },
)

def __string_or_none__test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(env, '"Isenguard"', _string_or_none("Isenguard"))
    asserts.equals(env, None, _string_or_none(None))

    return unittest.end(env)

string_or_none__test = unittest.make(__string_or_none__test_impl)

def _host_platform__test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(env, "windows", host_platform(struct(os = struct(name = "Windows"))))
    asserts.equals(env, "linux", host_platform(struct(os = struct(name = "Linux"))))
    asserts.equals(env, "mac", host_platform(struct(os = struct(name = "Mac"))))

    return unittest.end(env)

host_platform__test = unittest.make(_host_platform__test_impl)
