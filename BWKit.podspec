#
# Be sure to run `pod lib lint BWKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'BWKit'
  s.version          = '1.0.0'
  s.summary          = '百微SDK。'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/YuHua/BWKit'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'YuHua' => '316910279@qq.com' }
  s.source           = { :git => 'https://github.com/YuHua/BWKit.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = 'BWKit/Classes/**/*'
  
  # s.resource_bundles = {
  #   'BWKit' => ['BWKit/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'SQLite.swift', '0.12.2'
  s.dependency 'SwiftyBeaver', '1.9.2'
  s.dependency 'CocoaAsyncSocket', '7.6.4'
  s.dependency 'ObjectMapper', '4.2.0'
  s.dependency 'SwiftyJSON', '5.0.0'
  s.dependency 'Alamofire', '4.9.1'
  s.dependency 'CryptoSwift', '1.3.2'
end
