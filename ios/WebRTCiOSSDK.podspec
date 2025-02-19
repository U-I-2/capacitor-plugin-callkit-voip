Pod::Spec.new do |s|
  s.name         = 'WebRTCiOSSDK'
  s.version      = '2.10.0'
  s.summary      = 'WebRTC iOS SDK by Ant Media'
  s.description  = 'WebRTC iOS SDK for integrating WebRTC functionalities.'
  s.homepage     = 'https://github.com/ant-media/WebRTC-iOS-SDK'
  s.license      = { :type => 'Apache-2.0', :file => 'LICENSE' }
  s.author       = { 'Ant Media' => 'contact@antmedia.io' }
  s.source       = { :git => 'https://github.com/ant-media/WebRTC-iOS-SDK.git' }
  s.platform     = :ios, '13.0'
  # Point to the folder where your header (and possibly other sources) live:
  s.source_files = 'WebRTCiOSSDK/**/*.{h,m,swift}'
  # Declare public headers (adjust the pattern if needed):
  s.public_header_files = 'WebRTCiOSSDK/*.h'
  # Include the prebuilt framework:
  s.vendored_frameworks = 'WebRTCiOSSDK.xcframework'
  s.requires_arc = true
  s.module_name = 'WebRTCiOSSDK'
  s.dependency 'Starscream', '~> 4.0.6'
end