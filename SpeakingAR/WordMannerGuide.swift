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
    // MARK: - 日常のあいさつ
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

    // MARK: - レストラン
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
            ),
            .init(
                english: "A table for one, please.",
                japanese: "1人です。",
                romaji: "ア・テイブル・フォー・ワン・プリーズ",
                scenario: "入店して人数を伝えるとき。",
                etiquette: "人数だけでも OK。two / three に変えて使い回せる。"
            ),
            .init(
                english: "Can I sit at the bar?",
                japanese: "カウンター席でも大丈夫です。",
                romaji: "キャン・アイ・シット・アット・ザ・バー？",
                scenario: "混んでいるときにカウンターでもいいと伝えるとき。",
                etiquette: "一人での利用では、カウンターを希望すると通されやすい。"
            ),
            .init(
                english: "I'd like this one, please.",
                japanese: "これをお願いします。",
                romaji: "アイド・ライク・ディス・ワン・プリーズ",
                scenario: "メニューを指さしながら注文するとき。",
                etiquette: "読み方が分からない料理は、指さし＋このフレーズで十分。"
            ),
            .init(
                english: "Could you recommend something?",
                japanese: "おすすめはありますか。",
                romaji: "クッド・ユー・レコメンド・サムシング？",
                scenario: "何を頼むか迷ったときに、おすすめを聞きたいとき。",
                etiquette: "辛さや量など、軽く希望を付け加えるとミスマッチが減る。"
            ),
            .init(
                english: "Could I get some water, please?",
                japanese: "お水をいただけますか。",
                romaji: "クダイ・ゲット・サム・ウォーター・プリーズ？",
                scenario: "水が欲しいとき（アメリカでも店によっては自分で頼む必要がある）。",
                etiquette: "グラスを少し持ち上げてお願いすると伝わりやすい。"
            ),
            .init(
                english: "Can I have it to go?",
                japanese: "持ち帰りにしてもらえますか。",
                romaji: "キャン・アイ・ハブ・イット・トゥ・ゴウ？",
                scenario: "残った料理をテイクアウト用にしてもらいたいとき。",
                etiquette: "アメリカでは食べ残しを持ち帰るのはごく普通の文化。"
            ),
            .init(
                english: "Can I pay by card?",
                japanese: "カードで支払えますか。",
                romaji: "キャン・アイ・ペイ・バイ・カード？",
                scenario: "会計時にクレジットカードが使えるか確認したいとき。",
                etiquette: "レジやテーブル会計どちらでも、会計前に一言聞いておくと安心。"
            ),
            .init(
                english: "Can we split the bill?",
                japanese: "割り勘にできますか。",
                romaji: "キャン・ウィ・スプリット・ザ・ビル？",
                scenario: "友達と一緒に食事をして、割り勘にしたいとき。",
                etiquette: "人数が多い場合は、会計の前に早めに伝えておくと店側も助かる。"
            ),
            .init(
                english: "I'm allergic to nuts.",
                japanese: "ナッツにアレルギーがあります。",
                romaji: "アイム・アレルジック・トゥ・ナッツ",
                scenario: "アレルギーを事前に伝えたいとき。",
                etiquette: "nuts を shrimp / dairy などに変えても使える。メニューを開いた最初のタイミングで伝えると安全。"
            )
        ]
    ),

    // MARK: - ホテル
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
            ),
            // --- 追加ここから ---
            .init(
                english: "Is breakfast included?",
                japanese: "朝食は含まれていますか。",
                romaji: "イズ・ブレックファスト・インクルーデッド？",
                scenario: "朝食付きプランかどうか確認したいとき。",
                etiquette: "朝食会場の場所も一緒に確認すると安心。"
            ),
            .init(
                english: "What time is check-out?",
                japanese: "チェックアウトは何時ですか。",
                romaji: "ワット・タイム・イズ・チェックアウト？",
                scenario: "チェックアウト時間を確認したいとき。",
                etiquette: "荷物預かりが必要なら続けて依頼するとスムーズ。"
            ),
            .init(
                english: "Could I get a late check-out?",
                japanese: "レイトチェックアウトはできますか。",
                romaji: "クッド・アイ・ゲット・ア・レイト・チェックアウト？",
                scenario: "出発が遅いときに、少し長く部屋を使いたいとき。",
                etiquette: "混雑日は難しいので、早めにお願いするのがベター。"
            ),
            .init(
                english: "The Wi-Fi isn't working.",
                japanese: "Wi-Fiが使えません。",
                romaji: "ザ・ワイファイ・イズント・ワーキング",
                scenario: "Wi-Fi接続に問題があるとき。",
                etiquette: "部屋番号を伝えると案内がスムーズ。"
            ),
            .init(
                english: "There's an issue with my room.",
                japanese: "部屋に問題があります。",
                romaji: "ゼアズ・アン・イシュー・ウィズ・マイ・ルーム",
                scenario: "部屋の設備トラブルを伝えるとき。",
                etiquette: "問題箇所を写真で見せると説明が簡単。"
            ),
            .init(
                english: "Could you bring some extra towels?",
                japanese: "タオルを追加でいただけますか。",
                romaji: "クッド・ユー・ブリング・サム・エクストラ・タウルズ？",
                scenario: "タオルやアメニティを追加で頼みたいとき。",
                etiquette: "“extra” をつけると自然で丁寧。"
            ),
            .init(
                english: "Do you have a microwave I can use?",
                japanese: "電子レンジは使えますか。",
                romaji: "ドゥ・ユー・ハブ・ア・マイクロウェーブ・アイ・キャン・ユーズ？",
                scenario: "買ってきた食べ物を温めたいとき。",
                etiquette: "ロビーやラウンジに置いてあるホテルも多い。"
            ),
            .init(
                english: "Could I get a bottle of water?",
                japanese: "お水のボトルをいただけますか。",
                romaji: "クッド・アイ・ゲット・ア・ボトル・オブ・ウォーター？",
                scenario: "フロントで水を頼みたいとき（アメリカは無料のことが多い）。",
                etiquette: "“still（水） or sparkling（炭酸）” を聞かれることがある。"
            ),
            .init(
                english: "Could you call an Uber for me?",
                japanese: "Uberを呼んでもらえますか。",
                romaji: "クッド・ユー・コール・アン・ウーバー・フォー・ミー？",
                scenario: "アプリが使えないときや電波が悪いときに依頼したい場合。",
                etiquette: "行き先を地図で見せるとミスが減る。"
            )
            // --- 追加ここまで ---
        ]
    ),


    // MARK: - 交通・移動
    // MARK: - 交通・移動
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
                scenario: "座ってよいか確認したとき。",
                etiquette: "声は小さめに、相手の反応を待ってから座る。"
            ),
            .init(
                english: "Please go ahead.",
                japanese: "どうぞお先に。",
                romaji: "プリーズ・ゴー・アヘッド",
                scenario: "順番を譲るときや先に行ってもらうとき。",
                etiquette: "軽く手で促すジェスチャーを添えると親切さが伝わる。"
            ),
            // --- 追加ここから ---
            .init(
                english: "Where is the bus stop?",
                japanese: "バス停はどこですか。",
                romaji: "ウェア・イズ・ザ・バス・ストップ？",
                scenario: "バス停の場所を聞きたいとき。",
                etiquette: "地図アプリを見せるとより伝わりやすい。"
            ),
            .init(
                english: "Does this bus go to downtown?",
                japanese: "このバスはダウンタウンに行きますか。",
                romaji: "ダズ・ディス・バス・ゴー・トゥ・ダウンタウン？",
                scenario: "乗るバスが目的地に向かうか確認したいとき。",
                etiquette: "“downtown” を “airport” などに変えても使える。"
            ),
            .init(
                english: "How many stops until my station?",
                japanese: "私の降りる駅まであと何駅ですか。",
                romaji: "ハウ・メニー・ストップス・アンティル・マイ・ステーション？",
                scenario: "目的地までの距離感を知りたいとき。",
                etiquette: "降りる駅名を見せるとスムーズ。"
            ),
            .init(
                english: "Is this the right train?",
                japanese: "この電車で合っていますか。",
                romaji: "イズ・ディス・ザ・ライト・トレイン？",
                scenario: "電車が正しい方向か不安なとき。",
                etiquette: "行き先の駅名をスマホで見せながら聞くと早い。"
            ),
            .init(
                english: "Where can I get an Uber?",
                japanese: "Uberはどこで乗れますか。",
                romaji: "ウェア・キャン・アイ・ゲット・アン・ウーバー？",
                scenario: "Uberを拾う場所が分からないとき（アメリカでよくある）。",
                etiquette: "ホテル前や専用エリアがあるので、スタッフに聞くと安全。"
            ),
            .init(
                english: "Could you take me to this address?",
                japanese: "この住所までお願いします。",
                romaji: "クッド・ユー・テイク・ミー・トゥ・ディス・アドレス？",
                scenario: "タクシーで目的地を伝えるとき。",
                etiquette: "スマホの地図を見せるのが一番早い。"
            ),
            .init(
                english: "How long will it take?",
                japanese: "どれくらい時間がかかりますか。",
                romaji: "ハウ・ロング・ウィル・イット・テイク？",
                scenario: "移動時間をざっくり知りたいとき。",
                etiquette: "タクシーでも電車でも使える万能フレーズ。"
            ),
            .init(
                english: "Is this stop close to the museum?",
                japanese: "この停留所は博物館の近くですか。",
                romaji: "イズ・ディス・ストップ・クロース・トゥ・ザ・ミュージアム？",
                scenario: "下りる場所が合っているか確認したいとき。",
                etiquette: "降りるタイミングが不安なら、事前に聞くのがベター。"
            ),
            .init(
                english: "I'm lost. Could you help me?",
                japanese: "道に迷いました。助けてもらえますか。",
                romaji: "アイム・ロスト。クッド・ユー・ヘルプ・ミー？",
                scenario: "道に迷ってしまったとき。",
                etiquette: "地図を見せながら現在地を指さすと伝わりやすい。"
            ),
            .init(
                english: "What time does the next train come?",
                japanese: "次の電車は何時に来ますか。",
                romaji: "ワット・タイム・ダズ・ザ・ネクスト・トレイン・カム？",
                scenario: "時刻が気になるとき。",
                etiquette: "“bus” に置き換えてそのまま使える。"
            )
            // --- 追加ここまで ---
        ]
    ),


    // MARK: - 入国審査
    WordMannerCategory(
        title: "入国審査",
        subtitle: "聞かれることと回答例",
        overview: "渡航目的や滞在先などを端的に伝え、パスポートや予約画面をすぐ見せられるようにしておくとスムーズです。",
        systemImage: "checkmark.shield",
        accent: .teal,
        gradient: [Color.teal.opacity(0.8), Color.blue.opacity(0.6)],
        entries: [
            // 聞かれること
            .init(
                english: "What is the purpose of your visit?",
                japanese: "訪問の目的は何ですか？",
                romaji: "ワット・イズ・ザ・パーパス・オブ・ユア・ビジット？",
                scenario: "入国審査官から渡航目的を尋ねられたとき。",
                etiquette: "観光や仕事など一言で答えられるようにしておく。"
            ),
            .init(
                english: "Are you here for business or sightseeing?",
                japanese: "仕事ですか？観光ですか？",
                romaji: "アー・ユー・ヒア・フォー・ビジネス・オア・サイトシーイング？",
                scenario: "目的が仕事か観光かを確認されたとき。",
                etiquette: "どちらか一語で即答するとスムーズ。"
            ),
            .init(
                english: "How long will you be staying?",
                japanese: "どれくらい滞在しますか？",
                romaji: "ハウ・ロング・ウィル・ユー・ビー・ステイング？",
                scenario: "滞在日数を聞かれたとき。",
                etiquette: "日数を数字で答え、指で示すと確実。"
            ),
            .init(
                english: "Where will you be staying?",
                japanese: "どこに滞在しますか？",
                romaji: "ウェア・ウィル・ユー・ビー・ステイング？",
                scenario: "宿泊先を確認されたとき。",
                etiquette: "ホテル名や住所を予約画面で見せると安心。"
            ),
            .init(
                english: "Do you have a return ticket?",
                japanese: "帰りの航空券はありますか？",
                romaji: "ドゥ・ユー・ハヴ・ア・リターン・チケット？",
                scenario: "往復航空券の有無を確認されたとき。",
                etiquette: "eチケットをすぐ提示できるように準備する。"
            ),
            .init(
                english: "When will you leave the United States?",
                japanese: "いつアメリカを出国しますか？",
                romaji: "ウェン・ウィル・ユー・リーヴ・ザ・ユナイテッド・ステイツ？",
                scenario: "出国日を聞かれたとき。",
                etiquette: "日付を明確に伝え、必要なら航空券を提示する。"
            ),
            .init(
                english: "Have you visited the U.S. before?",
                japanese: "アメリカに来たことはありますか？",
                romaji: "ハヴ・ユー・ビジテッド・ザ・ユーエス・ビフォア？",
                scenario: "渡航歴の有無を確認されたとき。",
                etiquette: "初めてなら \"No, it's my first time.\" と簡潔に。"
            ),
            .init(
                english: "Is this your first time in the U.S.?",
                japanese: "アメリカは初めてですか？",
                romaji: "イズ・ディス・ユア・ファースト・タイム・イン・ザ・ユーエス？",
                scenario: "初訪問かどうかを確認されたとき。",
                etiquette: "Yes / No で短く返答する。"
            ),
            .init(
                english: "Are you traveling alone?",
                japanese: "一人で旅行していますか？",
                romaji: "アー・ユー・トラベリング・アローン？",
                scenario: "同行者がいるか確認されたとき。",
                etiquette: "人数や関係性を簡潔に付け加えると丁寧。"
            ),
            .init(
                english: "Who are you traveling with?",
                japanese: "誰と旅行していますか？",
                romaji: "フー・アー・ユー・トラベリング・ウィズ？",
                scenario: "同行者の詳細を聞かれたとき。",
                etiquette: "家族や友人など関係を一言で伝える。"
            ),
            .init(
                english: "Do you have any checked bags?",
                japanese: "預け荷物はありますか？",
                romaji: "ドゥ・ユー・ハヴ・エニー・チェックト・バッグス？",
                scenario: "預け荷物の有無を確認されたとき。",
                etiquette: "数を答え、必要ならタグを見せる。"
            ),
            .init(
                english: "Are you carrying any food?",
                japanese: "食べ物を持っていますか？",
                romaji: "アー・ユー・キャリング・エニー・フード？",
                scenario: "食品の持ち込みについて聞かれたとき。",
                etiquette: "持っている場合は正直に申告する。"
            ),
            .init(
                english: "Are you bringing any restricted items?",
                japanese: "禁止されている物を持っていますか？",
                romaji: "アー・ユー・ブリンギング・エニー・リストリクテッド・アイテムズ？",
                scenario: "持ち込み禁止品について確認されたとき。",
                etiquette: "No と明確に答え、疑問があれば聞き返す。"
            ),
            .init(
                english: "Do you have ESTA?",
                japanese: "ESTAは持っていますか？",
                romaji: "ドゥ・ユー・ハヴ・エスタ？",
                scenario: "ビザやESTAの有無を確認されたとき。",
                etiquette: "申請済みなら Yes と答え、番号を控えておく。"
            ),
            .init(
                english: "What do you do for work?",
                japanese: "仕事は何をしていますか？",
                romaji: "ワット・ドゥ・ユー・ドゥ・フォー・ワーク？",
                scenario: "職業を聞かれたとき。",
                etiquette: "職種名をシンプルに伝える。"
            ),
            .init(
                english: "Where do you plan to visit during your stay?",
                japanese: "滞在中どこを訪れる予定ですか？",
                romaji: "ウェア・ドゥ・ユー・プラン・トゥ・ビジット・デュアリング・ユア・ステイ？",
                scenario: "観光予定地を尋ねられたとき。",
                etiquette: "主要都市名をいくつか挙げると伝わりやすい。"
            ),
            .init(
                english: "How much cash are you carrying?",
                japanese: "どれくらい現金を持っていますか？",
                romaji: "ハウ・マッチ・キャッシュ・アー・ユー・キャリング？",
                scenario: "所持金額を確認されたとき。",
                etiquette: "金額を即答できるよう事前に把握しておく。"
            ),
            .init(
                english: "Do you have travel insurance?",
                japanese: "旅行保険には加入していますか？",
                romaji: "ドゥ・ユー・ハヴ・トラベル・インシュランス？",
                scenario: "保険加入の有無を尋ねられたとき。",
                etiquette: "加入していれば Yes と答え、証明書を準備。"
            ),
            .init(
                english: "Can I see your hotel reservation?",
                japanese: "ホテル予約を見せてもらえますか？",
                romaji: "キャン・アイ・シー・ユア・ホテル・リザベーション？",
                scenario: "予約確認の提示を求められたとき。",
                etiquette: "スマホで即座に表示できるようにしておく。"
            ),
            .init(
                english: "Can I see your return ticket?",
                japanese: "帰りの航空券を見せてもらえますか？",
                romaji: "キャン・アイ・シー・ユア・リターン・チケット？",
                scenario: "復路チケットの提示を求められたとき。",
                etiquette: "eチケット画面を準備し、パスポートと一緒に見せる。"
            ),

            // 回答例
            .init(
                english: "Here’s my passport.",
                japanese: "こちらが私のパスポートです。",
                romaji: "ヒアズ・マイ・パスポート",
                scenario: "パスポートの提示を求められたとき。",
                etiquette: "カバーを外してすぐ開ける状態で渡す。"
            ),
            .init(
                english: "Could you repeat that, please?",
                japanese: "もう一度言っていただけますか？",
                romaji: "クッド・ユー・リピート・ザット・プリーズ？",
                scenario: "質問を聞き取れなかったとき。",
                etiquette: "落ち着いて聞き返すのは失礼ではない。"
            ),
            .init(
                english: "I'm here for sightseeing.",
                japanese: "観光が目的です。",
                romaji: "アイム・ヒア・フォー・サイトシーイング",
                scenario: "観光目的であることを伝えるとき。",
                etiquette: "笑顔で簡潔に答える。"
            ),
            .init(
                english: "I'll stay for five days.",
                japanese: "5日間滞在します。",
                romaji: "アイル・ステイ・フォー・ファイブ・デイズ",
                scenario: "滞在日数を答えるとき。",
                etiquette: "指で日数を示すとより確実。"
            ),
            .init(
                english: "I’ll stay in Los Angeles for two days, and I’ll be staying at the Freehand Los Angeles hotel.",
                japanese: "ロサンゼルスには2日間滞在し、Freehand Los Angelesホテルに泊まります。",
                romaji: "アイル・ステイ・イン・ロサンゼルス・フォー・トゥー・デイズ・アンド・アイル・ビー・ステイング・アット・ザ・フリーハンド・ロサンゼルス・ホテル",
                scenario: "最初の滞在都市とホテルを説明するとき。",
                etiquette: "ホテル予約画面を見せながら答えると安心。"
            ),
            .init(
                english: "For the remaining three days, I’ll stay in San Jose at an Airbnb.",
                japanese: "残りの3日間はサンノゼでAirbnbに泊まります。",
                romaji: "フォー・ザ・リメイニング・スリー・デイズ、アイル・ステイ・イン・サンノゼ・アット・アン・エアビーアンドビー",
                scenario: "別都市での滞在予定を伝えるとき。",
                etiquette: "住所や予約ページをすぐ提示できるとスムーズ。"
            ),
            .init(
                english: "I'm traveling alone.",
                japanese: "一人で旅行しています。",
                romaji: "アイム・トラベリング・アローン",
                scenario: "同行者がいないことを伝えるとき。",
                etiquette: "落ち着いてシンプルに答える。"
            ),
            .init(
                english: "I work as a software engineer.",
                japanese: "ソフトウェアエンジニアとして働いています。",
                romaji: "アイ・ワーク・アズ・ア・ソフトウェア・エンジニア",
                scenario: "職業を聞かれたときの回答。",
                etiquette: "会社名を添えるとより丁寧。"
            ),
            .init(
                english: "Yes, I have ESTA.",
                japanese: "はい、ESTAを取得しています。",
                romaji: "イエス、アイ・ハヴ・エスタ",
                scenario: "ESTA保有の確認に答えるとき。",
                etiquette: "申請番号や有効期限を控えておくと安心。"
            ),
            .init(
                english: "No, this is my first time visiting the U.S.",
                japanese: "いいえ、アメリカは初めてです。",
                romaji: "ノー、ディス・イズ・マイ・ファースト・タイム・ビジティング・ジ・ユーエス",
                scenario: "初渡航かどうかの質問に答えるとき。",
                etiquette: "初めてであることを素直に伝える。"
            ),
            .init(
                english: "I have no checked bags.",
                japanese: "預け荷物はありません。",
                romaji: "アイ・ハヴ・ノー・チェックト・バッグス",
                scenario: "預け荷物の有無を答えるとき。",
                etiquette: "必要なら手荷物のみと付け加える。"
            ),
            .init(
                english: "I only have carry-on luggage.",
                japanese: "機内持ち込みのみです。",
                romaji: "アイ・オンリー・ハヴ・キャリーオン・ラゲッジ",
                scenario: "持ち込み荷物だけであると伝えるとき。",
                etiquette: "荷物検査で取り出しやすいようまとめておく。"
            ),
            .init(
                english: "I will leave the U.S. on December 9th.",
                japanese: "12月9日に出国します。",
                romaji: "アイ・ウィル・リーヴ・ザ・ユーエス・オン・ディセンバー・ナインス",
                scenario: "具体的な出国日を伝えるとき。",
                etiquette: "日付をはっきり言い、チケットを見せられるよう準備する。"
            )
        ]
    ),


    // MARK: - 空港・入国審査
    WordMannerCategory(
        title: "空港・入国審査",
        subtitle: "アメリカ到着時に使うフレーズ",
        overview: "入国審査では、短くはっきりと要点だけ答えるのが安心です。質問が聞き取れなければ、聞き返しても失礼ではありません。",
        systemImage: "airplane",
        accent: .purple,
        gradient: [Color.purple.opacity(0.8), Color.blue.opacity(0.7)],
        entries: [
            .init(
                english: "I'm here for sightseeing.",
                japanese: "観光で来ました。",
                romaji: "アイム・ヒア・フォー・サイトシーイング",
                scenario: "入国審査で渡航目的を聞かれたとき。",
                etiquette: "パスポートを見せながら、落ち着いて答える。"
            ),
            .init(
                english: "I'm here for business.",
                japanese: "仕事で来ました。",
                romaji: "アイム・ヒア・フォー・ビジネス",
                scenario: "仕事が目的のときに渡航理由を伝えるとき。",
                etiquette: "会社名が出ない場合はイベント名でもOK。"
            ),
            .init(
                english: "I'll stay for five days.",
                japanese: "5日間滞在します。",
                romaji: "アイル・ステイ・フォー・ファイブ・デイズ",
                scenario: "滞在日数を聞かれたとき。",
                etiquette: "指で5を示すと確実に伝わる。"
            ),
            .init(
                english: "I'm staying at this hotel.",
                japanese: "このホテルに滞在します。",
                romaji: "アイム・ステイイング・アット・ディス・ホテル",
                scenario: "宿泊先を聞かれたとき。",
                etiquette: "予約画面を見せるとスムーズ。"
            ),
            // --- 追加 ---
            .init(
                english: "I'm traveling alone.",
                japanese: "一人で旅行しています。",
                romaji: "アイム・トラベリング・アローン",
                scenario: "同行者の有無を聞かれたとき。",
                etiquette: "相手がフォローアップ質問をしてくるので落ち着いて答える。"
            ),
            .init(
                english: "I have no checked bags.",
                japanese: "預け荷物はありません。",
                romaji: "アイ・ハブ・ノー・チェックト・バッグス",
                scenario: "荷物について聞かれたとき。",
                etiquette: "あれば “I have one checked bag.” に変更。"
            ),
            .init(
                english: "Where is baggage claim?",
                japanese: "手荷物受取所はどこですか。",
                romaji: "ウェア・イズ・バゲッジ・クレイム？",
                scenario: "到着後の荷物受取場所を探すとき。",
                etiquette: "案内板を見せながら聞くとより早い。"
            ),
            .init(
                english: "My bag didn’t arrive.",
                japanese: "荷物が届きませんでした。",
                romaji: "マイ・バッグ・ディドゥント・アライブ",
                scenario: "ロストバゲージのとき。",
                etiquette: "航空会社のカウンターへ落ち着いて伝える。"
            ),
            .init(
                english: "Could you repeat that, please?",
                japanese: "もう一度言っていただけますか。",
                romaji: "クッド・ユー・リピート・ザット・プリーズ？",
                scenario: "聞き取れなかったとき。",
                etiquette: "聞き返しても全く問題なし。"
            )
        ]
    ),

    // MARK: - ショッピング・買い物
    // MARK: - ショッピング・買い物
    WordMannerCategory(
        title: "ショッピング・買い物",
        subtitle: "サイズ・色・購入時のひと言",
        overview: "服やガジェット選びでは、サイズ・色・在庫の確認ができると安心です。欲しいものが決まったら、笑顔で「これにします」と伝えましょう。",
        systemImage: "bag.fill",
        accent: .pink,
        gradient: [Color.pink.opacity(0.8), Color.orange.opacity(0.7)],
        entries: [
            .init(
                english: "Do you have this in a different size?",
                japanese: "このサイズ違いはありますか。",
                romaji: "ドゥ・ユー・ハブ・ディス・イン・ア・ディファレント・サイズ？",
                scenario: "服や靴などで、他のサイズを探したいとき。",
                etiquette: "商品を持ちながら聞くと早い。"
            ),
            .init(
                english: "Do you have this in another color?",
                japanese: "色違いはありますか。",
                romaji: "ドゥ・ユー・ハブ・ディス・イン・アナザー・カラー？",
                scenario: "同じ商品の別カラーを探したいとき。",
                etiquette: "色見本を指差すと伝わりやすい。"
            ),
            .init(
                english: "Can I try this on?",
                japanese: "試着してもいいですか。",
                romaji: "キャン・アイ・トライ・ディス・オン？",
                scenario: "服や靴を試着したいとき。",
                etiquette: "試着室の場所を聞くとスムーズ。"
            ),
            .init(
                english: "I'll take this.",
                japanese: "これを買います。",
                romaji: "アイル・テイク・ディス",
                scenario: "購入する商品が決まったとき。",
                etiquette: "レジに持っていき笑顔で。"
            ),
            // --- 追加 ---
            .init(
                english: "Is this the newest model?",
                japanese: "これは最新モデルですか。",
                romaji: "イズ・ディス・ザ・ニューイスト・モデル？",
                scenario: "ガジェット購入時、Metaメガネなどで確認したいとき。",
                etiquette: "“newest” だけで通じる場合も多い。"
            ),
            .init(
                english: "Do you have it in stock?",
                japanese: "在庫はありますか。",
                romaji: "ドゥ・ユー・ハブ・イット・イン・ストック？",
                scenario: "人気商品で在庫確認したいとき。",
                etiquette: "色・モデルを指さして確認。"
            ),
            .init(
                english: "Does this come with a warranty?",
                japanese: "保証は付いていますか。",
                romaji: "ダズ・ディス・カム・ウィズ・ア・ウォランティ？",
                scenario: "高額商品の保証を確認したいとき。",
                etiquette: "期間も続けて聞くと良い（How long is it?）"
            ),
            .init(
                english: "Is tax included?",
                japanese: "税金は含まれていますか。",
                romaji: "イズ・タックス・インクルーデッド？",
                scenario: "会計時の税金を確認したいとき（アメリカは税別が多い）。",
                etiquette: "レシートを指さしながら聞くと確実。"
            )
        ]
    ),

    // MARK: - カフェ・バー
    WordMannerCategory(
        title: "カフェ・バー",
        subtitle: "注文・席・コンセントで使う表現",
        overview: "カフェでは、サイズ・テイクアウト・名前の確認などがよく使われます。落ち着いて短く伝えれば十分通じます。",
        systemImage: "cup.and.saucer.fill",
        accent: .brown,
        gradient: [Color.brown.opacity(0.8), Color.orange.opacity(0.6)],
        entries: [
            .init(
                english: "Can I have a medium coffee, please?",
                japanese: "Mサイズのコーヒーをください。",
                romaji: "キャン・アイ・ハブ・ア・ミディアム・コーヒー・プリーズ？",
                scenario: "レジでサイズを指定して注文するとき。",
                etiquette: "最後の please が丁寧さを出す。"
            ),
            .init(
                english: "Is there a power outlet I can use?",
                japanese: "使えるコンセントはありますか。",
                romaji: "イズ・ゼア・ア・パワー・アウトレット・アイ・キャン・ユーズ？",
                scenario: "PCやスマホの充電をしたいとき。",
                etiquette: "混雑時は長時間の占有は避ける。"
            ),
            .init(
                english: "Can I get it to go?",
                japanese: "テイクアウトでお願いします。",
                romaji: "キャン・アイ・ゲット・イット・トゥ・ゴウ？",
                scenario: "持ち帰りにしたいとき。",
                etiquette: "注文時に先に言うと伝わりやすい。"
            ),
            .init(
                english: "Is it okay if I sit here?",
                japanese: "ここに座ってもいいですか。",
                romaji: "イズ・イット・オーケー・イフ・アイ・シット・ヒア？",
                scenario: "他の人の隣に座るとき。",
                etiquette: "椅子を指して軽く聞く。"
            ),
            // --- 追加 ---
            .init(
                english: "Can I have your Wi-Fi password?",
                japanese: "Wi-Fiのパスワードを教えてください。",
                romaji: "キャン・アイ・ハブ・ユア・ワイファイ・パスワード？",
                scenario: "Wi-Fiが必要なとき。",
                etiquette: "レシートに書いてある場合も多い。"
            ),
            .init(
                english: "What do you recommend?",
                japanese: "おすすめはありますか？",
                romaji: "ワット・ドゥ・ユー・レコメンド？",
                scenario: "飲み物選びに迷ったとき。",
                etiquette: "甘い系・苦い系など軽く好みを添えると◎"
            ),
            .init(
                english: "Can I get a refill?",
                japanese: "おかわりをいただけますか。",
                romaji: "キャン・アイ・ゲット・ア・リフィル？",
                scenario: "アメリカではドリンクはリフィル可能なことが多い。",
                etiquette: "レシートを持っていくと確認が早い。"
            ),
            .init(
                english: "Can you write my name as Itsuki?",
                japanese: "名前はItsukiでお願いします。",
                romaji: "キャン・ユー・ライト・マイ・ネーム・アズ・イツキ？",
                scenario: "スタバでカップに名前を書かれるとき。",
                etiquette: "ゆっくり名前を発音すると親切。"
            )
        ]
    ),

    // MARK: - 自己紹介・ネットワーキング
    WordMannerCategory(
        title: "自己紹介・ネットワーキング",
        subtitle: "エンジニアの友達を増やすとき",
        overview: "イベントやカフェで話しかけるときは、簡単な自己紹介と相手への質問がセットになっていると会話が続きやすくなります。",
        systemImage: "person.2.fill",
        accent: .teal,
        gradient: [Color.teal.opacity(0.8), Color.blue.opacity(0.6)],
        entries: [
            .init(
                english: "Nice to meet you. I'm Itsuki from Japan.",
                japanese: "初めまして、日本から来たItsukiです。",
                romaji: "ナイス・トゥ・ミーチュー。アイム・イツキ・フロム・ジャパン",
                scenario: "初対面の人に自己紹介するとき。",
                etiquette: "軽く握手や会釈をしながら、目を見て伝えると好印象。"
            ),
            .init(
                english: "I'm a software engineer working on an AR app.",
                japanese: "ARアプリを開発しているソフトウェアエンジニアです。",
                romaji: "アイム・ア・ソフトウェア・エンジニア・ワーキング・オン・アン・エーアール・アプリ",
                scenario: "職業や今やっているプロジェクトを説明するとき。",
                etiquette: "専門用語は短くまとめて、相手の反応を見ながら話す。"
            ),
            .init(
                english: "What are you working on these days?",
                japanese: "最近はどんなことをやっていますか。",
                romaji: "ワット・アー・ユー・ワーキング・オン・ディーズ・デイズ？",
                scenario: "相手の仕事やプロジェクトに興味を示したいとき。",
                etiquette: "相手の話を遮らず、うなずきながら聞くと印象が良い。"
            ),
            .init(
                english: "Can I connect with you on LinkedIn?",
                japanese: "LinkedInでつながってもいいですか。",
                romaji: "キャン・アイ・コネクト・ウィズ・ユー・オン・リンクトイン？",
                scenario: "会話の最後にSNSでつながりたいとき。",
                etiquette: "その場でQRコードやプロフィール画面を見せるとスムーズ。"
            ),
            .init(
                english: "How long have you been in the Bay Area?",
                japanese: "ベイエリアにはどれくらいいるんですか。",
                romaji: "ハウ・ロング・ハブ・ユー・ビーン・イン・ザ・ベイ・エリア？",
                scenario: "現地にどれくらい住んでいる／滞在しているかを聞きたいとき。",
                etiquette: "自分の滞在期間も軽くシェアすると会話が広がる。"
            ),
            .init(
                english: "I'm visiting Silicon Valley for a few days.",
                japanese: "シリコンバレーに数日間滞在しています。",
                romaji: "アイム・ビジティング・シリコンバレー・フォー・ア・フュー・デイズ",
                scenario: "今回の滞在について簡単に説明したいとき。",
                etiquette: "続けて「Any places you recommend?」などと聞くと盛り上がる。"
            ),
            .init(
                english: "Are you working at a startup now?",
                japanese: "今はスタートアップで働いていますか。",
                romaji: "アー・ユー・ワーキング・アット・ア・スタートアップ・ナウ？",
                scenario: "相手の働いている環境に興味を持ったとき。",
                etiquette: "会社名を教えてくれたら、驚きや興味をリアクションで返す。"
            ),
            .init(
                english: "Do you want to grab coffee sometime?",
                japanese: "よかったら今度コーヒーでも行きませんか。",
                romaji: "ドゥ・ユー・ウォント・トゥ・グラブ・コーヒー・サムタイム？",
                scenario: "後日ゆっくり話したいときに誘うフレーズ。",
                etiquette: "具体的なエリア名（around Mountain View など）を付けると予定を立てやすい。"
            ),
            .init(
                english: "It was great talking with you.",
                japanese: "話せてとても楽しかったです。",
                romaji: "イット・ワズ・グレイト・トーキング・ウィズ・ユー",
                scenario: "会話を終えるときの締めの一言。",
                etiquette: "別れ際にさらっと言うと好印象のまま終われる。"
            ),
            .init(
                english: "Let me know if you visit Japan.",
                japanese: "もし日本に来ることがあったら教えてください。",
                romaji: "レット・ミー・ノウ・イフ・ユー・ビジット・ジャパン",
                scenario: "また日本で会いたい気持ちを伝えたいとき。",
                etiquette: "日本のおすすめスポットの話に繋げても盛り上がる。"
            )
        ]
    ),


    // MARK: - ハッカソン・エンジニア会話
    WordMannerCategory(
        title: "ハッカソン・エンジニア会話",
        subtitle: "技術・プロダクトの話をするとき",
        overview: "ハッカソンやミートアップでは、お互いのプロダクトや技術スタックの話が中心になります。細かい英語よりも、簡単な単語で熱量を伝えることが大事です。",
        systemImage: "laptopcomputer",
        accent: .indigo,
        gradient: [Color.indigo.opacity(0.8), Color.purple.opacity(0.7)],
        entries: [
            .init(
                english: "What are you building in this hackathon?",
                japanese: "このハッカソンでは何を作っていますか。",
                romaji: "ワット・アー・ユー・ビルディング・イン・ディス・ハッカソン？",
                scenario: "相手のプロジェクト内容を聞きたいとき。",
                etiquette: "PC画面やデモを見せてもらうと、会話が広がりやすい。"
            ),
            .init(
                english: "That sounds really cool.",
                japanese: "それはすごく面白そうですね。",
                romaji: "ザット・サウンズ・リアリー・クール",
                scenario: "相手のアイデアやプロジェクトを褒めたいとき。",
                etiquette: "続けて「How did you come up with that?」など質問をすると会話が続く。"
            ),
            .init(
                english: "I'm not very good at English, so I may speak slowly.",
                japanese: "英語があまり得意ではないので、ゆっくり話すかもしれません。",
                romaji: "アイム・ノット・ベリー・グッド・アット・イングリッシュ、ソウ・アイ・メイ・スピーク・スローリー",
                scenario: "最初に一言添えておくことで、聞き返しやすくしたいとき。",
                etiquette: "自分から伝えておくと、相手もゆっくり話してくれやすくなる。"
            ),
            .init(
                english: "Which tech stack are you using?",
                japanese: "どんな技術スタックを使っていますか。",
                romaji: "ウィッチ・テック・スタック・アー・ユー・ユージング？",
                scenario: "使用している言語やフレームワークを聞きたいとき。",
                etiquette: "自分のスタックも簡単にシェアすると会話のバランスがよい。"
            ),
            .init(
                english: "Do you already have a team?",
                japanese: "もうチームは決まっていますか。",
                romaji: "ドゥ・ユー・オールレディ・ハブ・ア・チーム？",
                scenario: "チームビルディングのタイミングで相手の状況を聞きたいとき。",
                etiquette: "まだなら「We're looking for someone.」と続けると自然。"
            ),
            .init(
                english: "Would you like to join our team?",
                japanese: "よかったら僕たちのチームに入りませんか。",
                romaji: "ウッド・ユー・ライク・トゥ・ジョイン・アワ・チーム？",
                scenario: "気が合いそうな人をチームに誘うとき。",
                etiquette: "役割やアイデアの方向性も簡単に伝えると安心感が出る。"
            ),
            .init(
                english: "We're looking for someone good at iOS or backend.",
                japanese: "iOSかバックエンドが得意な人を探しています。",
                romaji: "ウィア・ルッキング・フォー・サムワン・グッド・アット・アイオーエス・オア・バックエンド",
                scenario: "足りないスキルセットを伝えたいとき。",
                etiquette: "design / ML などにも置き換えて使える。"
            ),
            .init(
                english: "Let's build a quick prototype first, then polish it.",
                japanese: "まずは早めにプロトタイプを作って、そのあとブラッシュアップしましょう。",
                romaji: "レッツ・ビルド・ア・クイック・プロトタイプ・ファースト、ゼン・ポリッシュ・イット",
                scenario: "進め方の方針をチームで共有したいとき。",
                etiquette: "ハッカソンではスピード重視の方針を伝えると安心されやすい。"
            ),
            .init(
                english: "Can I see your demo?",
                japanese: "デモを見せてもらってもいいですか。",
                romaji: "キャン・アイ・シー・ユア・デモ？",
                scenario: "他チームや参加者のプロダクトに興味を持ったとき。",
                etiquette: "デモ後に一言「That's awesome.」などと感想を伝えると◎"
            ),
            .init(
                english: "Let's keep in touch after this event.",
                japanese: "このイベントのあとも連絡を取り合いましょう。",
                romaji: "レッツ・キープ・イン・タッチ・アフター・ディス・イベント",
                scenario: "イベント後もつながり続けたいとき。",
                etiquette: "その場でLinkedInやXを交換しておくと確実。"
            )
        ]
    ),


    // MARK: - 困ったとき・ヘルプ
    WordMannerCategory(
        title: "困ったとき・ヘルプ",
        subtitle: "聞き返し・道に迷ったときなど",
        overview: "聞き取れないときや困ったときに使えるフレーズを知っておくと、安心して海外で行動できます。",
        systemImage: "exclamationmark.triangle.fill",
        accent: .red,
        gradient: [Color.red.opacity(0.8), Color.orange.opacity(0.7)],
        entries: [
            .init(
                english: "Could you say that again, please?",
                japanese: "もう一度言っていただけますか。",
                romaji: "クッド・ユー・セイ・ザット・アゲイン・プリーズ？",
                scenario: "相手の言葉が聞き取れなかったとき。",
                etiquette: "申し訳なさそうにせず、自然に聞き返してOK。"
            ),
            .init(
                english: "Could you speak a little more slowly?",
                japanese: "もう少しゆっくり話していただけますか。",
                romaji: "クッド・ユー・スピーク・ア・リトル・モア・スローリー？",
                scenario: "話すスピードが速くて聞き取りづらいとき。",
                etiquette: "最初に自分の英語力を軽く伝えておくとお願いしやすい。"
            ),
            .init(
                english: "Where is the restroom?",
                japanese: "トイレはどこですか。",
                romaji: "ウェア・イズ・ザ・レストルーム？",
                scenario: "トイレの場所を聞きたいとき。",
                etiquette: "周囲の人に軽く声をかけ、指差しで教えてもらうことが多い。"
            ),
            .init(
                english: "I'm lost. Could you help me?",
                japanese: "道に迷ってしまいました。助けていただけますか。",
                romaji: "アイム・ロスト。クッド・ユー・ヘルプ・ミー？",
                scenario: "道が分からなくなったときに助けを求めたいとき。",
                etiquette: "地図アプリを一緒に見せると、案内してもらいやすい。"
            ),
            .init(
                english: "Sorry, I didn’t catch that.",
                japanese: "すみません、今のが聞き取れませんでした。",
                romaji: "ソーリー、アイ・ディドゥント・キャッチ・ザット",
                scenario: "一部だけ聞き逃したとき。",
                etiquette: "表情で「もう一度お願いします」の雰囲気を出すと伝わりやすい。"
            ),
            .init(
                english: "Could you write it down for me?",
                japanese: "書いていただけますか。",
                romaji: "クッド・ユー・ライト・イット・ダウン・フォー・ミー？",
                scenario: "固有名詞や聞き取りにくい単語を確認したいとき。",
                etiquette: "スマホのメモアプリを開いて差し出すのもアリ。"
            ),
            .init(
                english: "Could you show me on the map?",
                japanese: "地図で教えていただけますか。",
                romaji: "クッド・ユー・ショウ・ミー・オン・ザ・マップ？",
                scenario: "場所の説明が分かりにくいとき。",
                etiquette: "自分のスマホではなく、相手の地図でもOK。指差しで理解できる。"
            ),
            .init(
                english: "Is there someone who speaks Japanese?",
                japanese: "日本語を話せる方はいらっしゃいますか。",
                romaji: "イズ・ゼア・サムワン・フー・スピークス・ジャパニーズ？",
                scenario: "トラブル時に日本語話者を探したいとき。",
                etiquette: "空港やホテルでは意外と通じることがある。"
            ),
            .init(
                english: "My phone battery is almost dead.",
                japanese: "携帯のバッテリーがほとんどありません。",
                romaji: "マイ・フォン・バッテリー・イズ・オールモスト・デッド",
                scenario: "充電の必要性を伝えたいとき。",
                etiquette: "続けて「Where can I charge my phone?」と聞くと実用的。"
            ),
            .init(
                english: "Where can I charge my phone?",
                japanese: "携帯はどこで充電できますか。",
                romaji: "ウェア・キャン・アイ・チャージ・マイ・フォン？",
                scenario: "コンセントや充電スポットを探したいとき。",
                etiquette: "カフェや空港、ホテルのロビーでよく使う。"
            ),
            .init(
                english: "It’s my first time here.",
                japanese: "ここに来るのは初めてです。",
                romaji: "イッツ・マイ・ファースト・タイム・ヒア",
                scenario: "土地勘がないことを伝えて助けを求めやすくしたいとき。",
                etiquette: "観光客であることを伝えると、丁寧に教えてもらえることが多い。"
            ),
            .init(
                english: "If I have any trouble, who should I contact?",
                japanese: "何かあったときは、誰に連絡すればいいですか。",
                romaji: "イフ・アイ・ハブ・エニー・トラブル、フー・シュッド・アイ・コンタクト？",
                scenario: "チェックインや説明のときに、連絡先を確認しておきたいとき。",
                etiquette: "ホテルやイベント受付で事前に確認しておくと安心。"
            )
        ]
    ),

    // MARK: - Meta デモ・購入
    WordMannerCategory(
        title: "Meta (Ray-Ban Display)",
        subtitle: "デモ予約・在庫確認・購入のフレーズ",
        overview: "デモ受付や購入相談では、予約時間・モデル名・希望する確認事項を簡潔に伝えるとスムーズです。実機を触らせてもらうときはスタッフの指示に従いましょう。",
        systemImage: "eyeglasses",
        accent: .indigo,
        gradient: [Color.indigo.opacity(0.8), Color.blue.opacity(0.6)],
        entries: [
            .init(
                english: "I have a demo appointment at 1 p.m.",
                japanese: "13時からデモの予約をしています。",
                romaji: "アイ・ハブ・ア・デモ・アポイントメント・アット・ワン・ピーエム",
                scenario: "Meta Store の受付でデモ予約時間を伝えるとき。",
                etiquette: "予約画面を一緒に提示すると案内が早い。"
            ),
            .init(
                english: "My name is Itsuki Mizuhara.",
                japanese: "名前は Itsuki Mizuhara です。",
                romaji: "マイ・ネーム・イズ・イツキ・ミズハラ",
                scenario: "受付で氏名を確認されたとき。",
                etiquette: "名字をゆっくり発音し、予約名と同じ表記を示す。"
            ),
            .init(
                english: "I'm here for the Ray-Ban Display demo.",
                japanese: "Ray-Ban Display のデモで来ました。",
                romaji: "アイム・ヒア・フォー・ザ・レイバン・ディスプレイ・デモ",
                scenario: "来店理由としてデモ参加を伝えるとき。",
                etiquette: "デモ対象モデルをはっきり伝える。"
            ),
            .init(
                english: "Do you have it in stock today?",
                japanese: "今日は在庫ありますか？",
                romaji: "ドゥ・ユー・ハブ・イット・イン・ストック・トゥデイ？",
                scenario: "当日購入できるか在庫を確認したいとき。",
                etiquette: "モデルやカラーを指差しながら尋ねる。"
            ),
            .init(
                english: "Is this the newest model?",
                japanese: "これは最新モデルですか。",
                romaji: "イズ・ディス・ザ・ニューイスト・モデル？",
                scenario: "展示されている機種が最新か確認したいとき。",
                etiquette: "発売日も気になる場合は続けて尋ねると良い。"
            ),
            .init(
                english: "Can I buy the Display model after the demo?",
                japanese: "デモ後に Display モデルを購入できますか？",
                romaji: "キャン・アイ・バイ・ザ・ディスプレイ・モデル・アフター・ザ・デモ？",
                scenario: "デモ参加後に購入可能か確認するとき。",
                etiquette: "購入希望を早めに伝えると在庫を確保してもらいやすい。"
            ),
            .init(
                english: "Does the Display support all features in Japan?",
                japanese: "日本でもすべての機能が使えますか？",
                romaji: "ダズ・ザ・ディスプレイ・サポート・オール・フィーチャーズ・イン・ジャパン？",
                scenario: "日本での機能制限がないか確認したいとき。",
                etiquette: "具体的な機能名（通話、通知など）も合わせて尋ねると確実。"
            ),
            .init(
                english: "I'll take this one.",
                japanese: "これを購入します。",
                romaji: "アイル・テイク・ディス・ワン",
                scenario: "購入意思を伝えるとき。",
                etiquette: "カラーやサイズを指差しで示すと間違いを防げる。"
            ),
            .init(
                english: "Can I pair this with my iPhone here?",
                japanese: "iPhoneとここでペアリングできますか。",
                romaji: "キャン・アイ・ペア・ディス・ウィズ・マイ・アイフォーン・ヒア？",
                scenario: "その場でiPhoneと接続できるか確認したいとき。",
                etiquette: "スタッフの指示に従い、Wi-FiやBluetooth設定を開いておく。"
            ),
            .init(
                english: "How long is the battery life with the display on?",
                japanese: "ディスプレイを使った場合のバッテリー持ちはどれくらいですか。",
                romaji: "ハウ・ロング・イズ・ザ・バッテリー・ライフ・ウィズ・ザ・ディスプレイ・オン？",
                scenario: "ディスプレイ使用時の稼働時間を確認したいとき。",
                etiquette: "利用時間の目安と充電方法も合わせて聞くと安心。"
            ),
            .init(
                english: "Can I see notifications from my iPhone on the display?",
                japanese: "iPhoneの通知をディスプレイに表示できますか。",
                romaji: "キャン・アイ・シー・ノーティフィケーションズ・フロム・マイ・アイフォーン・オン・ザ・ディスプレイ？",
                scenario: "通知連携が可能か確認したいとき。",
                etiquette: "実演をお願いする場合は画面を見せてもらうよう頼む。"
            ),
            .init(
                english: "What voice commands are supported?",
                japanese: "どの音声コマンドが使えますか。",
                romaji: "ワット・ヴォイス・コマンズ・アー・サポーテッド？",
                scenario: "利用できる音声操作の一覧を知りたいとき。",
                etiquette: "代表的なコマンドを教えてもらい、復唱して確認する。"
            ),
            .init(
                english: "How durable is this model?",
                japanese: "このモデルの耐久性はどれくらいですか。",
                romaji: "ハウ・デュラブル・イズ・ディス・モデル？",
                scenario: "強度や防水性能が気になるとき。",
                etiquette: "落下や雨天での使用可否など具体例を添える。"
            ),
            .init(
                english: "Does this support third-party apps or APIs?",
                japanese: "サードパーティアプリやAPIはサポートしていますか。",
                romaji: "ダズ・ディス・サポート・サードパーティー・アプス・オア・エーピーアイズ？",
                scenario: "外部アプリ連携や開発可能性を確認したいとき。",
                etiquette: "開発目的を簡潔に伝えると詳しい担当につないでもらいやすい。"
            ),
            .init(
                english: "Is there a developer mode available?",
                japanese: "開発者向けモードはありますか。",
                romaji: "イズ・ゼア・ア・デベロッパー・モード・アベイラブル？",
                scenario: "デベロッパー向け設定の有無を確認したいとき。",
                etiquette: "必要ならどのように有効化するかも聞いておく。"
            ),
            .init(
                english: "Do you have any information about the upcoming SDK?",
                japanese: "今後提供予定のSDKについて情報はありますか。",
                romaji: "ドゥ・ユー・ハブ・エニー・インフォメーション・アバウト・ジ・アップカミング・エスディーケー？",
                scenario: "公開予定のSDKの情報を確認したいとき。",
                etiquette: "非公開情報がある場合もあるので、聞き方は丁寧に。"
            ),
            .init(
                english: "Can I test the display navigation or UI here?",
                japanese: "ディスプレイのナビゲーションやUIをここで試せますか。",
                romaji: "キャン・アイ・テスト・ザ・ディスプレイ・ナビゲーション・オア・ユーアイ・ヒア？",
                scenario: "実機でUI操作を体験したいとき。",
                etiquette: "スタッフの案内を受けながら安全に触る。"
            )
        ]
    ),
]
