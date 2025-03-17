import SwiftUI
import Contacts
import EventKit
import plate

struct DatePickerView: View {
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth = Calendar.current.component(.month, from: Date()) {
        didSet { validateDay() }
    }
    @State private var selectedDay = Calendar.current.component(.day, from: Date())
    @State private var selectedHour = 12
    @State private var selectedMinute = 0
    @State private var outputFormat = "yyyy-MM-dd HH:mm"
    
    private let months = Calendar.current.monthSymbols
    private let hours = Array(0...23)
    private let minutes = Array(0...59)
    
    private var days: [Int] {
        let dateComponents = DateComponents(year: year, month: selectedMonth)
        if let range = Calendar.current.range(of: .day, in: .month, for: Calendar.current.date(from: dateComponents)!) {
            return Array(range)
        }
        return Array(1...31)
    }
    
    private func validateDay() {
        if selectedDay > days.count {
            selectedDay = days.count
        }
    }
    
    var formattedDate: String {
        let dateComponents = DateComponents(year: year, month: selectedMonth, day: selectedDay, hour: selectedHour, minute: selectedMinute)
        if let date = Calendar.current.date(from: dateComponents) {
            let formatter = DateFormatter()
            formatter.dateFormat = outputFormat
            return formatter.string(from: date)
        }
        return ""
    }

    var formattedOutput: String {
        if outputFormat == "--date dd/MM/yyyy --time HH:mm" {
            return String(format: "--date %02d/%02d/%04d --time %02d:%02d",
                          selectedDay, selectedMonth, year, selectedHour, selectedMinute)
        }
        return formattedDate
    }

    @State private var showMailerFields = true
    @State private var client = ""
    @State private var email = ""
    @State private var dog = ""
    @State private var location = ""
    @State private var areaCode: String?
    @State private var street: String?
    @State private var number: String?
    @State private var localLocation = "Alkmaar"

    var cliDate: String {
        return String(format: "%02d/%02d/%04d", selectedDay, selectedMonth, year)
    }

    var cliTime: String {
        return String(format: "%02d:%02d", selectedHour, selectedMinute)
    }

    @State private var appointmentsQueue: [Appointment] = [] // ⬅️ Holds multiple appointments

    var mailerCommand: String {
        let mailerArgs = MailerArguments(
            client: client,
            email: email,
            dog: dog,
            appointmentsJSON: appointmentsQueueToJSON(appointmentsQueue)
            // date: cliDate,
            // time: cliTime,
            // location: location,
            // areaCode: areaCode,
            // street: street,
            // number: number
        )
        return mailerArgs.string()
    }

    @State private var searchQuery = ""
    @State private var contacts: [CNContact] = []
    @State private var selectedContact: CNContact?

    var filteredContacts: [CNContact] {
        if searchQuery.isEmpty { return contacts }
        let normalizedQuery = searchQuery.normalizedForSearch
        return contacts.filter {
            $0.givenName.normalizedForSearch.contains(normalizedQuery) ||
            $0.familyName.normalizedForSearch.contains(normalizedQuery) ||
            (($0.emailAddresses.first?.value as String?)?.normalizedForSearch.contains(normalizedQuery) ?? false)
        }
    }

    @State private var local = false

    /// **Formats a selected date into the appointment structure**
    private func createAppointment() -> Appointment {
        let dateString = String(format: "%02d/%02d/%04d", selectedDay, selectedMonth, year)
        let timeString = String(format: "%02d:%02d", selectedHour, selectedMinute)
        let dayString = getDayName(day: selectedDay, month: selectedMonth, year: year)

        return Appointment(
            date: dateString,
            time: timeString,
            day: dayString,
            street: local ? "" : (street ?? ""),
            number: local ? "" : (number ?? ""),
            areaCode: local ? "" : (areaCode ?? ""),
            location: local ? localLocation : location
        )
    }

    /// **Adds the selected appointment to the queue**
    private func addToQueue() {
        let newAppointment = createAppointment()
        if !appointmentsQueue.contains(where: { $0.date == newAppointment.date && $0.time == newAppointment.time }) {
            appointmentsQueue.append(newAppointment)
        }
    }

    /// **Clears the queue**
    private func clearQueue() {
        appointmentsQueue.removeAll()
    }

    /// **Removes an appointment from the queue**
    private func removeAppointment(at index: Int) {
        appointmentsQueue.remove(at: index)
    }

