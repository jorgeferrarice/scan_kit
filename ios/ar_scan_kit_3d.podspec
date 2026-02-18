Pod::Spec.new do |s|
  s.name             = 'ar_scan_kit_3d'
  s.version          = '0.1.0'
  s.summary          = 'Flutter plugin for 3D scanning with ARKit.'
  s.description      = 'Uses LiDAR and TrueDepth sensors for real-time 3D mesh capture.'
  s.homepage         = 'https://github.com/jorgeferrarice/ar_scan_kit_3d'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Jorge L Ferrari Ce' => 'jorge@jorgeferrarice.dev' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '15.0'
  s.swift_version    = '5.0'
  s.frameworks       = 'ARKit', 'SceneKit'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
