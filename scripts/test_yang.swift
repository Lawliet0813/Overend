#!/usr/bin/env swift

let cleanAuthor = "yang"

let looksLikeCode = cleanAuthor.count <= 3 || 
                   cleanAuthor.contains("-") ||
                   cleanAuthor.lowercased() == "administrator" ||
                   cleanAuthor.lowercased() == "user" ||
                   cleanAuthor.lowercased() == "owner"

let isSingleEnglishWord = !cleanAuthor.contains(" ") && 
                         !cleanAuthor.contains(",") &&
                         cleanAuthor.count <= 15 &&
                         cleanAuthor.allSatisfy { $0.isLetter || $0.isWhitespace }

let isProbablyUsername = cleanAuthor.count <= 10 && 
                        cleanAuthor.allSatisfy { $0.isLetter } &&
                        !cleanAuthor.contains(" ")

print("Testing: '\(cleanAuthor)'")
print("looksLikeCode: \(looksLikeCode)")
print("isSingleEnglishWord: \(isSingleEnglishWord)")
print("isProbablyUsername: \(isProbablyUsername)")
print("")

let shouldAccept = !cleanAuthor.isEmpty && !looksLikeCode && !isSingleEnglishWord && !isProbablyUsername

print("Final decision: \(shouldAccept ? "ACCEPT ✅" : "REJECT ❌")")

if shouldAccept {
    print("Author will be set to: '\(cleanAuthor)'")
} else {
    print("Author will remain: 'Unknown' → Extract from content")
}
