//
//  SettingsView.swift
//  CIFilter.io
//
//  Created by Noah Gilmore on 8/4/19.
//  Copyright © 2019 Noah Gilmore. All rights reserved.
//

import SwiftUI
import Combine

struct SettingsView: View {
    let didTapDone = PassthroughSubject<Void, Never>()

    var debugView: some View {
        #if DEBUG
        return Section(header: Text("DEBUG").padding([.top], 20)) {
            HStack {
                Text("Nothing here right now")
            }
        }
        #else
        return EmptyView()
        #endif
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                HStack(alignment: .lastTextBaseline) {
                    Text("CIFilter.io")
                        .font(Font.title.bold())
                    Text("v\(AppDelegate.shared.appVersion())")
                        .font(.body)
                }.foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding([.top], 60)
                    .padding([.bottom], 10)
                List {
                    Section(header: Text("LINKS").padding([.top], 20)) {
                        Button(action: {
                            UIApplication.shared.open(URL(string: "https://twitter.com/cifilterio")!)
                        }) {
                            Text("Twitter")
                        }
                        Button(action: {
                            UIApplication.shared.open(URL(string: "https://github.com/noahsark769/cifilter.io")!)
                        }) {
                            Text("Github")
                        }
                        Button(action: {
                            UIApplication.shared.open(URL(string: "https://itunes.apple.com/us/app/cifilter-io/id1457458557?mt=8")!)
                        }) {
                            Text("Rate on App Store")
                        }
                        Button(action: {
                            UIApplication.shared.open(URL(string: "https://github.com/noahsark769/cifilter.io/issues")!)
                        }) {
                            Text("Report a Bug")
                        }
                    }
                    self.debugView
                }.listStyle(GroupedListStyle())
            }.background(Colors.primary)
            Button(action: { self.didTapDone.send() }) {
                Text("Done")
                    .font(Font.body.bold())
                    .foregroundColor(.white)
                    .padding([.top], 12)
                    .padding([.trailing], 14)
            }
        }
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
#endif
