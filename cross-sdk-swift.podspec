require "json"

package = JSON.parse(File.read(File.join(__dir__, "Sources/WalletConnectRelay/PackageConfig.json")))

Pod::Spec.new do |spec|

  spec.name        = "cross-sdk-swift"
  spec.version     = package["version"]
  spec.summary     = "CrossSDKSwift - Easy CROSSx wallet integration for Dapp developers"
  spec.description = "CrossSDKSwift provides an easy way for Dapp developers to integrate CROSSx wallet connections. It pre-defines common functionality needed when using ReownAppKit, enhancing developer convenience for Dapp development."
  spec.homepage    = "https://github.com/to-nexus/cross-sdk-swift"
  spec.license     = { :type => 'Apache-2.0', :file => 'LICENSE' }
  spec.authors          = "NEXUS"
  spec.source = {
    :git => 'https://github.com/to-nexus/cross-sdk-swift.git',
    :tag => spec.version.to_s
  }

  spec.platform     = :ios, '13.0'
  spec.swift_versions = '5.9'
  spec.pod_target_xcconfig = {
    'OTHER_SWIFT_FLAGS' => '-DCocoaPods'
  }

  spec.default_subspecs = 'CrossSDKSwift'

  spec.subspec 'CrossSDKSwift' do |ss|
    ss.source_files = 'Sources/CrossSDKSwift/**/*.{h,m,swift}'
    ss.dependency 'cross-sdk-swift/CrossAppKit'
    ss.dependency 'cross-sdk-swift/WalletConnectSign'
    ss.resource_bundles = {
      'CrossSDKSwift' => [
        'Sources/CrossSDKSwift/Resources/*'
      ]
    }
  end

  spec.subspec 'WalletKit' do |ss|
    ss.source_files = 'Sources/WalletKit/**/*.{h,m,swift}'
    ss.dependency 'cross-sdk-swift/WalletConnectSign'
    ss.dependency 'cross-sdk-swift/WalletConnectPush'
    ss.dependency 'cross-sdk-swift/WalletConnectVerify'
  end

  spec.subspec 'AppKitBackport' do |ss|
    ss.source_files = 'Sources/AppKitBackport/**/*.{h,m,swift}'
  end

  spec.subspec 'AppKitUI' do |ss|
    ss.source_files = 'Sources/AppKitUI/**/*.{h,m,swift}'
    ss.dependency 'cross-sdk-swift/AppKitBackport'
    ss.resource_bundles = {
      'AppKitUI' => [
        'Sources/AppKitUI/Resources/*'
      ]
    }
  end

  spec.subspec 'CrossAppKit' do |ss|
    ss.source_files = 'Sources/CrossAppKit/**/*.{h,m,swift}'
    ss.dependency 'cross-sdk-swift/WalletConnectSign'
    ss.dependency 'cross-sdk-swift/AppKitUI'
    ss.dependency 'cross-sdk-swift/AppKitBackport'
    ss.dependency 'DSF_QRCode', '~> 16.1.1'
    ss.dependency 'CoinbaseWalletSDK', '~> 1.0.0'
    ss.resource_bundles = {
      'CrossAppKit' => [
        'Sources/CrossAppKit/Resources/*'
      ]
    }
  end

  spec.subspec 'WalletConnectSign' do |ss|
    ss.source_files = 'Sources/WalletConnectSign/**/*.{h,m,swift}'
    ss.dependency 'cross-sdk-swift/WalletConnectPairing'
    ss.dependency 'cross-sdk-swift/WalletConnectSigner'
    ss.dependency 'cross-sdk-swift/WalletConnectVerify'
    ss.dependency 'cross-sdk-swift/Events'
  end

  spec.subspec 'WalletConnectVerify' do |ss|
    ss.source_files = 'Sources/WalletConnectVerify/**/*.{h,m,swift}'
    ss.dependency 'cross-sdk-swift/WalletConnectUtils'
    ss.dependency 'cross-sdk-swift/WalletConnectNetworking'
  end

  spec.subspec 'WalletConnectSigner' do |ss|
    ss.source_files = 'Sources/WalletConnectSigner/**/*.{h,m,swift}'
    ss.dependency 'cross-sdk-swift/WalletConnectNetworking'
  end

  spec.subspec 'WalletConnectIdentity' do |ss|
    ss.source_files = 'Sources/WalletConnectIdentity/**/*.{h,m,swift}'
    ss.dependency 'cross-sdk-swift/WalletConnectNetworking'
    ss.dependency 'cross-sdk-swift/WalletConnectJWT'
  end

  spec.subspec 'WalletConnectPush' do |ss|
    ss.source_files = 'Sources/WalletConnectPush/**/*.{h,m,swift}'
    ss.dependency 'cross-sdk-swift/WalletConnectNetworking'
    ss.dependency 'cross-sdk-swift/WalletConnectJWT'
  end

  spec.subspec 'WalletConnectJWT' do |ss|
    ss.source_files = 'Sources/WalletConnectJWT/**/*.{h,m,swift}'
    ss.dependency 'cross-sdk-swift/WalletConnectKMS'
  end

  spec.subspec 'WalletConnectNetworking' do |ss|
    ss.source_files = 'Sources/WalletConnectNetworking/**/*.{h,m,swift}'
    ss.dependency 'cross-sdk-swift/WalletConnectRelay'
    ss.dependency 'cross-sdk-swift/HTTPClient'
  end

  spec.subspec 'WalletConnectPairing' do |ss|
    ss.source_files = 'Sources/WalletConnectPairing/**/*.{h,m,swift}'
    ss.dependency 'cross-sdk-swift/WalletConnectNetworking'
    ss.dependency 'cross-sdk-swift/Events'
  end

  spec.subspec 'CrossRouter' do |ss|
    ss.source_files = 'Sources/CrossRouter/**/*.{h,m,swift}'
    ss.platform = :ios
  end

  spec.subspec 'WalletConnectRelay' do |ss|
    ss.source_files = 'Sources/WalletConnectRelay/**/*.{h,m,swift}'
    ss.dependency 'cross-sdk-swift/WalletConnectJWT'
    ss.resource_bundles = {
      'WalletConnect_WalletConnectRelay' => [
         'Sources/WalletConnectRelay/PackageConfig.json'
      ]
    }
  end

  spec.subspec 'WalletConnectUtils' do |ss|
    ss.source_files = 'Sources/WalletConnectUtils/**/*.{h,m,swift}'
    ss.dependency 'cross-sdk-swift/JSONRPC'
  end

  spec.subspec 'WalletConnectKMS' do |ss|
    ss.source_files = 'Sources/WalletConnectKMS/**/*.{h,m,swift}'
    ss.dependency 'cross-sdk-swift/WalletConnectUtils'
  end

  spec.subspec 'Commons' do |ss|
    ss.source_files = 'Sources/Commons/**/*.{h,m,swift}'
  end

  spec.subspec 'Events' do |ss|
    ss.source_files = 'Sources/Events/**/*.{h,m,swift}'
    ss.dependency 'cross-sdk-swift/WalletConnectNetworking'
    ss.dependency 'cross-sdk-swift/WalletConnectUtils'
  end

  spec.subspec 'JSONRPC' do |ss|
    ss.source_files = 'Sources/JSONRPC/**/*.{h,m,swift}'
    ss.dependency 'cross-sdk-swift/Commons'
  end

  spec.subspec 'HTTPClient' do |ss|
    ss.source_files = 'Sources/HTTPClient/**/*.{h,m,swift}'
  end

end
