//
//  HomeView.swift
//  FirePlayer
//
//  Created by Alper Ozturk on 2.10.2023.
//

import SwiftUI
import AVFoundation
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var songs: [Track]
    @State private var url: URL?
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredSongs) { item in
                    Button(action: {
                        // FIXME Increase song switch performance
                        url = item.path
                    }, label: {
                        Text(item.title)
                            .font(.title)
                    })
                    .buttonStyle(.borderless)
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("Home")
            .searchable(text: $searchText, prompt: "Search song")
            .overlay(alignment: .bottom) {
                if let url {
                    SeekbarView(url: url)
                }
            }
            .toolbar {
                ToolbarItem {
                    Button(action: scanFolder) {
                        Label("Scan", systemImage: "folder.fill.badge.plus")
                    }
                }
            }
        }
    }
    
    private var filteredSongs: [Track] {
        if searchText.isEmpty {
            return songs
        } else {
            return songs.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    // FIXME Without for each app launch folder scan not working
    private func scanFolder() {
        let folderAnalyzer = FolderAnalyzer()
        folderAnalyzer.browse { folderUrl in
            guard let urls = try? FileManager.default.contentsOfDirectory(at: folderUrl, includingPropertiesForKeys: nil, options: []) else {
                return
            }
            
            let fileAnalyzer = FileAnalyzer()
            
            for url in urls {
                let title = url.lastPathComponent
                
                if let metadata = fileAnalyzer.getMetadata(url: url) {
                    let artist = metadata["artist"] as? String ?? "Unknown"
                    let album = metadata["album"] as? String ?? "Unknown"
                    let length = metadata["approximate duration in seconds"] as? Double ?? 0.0
                    
                    let track = Track(title: title, artist: artist, album: album, length: length, path: url)
                    
                    modelContext.insert(track)
                }
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(songs[index])
            }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Track.self, inMemory: true)
}
