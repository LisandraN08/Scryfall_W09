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
}

import SwiftUI

struct ContentView: View {
    @State private var gridLayout = [GridItem(.adaptive(minimum: 50))]
    @State private var isShowingDetail = false
    @State private var selectedCard: Card?
    @State private var searchText = ""
    @State private var cards: [Card]
    @State private var isAscendingOrder = true

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
                SearchBar(text: $searchText)
                HStack {
                    Spacer()
                    Button(action: {
                        isAscendingOrder.toggle()
                    }) {
                        Image(systemName: isAscendingOrder ? "arrow.down" : "arrow.up")
                            .foregroundColor(.blue)
                    }
                    .padding()
                }
                
                ScrollView {
                    LazyVGrid(columns: gridLayout, spacing: 10) {
                            ForEach(sortedCards, id: \.self) { card in
                            VStack {
                                Button(action: {
                                    selectedCard = card
                                    isShowingDetail = true
                                }) {
                                    Text(card.name)
                                }
                                if let url = URL(string: card.image_uris.large) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(maxWidth: .infinity)
                                                    .aspectRatio(3/2, contentMode: .fit)
                                            default:
                                                ProgressView()
                                        }
                                    }
                                    .frame(width: 200, height: 300)
                                }
                            }
                        }
                    }
                }
                .onAppear {
                    let screenRect = UIScreen.main.bounds
                    let screenWidth = screenRect.size.width
                    gridLayout = [GridItem(.adaptive(minimum: screenWidth / 3))]
                }
                .navigationTitle("Cards")
                .background(
                    NavigationLink("", destination: CardDetailsView(card: selectedCard), isActive: $isShowingDetail)
                )
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
    
    struct CardDetailsView: View {
        let card: Card?
        
        var body: some View {
            NavigationView {
                VStack {
                    if let card = card, let url = URL(string: card.image_uris.normal) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            default:
                                ProgressView()
                            }
                        }
                        .frame(width: 200, height: 300)
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
