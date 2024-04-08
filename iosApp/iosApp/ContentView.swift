//
//  ContentView.swift
//  iOSApp
//
//  Copyright 2024 thunderbiscuit, geigerzaehler, and contributors.
//  Use of this source code is governed by the Apache 2.0 license that can be found in the ./LICENSE.txt file.
//

import SwiftUI
//import SharedPadawan

struct ContentView: View {
    
// MARK: PROPERTIES
    
    @EnvironmentObject var viewModel: WalletViewModel
    @State var selectedTab: Int = 0

    enum Tab: Int {
        case firstTab = 0, secondTab, thirdTab
    }
    
// MARK: BODY
	var body: some View {
        
        Group {

            TabView(selection: $selectedTab) {
                            
                WalletView(selectedTab: $selectedTab)
                    .tabItem {
                        Image(systemName: "bitcoinsign.square.fill")
                        Text("Wallet")
                    }
                    .tag(Tab.firstTab.rawValue)
                
                LearnView(selectedTab: $selectedTab)
                    .tabItem {
                        Image(systemName: "graduationcap.fill")
                        Text("Learn")
                    }
                    .tag(Tab.secondTab.rawValue)
                
                MenuView(selectedTab: $selectedTab)
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                    .tabItem{
                        Image(systemName: "text.justify.trailing")
                        Text("Menu")
                    }
                    .tag(Tab.thirdTab.rawValue)
            }
//            .fullScreenCover(isPresented: $firstTimeRunning, content: {
//                WelcomeView()
//            })
        }
        .onAppear{
            viewModel.load()
        }
	}
}

// MARK: PREVIEW

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
            .environmentObject(WalletViewModel())
	}
}
