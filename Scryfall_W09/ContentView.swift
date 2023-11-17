//
//  ContentView.swift
//  Scryfall_W09
//
//  Created by MacBook Pro on 10/11/23.
//
import Foundation

struct CardData: Codable {
    let data: [Card]
}

struct Card: Codable, Hashable {
    let name: String
    let type_line: String
    let oracle_text: String
    let mana_cost: String
    let image_uris: ImageURIs
    let prices: Prices
    let legalities: [String: String]
    let games: [String]
    let collector_number: String


    func hash(into hasher: inout Hasher) {
        hasher.combine(image_uris.large)
    }

    static func == (lhs: Card, rhs: Card) -> Bool {
        return lhs.image_uris.large == rhs.image_uris.large
    }
}


struct Prices: Codable {
    let usd: String?
    let usd_foil: String?
    let eur: String?
    let eur_foil: String?
}


struct ImageURIs: Codable {
    let large: String
    let normal: String
    let art_crop: String
    let border_crop: String
}



import SwiftUI

class ImageLoader: ObservableObject {
    @Published var image: UIImage?

    init(url: URL) {
        downloadImage(url: url)
    }

    private func downloadImage(url: URL) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data {
                DispatchQueue.main.async {
                    self.image = UIImage(data: data)
                }
            }
        }.resume()
    }
}

enum SortMode {
    case alphabetical
    case numeric
}

struct ContentView: View {
    @State private var gridLayout = [GridItem(.adaptive(minimum: 50))]
    @State private var isShowingDetail = false
    @State private var selectedCard: Card?
    @State private var searchText = ""
    @State private var cards: [Card]
    @State private var isAscendingOrder = true
    @State private var cachedImages: [String: UIImage] = [:]
    @State private var sortMode: SortMode = .alphabetical
    @State private var colorScheme: ColorScheme = .dark
    
    var sortedCards: [Card] {
        return isAscendingOrder ? filteredCards.sorted { card1, card2 in
            if sortMode == .alphabetical {
                return card1.name < card2.name
            } else {
                guard let number1 = Int(card1.collector_number), let number2 = Int(card2.collector_number) else {
                    return card1.name < card2.name
                }
                return number1 < number2
            }
        } : filteredCards.sorted { card1, card2 in
            if sortMode == .alphabetical {
                return card1.name > card2.name
            } else {
                guard let number1 = Int(card1.collector_number), let number2 = Int(card2.collector_number) else {
                    return card1.name > card2.name
                }
                return number1 > number2
            }
        }
    }
    
