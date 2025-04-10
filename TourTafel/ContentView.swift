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
                summary = try await WikipediaService.fetchSummary(for: tafel, context: modelContext)
                if summary != nil && summary?.extract != nil {
                    speak(summary!.extract)
                }
            } catch {
                print("ERROR: Wikipedia fetch failed: \(error)")
            }
            loading = false
        }
    }
    
    func deleteAllTafeln(context: ModelContext) {
        let descriptor = FetchDescriptor<Tafel>()
        if let tafeln = try? context.fetch(descriptor) {
            for tafel in tafeln {
                context.delete(tafel)
            }
            try? context.save()
            print("🧹 Deleted \(tafeln.count) Tafeln")
        }
    }
    
    func resetAndReloadTafeln(context: ModelContext) {
        deleteAllTafeln(context: context)
        GeoJSONImporter.importTafeln(from: "tafel", into: context)
    }
    
    func debug_printAllEmptyTafeln() {
        Task {
            var count = 0
            for tafel in tafeln {
                do {
                    let summary = try await WikipediaService.fetchSummary(for: tafel, context: modelContext)
                    if summary == nil || summary!.extract.isEmpty || summary!.type == "disambiguation" {
                        count += 1
                        print("❌ No useful Wikipedia entry for: \(tafel.title)")
                    }
                } catch {
                    count += 1
                    print("⚠️ Error fetching Wikipedia for \(tafel.title): \(error)")
                }
            }
            print("Not found: \(count)")
        }
    }
    
    func speak(_ text: String) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("🔇 Failed to set audio session: \(error)")
        }
        
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
                        locationManager.nearbyTafel = selected
                        showingTafelList = false
                    }
                    .environmentObject(locationManager)
                }
                /*#if DEBUG
                Button("DEBUG: Show Empty") {
                    debug_printAllEmptyTafeln()
                }
                #endif*/
            }
            .padding()
            .onAppear {
                /*#if DEBUG
                resetAndReloadTafeln(context: modelContext)
                #endif*/
                if tafeln.isEmpty {
                    GeoJSONImporter.importTafeln(from: "tafel", into: modelContext)
                }
                locationManager.tafeln = tafeln
            }
            .onChange(of: locationManager.nearbyTafel) { oldTafel, newTafel in
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
