#!/usr/bin/env ruby
require 'xcodeproj'
require 'fileutils'

PROJECT_DIR = '/home/zmonster/Projects/stocknote-ios'
PROJECT_NAME = 'StockNote'

# Remove old project file
FileUtils.rm_rf("#{PROJECT_DIR}/#{PROJECT_NAME}.xcodeproj")

# Create new project
project = Xcodeproj::Project.new("#{PROJECT_DIR}/#{PROJECT_NAME}.xcodeproj")

# Add main target
target = project.new_target(:application, PROJECT_NAME, :ios, '17.0')

# Create groups matching directory structure
main_group = project.main_group
stocknote_group = main_group.new_group(PROJECT_NAME, PROJECT_NAME)

app_group = stocknote_group.new_group('App', 'App')
models_group = stocknote_group.new_group('Models', 'Models')
views_group = stocknote_group.new_group('Views', 'Views')
components_group = views_group.new_group('Components', 'Components')
services_group = stocknote_group.new_group('Services', 'Services')
resources_group = stocknote_group.new_group('Resources', 'Resources')

# Add source files
source_files = {
  app_group => [
    'StockNoteApp.swift',
    'ContentView.swift',
  ],
  models_group => [
    'Stock.swift',
    'Tag.swift',
    'Strategy.swift',
    'Deal.swift',
  ],
  views_group => [
    'WatchlistView.swift',
    'AddStockView.swift',
    'TagManagerView.swift',
    'StrategyView.swift',
    'AddStrategyView.swift',
    'AddDealView.swift',
    'SettingsView.swift',
  ],
  components_group => [
    'StockRow.swift',
  ],
  services_group => [
    'EastMoneyAPI.swift',
    'PriceService.swift',
  ],
}

source_files.each do |group, files|
  files.each do |filename|
    file_path = "#{group.real_path}/#{filename}"
    file_ref = group.new_file(file_path)
    target.source_build_phase.add_file_reference(file_ref)
  end
end

# Add Assets.xcassets
assets_ref = resources_group.new_file('Assets.xcassets')
target.resources_build_phase.add_file_reference(assets_ref)

# Configure build settings
target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.linusp.stocknote'
  config.build_settings['INFOPLIST_KEY_CFBundleDisplayName'] = '股记'
  config.build_settings['INFOPLIST_KEY_UIApplicationSceneManifest_Generation'] = 'YES'
  config.build_settings['INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents'] = 'YES'
  config.build_settings['INFOPLIST_KEY_UILaunchScreen_Generation'] = 'YES'
  config.build_settings['INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone'] = 'UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight'
  config.build_settings['INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad'] = 'UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  config.build_settings['SWIFT_EMIT_LOC_STRINGS'] = 'YES'
  config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
  config.build_settings['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'] = 'AccentColor'
  config.build_settings['MARKETING_VERSION'] = '1.0'
  config.build_settings['CURRENT_PROJECT_VERSION'] = '1'
  config.build_settings['DEVELOPMENT_TEAM'] = ''
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
  config.build_settings['ENABLE_PREVIEWS'] = 'YES'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks']
end

# Set project-level build settings
project.build_configurations.each do |config|
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['CLANG_ENABLE_MODULES'] = 'YES'
  config.build_settings['ALWAYS_SEARCH_USER_PATHS'] = 'NO'

  if config.name == 'Debug'
    config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf'
    config.build_settings['GCC_OPTIMIZATION_LEVEL'] = '0'
    config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
    config.build_settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = 'DEBUG'
    config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
    config.build_settings['MTL_ENABLE_DEBUG_INFO'] = 'INCLUDE_SOURCE'
  else
    config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf-with-dsym'
    config.build_settings['SWIFT_COMPILATION_MODE'] = 'wholemodule'
    config.build_settings['VALIDATE_PRODUCT'] = 'YES'
    config.build_settings['ENABLE_NS_ASSERTIONS'] = 'NO'
  end
end

# Save project
project.save

# Create workspace files
workspace_dir = "#{PROJECT_DIR}/#{PROJECT_NAME}.xcodeproj/project.xcworkspace"
FileUtils.mkdir_p("#{workspace_dir}/xcshareddata")

File.write("#{workspace_dir}/contents.xcworkspacedata", <<~XML)
<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "self:">
   </FileRef>
</Workspace>
XML

File.write("#{workspace_dir}/xcshareddata/IDEWorkspaceChecks.plist", <<~XML)
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>IDEDidComputeMac32BitWarning</key>
	<true/>
</dict>
</plist>
XML

puts "Project generated successfully!"
