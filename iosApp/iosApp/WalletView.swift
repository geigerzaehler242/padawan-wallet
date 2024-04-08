//
//  WalletView.swift
//  iOSApp
//
//  Copyright 2024 thunderbiscuit, geigerzaehler, and contributors.
//  Use of this source code is governed by the Apache 2.0 license that can be found in the ./LICENSE.txt file.
//

import SwiftUI
import BitcoinDevKit

struct WalletView: View {
    
    @EnvironmentObject var viewModel: WalletViewModel
    @Binding var selectedTab: Int
   
    @State var navigationPath: [String] = []
    
    @State private var satsBTC = "BTC"
    var amountDisplayOptions = ["BTC", "sats"]
    
    var body: some View {

        NavigationStack(path: $navigationPath) {
            
            VStack(spacing: 20) {
                
                RoundedRectangle(cornerRadius: 20)
                    .frame(height: 200)
                    .foregroundColor( Color.purple)
                    .overlay(
                        VStack {
                            Spacer()
                            HStack {
                                Text("Bitcoin Testnet")
                                
                                Picker("Display in BTC or sats?", selection: $satsBTC) {
                                    ForEach(amountDisplayOptions, id: \.self) {
                                        Text($0)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .onChange(of: satsBTC) {
                                    if satsBTC == "BTC" {
                                        viewModel.toggleBTCDisplay(displayOption: "BTC")
                                    } else {
                                        viewModel.toggleBTCDisplay(displayOption: "sats")
                                    }
                                }
                            }
                            
                            Spacer()
                            VStack {
                                Text(viewModel.balanceText).font(.largeTitle)
                                Text("\(satsBTC)")
                            }
                            
                            Spacer()
                            Button(action: {
                                viewModel.sync()
                                satsBTC = amountDisplayOptions[0] //reset segment picker to display BTC
                            }, label: {
                                Text("Sync \(Image(systemName: "bitcoinsign.arrow.circlepath"))")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(height: 55)
                                .frame(maxWidth: .infinity)
                                .background(Color.black)
                                .cornerRadius(20)
                            }).padding(60)
                            
                        }.padding(20)
                    )
                
                HStack {
                    Button(action: {
                        navigationPath.append("Receive ↓")
                    }, label: {
                        Text("Receive ↓")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(height: 55)
                            .frame(maxWidth: .infinity)
                            .background(Color.teal)
                            .cornerRadius(20)
                    })
                    
                    Button(action: {
                        navigationPath.append("Send ↑")
                    }, label: {
                        Text("Send ↑")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(height: 55)
                            .frame(maxWidth: .infinity)
                            .background(Color.orange)
                            .cornerRadius(20)
                    })
                }
                .navigationDestination(for: String.self) { navigaionValue in
                    
                    switch viewModel.state {
                        
                        case .loaded(let wallet, let blockchain):
                            do {
                                switch navigaionValue {
                                    
                                case "Receive ↓":
                                    ReceiveView( navigationPath: $navigationPath)
                                case "Send ↑":
                                    SendView(onSend: { recipient, amount, fee in
                                        do {
                                            let address = try Address(address: recipient, network: wallet.network())
                                            let script = address.scriptPubkey()
                                            let txBuilder = TxBuilder().addRecipient(script: script, amount: amount)
                                                .feeRate(satPerVbyte: fee)
                                            let details = try txBuilder.finish(wallet: wallet)
                                            let _ = try wallet.sign(psbt: details.psbt, signOptions: nil)
                                            let tx = details.psbt.extractTx()
                                            try blockchain.broadcast(transaction: tx)
                                            let txid = details.psbt.txid()
                                            print(txid)
                                           
                                        } catch let error {
                                            print(error)
                                        }
                                    })
                                default:
                                    Text("undefined button value")
                                }
                            }
                        default: do { }
                    }
                }
                
                HStack() {
                    Text("Transactions")
                        .font(.title)
                    Spacer()
                }
                
                if viewModel.transactions.isEmpty {
                    
                    FaucetView()
                    
                } else {
                    List {
                                        
                        ForEach(
                            viewModel.transactions.sorted(
                                by: {
                                    $0.confirmationTime?.timestamp ?? $0.received > $1.confirmationTime?
                                        .timestamp ?? $1.received
                                }
                            ),
                            id: \.txid
                        ) 
                            { transaction in
                                
                                NavigationLink(
                                    destination: TransactionDetailsView(
                                        transaction: transaction,
                                        amount:
                                            transaction.sent > transaction.received
                                            ? transaction.sent - transaction.received
                                            : transaction.received - transaction.sent
                                    )
                                )
                                    {
            
                                        WalletTransactionsListItemView(transaction: transaction)
        //                                .refreshable {
        //                                    viewModel.sync()
        //                                    //viewModel.getBalance()
        //                                    //viewModel.getTransactions()
        //                                    //await viewModel.getPrices()
        //                                }
                                    }
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                        
                    }.listStyle(.plain)
                    
                }//viewModel.transactions.isEmpty
                
            }//VStack
            .padding(30)
           
        } //navigation stack
        .onAppear{
            viewModel.load()
        }
    } //body
}


struct FaucetView: View {
    
    @EnvironmentObject var viewModel: WalletViewModel
    @State private var faucetFailed = false
    
    var body: some View {
        
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                        .stroke(Color.black , lineWidth: 1)
                        .frame(width: 350, height: 150, alignment: Alignment.top   )
                        .layoutPriority(1) // default is 0, now higher priority than Text()
                Text("Hey! It looks like your transaction list is empty. Take a look around, and come back to get some coins so you can start playing with the wallet!").padding(20)
            }
        
            if viewModel.syncState == .synced { //only show button once synced!
                Button(action: {
                    //TODO add nnetwork call to get testnet coins!!
                    faucetFailed = true
                }, label: {
                    Text("Get coins \(Image(systemName: "bitcoinsign")) \(Image(systemName: "arrow.down.left"))")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(height: 55)
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .cornerRadius(20)
                })
                .padding(20)
                .alert("Faucet Not Implemented Yet!",
                       isPresented: $faucetFailed) {
                       Button("Ok", role: .destructive) {
                             // TODO
                       }
                } message: {
                       Text("Try to recover a wallet instead")
                }
            }
        
        }
    }
}

struct WalletTransactionsListItemView: View {
    let transaction: TransactionDetails
    let isRedacted: Bool

