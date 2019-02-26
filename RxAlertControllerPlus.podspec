# For details see: https://guides.cocoapods.org/syntax/podspec.html

Pod::Spec.new do |s|
    s.name         = "RxAlertControllerPlus"
    s.version      = "0.9.0"
    s.summary      = "Extension for ObservableType to use UIAlertController as a filter utilizing user responce"
    s.description  = <<-DESC
    Extension for ObservableType allowing to:
    - use UIAlertController as a filter utilizing user responce
    - display alert in chain of transformations of the observable
    DESC

    s.license      = { :type => "MIT", :file => "LICENSE" }
    s.author       = { "kodelit" => "kodel.company@gmail.com" }
    s.homepage     = "https://github.com/#{s.authors.keys[0]}/#{s.name}"
    s.social_media_url = "https://www.facebook.com/#{s.authors.keys[0]}"
    s.platform     = :ios, "9.0"
    s.source       = { :git => "https://github.com/#{s.authors.keys[0]}/#{s.name}.git", :tag => "#{s.version}" }
    s.source_files = "Source/*.swift"

    s.frameworks = 'UIKit'
    s.dependency "RxAlertController", '~> 4.0'
    s.ios.deployment_target = '9.0'
end
