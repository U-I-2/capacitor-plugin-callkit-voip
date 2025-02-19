Pod::Spec.new do |s|
  s.name             = 'capacitor-plugin-callkit-voip'
  s.version          = '5.0.0'
  s.summary          = 'Capacitor plugin for CallKit and VoIP push notifications'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'kin9aziz' => 'your-email@example.com' }
  s.homepage         = 'https://github.com/kin9aziz/capacitor-plugin-callkit-voip'
  s.source           = { :git => 'https://github.com/kin9aziz/capacitor-plugin-callkit-voip.git', :tag => s.version.to_s }
  s.platform         = :ios, '13.0'
  s.swift_version    = '5.0'

  # Source files
  s.source_files  = 'ios/Plugin/**/*.{h,m,swift}'
  
  # Capacitor dependencies
  s.dependency 'Capacitor', '~> 5.0'
  s.dependency 'CapacitorCordova', '~> 5.0'
  
  # WebRTC dependency
  s.dependency 'WebRTC-lib'

  # Required framework for CallKit and VoIP
  s.frameworks = 'CallKit', 'PushKit'
end