    init(transaction: TransactionDetails, isRedacted: Bool = false) {
        self.transaction = transaction
        self.isRedacted = isRedacted
    }

    var body: some View {
        HStack(spacing: 15) {
            
            if isRedacted {
                Image(
                    systemName:
                        "circle.fill"
                )
                .font(.largeTitle)
                .symbolRenderingMode(.palette)
                .foregroundStyle(
                    Color.gray.opacity(0.5)
                )
            } else {
                Image(
                    systemName:
                        transaction.sent > transaction.received
                    ? "arrow.up.circle.fill" : "arrow.down.circle.fill"
                )
                .font(.largeTitle)
                .symbolRenderingMode(.palette)
                .foregroundStyle(
                    transaction.confirmationTime != nil
                    ? Color.orange : Color.secondary,
                    isRedacted ? Color.gray.opacity(0.5) : Color.gray.opacity(0.05)
                )
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(transaction.txid)
                    .truncationMode(.middle)
                    .lineLimit(1)
                    .fontDesign(.monospaced)
                    .fontWeight(.semibold)
                    .font(.callout)
                    .foregroundColor(.primary)
                Text(
                    transaction.confirmationTime?.timestamp.toDate().formatted(
                        .dateTime.day().month().hour().minute()
                    )
                    ?? "Unconfirmed"
                )
            }
            .foregroundColor(.secondary)
            .font(.caption)
            .padding(.trailing, 30.0)
            .redacted(reason: isRedacted ? .placeholder : [])
            
            Spacer()
            Text(
                transaction.sent > transaction.received
                ? "- \(transaction.sent - transaction.received) sats"
                : "+ \(transaction.received - transaction.sent) sats"
            )
            .font(.caption)
            .fontWeight(.semibold)
            .fontDesign(.rounded)
            .redacted(reason: isRedacted ? .placeholder : [])
        }
        .padding(.vertical, 15.0)
        .padding(.vertical, 5.0)
    }//body
}

struct TransactionDetailsView: View {
//    @ObservedObject var viewModel: TransactionDetailsViewModel
    @EnvironmentObject var viewModel: WalletViewModel
    
    let transaction: TransactionDetails
    let amount: UInt64
    @State private var isCopied = false
    @State private var showCheckmark = false

    var body: some View {

        VStack {

            VStack(spacing: 8) {
                Image(systemName: "bitcoinsign.circle.fill")
                    .resizable()
                    .foregroundColor(.orange)
                    .fontWeight(.bold)
                    .frame(width: 100, height: 100, alignment: .center)
                HStack(spacing: 3) {
                    Text(
                        transaction.sent > transaction.received ? "Send" : "Receive"
                    )
                    if transaction.confirmationTime == nil {
                        Text("Unconfirmed")
                    } else {
                        Text("Confirmed")
                    }
                }
                .fontWeight(.semibold)
                if let height = transaction.confirmationTime?.height {
                    Text("Block \(height.delimiter)")
                        .foregroundColor(.secondary)
                }
            }
            .font(.caption)

            Spacer()

            VStack(spacing: 8) {
                HStack {
                    Text(amount.delimiter)
                    Text("sats")
                }
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .font(.largeTitle)
                .foregroundColor(.primary)
                .fontWeight(.bold)
                .fontDesign(.rounded)
                VStack(spacing: 4) {
                    if transaction.confirmationTime == nil {
                        Text("Unconfirmed")
                    } else {
                        VStack {
                            if let timestamp = transaction.confirmationTime?.timestamp {
                                Text(
                                    timestamp.toDate().formatted(
                                        date: .abbreviated,
                                        time: Date.FormatStyle.TimeStyle.shortened
                                    )
                                )
                            }
                        }
                    }
                    if let fee = transaction.fee {
                        Text("\(fee) sats fee")
                    }
                }
                .foregroundColor(.secondary)
                .font(.callout)
            }

            Spacer()

            HStack {
//                if viewModel.network != Network.regtest.description {
//                    Button {
//                        if let esploraURL = viewModel.esploraURL {
//                            let urlString = "\(esploraURL)/tx/\(transaction.txid)"
//                                .replacingOccurrences(of: "/api", with: "")
//                            if let url = URL(string: urlString) {
//                                UIApplication.shared.open(url)
//                            }
//                        }
//                    } label: {
//                        Image(systemName: "safari")
//                            .fontWeight(.semibold)
//                            .foregroundColor(.bitcoinOrange)
//                    }
//                    Spacer()
//                }
                Text(transaction.txid)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Button {
                    UIPasteboard.general.string = transaction.txid
                    isCopied = true
                    showCheckmark = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isCopied = false
                        showCheckmark = false
                    }
                } label: {
                    HStack {
                        withAnimation {
                            Image(systemName: showCheckmark ? "checkmark" : "doc.on.doc")
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                }
            }
            .fontDesign(.monospaced)
            .font(.caption)
            .padding()
            .onAppear {
 //               viewModel.getNetwork()
 //               viewModel.getEsploraUrl()
            }

        }
        .padding()

    }
}

#Preview {
    WalletView(selectedTab: .constant (0))
        .environmentObject(WalletViewModel())
}
