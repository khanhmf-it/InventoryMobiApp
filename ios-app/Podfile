# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'BIVN' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for BIVN

pod 'Moya', '~> 15.0'
pod 'R.swift'
pod 'Kingfisher', '~> 7.9'
pod 'netfox'
pod 'DropDown', '2.3.13'
pod 'SnapKit'
pod 'IQKeyboardManagerSwift'
pod 'Localize-Swift', '~> 3.2'

  target 'BIVNTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'BIVNUITests' do
    # Pods for testing
  end
  post_install do |installer|
        installer.generated_projects.each do |project|
            project.targets.each do |target|
                target.build_configurations.each do |config|
                    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
                end
            end
        end
    end
end
