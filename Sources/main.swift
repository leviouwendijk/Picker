import SwiftUI
import Contacts
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

    var mailerCommand: String {
        let mailerArgs = MailerArguments(
            client: client,
            email: email,
            dog: dog,
            date: cliDate,
            time: cliTime,
            location: location,
            areaCode: areaCode,
            street: street,
            number: number
        )
        return mailerArgs.string(local, localLocation)
    }

    @State private var searchQuery = ""
    @State private var contacts: [CNContact] = []
    @State private var selectedContact: CNContact?

    var filteredContacts: [CNContact] {
        if searchQuery.isEmpty { return contacts }
        return contacts.filter {
            $0.givenName.lowercased().contains(searchQuery.lowercased()) ||
            $0.familyName.lowercased().contains(searchQuery.lowercased()) ||
            ($0.emailAddresses.first?.value as String?)?.lowercased().contains(searchQuery.lowercased()) ?? false
        }
    }

    @State private var local = false

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
            .frame(width: 200)
            
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
            .frame(width: 200)
            
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
                                client = ""
                                dog = ""
                                email = ""
                                location = ""
                                street = ""
                                areaCode = ""

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
        }
        .padding()
        .onAppear {
            fetchContacts()
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
    let date: String
    let time: String
    let location: String
    let areaCode: String?
    let street: String?
    let number: String?

    func string(_ local: Bool,_ localLocation: String) -> String {
        var components: [String] = [
            "mailer",
            "appointment",
            "--client \"\(client)\"",
            "--email \"\(email)\"",
            "--dog \"\(dog)\"",
            "--date \"\(date)\"",
            "--time \"\(time)\"",
            "--location \"\(local ? localLocation : location)\""
        ]

        if let areaCode = areaCode, !areaCode.isEmpty, !local {
            components.append("--area-code \"\(areaCode)\"")
        }
        if let street = street, !street.isEmpty, !local {
            components.append("--street \"\(street)\"")
        }
        if let number = number, !number.isEmpty, !local {
            components.append("--number \"\(number)\"")
        }

        return components.joined(separator: " ")
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
