#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint dev_guard_ffi_tmp.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'dev_guard'
  s.version          = '1.0.1'
  s.summary          = 'Remote licensing and app protection for Flutter.'
  s.description      = <<-DESC
DevGuard secures Flutter apps with HMAC-signed REST sync, native FFI, lock screens, and remote governance.
                       DESC
  s.homepage         = 'https://github.com/DevGuard-uk/dev_guard'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'DevGuard' => 'contact@devguard.uk' }

  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.vendored_frameworks = 'Frameworks/devguard_core.xcframework'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
