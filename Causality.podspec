#
# Be sure to run `pod lib lint Causality.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Causality'
  s.version          = '0.0.3'
  s.summary          = 'A simple thread-safe, in-memory bus for Swift that supports fully-typed Events and States.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Causality is simple in-memory event bus for Swift. Events may have an
associated message and are fully typed. All publish/subscribe methods are
thread-safe.

In addition, Causality has provisions for monitoring State information. State
is similar to Event, but differ in that:

State handlers will be called immediately with the last known good value (if
one is available) State handlers will not be called if the state value is
identical to the previous value Whereas an Event has an associated Message, a
State has an associated Value.  A state's Value must conform to the Equatable
protocol.

                       DESC

  s.homepage         = 'https://github.com/dannys42/Causality'
  s.license          = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
  s.author           = { 'dannys42' => 'danny@dannysung.com' }
  s.source           = { :git => 'https://github.com/dannys42/Causality.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '11.0'

  s.source_files = 'Sources/Causality/**/*.swift'

  s.swift_versions = [ '5.1', '5.2', '5.3' ]
  
  # s.resource_bundles = {
  #   'Causality' => ['Causality/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
