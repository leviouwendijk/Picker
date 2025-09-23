import Foundation
import SwiftUI
import plate
import Interfaces
import ViewComponents
import Compositions
import Implementations
import Interfaces

@main
struct PickerApp: App {
    @StateObject private var viewmodel = ResponderViewModel(pickerMode: true)

    public var errorMessage = ""

    init() {
        NSWindow.allowsAutomaticWindowTabbing = false
        // print("ResVM created at \(Unmanaged.passUnretained(viewmodel).toOpaque())")
        do {
            try prepareEnvironment()
        } catch {
            print(error)
            self.errorMessage = error.localizedDescription
        }
    }

    @State private var selectedTab: Int = 0

    var body: some Scene {
        WindowGroup {
            VStack {
                TabView(selection: $selectedTab) {
                    Picker()
                      .environmentObject(viewmodel)
                      .onAppear {
                          viewmodel.apiPathVm.selectedRoute = .appointment
                          viewmodel.apiPathVm.selectedEndpoint = .init(base: .confirmation)
                      }
                      .tabItem {
                          Label("Mailer", systemImage: "paperplane.fill")
                      }
                      .tag(0)

                    MailerStandardOutput()
                      .environmentObject(viewmodel)
                      .tabItem {
                          Label("stdout", systemImage: "terminal.fill")
                      }
                      .tag(2)

                    // CodeAndPreviewView()
                    //   .tabItem {
                    //       Label("lab", systemImage: "terminal.fill")
                    //   }
                    //   .tag(3)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)

                NotificationBanner(
                    type: .error,
                    message: self.errorMessage
                )
                .hide(when: self.errorMessage.isEmpty)

                BuildInformationSwitch(
                    alignment: .center,
                    display: [
                        [.version],
                        [.latestVersion],
                        [.name],
                        [.author]
                    ],
                    prefixStyle: .long
                )
            }
        }
    }
}

