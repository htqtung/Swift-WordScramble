//
//  ContentView.swift
//  Word Scramble
//
//  Created by Tung Huynh on 22.5.2023.
//

import SwiftUI

struct ContentView: View {
    @State private var usedWords = [String]()
    @State private var rootChars = [String]()
    @State private var rootWord = ""
    @State private var newWord = ""
    
    @State private var errorTitle = ""
    @State private var errorMessage = ""
    @State private var showingError = false
    
    @State private var score = 0
    let baseScore = 100
    
    func wordError(title: String, message: String) {
        errorTitle = title
        errorMessage = message
        showingError = true
    }
    
    func isOriginal(word: String) -> Bool {
        !usedWords.contains(word)
    }
    
    func isPossible(word: String) -> Bool {
        var rootCharsCopy = rootChars
        let tempAnswer = word.map { String($0) }
        
        for letter in tempAnswer {
            if let pos = rootCharsCopy.firstIndex(of: letter) {
                rootCharsCopy.remove(at: pos)
            } else {
                return false
            }
        }
        
        return true
    }
    
    func isReal(word: String) -> Bool {
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
        
        return misspelledRange.location == NSNotFound
    }
    
    func startGame() {
        // 1. Find the URL for start.txt in our app bundle
        if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
            // 2. Load start.txt into a string
            if let startWords = try? String(contentsOf: startWordsURL) {
                // 3. Split the string up into an array of strings, splitting on line breaks
                let allWords = startWords.components(separatedBy: "\n")
                
                // 4. Pick one random word, or use "silkworm" as a sensible default
                rootWord = allWords.randomElement() ?? "silkworm"
                rootChars = (rootWord).map { String($0) }
                
                rootChars.shuffle()
                
                // If we are here everything has worked, so we can exit
                return
            }
        }
        
        // If were are *here* then there was a problem – trigger a crash and report the error
        fatalError("Could not load start.txt from bundle.")
    }
    
    func addNewWord() {
        let answer = newWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // answer must be at least 3 letters
        guard answer.count > 2 else {
            wordError(title: "Too short", message: "Enter a word that's at least 3 letters long")
            return }
        
        guard isOriginal(word: answer) else {
            wordError(title: "Word used already", message: "Be more original")
            return
        }
        
        guard isPossible(word: answer) else {
            wordError(title: "Word not possible", message: "You can't spell that word from \"\(rootChars)\"")
            return
        }
        
        guard isReal(word: answer) else {
            wordError(title: "Word not recognized", message: "You can't just make them up, you know!")
            return
        }
        
        withAnimation {
            usedWords.insert(answer, at: 0)
            if answer != rootWord {
                score += (answer.count * baseScore)
            } else {
                score += 2000
                wordError(title: "CONGRATULATION!", message: "You found the key word!")
            }
        }
        newWord = ""
    }
        
    var body: some View {
        NavigationView {
            VStack {
                Text("Score: \(score)").font(.title2)
                Spacer()
                HStack {
                    VStack {
                        ForEach(rootChars.indices, id: \.self) {index in
                            Text(rootChars[index].uppercased()).font(.title).bold()
                        }
                    }.padding()
                        .background(Color.yellow, in: RoundedRectangle(cornerRadius: 20))
                    Spacer()
                    VStack {
                        ForEach(usedWords, id: \.self) {word in
                            HStack {
                                Image(systemName: "\(word.count).circle")
                                Text(word)
                            }
                            .foregroundColor(word == rootWord ? .blue : .primary)
                        }
                    }
                    Spacer()
                }
                Spacer()
                
                TextField("Enter your word", text: $newWord)
                    .textInputAutocapitalization(.never)
                    .padding()
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 20))
            }
            .padding()
            .navigationTitle("Word Scramble")
            .toolbar {
                Button("New Game", action: startGame).foregroundColor(.yellow)
            }
            .onSubmit(addNewWord)
            .onAppear(perform: startGame)
            .alert(errorTitle, isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .background(LinearGradient(gradient: Gradient(stops: [
                Gradient.Stop(color: .white, location: 0.80),
                Gradient.Stop(color: Color.yellow, location: 0.80),
            ]), startPoint: .top, endPoint: .bottom))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
