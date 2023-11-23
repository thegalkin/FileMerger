//
//  ContentView.swift
//  FileMerger
//
//  Created by Никита Галкин on 11/23/23.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
	@State private var mergedText: String = ""
	@State private var isLoading: Bool = false
	@State private var progress: CGFloat = 0
	@State private var total: CGFloat = 0
	@State private var isImporting: Bool = false
	
	var body: some View {
		VStack {
			if isLoading {
				ProgressView(value: progress, total: total)
			} else {
				ZStack {
					ScrollView {
						Text(mergedText)
							.padding()
							.padding()
							.id(mergedText.hashValue)
							.monospaced()
					}
					.padding()
					VStack(alignment: mergedText.count > 0 ? .leading : .center) {
						HStack {
							if mergedText.count > 0 {
								Button(action: {
									let pasteboard = NSPasteboard.general
									pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
									pasteboard.setString(mergedText, forType: NSPasteboard.PasteboardType.string)
								}) {
									Image(systemName: String("doc.on.doc"))
								}
								.padding()
								Spacer()
								Button(action: {
									//creating an output file and adding it to pasteboard
									let pasteboard = NSPasteboard.general
									pasteboard.declareTypes([NSPasteboard.PasteboardType.fileURL], owner: nil)
									let tempDirURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
									let outputFileURL = tempDirURL.appendingPathComponent(String("merged.txt"))
									do {
										try mergedText.write(to: outputFileURL, atomically: true, encoding: .utf8)
										pasteboard.writeObjects([outputFileURL as NSPasteboardWriting])
										DispatchQueue.main.async {
											let alert = NSAlert()
											alert.messageText = "File is in the pasteboard now"
											alert.runModal()
										}
									} catch {
										print("Error writing file to temp directory: \(error.localizedDescription)")
									}
								}){
									Image(systemName: String("doc.plaintext")
)								}
								.padding()
							}
						}
						if mergedText.count > 0 {
							Button {
								mergedText = String("")
							} label: {
								Image(systemName: "trash.square.fill")
									.foregroundColor(Color.red)
							}.padding()
						}
						if mergedText.count > 0 {
							Spacer()
						}
						if mergedText.count < 1 {
							ZStack {
								RoundedRectangle(cornerRadius: 10)
									.stroke(style: StrokeStyle(lineWidth: 2, dash: [10]))
									.background(RoundedRectangle(cornerRadius: 10).foregroundColor(.clear))
									.overlay(
										Image(systemName: "tray.and.arrow.down")
											.font(.system(size: 50))
											.opacity(0.5)
									)
									.frame(width: 100, height: 100)
							}
							Button(action: {
								isImporting = true
							}) {
								Text("Please drop files or click to select")
									.padding()
							}
							.fileImporter(
								isPresented: $isImporting,
								allowedContentTypes: [UTType.directory,
													 UTType.fileURL,
													 UTType.item,
													 UTType.json,
													 UTType.package,
													 UTType.plainText,
													 UTType.utf16PlainText,
													 UTType.utf8PlainText],
								allowsMultipleSelection: true
							) { result in
								switch result {
								case .success(let urls):
									self.mergeText(from: urls)
								case .failure(let error):
									print("Error importing files: \(error.localizedDescription)")
								}
							}
						}
					}
				}
				.frame(maxWidth: CGFloat.infinity, maxHeight: CGFloat.infinity)
				.onDrop(of: [UTType.data], isTargeted: nil) { (providers: [NSItemProvider], location: CGPoint) -> Bool in
					for provider: NSItemProvider in providers {
						provider.loadFileRepresentation(forTypeIdentifier: UTType.text.identifier) { (url: URL?, error: Error?) in
							if let url: URL = url {
								let tempDir = FileManager.default.temporaryDirectory
								let tempURL = tempDir.appendingPathComponent(url.lastPathComponent)
								do {
									try FileManager.default.copyItem(at: url, to: tempURL)
									mergeText(from: [tempURL])
								} catch {
									print("Error copying file to temp directory: \(error.localizedDescription)")
								}
							}
						}
					}
					return true
				}
			}
		}.transition(AnyTransition.opacity)
	}
	
	private func mergeFiles() {
		// Open file dialog
		let openPanel: NSOpenPanel = .init()
		openPanel.allowsMultipleSelection = true
		openPanel.canChooseDirectories = false
		openPanel.allowedContentTypes = [UTType.text,
										 UTType.json,
										 UTType.plainText,
										 UTType.utf16PlainText,
										 UTType.utf8PlainText]
		
		openPanel.begin { (result: NSApplication.ModalResponse) in
			if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
				// Handle file selection result
				let selectedURLs = openPanel.urls
				mergeText(from: selectedURLs)
				
			}
		}
	}
	
	private func mergeText(from fileURLs: [URL]) {
		DispatchQueue.main.async {
			var mergedText = self.mergedText
			self.total = CGFloat(fileURLs.count)
			self.progress = 0
			self.isLoading = true
			
			for url: URL in fileURLs {
				do {
					let fileContents = try String(contentsOf: url)
					mergedText.append(fileContents)
					self.progress += 1
				} catch {
					print("Error reading file at \(url.path): \(error.localizedDescription)")
				}
			}
			do {
				let fileManager = FileManager.default
				let tempDir = fileManager.temporaryDirectory
				let tempFiles = try fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
				for fileURL in tempFiles {
					try fileManager.removeItem(at: fileURL)
				}
			} catch {
				print("Error deleting temp files: \(error.localizedDescription)")
			}
			
			self.isLoading = false
			self.mergedText = mergedText
		}
	}
}
