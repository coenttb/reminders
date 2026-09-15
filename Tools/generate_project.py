"""Generates the Xcode artefacts of one example, or of the umbrella, from wherever this file sits.

Example mode (`<example>/Tools/generate_project.py`, next to the core `Package.swift`): writes
`<example>-apple/Hosts/<Example>/` (App.swift, App.xcconfig), `<example>-apple/<Example>.xcodeproj`
(one host target over the local package products) with its shared host scheme, and
`<example>.xcworkspace` at the example root with one shared scheme named after the workspace
file that builds every target of the two packages and runs every test target. The workspace
references the sibling `accessory` checkout and the `pointfreeco/TCA26` checkout so the URL
dependencies resolve locally; both paths are probed, so the file is right inside the umbrella
checkout and in a standalone checkout alike.

Umbrella mode (`apple-apps/Tools/generate_project.py`, no `Package.swift` beside it): writes
`apple-apps.xcworkspace` over the example checkouts (in place under the umbrella or as
siblings of it) and its aggregate scheme. It never writes into an example.

Deterministic identifiers, so re-runs are byte-identical; files are only written when they change,
so an open Xcode window is not disturbed by a no-op run. The same file is copied verbatim into every
example's `Tools/`."""
import hashlib, pathlib, re, sys

HERE = pathlib.Path(__file__).resolve()
ROOT = HERE.parents[1]
UMBRELLA = "apple-apps"
EXAMPLES = ["Maps", "Messages", "Music", "Reminders", "Safari"]
DOMAINS = {"Maps": "Places", "Messages": "Conversations", "Music": "Player", "Reminders": "Lists", "Safari": "Navigation"}
# local checkouts that override URL dependencies, probed in order from the workspace's directory
ACCESSORY = ["accessory", "../accessory"]
TCA26 = ["../../pointfreeco/TCA26", "../../../pointfreeco/TCA26"]
SCHEME_VERSION = "1.3"  # what Xcode 27 writes back, so an open window leaves the file alone

def core(X): return X.lower()
def apple(X): return f"{X.lower()}-apple"

def oid(*parts):
    return hashlib.sha1("|".join(parts).encode()).hexdigest()[:24].upper()

def q(s):
    return s if re.fullmatch(r"[A-Za-z0-9_./]+", s) else '"' + s.replace('"', '\\"') + '"'

def first_existing(base, candidates):
    for c in candidates:
        if (base / c).exists():
            return c
    return None

def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() and path.read_text() == text:
        return False
    path.write_text(text)
    return True

def buildable(blueprint, name, container, buildable_name=None):
    return f'''            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{blueprint}"
               BuildableName = "{buildable_name or name}"
               BlueprintName = "{name}"
               ReferencedContainer = "container:{container}">
            </BuildableReference>'''

def entry(kind, ref):
    flags = ('buildForTesting = "YES"\n            buildForRunning = "YES"\n            buildForProfiling = "YES"\n            buildForArchiving = "YES"\n            buildForAnalyzing = "YES"'
             if kind == "YES" else
             'buildForTesting = "YES"\n            buildForRunning = "NO"\n            buildForProfiling = "NO"\n            buildForArchiving = "NO"\n            buildForAnalyzing = "YES"')
    return f"         <BuildActionEntry\n            {flags}>\n{ref}\n         </BuildActionEntry>"

def scheme_xml(build_entries, testables, runnable):
    tests = "\n".join(f'         <TestableReference\n            skipped = "NO">\n{t}\n         </TestableReference>' for t in testables)
    return f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "2700"
   version = "{SCHEME_VERSION}">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
{chr(10).join(entry(k, r) for k, r in build_entries)}
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
{tests}
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
{runnable}
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
{runnable}
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
'''

WORKSPACE_SETTINGS = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>IDEWorkspaceSharedSettings_AutocreateContextsIfNeeded</key>
	<false/>
</dict>
</plist>
'''

common = {
    "ALWAYS_SEARCH_USER_PATHS": "NO", "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
    "CLANG_ANALYZER_NONNULL": "YES", "CLANG_ENABLE_MODULES": "YES", "CLANG_ENABLE_OBJC_ARC": "YES",
    "COPY_PHASE_STRIP": "NO", "ENABLE_STRICT_OBJC_MSGSEND": "YES", "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
    "GCC_NO_COMMON_BLOCKS": "YES", "LOCALIZATION_PREFERS_STRING_CATALOGS": "YES", "MTL_FAST_MATH": "YES",
    "STRING_CATALOG_GENERATE_SYMBOLS": "YES", "SWIFT_VERSION": "6.0",
}
debug = {**common, "DEBUG_INFORMATION_FORMAT": "dwarf", "ENABLE_TESTABILITY": "YES", "GCC_DYNAMIC_NO_PIC": "NO",
         "GCC_OPTIMIZATION_LEVEL": "0", "GCC_PREPROCESSOR_DEFINITIONS": '"DEBUG=1 $(inherited)"', "MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE",
         "ONLY_ACTIVE_ARCH": "YES", "SWIFT_ACTIVE_COMPILATION_CONDITIONS": '"DEBUG $(inherited)"', "SWIFT_OPTIMIZATION_LEVEL": '"-Onone"'}
