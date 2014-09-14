#
# Be sure to run `pod lib lint BDRouter.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "BDRouter"
  s.version          = "0.2.2"
  s.summary          = "App router and history manager for iOS."
  s.description      = <<-DESC
                       Unobtrusive app router and history manager for iOS.
                       DESC
  s.homepage         = "https://github.com/dachev/BDRouter"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Blagovest Dachev" => "blago@dachev.com" }
  s.source           = { :git => "https://github.com/dachev/BDRouter.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform     = :ios, '6.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes'
  # s.resources = 'Pod/Assets/*.png'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'Underscore.m', '~> 0.2'
end
