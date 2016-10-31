Pod::Spec.new do |s|
  s.name             = "SwiftDDP"
  s.version          = "0.3.2"
  s.summary          = "A DDP Client for communicating with Meteor servers, written in Swift. Supports OAuth login with Facebook, Google, Twitter & Github."

  s.description      = <<-DESC "A DDP Client for communicating with DDP Servers (Meteor JS), written in Swift. Supports OAuth authentication with Facebook, Google, Twitter & Github."
                       DESC

  s.homepage         = "https://github.com/siegesmund/SwiftDDP"
  s.license          = 'MIT'
  s.author           = { "Peter Siegesmund" => "peter.siegesmund@icloud.com" }
  s.source           = { :git => "https://github.com/black-lotus/SwiftDDP.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/psiegesmund'

  s.requires_arc = true
  s.platform = :ios, '8.1'
  s.source_files = 'SwiftDDP/**/*.swift'

  s.dependency 'CryptoSwift', '~> 0.3.1'
  s.dependency 'SwiftWebSocket', '2.6.0'
  s.dependency 'XCGLogger', '3.5.1'

end