    var filteredCards: [Card] {
        if searchText.isEmpty {
            return cards
        } else {
            return cards.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    init() {
        self._cards = State(initialValue: ContentView.loadJSONData())
        let appearance = UINavigationBarAppearance()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
        UINavigationBar.appearance().standardAppearance = appearance
    }
    
    func getNextCardDetails() {
        if let currentIndex = sortedCards.firstIndex(of: selectedCard!) {
            let nextIndex = (currentIndex + 1) % sortedCards.count
            selectedCard = sortedCards[nextIndex]
        }
    }

    func getPreviousCardDetails() {
        if let currentIndex = sortedCards.firstIndex(of: selectedCard!) {
            let previousIndex = (currentIndex - 1 + sortedCards.count) % sortedCards.count
            selectedCard = sortedCards[previousIndex]
        }
    }

    var body: some View {
        NavigationView {
            TabView {
                VStack {
                    Text("Scryfall")
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .font(.largeTitle)
                        .padding(.bottom, 10)
                    HStack {
                        
                        SearchBar(text: $searchText)
                            .padding(4)
                            .background(Color(.systemGray6))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .cornerRadius(8)
                            .frame(minWidth: 0, maxWidth: 600) // Set the frame to make it expand to the maximum width
                            .padding(.horizontal)
                            .accentColor(.orange)
                        
                        Menu {
                            Button(action: {
                                // Sort A-Z (ascending alphabet)
                                isAscendingOrder = true
                                sortMode = .alphabetical
                            }) {
                                Label("Sort A-Z", systemImage: "arrow.up")
                            }

                            Button(action: {
                                // Sort Z-A (descending alphabet)
                                isAscendingOrder = false
                                sortMode = .alphabetical
                            }) {
                                Label("Sort Z-A", systemImage: "arrow.down")
                            }

                            Divider()

                            Button(action: {
                                // Sort by Collector Number Ascending
                                isAscendingOrder = true
                                sortMode = .numeric
                            }) {
                                Label("Sort by Collector Number Ascending", systemImage: "number")
                            }

                            Button(action: {
                                // Sort by Collector Number Descending
                                isAscendingOrder = false
                                sortMode = .numeric
                            }) {
                                Label("Sort by Collector Number Descending", systemImage: "arrow.down.number")
                            }
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .padding()
                        }


                    }
                    Spacer()
                    
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 200), spacing: 10),
                            GridItem(.adaptive(minimum: 200), spacing: 10),
                        ], spacing: 10) {
                            ForEach(sortedCards, id: \.self) { card in
                                VStack(spacing: 8) {
                                    NavigationLink(destination: CardDetailsView(
                                        card: card,
                                        onNextCardTapped: {
                                            getNextCardDetails()
                                        },
                                        onPreviousCardTapped: {
                                            getPreviousCardDetails()
                                        }
                                    )) {
                                        CardImageView(card: card, cachedImages: $cachedImages)
                                    }
                                }
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .onAppear {
                        let screenRect = UIScreen.main.bounds
                        let screenWidth = screenRect.size.width
                        gridLayout = [GridItem(.adaptive(minimum: screenWidth / 3))]
                        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
                    }
                    .background(colorScheme == .dark ? Color.black : Color.white)
                    Toggle("Dark Mode", isOn: colorSchemeToggle)
                                        .toggleStyle(SwitchToggleStyle(tint: .orange))
                                        .padding()
                }
                .background(colorScheme == .dark ? Color.black : Color.white)
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                    .foregroundColor(colorScheme == .dark ? .white : .black)

                    // In Development 1
                    ZStack {
                        Color.black.edgesIgnoringSafeArea(.all)
                        Text("In Development 1")
                            .foregroundColor(.white)
                    }
                    .tabItem {
                        Label("In Development 1", systemImage: "gear")
                    }
                    .foregroundColor(.white)

                    // In Development 2
                    ZStack {
                        Color.black.edgesIgnoringSafeArea(.all)
                        Text("In Development 2")
                            .foregroundColor(.white)
                    }
                    .tabItem {
                        Label("In Development 2", systemImage: "gear")
                    }
                    .foregroundColor(.white)

                    // In Development 3
                    ZStack {
                        Color.black.edgesIgnoringSafeArea(.all)
                        Text("In Development 3")
                            .foregroundColor(.white)
                    }
                    .tabItem {
                        Label("In Development 3", systemImage: "person")
                    }
                }
                .background(colorScheme == .dark ? Color.black : Color.white) // Set the background color of the TabView
                .accentColor(colorScheme == .dark ? .white : .black) // Set accent color dynamically
                .onAppear {
                    let tabBarAppearance = UITabBar.appearance()
                    tabBarAppearance.barTintColor = colorScheme == .dark ? UIColor.black : UIColor.white // Set background color dynamically
                }
                .accentColor(colorScheme == .dark ? .white : .black) // Set accent color dynamically
                .navigationBarHidden(true)
                .navigationViewStyle(StackNavigationViewStyle())
                .preferredColorScheme(colorScheme)
            
        }
    }
    
    public var colorSchemeToggle: Binding<Bool> {
        Binding(
            get: { colorScheme == .dark },
            set: {
                colorScheme = $0 ? .dark : .light
            }
        )
    }
    
    
}


struct CardImageView: View {
    let card: Card
    @Binding var cachedImages: [String: UIImage]

    var onNextCardTapped: (() -> Void)?
    
    var body: some View {
        NavigationLink(destination: CardDetailsView(card: card)) {
            if let uiImage = cachedImages[card.image_uris.art_crop] {
                ZStack(alignment: .topLeading) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 200, maxHeight: .infinity)
                    
                    VStack {
                        Text(card.name)
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                Rectangle()
                                    .foregroundColor(Color.black.opacity(0.4))
                                    .frame(minWidth: 300, maxWidth: 150)
                            )
                            .frame(maxWidth: .infinity)
                    }
                    ZStack(alignment: .bottomLeading) {
                        // Rounded Rectangle
                        RoundedRectangle(cornerRadius: 8)
                            .foregroundColor(Color.black.opacity(0.8))
                            .frame(width: 76, height: 25)
                        VStack(alignment: .leading, spacing: 4) {
                            Spacer() // Spasi di bawah gambar
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    Image("foil")
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                        .padding(.leading, 3)
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .foregroundColor(Color.black.opacity(0.8))
                                )
                                
                                Text("$\(card.prices.usd_foil ?? "")")
                                    .font(.footnote)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                    .padding(.bottom, 1.5)
                            }
                        }
                    }
                    
                }

                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
            } else {
                AsyncImageLoader(url: URL(string: card.image_uris.art_crop)!) { image in
                    cachedImages[card.image_uris.art_crop] = image
                } onFailure: { error in
                    print("Failed to load image: \(error)")
                }
                .frame(height: 150)
            }
        }
    }
}


