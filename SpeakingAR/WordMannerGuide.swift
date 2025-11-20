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
        title: "日常のあいさつ",
        subtitle: "朝・昼・夜の基本表現",
        overview: "日本語でのあいさつに近い感覚で、短い英語フレーズを使うと自然に聞こえます。軽く会釈を添えると丁寧です。",
        systemImage: "sun.max.fill",
        accent: .orange,
        gradient: [Color.orange.opacity(0.8), Color.pink.opacity(0.6)],
        entries: [
            .init(
                english: "Good morning.",
                japanese: "おはようございます。",
                romaji: "グッド・モーニング",
                scenario: "朝に会った人へ最初に声をかけるとき。",
                etiquette: "軽く会釈して、明るい声で伝えると丁寧。"
            ),
            .init(
                english: "Good afternoon.",
                japanese: "こんにちは。",
                romaji: "グッド・アフタヌーン",
                scenario: "昼過ぎ～夕方前に会った相手への挨拶。",
                etiquette: "穏やかなトーンで、笑顔を添えると印象がよい。"
            ),
            .init(
                english: "Good evening.",
                japanese: "こんばんは。",
                romaji: "グッド・イブニング",
                scenario: "夕方以降に会ったときの挨拶。",
                etiquette: "声量は控えめにして、落ち着いた雰囲気で伝える。"
            ),
            .init(
                english: "Thank you very much.",
                japanese: "ありがとうございます。",
                romaji: "サンキュー・ベリー・マッチ",
                scenario: "助けてもらったり、サービスを受けたときのお礼。",
                etiquette: "一礼したり、胸に手を当てて感謝を示すと丁寧。"
            )
        ]
    ),
    WordMannerCategory(
        title: "レストラン",
        subtitle: "注文・呼びかけ・会計で使う表現",
        overview: "店員さんを呼ぶときや注文を伝えるときは、短くはっきり言うのがコツ。感謝のひと言を添えると好印象です。",
        systemImage: "fork.knife",
        accent: .red,
        gradient: [Color.red.opacity(0.8), Color.orange.opacity(0.7)],
        entries: [
            .init(
                english: "Excuse me (to call staff).",
                japanese: "すみません。",
                romaji: "エクスキューズ・ミー",
                scenario: "店員さんを呼びたいときや、人の横を通るとき。",
                etiquette: "軽く手を上げ、店内で大声を出さないようにする。"
            ),
            .init(
                english: "Do you have an English menu?",
                japanese: "英語のメニューはありますか。",
                romaji: "ドゥ・ユー・ハブ・アン・イングリッシュ・メニュー？",
                scenario: "席についたときに英語メニューの有無を確認したいとき。",
                etiquette: "注文前に落ち着いて尋ねるとスムーズ。"
            ),
            .init(
                english: "This is delicious!",
                japanese: "とてもおいしいです。",
                romaji: "ディス・イズ・デリシャス！",
                scenario: "料理を食べておいしいと感じたとき。",
                etiquette: "笑顔で伝えると、シェフやスタッフに好意が伝わる。"
            ),
            .init(
                english: "Check, please.",
                japanese: "お会計をお願いします。",
                romaji: "チェック・プリーズ",
                scenario: "会計をお願いするとき。",
                etiquette: "伝票やトレイを両手で渡すと丁寧に見える。"
            )
        ]
    ),
    WordMannerCategory(
        title: "ホテル",
        subtitle: "チェックイン・荷物・お願いごと",
        overview: "チェックイン時の一言や荷物の相談など、丁寧な言い回しで伝えると安心感を与えられます。",
        systemImage: "bed.double.fill",
        accent: .blue,
        gradient: [Color.blue.opacity(0.8), Color.purple.opacity(0.7)],
        entries: [
            .init(
                english: "I have a reservation.",
                japanese: "予約しています。",
                romaji: "アイ・ハブ・ア・レザベーション",
                scenario: "フロントでチェックインするときの最初のひと言。",
                etiquette: "予約名とパスポートを一緒に見せるとスムーズ。"
            ),
            .init(
                english: "Could you keep my luggage?",
                japanese: "荷物を預かっていただけますか。",
                romaji: "クッド・ユー・キープ・マイ・ラゲッジ？",
                scenario: "早く着いたときやチェックアウト後に荷物を預けたいとき。",
                etiquette: "荷物を指し示しながら、丁寧に依頼すると伝わりやすい。"
            ),
            .init(
                english: "What time is breakfast?",
                japanese: "朝食は何時ですか。",
                romaji: "ワット・タイム・イズ・ブレックファスト？",
                scenario: "チェックインのときに朝食時間を確認するとき。",
                etiquette: "チェックイン時にまとめて聞くと列を妨げずスマート。"
            ),
            .init(
                english: "Please call a taxi.",
                japanese: "タクシーを呼んでください。",
                romaji: "プリーズ・コール・ア・タクシー",
                scenario: "ロビーでタクシーを呼んでもらいたいとき。",
                etiquette: "行き先をスマホで見せると聞き間違いを防げる。"
            )
        ]
    ),
    WordMannerCategory(
        title: "交通・移動",
        subtitle: "電車・バス・道を尋ねるとき",
        overview: "公共交通では短く静かなやり取りが基本。道を聞くときも周囲の通行を妨げない位置で声をかけましょう。",
        systemImage: "tram.fill",
        accent: .green,
        gradient: [Color.green.opacity(0.8), Color.teal.opacity(0.7)],
        entries: [
            .init(
                english: "Where can I buy a ticket?",
                japanese: "切符はどこで買えますか。",
                romaji: "ウェア・キャン・アイ・バイ・ア・チケット？",
                scenario: "駅で券売機や窓口の場所を聞きたいとき。",
                etiquette: "通路をふさがないよう端に寄ってから尋ねる。"
            ),
            .init(
                english: "Which line goes to Shibuya?",
                japanese: "渋谷行きはどの線ですか。",
                romaji: "ウィッチ・ライン・ゴーズ・トゥ・シブヤ？",
                scenario: "目的地に向かう路線・ホームを確認したいとき。",
                etiquette: "改札や通路をふさがず、少し離れた場所で聞く。"
            ),
            .init(
                english: "Is this seat free?",
                japanese: "この席は空いていますか。",
                romaji: "イズ・ディス・シート・フリー？",
                scenario: "座ってよいか確認したいとき。",
                etiquette: "声は小さめに、相手の反応を待ってから座る。"
            ),
            .init(
                english: "Please go ahead.",
                japanese: "どうぞお先に。",
                romaji: "プリーズ・ゴー・アヘッド",
                scenario: "順番を譲るときや先に行ってもらうとき。",
                etiquette: "軽く手で促すジェスチャーを添えると親切さが伝わる。"
            )
        ]
    )
]
