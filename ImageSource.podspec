Pod::Spec.new do |s|
  s.name                   = 'ImageSource'
  s.module_name            = 'ImageSource'
  s.version                = '3.0.1'
  s.summary                = 'Image abstraction toolkit'
  s.homepage               = 'https://github.com/avito-tech/ImageSource'
  s.license                = 'MIT'
  s.author                 = { 'Andrey Yutkin' => 'ayutkin@avito.ru' }
  s.source                 = { :git => 'https://github.com/avito-tech/ImageSource.git', :tag => "#{s.version}" }
  s.platform               = :ios, '9.0'
  s.ios.deployment_target  = '9.0'
  s.swift_version          = '5.0'
  s.requires_arc           = true
  s.default_subspec        = 'Core', 'PHAsset', 'Local', 'Remote', 'AlamofireImage'
  
  s.subspec 'Core' do |cs|
  	cs.frameworks = 'CoreGraphics'
    cs.source_files = 'ImageSource/Core/*'
  end
  
  s.subspec 'PHAsset' do |ps|
    ps.frameworks = 'Photos'
	  ps.dependency 'ImageSource/Core'
	  ps.source_files = 'ImageSource/PHAsset/*'
  end
  
  s.subspec 'Local' do |ls|
    ls.frameworks = 'ImageIO', 'MobileCoreServices'
	  ls.dependency 'ImageSource/Core'
	  ls.source_files = 'ImageSource/Local/*'
  end
  
  s.subspec 'Remote' do |rs|
    rs.frameworks = 'ImageIO', 'MobileCoreServices'
    rs.dependency 'ImageSource/Core'
    rs.dependency 'ImageSource/UIKit'
    rs.source_files = 'ImageSource/Remote/*'
  end

  s.subspec 'SDWebImage' do |sw|
    sw.dependency 'ImageSource/Remote'
    sw.dependency 'SDWebImage', '~> 3.8'
    sw.source_files = 'ImageSource/SDWebImage/*'
  end

  s.subspec 'AlamofireImage' do |ai|
    ai.dependency 'ImageSource/Remote'
    ai.dependency 'AlamofireImage', '~> 3.4'
    ai.source_files = 'ImageSource/AlamofireImage/*'
  end
  
  s.subspec 'UIKit' do |uis|
    uis.frameworks = 'UIKit'
	  uis.dependency 'ImageSource/Core'
	  uis.source_files = 'ImageSource/UIKit/*'
  end
end
