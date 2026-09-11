#!/usr/bin/env python3
"""Generate DepremOldu.xcodeproj deterministically from the repository tree.

The project file is a checked-in build artifact. Adding or removing Swift,
resource or test files only requires re-running this script; IDs are derived
from stable identifiers so the output does not churn between runs.

Usage:
    python3 scripts/generate_xcodeproj.py
    make project
"""

from __future__ import annotations

import hashlib
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
PROJECT_NAME = "DepremOldu"
PROJECT_DIR = ROOT / f"{PROJECT_NAME}.xcodeproj"
PACKAGE_PATH = "Packages/DepremOlduCore"

APP_SOURCES = sorted(ROOT.glob("Apps/DepremOldu/**/*.swift"))
APP_RESOURCES = [
    ROOT / "Apps/DepremOldu/Resources/Assets.xcassets",
    *sorted((ROOT / "Apps/DepremOldu/Resources/Fonts").glob("*.ttf")),
    ROOT / "Apps/DepremOldu/Resources/Fonts/OFL.txt",
    ROOT / "Apps/DepremOldu/Resources/Faults.json",
]
APP_TEST_SOURCES = sorted(ROOT.glob("Tests/DepremOlduAppTests/**/*.swift"))
UI_TEST_SOURCES = sorted(ROOT.glob("Tests/DepremOlduAppUITests/**/*.swift"))
CONFIG_FILES = sorted((ROOT / "Configuration").glob("*.xcconfig"))

APP_PRODUCTS = [
    "DepremOlduDomain",
    "DepremOlduFaults",
    "DepremOlduNetworking",
    "DepremOlduPersistence",
    "DepremOlduRepository",
]
TEST_PRODUCTS = APP_PRODUCTS + ["DepremOlduTestSupport"]

TARGET_APP = "DepremOldu"
TARGET_APP_TESTS = "DepremOlduAppTests"
TARGET_UI_TESTS = "DepremOlduAppUITests"


def stable_id(key: str) -> str:
    return hashlib.md5(key.encode("utf-8")).hexdigest().upper()[:24]


def file_type(path: Path) -> str:
    suffix = path.suffix.lower()
    return {
        ".swift": "sourcecode.swift",
        ".json": "text.json",
        ".ttf": "file",
        ".xcconfig": "text.xcconfig",
        ".plist": "text.plist.xml",
        ".xcstrings": "text.json.xcstrings",
    }.get(suffix, "text")


