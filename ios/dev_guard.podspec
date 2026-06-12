#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
Pod::Spec.new do |s|
  s.name             = 'dev_guard'
  s.version          = '1.0.0'
  s.summary          = 'Remote licensing and app protection for Flutter.'
  s.description      = <<-DESC
DevGuard Flutter plugin with native FFI security (HMAC signing, gzip telemetry tunnel),
lock screens, warning banners, remote wipe, and hardware fingerprinting.
                       DESC
  s.homepage         = 'https://github.com/DevGuard-uk/dev_guard'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'DevGuard' => 'support@devguard.uk' }

  s.source           = { :git => 'https://github.com/DevGuard-uk/dev_guard.git', :tag => 'v#{s.version}' }
  s.source_files = 'Classes/**/*'
  s.vendored_frameworks = 'Frameworks/devguard_core.xcframework'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
