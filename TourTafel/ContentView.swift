//
//  ContentView.swift
//  TourTafel
//
//  Created by Lars Junker on 08.04.25.
//

import SwiftUI
import SwiftData
import AVFoundation

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tafeln: [Tafel]
    @StateObject private var locationManager = LocationManager()
    
    @State private var summary: WikipediaSummary?
    @State private var loading = false
    @State private var speechSynth = AVSpeechSynthesizer()
    @State private var currentTafelID: UUID?
    @State private var showingTafelList = false
    
    func loadInfo(for tafel: Tafel) {
        Task {
            loading = true
            speak(tafel.title)
            do {
                summary = try await WikipediaService.fetchSummary(for: tafel.title)
                if summary != nil && summary?.extract != nil {
                    speak(summary!.extract)
                }
            } catch {
                print("ERROR: Wikipedia fetch failed: \(error)")
            }
            loading = false
        }
    }
    
    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.siri_Martin_de-DE_compact")
        speechSynth.speak(utterance)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Unterrichtungstafeln")
                    .font(.title)
                
                if let tafel = locationManager.nearbyTafel {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(tafel.title).font(.headline)
                        if let imageURL = summary?.thumbnail?.source,
                           let url = URL(string: imageURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty: ProgressView()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 150)
                                        .cornerRadius(8)
                                case .failure:
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundColor(.secondary)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                        Text(tafel.info)
                        if loading {
                            ProgressView()
                        } else if let summary {
                            Divider()
                            Text(summary.extract)
                                .font(.subheadline)
                            if let url = summary.content_urls?.desktop.page {
                                Link("Wikipedia", destination: URL(string: url)!)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                } else {
                    Text("Keine Tafel in der Nähe.")
                        .foregroundColor(.secondary)
                }
                Button("Alle Tafeln anzeigen") {
                    showingTafelList = true
                }
                .padding()
                .navigationDestination(isPresented: $showingTafelList) {
                    TafelListView(tafeln: tafeln) { selected in
                        print(selected.title)
                        locationManager.nearbyTafel = selected
                        showingTafelList = false
                    }
                    .environmentObject(locationManager)
                }
            }
            .padding()
            .onAppear {
                if tafeln.isEmpty {
                    GeoJSONImporter.importTafeln(from: "tafel", into: modelContext)
                }
                locationManager.tafeln = tafeln
            }
            .onChange(of: locationManager.nearbyTafel) { oldTafel, newTafel in
                print("👀 ContentView saw new nearbyTafel: \(newTafel?.title ?? "nil")")
                guard let tafel = newTafel else { return }
                
                if tafel.id != currentTafelID {
                    currentTafelID = tafel.id
                    summary = nil
                    loadInfo(for: tafel)
                }
            }
        }
    }
}

/*#Preview {
    ContentView()
        .modelContainer(for: Tafel.self, inMemory: true)
}*/
