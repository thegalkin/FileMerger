//
//  FileMergerApp.swift
//  FileMerger
//
//  Created by Никита Галкин on 11/23/23.
//

import SwiftUI

@main
struct FileMergerApp: App {
    init() {
        DispatchQueue.main.async{
            // Clear temp directory on app start
            let fileManager = FileManager.default
            let tempDir = fileManager.temporaryDirectory
            do {
                let tempFiles = try fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
                for fileURL in tempFiles {
                    try fileManager.removeItem(at: fileURL)
                }
            } catch {
                print("Error deleting temp files: \(error.localizedDescription)")
            }
        }
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
	}
}
