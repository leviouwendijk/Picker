import Foundation
import SwiftUI
import Contacts
import EventKit
import plate
import Economics
import Compositions
import ViewComponents
import Interfaces
import Implementations

struct Picker: View {
    @EnvironmentObject var viewmodel: ResponderViewModel

    var body: some View {
        VStack {
                HStack {
                    // CORE DIFFERENCE TO RESPONDER.APP/

                    // MailerAPIPathSelectionView(
                    //     viewModel: viewmodel.apiPathVm
                    // )
                    // .frame(width: 450)

                    VariablesView(
                        // viewmodel: viewmodel
                    )
                    // .environmentObject(viewmodel)
                    .frame(minWidth: 380)

                    Divider()

                    ValuesPaneView()
                    // .environmentObject(viewmodel)
                    .frame(minWidth: 400)
                }
                .padding()

            ExecuteMailerView(
                // viewmodel: viewmodel
            )
            .environmentObject(viewmodel)
            .padding(.top, 8)
        }
    }
}
