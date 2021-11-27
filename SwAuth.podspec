Pod::Spec.new do |s|
  s.name             = 'SwAuth'
  s.version          = '1.0.0'
  s.summary          = 'Swift async/await OAuth 2.0 HTTP request library.'

  s.homepage         = 'https://github.com/Colaski/SwAuth'
  s.license          = { :type => 'MIT', :file => 'LICENSE.md' }
  s.author           = { 'Colaski' => 'colaskidev@gmail.com' }
  s.source           = { :git => 'https://github.com/Colaski/SwAuth.git', :tag => s.version.to_s }

  s.ios.deployment_target = '15.0'
  s.osx.deployment_target = '12.0'
  s.watchos.deployment_target = '8.0'
  s.tvos.deployment_target = '15.0'

  s.swift_version = '5.5'

  s.source_files = 'Sources/SwAuth/**/*'

  s.dependency = 'KeychainAccess', '~> 4.2'
  s.dependency = 'EFQRCode', '~> 6.1'
end