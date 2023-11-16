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
    let image_uris: ImageURIs
    let prices: Prices
    let legalities: [String: String]
    let games: [String]


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

struct ContentView: View {
    @State private var gridLayout = [GridItem(.adaptive(minimum: 50))]
    @State private var isShowingDetail = false
    @State private var selectedCard: Card?
    @State private var searchText = ""
    @State private var cards: [Card]
    @State private var isAscendingOrder = true
    @State private var cachedImages: [String: UIImage] = [:]
    
    var sortedCards: [Card] {
        return isAscendingOrder ? filteredCards.sorted(by: { $0.name < $1.name }) : filteredCards.sorted(by: { $0.name > $1.name })
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

    var body: some View {
        NavigationView {
            TabView {
                VStack {
                    Text("Scryfall")
                        .foregroundColor(.white)
                        .font(.largeTitle)
                        .padding(.bottom, 10)
                    HStack {
                        
                        SearchBar(text: $searchText)
                            .padding(4)
                            .background(Color(.systemGray6))
                            .foregroundColor(.black)
                            .cornerRadius(8)
                            .frame(minWidth: 0, maxWidth: 600) // Set the frame to make it expand to the maximum width
                            .padding(.horizontal)
                            .accentColor(.orange)
                        
                        Menu {
                            Button(action: {
                                isAscendingOrder = true
                            }) {
                                Label("Sort A-Z", systemImage: "arrow.up")
                            }
                            
                            Button(action: {
                                isAscendingOrder = false
                            }) {
                                Label("Sort Z-A", systemImage: "arrow.down")
                            }
                            

                        } label: {
                            Image(systemName:"slider.horizontal.3")
                                .foregroundColor(.white)
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
                                    NavigationLink(destination: CardDetailsView(card: card, onNextCardTapped: {
                                        getNextCardDetails()
                                    })) {
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
                }
                .background(Color.black)
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                    .foregroundColor(.white)

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
                .background(Color.black) // Set the background color of the TabView
                .accentColor(.white)
                .onAppear {
                    let tabBarAppearance = UITabBar.appearance()
                    tabBarAppearance.barTintColor = .black
                }
                .accentColor(.white)
                .navigationBarHidden(true)
                .navigationViewStyle(StackNavigationViewStyle())
        }
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
    
    var onNextCardTapped: (() -> Void)?

    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    if let card = card, let url = URL(string: card.image_uris.art_crop) {
                        GeometryReader { geometry in
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: geometry.size.width, height: geometry.size.height * 0.8)
                                        .clipped()
                                        .onTapGesture {
                                            isImageZoomed.toggle()
                                        }
                                        .sheet(isPresented: $isImageZoomed) {
                                            // Show the larger image when tapped
                                            AsyncImage(url: URL(string: card.image_uris.border_crop)) { phase in
                                                switch phase {
                                                case .success(let largeImage):
                                                    largeImage
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fit)
                                                default:
                                                    ProgressView()
                                                }
                                            }
                                        }
                                default:
                                    ProgressView()
                                }
                            }
                            .frame(height: UIScreen.main.bounds.height * 0.4)
                        }
                        .frame(height: UIScreen.main.bounds.height * 0.4)
                    }

                    VStack(alignment: .leading) {
                        Text(card?.name ?? "")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white) // Set warna teks
                        Text(card?.type_line ?? "")
                            .font(.headline)
                            .foregroundColor(.white) // Set warna teks
                        Text(card?.oracle_text ?? "")
                            .font(.caption)
                            .padding()
                            .foregroundColor(.white) // Set warna teks
                    }
                    .multilineTextAlignment(.leading)
                    .padding()
                    .background(Color.black)
                    
                    HStack {

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
                                    .foregroundColor(.white)

                                Text("USD Foil: \(prices.usd_foil ?? "N/A")")
                                    .padding(.bottom, 4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(.white)

                                Text("EUR: \(prices.eur ?? "N/A")")
                                    .padding(.bottom, 4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(.white)

                                Text("EUR Foil: \(prices.eur_foil ?? "N/A")")
                                    .padding(.bottom, 4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(.white)
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
                                               .foregroundColor(legality.value == "legal" ? .green : .red)
                                       }
                                   }.foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle(Text(card?.name ?? "") .foregroundColor(.black))
                .navigationBarItems(
                    leading:
                        Button(action: {
                            // Action untuk kembali ke home
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "arrow.left")
                                .foregroundColor(.blue)
                        }
                )
            }
            .background(Color.black)
        }
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

    var body: some View {
        HStack {
            TextField("Search", text: $text)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .foregroundColor(.black)

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


