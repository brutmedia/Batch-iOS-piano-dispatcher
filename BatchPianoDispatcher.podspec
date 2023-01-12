Pod::Spec.new do |s|
  s.name             = 'BatchPianoDispatcher'
  s.version          = '1.0.0'
  s.summary          = 'Batch.com Events Dispatcher Piano implementation.'

  s.description      = <<-DESC
  A ready-to-go event dispatcher for Piano Analytics. Requires the Batch iOS SDK.
                       DESC

  s.homepage         = 'https://batch.com'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Batch.com' => 'support@batch.com' }
  s.source           = { :git => 'https://github.com/BatchLabs/Batch-iOS-piano-dispatcher.git', :tag => s.version.to_s }

  s.ios.deployment_target = '11.0'
  s.platforms = {
    "ios" => "11.0"
  }

  s.requires_arc = true
  s.static_framework = true
  
  s.dependency 'Batch', '~> 1.19'
  s.dependency 'PianoAnalytics/iOS', '>=3.0'  
  s.source_files = 'Sources/BatchPianoDispatcher/**/*'
end