release = {**common, "DEBUG_INFORMATION_FORMAT": '"dwarf-with-dsym"', "ENABLE_NS_ASSERTIONS": "NO", "MTL_ENABLE_DEBUG_INFO": "NO",
           "SWIFT_COMPILATION_MODE": "wholemodule", "VALIDATE_PRODUCT": "YES"}
def settings(d):
    return " ".join(f"{k} = {v};" for k, v in sorted(d.items()))

def package_targets(pkg_dir):
    """(kind, name) for every target declared in the package manifest, in declaration order."""
    manifest = (pkg_dir / "Package.swift").read_text()
    targets_src = manifest[manifest.rfind("targets: ["):]
    return re.findall(r'\.(target|testTarget)\(\s*name:\s*"([^"]+)"', targets_src)

def package_entries(pkg_dir, container):
    """Aggregate-scheme build entries and testables for one package, referenced by `container`."""
    entries, testables = [], []
    for kind, name in package_targets(pkg_dir):
        if kind == "target":
            entries.append(("YES", buildable(name, name, container)))
        else:
            entries.append(("TEST", buildable(name, name, container)))
            testables.append(buildable(name, name, container))
    return entries, testables

def host_target_id(X):
    return oid(X, "target", X)

def generate_project(X, example_root):
    """Hosts, project, and host scheme for one example, under `example_root`. Returns changed paths."""
    domain = DOMAINS[X]
    apple_dir = example_root / apple(X)
    project_name = X
    changed = []
    hosts = [  # (target, [(package ref, product)])
        (X, [(".", f"{X} App"), ("..", X), ("..", f"{X} Feature")]),
    ]
    objects = []
    def add(id_, text):
        objects.append((id_, text)); return id_
    package_refs = {rel: add(oid(X, "package", rel), f'{{isa = XCLocalSwiftPackageReference; relativePath = {q(rel)}; }}') for rel in [".", ".."]}
    products_children, hosts_children, targets, host_entries = [], [], [], []
    for target, products in hosts:
        d = apple_dir / "Hosts" / target
        app = f"""import ComposableArchitecture2
import {X}
import {X}_App
import {X}_Feature
import SwiftUI

/// The host: one scene around the application layer in `{X} App`.
@main struct Application: App {{
    /// The root store, held once for the process as the Point-Free Way has it.
    static let store = {domain}.Feature.live()

    var body: some Scene {{
        WindowGroup {{ Root(store: Self.store) }}
    }}
}}
"""
        if write(d / "App.swift", app): changed.append(d / "App.swift")
        xcconfig_text = f"""// Bundle configuration shared by Debug and Release. The lifecycle lives in App.swift;
// everything else is the `{X} App` package product.
PRODUCT_NAME = {target}
PRODUCT_MODULE_NAME = {target}_Host
PRODUCT_BUNDLE_IDENTIFIER = com.coenttb.apple-apps.{X.lower()}
MARKETING_VERSION = 1.0
CURRENT_PROJECT_VERSION = 1

SDKROOT = iphoneos
SUPPORTED_PLATFORMS = iphoneos iphonesimulator
IPHONEOS_DEPLOYMENT_TARGET = 27.0
TARGETED_DEVICE_FAMILY = 1,2

SWIFT_VERSION = 6.0
SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor
SWIFT_APPROACHABLE_CONCURRENCY = YES
SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES
SWIFT_EMIT_LOC_STRINGS = YES
LD_RUNPATH_SEARCH_PATHS = @executable_path/Frameworks

GENERATE_INFOPLIST_FILE = YES
INFOPLIST_KEY_CFBundleDisplayName = {target}
INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES
INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES
INFOPLIST_KEY_UILaunchScreen_Generation = YES
INFOPLIST_KEY_UIStatusBarStyle = UIStatusBarStyleDefault
INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight
INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight

CODE_SIGN_STYLE = Automatic
"""
        if write(d / "App.xcconfig", xcconfig_text): changed.append(d / "App.xcconfig")
        swift = add(oid(X, "file", target, "App.swift"), '{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = App.swift; sourceTree = "<group>"; }')
        xcconfig = add(oid(X, "file", target, "App.xcconfig"), '{isa = PBXFileReference; lastKnownFileType = text.xcconfig; path = App.xcconfig; sourceTree = "<group>"; }')
        product = add(oid(X, "product", target), f'{{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = {q(target + ".app")}; sourceTree = BUILT_PRODUCTS_DIR; }}')
        products_children.append(product)
        hosts_children.append(add(oid(X, "group", target), f'{{isa = PBXGroup; children = ({swift}, {xcconfig}, ); path = {q(target)}; sourceTree = "<group>"; }}'))
        swift_build = add(oid(X, "build", target, "App.swift"), f'{{isa = PBXBuildFile; fileRef = {swift}; }}')
        deps, framework_files = [], []
        for rel, product_name in products:
            dep = add(oid(X, "productdep", target, product_name), f'{{isa = XCSwiftPackageProductDependency; package = {package_refs[rel]}; productName = {q(product_name)}; }}')
            deps.append(dep)
            framework_files.append(add(oid(X, "build", target, product_name), f'{{isa = PBXBuildFile; productRef = {dep}; }}'))
        sources = add(oid(X, "phase", target, "sources"), f'{{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({swift_build}, ); runOnlyForDeploymentPostprocessing = 0; }}')
        frameworks = add(oid(X, "phase", target, "frameworks"), f'{{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = ({", ".join(framework_files)}, ); runOnlyForDeploymentPostprocessing = 0; }}')
        resources = add(oid(X, "phase", target, "resources"), '{isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ( ); runOnlyForDeploymentPostprocessing = 0; }')
        configs = [add(oid(X, "config", target, name), f'{{isa = XCBuildConfiguration; baseConfigurationReference = {xcconfig}; buildSettings = {{ }}; name = {name}; }}') for name in ["Debug", "Release"]]
        config_list = add(oid(X, "configlist", target), f'{{isa = XCConfigurationList; buildConfigurations = ({", ".join(configs)}, ); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }}')
        native = add(oid(X, "target", target), f'{{isa = PBXNativeTarget; buildConfigurationList = {config_list}; buildPhases = ({sources}, {frameworks}, {resources}, ); buildRules = ( ); dependencies = ( ); name = {q(target)}; packageProductDependencies = ({", ".join(deps)}, ); productName = {q(target)}; productReference = {product}; productType = "com.apple.product-type.application"; }}')
        targets.append(native)
        host_entries.append((native, target))
    hosts_group = add(oid(X, "group", "Hosts"), f'{{isa = PBXGroup; children = ({", ".join(hosts_children)}, ); path = Hosts; sourceTree = "<group>"; }}')
    products_group = add(oid(X, "group", "Products"), f'{{isa = PBXGroup; children = ({", ".join(products_children)}, ); name = Products; sourceTree = "<group>"; }}')
    main_group = add(oid(X, "group", "main"), f'{{isa = PBXGroup; children = ({hosts_group}, {products_group}, ); sourceTree = "<group>"; }}')
    project_configs = [add(oid(X, "config", "project", "Debug"), f'{{isa = XCBuildConfiguration; buildSettings = {{ {settings(debug)} }}; name = Debug; }}'),
                       add(oid(X, "config", "project", "Release"), f'{{isa = XCBuildConfiguration; buildSettings = {{ {settings(release)} }}; name = Release; }}')]
    project_config_list = add(oid(X, "configlist", "project"), f'{{isa = XCConfigurationList; buildConfigurations = ({", ".join(project_configs)}, ); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }}')
    project = add(oid(X, "project"), f'{{isa = PBXProject; attributes = {{ BuildIndependentTargetsInParallel = 1; LastSwiftUpdateCheck = 2700; LastUpgradeCheck = 2700; }}; buildConfigurationList = {project_config_list}; compatibilityVersion = "Xcode 15.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, Base, ); mainGroup = {main_group}; packageReferences = ({", ".join(package_refs.values())}, ); productRefGroup = {products_group}; projectDirPath = ""; projectRoot = ""; targets = ({", ".join(targets)}, ); }}')
    body = "\n".join(f"\t\t{id_} = {text};" for id_, text in objects)
    proj_dir = apple_dir / f"{project_name}.xcodeproj"
    if write(proj_dir / "project.pbxproj", f"// !$*UTF8*$!\n{{\n\tarchiveVersion = 1;\n\tclasses = {{\n\t}};\n\tobjectVersion = 60;\n\tobjects = {{\n{body}\n\t}};\n\trootObject = {project};\n}}\n"):
        changed.append(proj_dir / "project.pbxproj")
    for native, target in host_entries:
        # a scheme stored inside the project references its container relative to the project
        own = buildable(native, target, f"{project_name}.xcodeproj", f"{target}.app")
        p = proj_dir / "xcshareddata" / "xcschemes" / f"{target}.xcscheme"
        if write(p, scheme_xml([("YES", own)], [], own)): changed.append(p)
    return changed

