"""Generate a dependency-free Xcode project. Run with Python 3 after adding sources."""
from pathlib import Path
import hashlib

root = Path(__file__).resolve().parent
objects = []
def uid(name):
    return hashlib.sha1(name.encode()).hexdigest()[:24].upper()
def add(name, body):
    objects.append(f'\t\t{uid(name)} = {{ {body} }};')
    return uid(name)
def refs(names):
    return '(' + ', '.join(uid(n) for n in names) + ')'

sources = ['PixelBloomApp.swift', 'Puzzle.swift', 'PaintStore.swift', 'ContentView.swift', 'ColoringAudio.swift', 'CharacterScenes.swift']
tests = ['PaintStoreTests.swift']
for name in sources + tests:
    add(name, f'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = "<group>";')
    add('build.' + name, f'isa = PBXBuildFile; fileRef = {uid(name)};')
add('Assets.xcassets', 'isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>";')
add('build.Assets.xcassets', f'isa = PBXBuildFile; fileRef = {uid("Assets.xcassets")};')
add('product.app', 'isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = PixelBloom.app; sourceTree = BUILT_PRODUCTS_DIR;')
add('product.tests', 'isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = PixelBloomTests.xctest; sourceTree = BUILT_PRODUCTS_DIR;')
add('main', f'isa = PBXGroup; children = {refs(["app.group", "test.group", "products"])}; sourceTree = "<group>";')
add('app.group', f'isa = PBXGroup; children = {refs(sources + ["Assets.xcassets"])}; path = PixelBloom; sourceTree = "<group>";')
add('test.group', f'isa = PBXGroup; children = {refs(tests)}; path = PixelBloomTests; sourceTree = "<group>";')
add('products', f'isa = PBXGroup; children = {refs(["product.app", "product.tests"])}; name = Products; sourceTree = "<group>";')
for target, files in [('app', sources), ('tests', tests)]:
    add(target + '.sources', f'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = {refs(["build." + n for n in files])}; runOnlyForDeploymentPostprocessing = 0;')
    for phase in ['frameworks', 'resources']:
        resource_files = refs(['build.Assets.xcassets']) if target == 'app' and phase == 'resources' else '()'
        add(target + '.' + phase, f'isa = PBX{phase.capitalize()}BuildPhase; buildActionMask = 2147483647; files = {resource_files}; runOnlyForDeploymentPostprocessing = 0;')
add('proxy', f'isa = PBXContainerItemProxy; containerPortal = {uid("project")}; proxyType = 1; remoteGlobalIDString = {uid("app")}; remoteInfo = PixelBloom;')
add('dependency', f'isa = PBXTargetDependency; target = {uid("app")}; targetProxy = {uid("proxy")};')
for name, product, product_type in [('app', 'PixelBloom', 'application'), ('tests', 'PixelBloomTests', 'bundle.unit-test')]:
    dep = refs(['dependency']) if name == 'tests' else '()'
    add(name, f'isa = PBXNativeTarget; buildConfigurationList = {uid(name + ".configs")}; buildPhases = {refs([name + ".sources", name + ".frameworks", name + ".resources"])}; buildRules = (); dependencies = {dep}; name = {product}; productName = {product}; productReference = {uid("product." + name)}; productType = "com.apple.product-type.{product_type}";')
for scope in ['project', 'app', 'tests']:
    for mode in ['Debug', 'Release']:
        settings = {
            'project': 'SDKROOT = iphoneos; IPHONEOS_DEPLOYMENT_TARGET = 17.0; SWIFT_VERSION = 5.0; CLANG_ENABLE_MODULES = YES; ENABLE_TESTABILITY = YES; SWIFT_OPTIMIZATION_LEVEL = ' + ('"-Onone";' if mode == 'Debug' else '"-O";') + ' DEBUG_INFORMATION_FORMAT = ' + ('dwarf;' if mode == 'Debug' else '"dwarf-with-dsym";'),
            'app': 'ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon; PRODUCT_BUNDLE_IDENTIFIER = com.example.PixelBloom; PRODUCT_NAME = "$(TARGET_NAME)"; TARGETED_DEVICE_FAMILY = 2; GENERATE_INFOPLIST_FILE = YES; INFOPLIST_KEY_CFBundleDisplayName = "Pixel Bloom"; INFOPLIST_KEY_UILaunchScreen_Generation = YES; INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES; INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"; CODE_SIGN_STYLE = Automatic; CURRENT_PROJECT_VERSION = 1; MARKETING_VERSION = 1.0; SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"; SUPPORTS_MACCATALYST = NO;',
            'tests': 'PRODUCT_BUNDLE_IDENTIFIER = com.example.PixelBloomTests; PRODUCT_NAME = "$(TARGET_NAME)"; GENERATE_INFOPLIST_FILE = YES; TARGETED_DEVICE_FAMILY = 2; CODE_SIGN_STYLE = Automatic; TEST_HOST = "$(BUILT_PRODUCTS_DIR)/PixelBloom.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/PixelBloom"; BUNDLE_LOADER = "$(TEST_HOST)";',
        }[scope]
        add(scope + '.' + mode, f'isa = XCBuildConfiguration; buildSettings = {{ {settings} }}; name = {mode};')
    add(scope + '.configs', f'isa = XCConfigurationList; buildConfigurations = {refs([scope + ".Debug", scope + ".Release"])}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
add('project', f'isa = PBXProject; attributes = {{ BuildIndependentTargetsInParallel = YES; LastUpgradeCheck = 1600; }}; buildConfigurationList = {uid("project.configs")}; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, Base); mainGroup = {uid("main")}; productRefGroup = {uid("products")}; projectDirPath = ""; projectRoot = ""; targets = {refs(["app", "tests"])};')
(root / 'PixelBloom.xcodeproj/project.pbxproj').write_text('// !$*UTF8*$!\n{\n\tarchiveVersion = 1;\n\tclasses = {};\n\tobjectVersion = 56;\n\tobjects = {\n' + '\n'.join(objects) + '\n\t};\n\trootObject = ' + uid('project') + ';\n}\n')
scheme = root / 'PixelBloom.xcodeproj/xcshareddata/xcschemes/PixelBloom.xcscheme'
scheme.parent.mkdir(parents=True, exist_ok=True)
def ref(target, product):
    return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{uid(target)}" BuildableName="{product}" BlueprintName="{product.split(".")[0]}" ReferencedContainer="container:PixelBloom.xcodeproj"/>'
scheme.write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{ref('app', 'PixelBloom.app')}</BuildActionEntry></BuildActionEntries></BuildAction>
<TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO">{ref('tests', 'PixelBloomTests.xctest')}</TestableReference></Testables></TestAction>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref('app', 'PixelBloom.app')}</BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref('app', 'PixelBloom.app')}</BuildableProductRunnable></ProfileAction>
<AnalyzeAction buildConfiguration="Debug"/>
<ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
''')
print('Generated PixelBloom.xcodeproj and shared scheme')
