#
#  Be sure to run `pod spec lint IotaKit.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #
  s.swift_version = '4.0'
  s.name         = "IotaKit"
  s.version      = "0.5.3"
  s.summary      = "The IOTA Swift API Library"

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  s.description  = <<-DESC
  The IOTA Swift API Library.
  IotaKit is compatible with all architectures, tested on iOS/MacOS/Ubuntu.
                   DESC

  s.homepage     = "https://github.com/pascalbros/IotaKit"

  s.license      = "MIT (Copyright (c) 2018 Pasquale Ambrosini)"

  s.author             = { "Pasquale Ambrosini" => "pasquale.ambrosini@gmail.com" }

  s.ios.deployment_target = "11.0"
  s.osx.deployment_target = "10.10"

  s.source       = { :git => "https://github.com/pascalbros/IotaKit.git", :tag => "v#{s.version}" }

  s.source_files  = "Sources", "Sources/**/*.{h, swift}"
  #s.exclude_files = "Classes/Exclude"
  s.preserve_paths = 'Sources/IotaKit/include/sha3/module.modulemap'
  #s.module_map = 'Sources/IotaKit/include/sha3/module.modulemap'
  s.pod_target_xcconfig = { 'HEADER_SEARCH_PATHS' => '$(PODS_ROOT)/IotaKit/Sources/IotaKit/include/sha3/' }
end
