#
# Be sure to run `pod lib lint KVKCalendar.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'KVKCalendar'
  s.version          = '0.1.0'
  s.summary          = 'Fully customized calendar with weekly timeline and day for iOS.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  Fully customized calendar with timeline for the week and day. Display appointments for a month, view the calendar for a year.
                       DESC

  s.homepage         = 'https://github.com/kvyatkovskys/KVKCalendar'
  s.license          = { :type => 'MIT', :file => 'LICENSE.md' }
  s.author           = { 'Sergei Kviatkovskii' => 'sergejkvyatkovskij@gmail.com' }
  s.source           = { :git => 'https://github.com/kvyatkovskys/KVKCalendar.git', :tag => s.version.to_s }
  s.social_media_url = 'https://github.com/kvyatkovskys'
  s.ios.deployment_target = '9.0'
  s.source_files = 'KVKCalendar/Classes/*.swift'
  s.swift_version = '4.2'
end
