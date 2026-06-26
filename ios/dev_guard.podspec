#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint dev_guard_ffi_tmp.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'dev_guard'
  s.version          = '1.0.4'
  s.summary          = 'Remote licensing and app protection for Flutter'
  s.description      = 'HMAC-signed REST telemetry, lock screens, and native security hardening for Flutter apps.'
  s.homepage         = 'https://github.com/DevGuard-uk/dev_guard'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.vendored_frameworks = 'Frameworks/devguard_core.xcframework'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
