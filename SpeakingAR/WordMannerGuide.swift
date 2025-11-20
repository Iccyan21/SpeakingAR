//
//  WordMannerGuide.swift
//  SpeakingAR
//
//  Created to provide a quick phrase and etiquette reference.
//

import SwiftUI

struct WordMannerEntry: Identifiable, Hashable {
    let id = UUID()
    let english: String
    let japanese: String
    let romaji: String
    let scenario: String
    let etiquette: String
}

struct WordMannerCategory: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let overview: String
    let systemImage: String
    let accent: Color
    let gradient: [Color]
    let entries: [WordMannerEntry]
}

let wordMannerCategories: [WordMannerCategory] = [
    WordMannerCategory(
        title: "Daily life",
        subtitle: "Greetings and everyday courtesies",
        overview: "In Japan, greetings come with a warm smile and often a slight bow. Having a few phrases ready helps you sound natural throughout the day.",
        systemImage: "sun.max.fill",
        accent: .orange,
        gradient: [Color.orange.opacity(0.8), Color.pink.opacity(0.6)],
        entries: [
            .init(
                english: "Good morning.",
                japanese: "おはようございます。",
                romaji: "Ohayou gozaimasu.",
                scenario: "Use when greeting someone in the morning.",
                etiquette: "Pair it with a small bow or nod to show respect."
            ),
            .init(
                english: "Good afternoon.",
                japanese: "こんにちは。",
                romaji: "Konnichiwa.",
                scenario: "Use when greeting someone in the afternoon.",
                etiquette: "Maintain light eye contact and a friendly tone."
            ),
            .init(
                english: "Good evening.",
                japanese: "こんばんは。",
                romaji: "Konbanwa.",
                scenario: "Use when greeting someone in the evening.",
                etiquette: "A gentle smile helps set a relaxed mood."
            ),
            .init(
                english: "Thank you very much.",
                japanese: "ありがとうございます。",
                romaji: "Arigatou gozaimasu.",
                scenario: "Use after receiving help, service, or a favor.",
                etiquette: "Slightly bow or place a hand to your chest to show gratitude."
            )
        ]
    ),
    WordMannerCategory(
        title: "Restaurant",
        subtitle: "Useful phrases while eating out",
        overview: "Restaurants value politeness. Calling staff with a clear voice and showing gratitude keeps service smooth.",
        systemImage: "fork.knife",
        accent: .red,
        gradient: [Color.red.opacity(0.8), Color.orange.opacity(0.7)],
        entries: [
            .init(
                english: "Excuse me (to call staff).",
                japanese: "すみません。",
                romaji: "Sumimasen.",
                scenario: "Use to get a server's attention or when squeezing past someone.",
                etiquette: "Raise your hand slightly; avoid shouting across the room."
            ),
            .init(
                english: "Do you have an English menu?",
                japanese: "英語のメニューはありますか。",
                romaji: "Eigo no menyuu wa arimasu ka?",
                scenario: "Use when first seated to request an English menu.",
                etiquette: "Ask politely before ordering to keep the flow easy."
            ),
            .init(
                english: "This is delicious!",
                japanese: "とてもおいしいです。",
                romaji: "Totemo oishii desu.",
                scenario: "Use after tasting a dish you enjoy.",
                etiquette: "A smile while saying this shows appreciation to the chef."
            ),
            .init(
                english: "Check, please.",
                japanese: "お会計をお願いします。",
                romaji: "Okaikei wo onegaishimasu.",
                scenario: "Use when you are ready to pay.",
                etiquette: "Hand the server your tray or bill folder with both hands."
            )
        ]
    ),
    WordMannerCategory(
        title: "Hotel",
        subtitle: "Check-in, check-out, and requests",
        overview: "A few considerate phrases make every stay smoother, from check-in to special requests.",
        systemImage: "bed.double.fill",
        accent: .blue,
        gradient: [Color.blue.opacity(0.8), Color.purple.opacity(0.7)],
        entries: [
            .init(
                english: "I have a reservation.",
                japanese: "予約しています。",
                romaji: "Yoyaku shiteimasu.",
                scenario: "Use when approaching the front desk to check in.",
                etiquette: "Offer your passport and reservation name together."
            ),
            .init(
                english: "Could you keep my luggage?",
                japanese: "荷物を預かっていただけますか。",
                romaji: "Nimotsu wo azukatte itadakemasu ka?",
                scenario: "Use if you arrive early or want to store bags after check-out.",
                etiquette: "Point to the luggage politely while asking."
            ),
            .init(
                english: "What time is breakfast?",
                japanese: "朝食は何時ですか。",
                romaji: "Choushoku wa nanji desu ka?",
                scenario: "Use at check-in to confirm breakfast hours.",
                etiquette: "Ask during check-in to avoid delaying the line later."
            ),
            .init(
                english: "Please call a taxi.",
                japanese: "タクシーを呼んでください。",
                romaji: "Takushii wo yonde kudasai.",
                scenario: "Use at the lobby when you need a taxi.",
                etiquette: "Share your destination on your phone to avoid mishearing."
            )
        ]
    ),
    WordMannerCategory(
        title: "Traffic",
        subtitle: "On trains, buses, and streets",
        overview: "Public transit is quiet and orderly. Short, clear phrases help you navigate without disrupting others.",
        systemImage: "tram.fill",
        accent: .green,
        gradient: [Color.green.opacity(0.8), Color.teal.opacity(0.7)],
        entries: [
            .init(
                english: "Where can I buy a ticket?",
                japanese: "切符はどこで買えますか。",
                romaji: "Kippu wa doko de kaemasu ka?",
                scenario: "Use inside a station when you need a ticket machine or counter.",
                etiquette: "Keep to the side so you don't block the walkway."
            ),
            .init(
                english: "Which line goes to Shibuya?",
                japanese: "渋谷行きはどの線ですか。",
                romaji: "Shibuya yuki wa dono sen desu ka?",
                scenario: "Use when confirming the correct platform or train.",
                etiquette: "Step aside from the gate while asking to avoid blocking."
            ),
            .init(
                english: "Is this seat free?",
                japanese: "この席は空いていますか。",
                romaji: "Kono seki wa aiteimasu ka?",
                scenario: "Use before sitting next to someone or taking an empty seat.",
                etiquette: "Speak softly and wait for a nod before sitting."
            ),
            .init(
                english: "Please go ahead.",
                japanese: "どうぞお先に。",
                romaji: "Douzo osaki ni.",
                scenario: "Use when letting someone board or exit before you.",
                etiquette: "A small hand gesture shows you are yielding politely."
            )
        ]
    )
]