struct CardDetailsView: View {
    let card: Card?
    @Environment(\.presentationMode) var presentationMode
    @State private var isImageZoomed = false
    @State private var selectedButton: String = "Versions"
    @Environment(\.colorScheme) var colorScheme
    
    var onNextCardTapped: (() -> Void)?
    var onPreviousCardTapped: (() -> Void)?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    if let card = card, let url = URL(string: card.image_uris.art_crop) {
                        GeometryReader { geometry in
                            ZStack {
                                // Your original image with blur background
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: geometry.size.width, height: geometry.size.height * 0.8)
                                            .clipped()
                                            .blur(radius: isImageZoomed ? 10 : 0) // Apply blur when zoomed
                                            .onTapGesture {
                                                isImageZoomed.toggle()
                                            }
                                    default:
                                        ProgressView()
                                    }
                                }
                                .frame(width: geometry.size.width, height: geometry.size.height * 0.8)

                                // Centered large image
                                if isImageZoomed {
                                    VStack {
                                        Spacer()
                                        AsyncImage(url: URL(string: card.image_uris.large)) { phase in
                                            switch phase {
                                            case .success(let largeImage):
                                                largeImage
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(maxHeight: .infinity)
                                                    .background(GeometryReader { proxy in
                                                        Color.clear
                                                            .alignmentGuide(HorizontalAlignment.center) { dimensions in
                                                                dimensions[HorizontalAlignment.center]
                                                            }
                                                            .alignmentGuide(VerticalAlignment.center) { dimensions in
                                                                dimensions[VerticalAlignment.center]
                                                            }
                                                    })
                                            default:
                                                ProgressView()
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.white)
                                        .cornerRadius(16)
                                        Spacer()
                                    }
                                    .padding()
                                }
                            }
                            .onTapGesture {
                                isImageZoomed.toggle()
                            }
                            .frame(height: UIScreen.main.bounds.height * 0.4)
                        }
                        .frame(height: UIScreen.main.bounds.height * 0.4)
                    }


                    VStack(alignment: .leading) {
                        HStack {
                            Text(card?.name ?? "")
                                .font(.title2)
                                .bold()
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            Spacer() // Spacer agar mana_cost rata kanan
                            manaCostOverlay()
                        }
                        Text(card?.type_line ?? "")
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        Text(card?.oracle_text ?? "")
                            .font(.caption)
                            .padding()
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    .multilineTextAlignment(.leading)
                    .padding()
                    .foregroundColor(colorScheme == .dark ? .white : .black)

                    
                    HStack {
//                        Button(action: {
//                            // Previous card button tapped
//                            onPreviousCardTapped?()
//                        }) {
//                            Image(systemName: "chevron.left.circle.fill")
//                                .font(.title)
//                                .foregroundColor(colorScheme == .dark ? .white : .black)
//                                .padding()
//                        }
//
//                        Spacer()

                        Button(action: {
                            // Logic untuk tombol Versions
                            selectedButton = "Versions"
                        }) {
                            Text("Versions")
                                .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                                .foregroundColor(selectedButton == "Versions" ? .white : .gray)
                                .background(selectedButton == "Versions" ? Color.orange : Color.clear)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.gray, lineWidth: 0.2) // Border color and width
                                )
                        }


                        Button(action: {
                            // Logic untuk tombol Ruling
                            selectedButton = "Ruling"
                        }) {
                            Text("Ruling")
                                .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                                .foregroundColor(selectedButton == "Ruling" ? .white : .gray)
                                .background(selectedButton == "Ruling" ? Color.orange : Color.clear)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.gray, lineWidth: 0.2) // Border color and width
                                )
                        }
                        