def relative(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def children_by_directory(paths: list[Path]) -> dict[str, list[Path]]:
    tree: dict[str, list[Path]] = {}
    for path in paths:
        parent = relative(path.parent)
        tree.setdefault(parent, []).append(path)
    return tree


def group_id(directory: str) -> str:
    return stable_id(f"group:{directory}")


def file_ref_id(path: Path) -> str:
    return stable_id(f"file:{relative(path)}")


def build_file_id(path: Path, phase: str) -> str:
    return stable_id(f"build:{phase}:{relative(path)}")


def product_ref_id(target: str, product: str) -> str:
    return stable_id(f"product-dependency:{target}:{product}")


def product_build_file_id(target: str, product: str) -> str:
    return stable_id(f"product-build:{target}:{product}")


def target_id(name: str) -> str:
    return stable_id(f"target:{name}")


def main() -> int:
    pbx_files: list[str] = []
    pbx_file_refs: list[str] = []
    pbx_build_files: list[str] = []
    pbx_groups: list[str] = []
    pbx_sources: list[str] = []
    pbx_resources: list[str] = []
    pbx_frameworks: list[str] = []
    pbx_configs: list[str] = []
    pbx_config_lists: list[str] = []
    pbx_product_deps: list[str] = []

    package_ref = stable_id(f"package:{PACKAGE_PATH}")
    package_ref_comment = f'{PACKAGE_PATH}'

    # Products group
    products = [
        ("app", f"{TARGET_APP}.app", "wrapper.application"),
        ("app-tests", f"{TARGET_APP_TESTS}.xctest", "wrapper.cfbundle"),
        ("ui-tests", f"{TARGET_UI_TESTS}.xctest", "wrapper.cfbundle"),
    ]
    product_files: dict[str, str] = {}
    for key, name, explicit_type in products:
        ref = stable_id(f"product:{name}")
        product_files[key] = ref
        pbx_file_refs.append(
            f'{ref} /* {name} */ = {{isa = PBXFileReference; explicitFileType = "{explicit_type}"; includeInIndex = 0; path = {name}; sourceTree = BUILT_PRODUCTS_DIR; }};'
        )

    # Application file references and build files
    app_source_refs = []
    for path in APP_SOURCES:
        ref = file_ref_id(path)
        app_source_refs.append(ref)
        pbx_file_refs.append(
            f'{ref} /* {path.name} */ = {{isa = PBXFileReference; lastKnownFileType = {file_type(path)}; path = {path.name}; sourceTree = "<group>"; }};'
        )
        bf = build_file_id(path, "app")
        pbx_build_files.append(
            f'{bf} /* {path.name} in Sources */ = {{isa = PBXBuildFile; fileRef = {ref} /* {path.name} */; }};'
        )
        pbx_sources.append(bf)

    app_resource_refs = []
    for path in APP_RESOURCES:
        ref = file_ref_id(path)
        app_resource_refs.append(ref)
        if path.suffix == ".xcassets":
            file_type_value = "folder.assetcatalog"
        else:
            file_type_value = file_type(path)
        pbx_file_refs.append(
            f'{ref} /* {path.name} */ = {{isa = PBXFileReference; lastKnownFileType = {file_type_value}; path = {path.name}; sourceTree = "<group>"; }};'
        )
        bf = build_file_id(path, "app-resources")
        pbx_build_files.append(
            f'{bf} /* {path.name} in Resources */ = {{isa = PBXBuildFile; fileRef = {ref} /* {path.name} */; }};'
        )
        pbx_resources.append(bf)

    info_plist = ROOT / "Apps/DepremOldu/Info.plist"
    info_ref = file_ref_id(info_plist)
    pbx_file_refs.append(
        f'{info_ref} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; }};'
    )

    test_source_refs = []
    for path in APP_TEST_SOURCES:
        ref = file_ref_id(path)
        test_source_refs.append(ref)
        pbx_file_refs.append(
            f'{ref} /* {path.name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {path.name}; sourceTree = "<group>"; }};'
        )
        bf = build_file_id(path, "app-tests")
        pbx_build_files.append(
            f'{bf} /* {path.name} in Sources */ = {{isa = PBXBuildFile; fileRef = {ref} /* {path.name} */; }};'
        )
        pbx_sources.append(bf)

    ui_source_refs = []
    for path in UI_TEST_SOURCES:
        ref = file_ref_id(path)
        ui_source_refs.append(ref)
        pbx_file_refs.append(
            f'{ref} /* {path.name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {path.name}; sourceTree = "<group>"; }};'
        )
        bf = build_file_id(path, "ui-tests")
        pbx_build_files.append(
            f'{bf} /* {path.name} in Sources */ = {{isa = PBXBuildFile; fileRef = {ref} /* {path.name} */; }};'
        )
        pbx_sources.append(bf)

    config_refs = []
    for path in CONFIG_FILES:
        ref = file_ref_id(path)
        config_refs.append(ref)
        pbx_file_refs.append(
            f'{ref} /* {path.name} */ = {{isa = PBXFileReference; lastKnownFileType = text.xcconfig; path = {path.name}; sourceTree = "<group>"; }};'
        )

    # Product dependencies (Frameworks phase)
    def add_product_dependency(target: str, product: str) -> None:
        dependency_id = product_ref_id(target, product)
        pbx_product_deps.append(
            f'{dependency_id} /* {product} */ = {{isa = XCSwiftPackageProductDependency; package = {package_ref} /* XCLocalSwiftPackageReference "{package_ref_comment}" */; productName = {product}; }};'
        )
        bf = product_build_file_id(target, product)
        pbx_build_files.append(
            f'{bf} /* {product} in Frameworks */ = {{isa = PBXBuildFile; productRef = {dependency_id} /* {product} */; }};'
        )
        pbx_frameworks.append(bf)

    for product in APP_PRODUCTS:
        add_product_dependency(TARGET_APP, product)
    for product in TEST_PRODUCTS:
        add_product_dependency(TARGET_APP_TESTS, product)

    # Groups
    group_members: dict[str, list[str]] = {}
    group_paths: set[str] = set()

    all_file_entries: list[tuple[str, str]] = []
    for path in APP_SOURCES:
        all_file_entries.append(("app", file_ref_id(path)))
    for path in APP_RESOURCES:
        all_file_entries.append(("app", file_ref_id(path)))
    for path in APP_TEST_SOURCES:
        all_file_entries.append(("app-tests", file_ref_id(path)))
    for path in UI_TEST_SOURCES:
        all_file_entries.append(("ui-tests", file_ref_id(path)))
    all_file_entries.append(("config", info_ref))
    for ref in config_refs:
        all_file_entries.append(("config", ref))

    def register_group(directory: str, entry_id: str) -> None:
        group_members.setdefault(directory, []).append(entry_id)
        current = directory
        while True:
            group_paths.add(current)
            if current == "":
                break
            parent = str(Path(current).parent)
            if parent == ".":
                parent = ""
            group_members.setdefault(parent, []).append(group_id(current))
            current = parent

    for _, ref in all_file_entries:
        directory = ""
        for path in (
            APP_SOURCES + APP_RESOURCES + APP_TEST_SOURCES + UI_TEST_SOURCES
        ):
            if file_ref_id(path) == ref:
                directory = relative(path.parent)
                break
        if directory == "":
            directory = relative(info_plist.parent) if ref == info_ref else "Configuration"
        register_group(directory, ref)

    for directory in sorted(group_paths):
        children = sorted(set(group_members.get(directory, [])))
        if directory == "":
            children.append(stable_id("group:Products"))
        display = directory.split("/")[-1] if directory else "root"
        path_line = f'\n\t\t\tpath = {display};' if directory else ""
        body = ",\n".join(f"\t\t\t\t{child}" for child in children)
        pbx_groups.append(
            f"{group_id(directory)} /* {display} */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n{body},\n\t\t\t);{path_line}\n\t\t\tsourceTree = \"<group>\";\n\t\t}};"
        )

    products_group_id = stable_id("group:Products")
    product_children = ",\n".join(f"\t\t\t\t{ref}" for ref in product_files.values())
    pbx_groups.append(
        f"{products_group_id} /* Products */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n{product_children},\n\t\t\t);\n\t\t\tname = Products;\n\t\t\tsourceTree = \"<group>\";\n\t\t}};"
    )

    root_group_id = group_id("")

    # Build phases
    sources_section = []
    for target, ids in (
        (TARGET_APP, [build_file_id(path, "app") for path in APP_SOURCES]),
        (TARGET_APP_TESTS, [build_file_id(path, "app-tests") for path in APP_TEST_SOURCES]),
        (TARGET_UI_TESTS, [build_file_id(path, "ui-tests") for path in UI_TEST_SOURCES]),
    ):
        phase_id = stable_id(f"phase:sources:{target}")
        body = ",\n".join(f"\t\t\t\t{bf}" for bf in ids)
        if body:
            body += ",\n"
        sources_section.append(
            f"{phase_id} = {{\n\t\t\tisa = PBXSourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n{body}\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}};"
        )

    app_resources_phase = stable_id("phase:resources:" + TARGET_APP)
    body = ",\n".join(f"\t\t\t\t{bf}" for bf in pbx_resources)
    if body:
        body += ",\n"
    resources_section = [
        f"{app_resources_phase} = {{\n\t\t\tisa = PBXResourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n{body}\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}};"
    ]
    for target in (TARGET_APP_TESTS, TARGET_UI_TESTS):
        phase_id = stable_id(f"phase:resources:{target}")
        resources_section.append(
            f"{phase_id} = {{\n\t\t\tisa = PBXResourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}};"
        )

    frameworks_section = []
    for target, products in (
        (TARGET_APP, APP_PRODUCTS),
        (TARGET_APP_TESTS, TEST_PRODUCTS),
        (TARGET_UI_TESTS, []),
    ):
        phase_id = stable_id(f"phase:frameworks:{target}")
        body = ",\n".join(f"\t\t\t\t{product_build_file_id(target, p)}" for p in products)
        if body:
            body += ",\n"
        frameworks_section.append(
            f"{phase_id} = {{\n\t\t\tisa = PBXFrameworksBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n{body}\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}};"
        )

    # Targets
    app_target = target_id(TARGET_APP)
    app_tests_target = target_id(TARGET_APP_TESTS)
    ui_tests_target = target_id(TARGET_UI_TESTS)

    app_dependency = stable_id("target-dependency:app-tests")
    ui_dependency = stable_id("target-dependency:ui-tests")
    app_proxy = stable_id("container-proxy:app-tests")
    ui_proxy = stable_id("container-proxy:ui-tests")

    targets_section = [
        f"""{app_target} /* {TARGET_APP} */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {stable_id('config-list:' + TARGET_APP)};
\t\t\tbuildPhases = (
\t\t\t\t{stable_id('phase:sources:' + TARGET_APP)},
\t\t\t\t{stable_id('phase:frameworks:' + TARGET_APP)},
\t\t\t\t{stable_id('phase:resources:' + TARGET_APP)},
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = {TARGET_APP};
\t\t\tpackageProductDependencies = (
"""
        + "".join(f"\t\t\t\t{product_ref_id(TARGET_APP, p)},\n" for p in APP_PRODUCTS)
        + f"""\t\t\t);
\t\t\tproductName = {TARGET_APP};
\t\t\tproductReference = {product_files['app']};
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};""",
        f"""{app_tests_target} /* {TARGET_APP_TESTS} */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {stable_id('config-list:' + TARGET_APP_TESTS)};
\t\t\tbuildPhases = (
\t\t\t\t{stable_id('phase:sources:' + TARGET_APP_TESTS)},
\t\t\t\t{stable_id('phase:frameworks:' + TARGET_APP_TESTS)},
\t\t\t\t{stable_id('phase:resources:' + TARGET_APP_TESTS)},
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t\t{app_dependency},
\t\t\t);
\t\t\tname = {TARGET_APP_TESTS};
\t\t\tpackageProductDependencies = (
"""
        + "".join(f"\t\t\t\t{product_ref_id(TARGET_APP_TESTS, p)},\n" for p in TEST_PRODUCTS)
        + f"""\t\t\t);
\t\t\tproductName = {TARGET_APP_TESTS};
\t\t\tproductReference = {product_files['app-tests']};
\t\t\tproductType = "com.apple.product-type.bundle.unit-test";
\t\t}};""",
        f"""{ui_tests_target} /* {TARGET_UI_TESTS} */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {stable_id('config-list:' + TARGET_UI_TESTS)};
\t\t\tbuildPhases = (
\t\t\t\t{stable_id('phase:sources:' + TARGET_UI_TESTS)},
\t\t\t\t{stable_id('phase:frameworks:' + TARGET_UI_TESTS)},
\t\t\t\t{stable_id('phase:resources:' + TARGET_UI_TESTS)},
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t\t{ui_dependency},
\t\t\t);
\t\t\tname = {TARGET_UI_TESTS};
\t\t\tpackageProductDependencies = (
\t\t\t);
\t\t\tproductName = {TARGET_UI_TESTS};
\t\t\tproductReference = {product_files['ui-tests']};
\t\t\tproductType = "com.apple.product-type.bundle.ui-testing";
\t\t}};""",
    ]

    target_dependencies = f"""{app_dependency} = {{
\t\t\tisa = PBXTargetDependency;
\t\t\ttarget = {app_target};
\t\t\ttargetProxy = {app_proxy};
\t\t}};
\t\t{ui_dependency} = {{
\t\t\tisa = PBXTargetDependency;
\t\t\ttarget = {app_target};
\t\t\ttargetProxy = {ui_proxy};
\t\t}};"""

    container_proxies = f"""{app_proxy} = {{
\t\t\tisa = PBXContainerItemProxy;
\t\t\tcontainerPortal = {stable_id('project')};
\t\t\tproxyType = 1;
\t\t\tremoteGlobalIDString = {app_target};
\t\t\tremoteInfo = {TARGET_APP};
\t\t}};
\t\t{ui_proxy} = {{
\t\t\tisa = PBXContainerItemProxy;
\t\t\tcontainerPortal = {stable_id('project')};
\t\t\tproxyType = 1;
\t\t\tremoteGlobalIDString = {app_target};
\t\t\tremoteInfo = {TARGET_APP};
\t\t}};"""

    # Build configurations
    def config_block(config_id: str, name: str, xcconfig_ref: str, settings: dict[str, str]) -> str:
        setting_lines = "".join(
            f"\t\t\t\t{key} = {value};\n" for key, value in settings.items()
        )
        return (
            f"{config_id} /* {name} */ = {{\n"
            f"\t\t\tisa = XCBuildConfiguration;\n"
            f"\t\t\tbaseConfigurationReference = {xcconfig_ref};\n"
            f"\t\t\tbuildSettings = {{\n{setting_lines}\t\t\t}};\n"
            f"\t\t\tname = {name};\n"
            f"\t\t}};"
        )

    app_settings = {
        "GENERATE_INFOPLIST_FILE": "YES",
        "INFOPLIST_FILE": "Apps/DepremOldu/Info.plist",
        "INFOPLIST_KEY_CFBundleDisplayName": '"Deprem Oldu"',
        "INFOPLIST_KEY_UIApplicationSceneManifest_Generation": "YES",
        "INFOPLIST_KEY_UILaunchScreen_Generation": "YES",
        "INFOPLIST_KEY_UISupportedInterfaceOrientations": "UIInterfaceOrientationPortrait",
        "PRODUCT_BUNDLE_IDENTIFIER": '"$(DEPREMOLDU_BUNDLE_ID)"',
        "PRODUCT_NAME": '"$(TARGET_NAME)"',
        "SUPPORTED_PLATFORMS": '"iphoneos iphonesimulator"',
    }
    test_settings = {
        "BUNDLE_LOADER": '"$(TEST_HOST)"',
        "GENERATE_INFOPLIST_FILE": "YES",
        "PRODUCT_BUNDLE_IDENTIFIER": '"$(DEPREMOLDU_BUNDLE_ID).tests"',
        "PRODUCT_NAME": '"$(TARGET_NAME)"',
        "SUPPORTED_PLATFORMS": '"iphoneos iphonesimulator"',
        "TEST_HOST": '"$(BUILT_PRODUCTS_DIR)/DepremOldu.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/DepremOldu"',
    }
    ui_test_settings = {
        "GENERATE_INFOPLIST_FILE": "YES",
        "PRODUCT_BUNDLE_IDENTIFIER": '"$(DEPREMOLDU_BUNDLE_ID).uitests"',
        "PRODUCT_NAME": '"$(TARGET_NAME)"',
        "SUPPORTED_PLATFORMS": '"iphoneos iphonesimulator"',
        "TEST_TARGET_NAME": TARGET_APP,
    }

    xcconfig_by_name = {
        "Debug": file_ref_id(ROOT / "Configuration/Debug.xcconfig"),
        "Test": file_ref_id(ROOT / "Configuration/Test.xcconfig"),
        "Release": file_ref_id(ROOT / "Configuration/Release.xcconfig"),
    }

    for name, ref in xcconfig_by_name.items():
        config_id = stable_id(f"config:project:{name}")
        pbx_configs.append(config_block(config_id, name, ref, {}))

    for name, ref in xcconfig_by_name.items():
        config_id = stable_id(f"config:app:{name}")
        pbx_configs.append(config_block(config_id, name, ref, app_settings))

    for name, ref in xcconfig_by_name.items():
        config_id = stable_id(f"config:app-tests:{name}")
        pbx_configs.append(config_block(config_id, name, ref, test_settings))

    for name, ref in xcconfig_by_name.items():
        config_id = stable_id(f"config:ui-tests:{name}")
        pbx_configs.append(config_block(config_id, name, ref, ui_test_settings))

    def config_list(list_id: str, label: str, keys: list[str]) -> str:
        items = ",\n".join(f"\t\t\t\t{stable_id(key)}" for key in keys)
        return (
            f"{list_id} /* Build configuration list for {label} */ = {{\n"
            f"\t\t\tisa = XCConfigurationList;\n"
            f"\t\t\tbuildConfigurations = (\n{items},\n\t\t\t);\n"
            f"\t\t\tdefaultConfigurationIsVisible = 0;\n"
            f"\t\t\tdefaultConfigurationName = Release;\n"
            f"\t\t}};"
        )

    pbx_config_lists.append(
        config_list(
            stable_id("config-list:" + TARGET_APP),
            f'PBXNativeTarget "{TARGET_APP}"',
            [f"config:app:{name}" for name in ("Debug", "Test", "Release")],
        )
    )
    pbx_config_lists.append(
        config_list(
            stable_id("config-list:" + TARGET_APP_TESTS),
            f'PBXNativeTarget "{TARGET_APP_TESTS}"',
            [f"config:app-tests:{name}" for name in ("Debug", "Test", "Release")],
        )
    )
    pbx_config_lists.append(
        config_list(
            stable_id("config-list:" + TARGET_UI_TESTS),
            f'PBXNativeTarget "{TARGET_UI_TESTS}"',
            [f"config:ui-tests:{name}" for name in ("Debug", "Test", "Release")],
        )
    )
    project_config_list = stable_id("config-list:project")
    items = ",\n".join(
        f"\t\t\t\t{stable_id(f'config:project:{name}')}" for name in ("Debug", "Test", "Release")
    )
    pbx_config_lists.append(
        f"""{project_config_list} /* Build configuration list for PBXProject "{PROJECT_NAME}" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
{items},
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};"""
    )

    project_id = stable_id("project")
    pbx_project = f"""{project_id} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastUpgradeCheck = 2660;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\t{app_target} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 26.6;
\t\t\t\t\t}};
\t\t\t\t\t{app_tests_target} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 26.6;
\t\t\t\t\t\tTestTargetID = {app_target};
\t\t\t\t\t}};
\t\t\t\t\t{ui_tests_target} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 26.6;
\t\t\t\t\t\tTestTargetID = {app_target};
\t\t\t\t\t}};
\t\t\t\t}};
\t\t\t}};
\t\t\tbuildConfigurationList = {project_config_list};
\t\t\tcompatibilityVersion = "Xcode 16.0";
\t\t\tdevelopmentRegion = tr;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ttr,
\t\t\t\tBase,
\t\t\t);
\t\t\tmainGroup = {root_group_id};
\t\t\tminimizedProjectReferenceProxies = 1;
\t\t\tpackageReferences = (
\t\t\t\t{package_ref} /* XCLocalSwiftPackageReference "{package_ref_comment}" */,
\t\t\t);
\t\t\tproductRefGroup = {products_group_id} /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t{app_target} /* {TARGET_APP} */,
\t\t\t\t{app_tests_target} /* {TARGET_APP_TESTS} */,
\t\t\t\t{ui_tests_target} /* {TARGET_UI_TESTS} */,
\t\t\t);
\t\t}};"""

    def section(name: str, entries: list[str]) -> str:
        return f"/* Begin {name} section */\n" + "\n".join(entries) + f"\n/* End {name} section */\n"

    parts = [
        "// !$*UTF8*$!\n{\n\tarchiveVersion = 1;\n\tclasses = {\n\t};\n\tobjectVersion = 71;\n\tobjects = {\n",
        section("PBXBuildFile", pbx_build_files),
        section("PBXContainerItemProxy", [container_proxies]),
        section("PBXFileReference", pbx_file_refs),
        section("PBXFrameworksBuildPhase", frameworks_section),
        section("PBXGroup", pbx_groups),
        section("PBXNativeTarget", targets_section),
        section("PBXProject", [pbx_project]),
        section("PBXResourcesBuildPhase", resources_section),
        section("PBXSourcesBuildPhase", sources_section),
        section("PBXTargetDependency", [target_dependencies]),
        section("XCBuildConfiguration", pbx_configs),
        section("XCConfigurationList", pbx_config_lists),
        section(
            "XCLocalSwiftPackageReference",
            [
                f'{package_ref} /* XCLocalSwiftPackageReference "{package_ref_comment}" */ = {{\n\t\t\tisa = XCLocalSwiftPackageReference;\n\t\t\trelativePath = {PACKAGE_PATH};\n\t\t}};'
            ],
        ),
        section("XCSwiftPackageProductDependency", pbx_product_deps),
        "\t};\n\trootObject = " + project_id + " /* Project object */;\n}\n",
    ]
    pbxproj = "\n".join(parts)

    PROJECT_DIR.mkdir(parents=True, exist_ok=True)
    (PROJECT_DIR / "project.pbxproj").write_text(pbxproj, encoding="utf-8")

    workspace_dir = PROJECT_DIR / "project.xcworkspace"
    workspace_dir.mkdir(parents=True, exist_ok=True)
    (workspace_dir / "contents.xcworkspacedata").write_text(
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<Workspace\n   version = "1.0">\n'
        '   <FileRef\n      location = "self:">\n   </FileRef>\n'
        "</Workspace>\n",
        encoding="utf-8",
    )

    schemes_dir = PROJECT_DIR / "xcshareddata" / "xcschemes"
    schemes_dir.mkdir(parents=True, exist_ok=True)
    for scheme_name, build_configuration in (
        (f"{PROJECT_NAME}-Development", "Debug"),
        (f"{PROJECT_NAME}-Test", "Test"),
        (f"{PROJECT_NAME}-Release", "Release"),
    ):
        (schemes_dir / f"{scheme_name}.xcscheme").write_text(
            render_scheme(scheme_name, build_configuration, app_target, app_tests_target, ui_tests_target),
            encoding="utf-8",
        )

    print(f"Generated {relative(PROJECT_DIR / 'project.pbxproj')}")
    return 0


def render_scheme(
    name: str,
    configuration: str,
    app_target: str,
    app_tests_target: str,
    ui_tests_target: str,
) -> str:
    def buildable(blueprint_id: str, buildable_name: str, blueprint_name: str) -> str:
        return (
            f'<BuildableReference\n'
            f'               BuildableIdentifier = "primary"\n'
            f'               BlueprintIdentifier = "{blueprint_id}"\n'
            f'               BuildableName = "{buildable_name}"\n'
            f'               BlueprintName = "{blueprint_name}"\n'
            f'               ReferencedContainer = "container:{PROJECT_NAME}.xcodeproj">\n'
            f'            </BuildableReference>'
        )

    app_reference = buildable(app_target, f"{TARGET_APP}.app", TARGET_APP)
    app_tests_reference = buildable(
        app_tests_target, f"{TARGET_APP_TESTS}.xctest", TARGET_APP_TESTS
    )
    ui_tests_reference = buildable(
        ui_tests_target, f"{TARGET_UI_TESTS}.xctest", TARGET_UI_TESTS
    )

    return f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "2660"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES"
      buildArchitectures = "Automatic">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "NO"
            buildForArchiving = "NO"
            buildForAnalyzing = "YES">
            {app_reference}
         </BuildActionEntry>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "NO"
            buildForProfiling = "NO"
            buildForArchiving = "NO"
            buildForAnalyzing = "YES">
            {app_tests_reference}
         </BuildActionEntry>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "NO"
            buildForProfiling = "NO"
            buildForArchiving = "NO"
            buildForAnalyzing = "YES">
            {ui_tests_reference}
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "{configuration}"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
         <TestableReference
            skipped = "NO">
            {app_tests_reference}
         </TestableReference>
         <TestableReference
            skipped = "NO">
            {ui_tests_reference}
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "{configuration}"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "YES"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         {app_reference}
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
         {app_reference}
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "{configuration}">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
'''


if __name__ == "__main__":
    raise SystemExit(main())
