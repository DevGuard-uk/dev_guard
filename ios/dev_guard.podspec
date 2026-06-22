#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
Pod::Spec.new do |s|
  s.name             = 'dev_guard'
  s.version          = '1.0.2'
  s.summary          = 'DevGuard remote licensing and app protection for Flutter.'
  s.description      = <<-DESC
DevGuard remote licensing and app protection for Flutter.
                       DESC
  s.homepage         = 'https://github.com/DevGuard-uk/dev_guard'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'DevGuard UK' => 'contact@devguard.uk' }

  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.vendored_frameworks = 'Frameworks/devguard_core.xcframework'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