//                        Spacer()
//
//                        Button(action: {
//                            // Next card button tapped
//                            onNextCardTapped?()
//                        }) {
//                            Image(systemName: "chevron.right.circle.fill")
//                                .font(.title)
//                                .foregroundColor(colorScheme == .dark ? .white : .black)
//                                .padding()
//                        }
//                        


                    }
                    .padding(.top, 10)

                    if selectedButton == "Versions", let prices = card?.prices {
                        // Display card prices
                        HStack(spacing: 10) {
                            VStack(alignment: .leading) { // Set alignment to .leading
                                Text("Prices")
                                    .font(.caption)
                                    .bold()
                                    .padding(.bottom, 8)
                                    .foregroundColor(.blue)

                                Text("USD: \(prices.usd ?? "N/A")")
                                    .padding(.bottom, 4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)

                                Text("USD Foil: \(prices.usd_foil ?? "N/A")")
                                    .padding(.bottom, 4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)

                                Text("EUR: \(prices.eur ?? "N/A")")
                                    .padding(.bottom, 4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)

                                Text("EUR Foil: \(prices.eur_foil ?? "N/A")")
                                    .padding(.bottom, 4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    } else if selectedButton == "Ruling", let legalities = card?.legalities {
                        // Display card legalities
                        // You may customize the layout as needed
                        VStack(alignment: .leading) {
                            Text("Legalities")
                                .font(.caption)
                                .bold()
                                .padding(.bottom, 8)
                                .foregroundColor(.blue)
                            
                            ForEach(legalities.sorted(by: { $0.key < $1.key }), id: \.key) { legality in
                                HStack {
                                    Text(legality.key.capitalized.replacingOccurrences(of: "_", with: " "))
                                    Spacer()

                                    // Handle "Not_Legal" case
                                    Text(legality.value.capitalized == "Not_Legal" ? "Not Legal" : legality.value.capitalized)
                                        .foregroundColor(legality.value == "legal" ? .white : .white)
                                        .padding(.horizontal, 10) // Add horizontal padding to text
                                        .background(RoundedRectangle(cornerRadius: 5)
                                            .fill(legality.value == "legal" ? Color.green : Color.gray))
                                    
                                        .padding(.horizontal, 8) // Adjust horizontal padding around the RoundedRectangle

                                }
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .padding(.vertical, 4)
                                // Add vertical padding to the HStack
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle(Text(card?.name ?? "") .foregroundColor(colorScheme == .dark ? .white : .black))
            }
            .background(colorScheme == .dark ? Color.black : Color.white)
        }
    }
    
    private func manaImageName(for symbol: String) -> String? {
        switch symbol {
        case "{1}":
            return "one"
        case "{2}":
            return "two"
        case "{3}":
            return "three"
        case "{4}":
            return "four"
        case "{7}":
            return "seven"
        case "{W}":
            return "white"
        case "{B}":
            return "black"
        case "{U}":
            return "blue"
        case "{R}":
            return "red"
        case "{G}":
            return "green"
        default:
            return nil
        }
    }

    private func manaCostOverlay() -> some View {
        guard let manaCost = card?.mana_cost else {
            return AnyView(EmptyView()) // Return an empty view if mana_cost is nil
        }

        return AnyView(
            HStack(spacing: 2) {
                ForEach(manaSymbols(for: manaCost), id: \.self) { symbol in
                    if let imageName = manaImageName(for: symbol) {
                        Image(imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                    }
                }
            }
            .padding(4)
        )
    }

    private func manaSymbols(for manaCost: String) -> [String] {
        var symbols: [String] = []
        var currentSymbol = ""

        for char in manaCost {
            if char == "{" {
                currentSymbol = "{"
            } else if char == "}" {
                currentSymbol += "}"
                symbols.append(currentSymbol)
                currentSymbol = ""
            } else {
                currentSymbol.append(char)
            }
        }

        return symbols
    }


}

struct AsyncImageLoader: View {
    @ObservedObject private var imageLoader: ImageLoader
    private var onSuccess: ((UIImage) -> Void)?
    private var onFailure: ((Error) -> Void)?

    init(url: URL, onSuccess: ((UIImage) -> Void)? = nil, onFailure: ((Error) -> Void)? = nil) {
        imageLoader = ImageLoader(url: url)
        self.onSuccess = onSuccess
        self.onFailure = onFailure
    }

    var body: some View {
        Group {
            if let image = imageLoader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if let image = imageLoader.image {
                onSuccess?(image)
            }
        }
        .onDisappear {
            if imageLoader.image == nil {
                onFailure?(NSError(domain: "ImageLoading", code: 404, userInfo: nil))
            }
        }
    }
}



struct SearchBar: View {
    @Binding var text: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack {
            TextField("Search", text: $text)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .foregroundColor(colorScheme == .dark ? .white : .black)

            Button(action: {
                text = ""
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
                    .padding(8)
            }
        }
        .padding(.horizontal)
    }
}

extension ContentView {

    static func loadJSONData() -> [Card] {
        guard let url = Bundle.main.url(forResource: "WOT-Scryfall", withExtension: "json") else {
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let decodedData = try decoder.decode(CardData.self, from: data)
            return decodedData.data
        } catch {
            print("Error decoding JSON: \(error)")
            return []
        }
    }
    

}
