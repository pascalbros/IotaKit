
Pod::Spec.new do |s|

  s.swift_versions = ['5.1', '5.2']
  s.name         = "IotaKit"
  s.version      = "0.8.8"
  s.summary      = "The IOTA Swift API Library"

  s.description  = <<-DESC
  The IOTA Swift API Library.
  IotaKit is compatible with all architectures, tested on iOS/MacOS/Ubuntu.
                   DESC

  s.homepage     = "https://github.com/pascalbros/IotaKit"

  s.license      = "MIT 2020 Pasquale Ambrosini"
  s.source       = { :git => "https://github.com/pascalbros/IotaKit.git", :tag => "v#{s.version}" }
  s.author             = { "Pasquale Ambrosini" => "pasquale.ambrosini@gmail.com" }

  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.10"
  s.requires_arc = true

  s.module_map = 'IotaKit.modulemap'
  s.source_files = 'Sources/**/*.{swift,c,h}'
  s.pod_target_xcconfig = {'SWIFT_INCLUDE_PATHS' => '$(PODS_TARGET_SRCROOT)/Sources/sha3/** $(PODS_TARGET_SRCROOT)/Sources/cpow','LIBRARY_SEARCH_PATHS' => '$(PODS_TARGET_SRCROOT)/Sources/', 'SWIFT_VERSION' => '4.0'}
  s.exclude_files = 'Sources/IotaKit/Utils/Crypto.swift'
  s.preserve_paths  = 'Sources/sha3/include/module.modulemap', 'Sources/cpow/include/module.modulemap'
end