def generate_workspace(ws, groups, refs, entries, testables, runnable):
    """`groups` = [(name, [locations])], `refs` = [locations]; returns changed paths."""
    changed = []
    body = "".join(f'   <Group location="container:" name="{name}">\n' + "".join(f'      <FileRef location="group:{loc}"/>\n' for loc in locs) + '   </Group>\n' for name, locs in groups)
    body += "".join(f'   <FileRef location="group:{loc}"/>\n' for loc in refs)
    if write(ws / "contents.xcworkspacedata", f'<?xml version="1.0" encoding="UTF-8"?>\n<Workspace version="1.0">\n{body}</Workspace>\n'):
        changed.append(ws / "contents.xcworkspacedata")
    if write(ws / "xcshareddata" / "WorkspaceSettings.xcsettings", WORKSPACE_SETTINGS):
        changed.append(ws / "xcshareddata" / "WorkspaceSettings.xcsettings")
    p = ws / "xcshareddata" / "xcschemes" / f"{ws.name}.xcscheme"
    if write(p, scheme_xml(entries, testables, runnable)): changed.append(p)
    return changed

def example_main():
    x = ROOT.name
    X = next((e for e in EXAMPLES if e.lower() == x), None)
    if X is None:
        sys.exit(f"{ROOT} is not one of {EXAMPLES}")
    changed = generate_project(X, ROOT)
    host = host_target_id(X)
    project_container = f"{apple(X)}/{X}.xcodeproj"
    host_ref = buildable(host, X, project_container, f"{X}.app")
    entries, testables = [("YES", host_ref)], []
    for pkg, container in [(ROOT, "."), (ROOT / apple(X), apple(X))]:
        e, t = package_entries(pkg, container)
        entries += e; testables += t
    accessory = first_existing(ROOT, ACCESSORY[1:])  # a sibling checkout; never nested inside an example
    tca26 = first_existing(ROOT, TCA26)
    refs = [p for p in (accessory, tca26) if p]
    missing = [n for n, p in (("accessory", accessory), ("TCA26", tca26)) if not p]
    ws = ROOT / f"{x}.xcworkspace"
    changed += generate_workspace(ws, [(X, [project_container, ".", apple(X)])], refs, entries, testables, host_ref)
    print(f"{x}: build entries {len(entries)}, testables {len(testables)}, overrides {refs}" + (f", MISSING {missing} (URL dependencies will be fetched)" if missing else ""))
    for p in changed: print("  wrote", p.relative_to(ROOT))