    /// **Get the Dutch name of the selected day**
    private func getDayName(day: Int, month: Int, year: Int) -> String {
        let dateComponents = DateComponents(year: year, month: month, day: day)
        let calendar = Calendar.current
        if let date = calendar.date(from: dateComponents) {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "nl_NL") // Dutch locale
            formatter.dateFormat = "EEEE" // Full day name
            return formatter.string(from: date).capitalized
        }
        return "Onbekend"
    }

    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    @State private var showSuccessBanner = false
    @State private var successBannerMessage = ""

    var body: some View {
        HStack {
            // Month selector
            VStack {
                Text("Months").bold()
                List(0..<months.count, id: \.self) { index in
                    Button(action: { selectedMonth = index + 1 }) {
                        Text(months[index])
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .padding()
                            .background(selectedMonth == index + 1 ? Color.blue.opacity(0.3) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .contentShape(Rectangle()) 
                }
                .scrollContentBackground(.hidden) 
            }
            .frame(width: 180)
            
            // Day selector
            VStack {
                Text("Days").bold()
                List(days, id: \.self) { day in
                    Button(action: { selectedDay = day }) {
                        Text("\(day)")
                            .frame(maxWidth: .infinity, minHeight: 40) 
                            .padding()
                            .background(selectedDay == day ? Color.blue.opacity(0.3) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 8)) 
                    }
                    .contentShape(Rectangle()) 
                }
                .scrollContentBackground(.hidden)
            }
            .frame(width: 140)
            
            // Hours selector
            VStack {
                Text("Hours").bold()
                List(hours, id: \.self) { hour in
                    Button(action: { selectedHour = hour }) {
                        Text("\(hour, specifier: "%02d")")
                            .frame(maxWidth: .infinity, minHeight: 40) 
                            .padding()
                            .background(selectedHour == hour ? Color.blue.opacity(0.3) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 8)) 
                    }
                    .contentShape(Rectangle()) 
                }
                .scrollContentBackground(.hidden)
            }
            .frame(width: 120)

            // Minutes selector
            VStack {
                Text("Minutes").bold()
                List(minutes, id: \.self) { minute in
                    Button(action: { selectedMinute = minute }) {
                        Text("\(minute, specifier: "%02d")")
                            .frame(maxWidth: .infinity, minHeight: 40) 
                            .padding()
                            .background(selectedMinute == minute ? Color.blue.opacity(0.3) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 8)) 
                    }
                    .contentShape(Rectangle()) 
                }
                .scrollContentBackground(.hidden) 

                Spacer()
                Divider()
                Spacer()

                Text("Common").bold()
                List([0, 15, 30, 45], id: \.self) { minute in
                    Button(action: { selectedMinute = minute }) {
                        Text("\(minute, specifier: "%02d")")
                            .frame(maxWidth: .infinity, minHeight: 40) 
                            .padding()
                            .background(selectedMinute == minute ? Color.blue.opacity(0.3) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 8)) 
                    }
                    .contentShape(Rectangle()) 
                }
                .scrollContentBackground(.hidden) 
            }
            .frame(width: 120)
            
            // Output and format control
            VStack {
                HStack {
                    Spacer()
                    Toggle("Show Mailer Arguments", isOn: $showMailerFields)
                        .padding()
                    Spacer()
                    Button("Load Contacts") {
                        requestContactsAccess()
                    }
                    .padding()
                    Spacer()
                    Toggle("Local Location", isOn: $local)
                    .padding()
                }

                if showMailerFields {
                    VStack(alignment: .leading) {
                        // Contact Search Bar
                        TextField("Search Contacts", text: $searchQuery)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)

                        // Contact List
                        List(filteredContacts, id: \.identifier) { contact in
                            Button(action: {
                                clearContact()

                                selectedContact = contact

                                let split = splitClientDog(contact.givenName)
                                client = split.name
                                dog = split.dog
                                email = contact.emailAddresses.first?.value as String? ?? ""
                                
                                if let postalAddress = contact.postalAddresses.first?.value {
                                    location = postalAddress.city
                                    street = postalAddress.street
                                    areaCode = postalAddress.postalCode
                                }
                            }) {
                                HStack {
                                    Text("\(contact.givenName) \(contact.familyName)")
                                        .font(selectedContact?.identifier == contact.identifier ? .headline : .body)
                                    Spacer()
                                    Text(contact.emailAddresses.first?.value as String? ?? "")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .scrollContentBackground(.hidden) 
                        .frame(height: 200)

                        Text("Mailer Arguments").bold()
                        
                        TextField("Client", text: $client)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("Dog", text: $dog)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        TextField("Location", text: Binding(
                            get: { local ? localLocation : location },
                            set: { location = $0 }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                        TextField("Area Code", text: Binding(
                            get: { local ? "" : (areaCode ?? "") },
                            set: { areaCode = local ? nil : ($0.isEmpty ? nil : $0) }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                        TextField("Street", text: Binding(
                            get: { local ? "" : (street ?? "") },
                            set: { street = local ? nil : ($0.isEmpty ? nil : $0) }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                        TextField("Number", text: Binding(
                            get: { local ? "" : (number ?? "") },
                            set: { number = local ? nil : ($0.isEmpty ? nil : $0) }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding()
                }

                Text("Preset Formats").bold()
                Picker("Select Format", selection: $outputFormat) {
                    Text("YYYY-MM-DD HH:mm").tag("yyyy-MM-dd HH:mm")
                    Text("DD/MM/YYYY HH:mm").tag("dd/MM/yyyy HH:mm")
                    Text("MM-DD-YYYY HH:mm").tag("MM-dd-yyyy HH:mm")
                    Text("ISO 8601").tag("yyyy-MM-dd'T'HH:mm:ssZ")
                    Text("CLI (mailer)").tag("--date dd/MM/yyyy --time HH:mm")
                }
                .pickerStyle(MenuPickerStyle())
                .padding()

                Spacer()

                VStack {
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(formattedOutput, forType: .string)
                    }) {
                        Text(formattedOutput)
                            .bold()
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(5)
                    }
                    .buttonStyle(PlainButtonStyle()) 

                    if showMailerFields {
                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(mailerCommand, forType: .string)
                        }) {
                            Text(mailerCommand)
                                .bold()
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(5)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .frame(width: 400)

            Divider()

            VStack {
                Text("Appointments Queue").bold()

                if appointmentsQueue.isEmpty {
                    Text("No appointments added")
                        .foregroundColor(.gray)
                } else {
                    ScrollView {
                        ForEach(appointmentsQueue.indices, id: \.self) { index in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("📅 \(appointmentsQueue[index].date) (\(appointmentsQueue[index].day))")
                                    Text("🕒 \(appointmentsQueue[index].time)")
                                    if !appointmentsQueue[index].street.isEmpty {
                                        Text("\(appointmentsQueue[index].street) \(appointmentsQueue[index].number)")
                                    }
                                    if !appointmentsQueue[index].areaCode.isEmpty {
                                        Text("\(appointmentsQueue[index].areaCode)")
                                    }
                                    Text("📍 \(appointmentsQueue[index].location)")
                                }
                                Spacer()
                                Button(action: { removeAppointment(at: index) }) {
                                    Image(systemName: "x.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                        }
                    }
                }

                Spacer()

                // **Queue Management Buttons**
                if showSuccessBanner {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                            Text(successBannerMessage)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.green)
                        .cornerRadius(8)
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom))
                    }
                    .animation(.easeInOut, value: showSuccessBanner)
                } else {
                    HStack {
                        Button(action: addToQueue) {
                            Label("Add to Queue", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)

                        Button(action: clearQueue) {
                            Label("Clear Queue", systemImage: "trash.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.bordered)

                        Button(action: sendConfirmationEmail) {
                            Label("Send confirmation", systemImage: "paperplane.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.top, 10)
                }
            }
            .frame(width: 400)
        }
        .padding()
        .onAppear {
            fetchContacts()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private func requestContactsAccess() {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { granted, error in
            if granted {
                fetchContacts()
            } else {
                print("Access denied: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    private func fetchContacts() {
        let store = CNContactStore()
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactEmailAddressesKey, CNContactPostalAddressesKey] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)

        var fetchedContacts: [CNContact] = []
        try? store.enumerateContacts(with: request) { contact, _ in
            fetchedContacts.append(contact)
        }

        DispatchQueue.main.async {
            contacts = fetchedContacts
        }
    }

    private func sendConfirmationEmail() {
        let data = MailerArguments(
            client: client,
            email: email,
            dog: dog,
            appointmentsJSON: appointmentsQueueToJSON(appointmentsQueue)
        )
        let arguments = data.string(false)

        // Execute on a background thread to avoid blocking the UI
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try executeMailer(arguments)
                // Prepare success alert on the main thread
                DispatchQueue.main.async {
                    successBannerMessage = "The confirmation email was sent successfully."
                    showSuccessBanner = true

                    clearQueue()
                    clearContact()

                    // Auto-dismiss after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            showSuccessBanner = false
                        }
                    }
                }
            } catch {
                // Prepare failure alert on the main thread
                DispatchQueue.main.async {
                    alertTitle = "Error"
                    alertMessage = "There was an error sending the confirmation email:\n\(error.localizedDescription) \(arguments)"
                    showAlert = true
                }
            }
        }
    }

    private func clearContact() {
        client = ""
        email = ""
        dog = ""
        location = ""
        areaCode = ""
        street = ""
        number = ""
        selectedContact = nil
    }
}

struct Client {
    let name: String
    let dog: String
}

func splitClientDog(_ givenName: String) -> Client {
    var name = "ERR"
    var dog = "ERR"

    let split = givenName.components(separatedBy: " | ")

    if split.count == 2 {
        name = String(split[0]).trimTrailing()
        dog = String(split[1]).trimTrailing()
    } else {
        print("Invalid input format: expected 'ClientName | DogName'")
    }

    return Client(name: name, dog: dog)
}

struct MailerArguments {
    let client: String
    let email: String
    let dog: String
    let appointmentsJSON: String
    // let date: String
    // let time: String
    // let location: String
    // let areaCode: String?
    // let street: String?
    // let number: String?

    // func string(_ local: Bool,_ localLocation: String) -> String {
    func string(_ includeBinaryName: Bool = true) -> String {
        if includeBinaryName {
            let components: [String] = [
                "mailer",
                "appointment",
                "--client \"\(client)\"",
                "--email \"\(email)\"",
                "--dog \"\(dog)\"",
                "\(appointmentsJSON)",
                // "--date \"\(date)\"",
                // "--time \"\(time)\"",
                // "--location \"\(local ? localLocation : location)\""
                ""
            ]

            // if let areaCode = areaCode, !areaCode.isEmpty, !local {
            //     components.append("--area-code \"\(areaCode)\"")
            // }
            // if let street = street, !street.isEmpty, !local {
            //     components.append("--street \"\(street)\"")
            // }
            // if let number = number, !number.isEmpty, !local {
            //     components.append("--number \"\(number)\"")
            // }

            return components.joined(separator: " ")
        } else {
            let components: [String] = [
                "appointment",
                "--client \"\(client)\"",
                "--email \"\(email)\"",
                "--dog \"\(dog)\"",
                "\(appointmentsJSON)",
                ""
            ]

            return components.joined(separator: " ")
        }
    }

}

struct Appointment: Identifiable {
    let id = UUID()
    let date: String
    let time: String
    let day: String
    let street: String
    let number: String
    let areaCode: String
    let location: String

    func jsonString() -> String {
        // if !appointment.street.isEmpty && !appointment.number.isEmpty && !appointment.areaCode.isEmpty {
        // is handled by api
        return "{\"date\": \"\(self.date)\", \"time\": \"\(self.time)\", \"day\": \"\(self.day)\", \"location\": \"\(self.location)\", \"area\": \"\(self.areaCode)\", \"street\": \"\(self.street)\", \"number\": \"\(self.number)\"}"
    }
}

func appointmentsQueueToJSON(_ appointments: [Appointment]) -> String {
    var jsonString = ""
    for (index, appt) in appointments.enumerated() {
        if index > 0 {
            jsonString.append(", ")
        }
        let jsonAppointment = appt.jsonString()
        jsonString.append(jsonAppointment)
    }
    return jsonString.wrapJsonForCLI()
}

func executeMailer(_ arguments: String) throws {
    do {
        let home = Home.string()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh") // Use Zsh directly
        process.arguments = ["-c", "source ~/dotfiles/.vars.zsh && \(home)/sbm-bin/mailer \(arguments)"]
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let outputString = String(data: outputData, encoding: .utf8) ?? ""
        let errorString = String(data: errorData, encoding: .utf8) ?? ""

        if process.terminationStatus == 0 {
            print("numbers-parser executed successfully:\n\(outputString)")
        } else {
            print("Error running numbers-parser:\n\(errorString)")
            throw NSError(domain: "numbers-parser", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: errorString])
        }
    } catch {
        print("Error running commands: \(error)")
        throw error
    }
}

// Replace '|' with space, split by whitespace, remove empty parts, and join back
extension String {
    var normalizedForSearch: String {
        return self.folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: "|", with: " ")
            .components(separatedBy: CharacterSet.whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .lowercased()
    }
}

extension String {
    func wrapJsonForCLI() -> String {
        return "'[\(self)]'"
    }
}

struct ContentView: View {
    var body: some View {
        DatePickerView()
    }
}

@main
struct DatePickerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
