Pod::Spec.new do |s|
    s.name         = 'WebRTCiOSSDK'
    s.version      = '1.0.0'
    s.summary      = 'WebRTC iOS SDK by Ant Media'
    s.description  = 'WebRTC iOS SDK for integrating WebRTC functionalities.'
    s.homepage     = 'https://github.com/ant-media/WebRTC-iOS-SDK'
    s.license      = { :type => 'Apache-2.0', :file => 'LICENSE' }
    s.author       = { 'Ant Media' => 'contact@antmedia.io' }
    s.source       = { :git => 'https://github.com/ant-media/WebRTC-iOS-SDK.git' }
    s.platform     = :ios, '13.0'
    s.source_files = 'src/**/*.{h,m,swift}' # Adjust according to the repository structure
    s.requires_arc = true
  end