def umbrella_main():
    groups, entries, testables, runnable, present = [], [], [], None, []
    for X in EXAMPLES:
        rel = first_existing(ROOT, [core(X), f"../{core(X)}"])
        if rel is None:
            print(f"{X}: no checkout under {ROOT} or beside it; skipped")
            continue
        present.append(X)
        project_container = f"{rel}/{apple(X)}/{X}.xcodeproj"
        groups.append((X, [project_container, rel, f"{rel}/{apple(X)}"]))
        host_ref = buildable(host_target_id(X), X, project_container, f"{X}.app")
        entries.append(("YES", host_ref))
        if X == "Messages": runnable = host_ref
        for pkg, container in [(ROOT / rel, rel), (ROOT / rel / apple(X), f"{rel}/{apple(X)}")]:
            e, t = package_entries(pkg, container)
            entries += e; testables += t
    runnable = runnable or entries[0][1]
    accessory = first_existing(ROOT, ACCESSORY)
    tca26 = first_existing(ROOT, TCA26)
    refs = [p for p in (accessory, tca26) if p]
    if accessory:
        e, t = package_entries(ROOT / accessory, accessory)
        entries += e; testables += t
    ws = ROOT / f"{UMBRELLA}.xcworkspace"
    changed = generate_workspace(ws, groups, refs, entries, testables, runnable)
    print(f"{UMBRELLA}: examples {present}, build entries {len(entries)}, testables {len(testables)}, overrides {refs}")
    for p in changed: print("  wrote", p.relative_to(ROOT))

if __name__ == "__main__":
    if (ROOT / "Package.swift").exists():
        example_main()
    else:
        umbrella_main()
