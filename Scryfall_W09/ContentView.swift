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
    let image_uris: ImageURIs
    let legalities: [String: String]

    func hash(into hasher: inout Hasher) {
        hasher.combine(image_uris.large)
    }

    static func == (lhs: Card, rhs: Card) -> Bool {
        return lhs.image_uris.large == rhs.image_uris.large
    }
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
    }

    var body: some View {
        NavigationView {
            VStack {
                Text("Scryfall")
                    .foregroundColor(.white)
                    .font(.largeTitle)
                    .padding(.bottom, 10)
                HStack {
                    
                    SearchBar(text: $searchText)
                        .padding(4)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .frame(minWidth: 0, maxWidth: 600) // Set the frame to make it expand to the maximum width
                            .padding(.horizontal)
                        
                        Menu {
                            Button(action: {
                                isAscendingOrder.toggle()
                            }) {
                                Label("Sort A-Z", systemImage: "arrow.up")
                            }
                            
                            Button(action: {
                                isAscendingOrder.toggle()
                            }) {
                                Label("Sort Z-A", systemImage: "arrow.down")
                            }

                            Button(action: {
                                // Add logic for sorting based on number
                            }) {
                                Label("Sort based on number", systemImage: "number")
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
                                    NavigationLink(destination: CardDetailsView(card: card)) {
                                        CardImageView(card: card, cachedImages: $cachedImages)
                                    }
                                }
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal) // Add horizontal padding
                    }
                    .onAppear {
                        let screenRect = UIScreen.main.bounds
                        let screenWidth = screenRect.size.width
                        gridLayout = [GridItem(.adaptive(minimum: screenWidth / 3))]
                        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
                    }
                }
                .background(Color.black)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}


struct CardImageView: View {
    let card: Card
    @Binding var cachedImages: [String: UIImage]
    

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
    @State private var isImageZoomed = false

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
                        }
                        .frame(height: UIScreen.main.bounds.height * 0.4)
                    }

                    Text(card?.name ?? "")
                        .font(.title)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)

                    if let legalities = card?.legalities {
                        VStack(alignment: .leading) {
                            ForEach(legalities.sorted(by: { $0.key < $1.key }), id: \.key) { legality in
                                HStack {
                                    Text(legality.key.capitalized)
                                    Spacer()
                                    Text(legality.value.capitalized)
                                        .foregroundColor(legality.value == "legal" ? .green : .red)
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
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
