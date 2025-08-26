import SwiftUI

struct ConnectWalletView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var router: Router

    @Environment(\.analyticsService) var analyticsService: AnalyticsService
    
    @EnvironmentObject var signInteractor: SignInteractor

    let displayWCConnection = false
    
    var wallets: [Wallet] {
        return [Wallet.CROSSx]
    }
    
    var body: some View {
        VStack {
            wcConnection()
            
            featuredWallets()
        }
        .padding(Spacing.s)
        .padding(.bottom)
    }
    
    @ViewBuilder
    private func featuredWallets() -> some View {
        ForEach(wallets, id: \.self) { wallet in
            Group {
                let isRecent: Bool = wallet.lastTimeUsed != nil
                let tagTitle: String? = isRecent ? "RECENT" : nil
                
                Button(action: {
                    Task {
                        do {
                            try await signInteractor.connect(walletUniversalLink: wallet.linkMode)
                            router.setRoute(Router.ConnectingSubpage.walletDetail(wallet))
                            analyticsService.track(.SELECT_WALLET(name: wallet.name, platform: .mobile))
                        } catch {
                            store.toast = .init(style: .error, message: error.localizedDescription)
                        }
                    }
                }, label: {
                    Text(wallet.name)
                })
                .buttonStyle(W3MListSelectStyle(
                    imageContent: { _ in
                        Group {
                            if let storedImage = store.walletImages[wallet.id] {
                                Image(uiImage: storedImage)
                                    .resizable()
                            } else {
                                Image.Regular.wallet
                                    .resizable()
                                    .padding(Spacing.xxs)
                            }
                        }
                        .background(Color.Overgray005)
                        .backport.overlay {
                            RoundedRectangle(cornerRadius: Radius.xxxs)
                                .stroke(.Overgray010, lineWidth: 1)
                        }
                    },
                    tag: tagTitle != nil ? .init(title: tagTitle!, variant: .info) : nil
                ))
            }
        }
    }
    
    @ViewBuilder
    private func wcConnection() -> some View {
        if displayWCConnection {
            Button(action: {
                router.setRoute(Router.ConnectingSubpage.qr)
            }, label: {
                Text("WalletConnect")
            })
            .buttonStyle(W3MListSelectStyle(
                imageContent: { _ in
                    ZStack {
                        Color.Blue100
                        
                        Image.imageLogo
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.white)
                    }
                },
                tag: W3MTag(title: "QR CODE", variant: .main)
            ))
        }
    }
}

struct ConnectWalletView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectWalletView()
    }
}
