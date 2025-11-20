//
//  WordMannerView.swift
//  SpeakingAR
//
//  Created to mirror the phrase and manner flow shown in the design reference.
//

import SwiftUI

struct WordMannerCatalogView: View {
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    NavigationLink {
                        PronunciationBuilderView()
                    } label: {
                        PronunciationShortcutCard()
                    }
                    .buttonStyle(.plain)

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(wordMannerCategories) { category in
                            NavigationLink(value: category) {
                                WordMannerCategoryCard(category: category)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
            }
            .navigationDestination(for: WordMannerCategory.self) { category in
                WordMannerDetailView(category: category)
            }
            .navigationTitle("ワード・マナー")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("日常で使えるワード・マナー")
                .font(.title.weight(.bold))
                .foregroundStyle(.primary)

            Text("日常生活ですぐに使える英語フレーズとマナーをまとめました。")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Label("あいさつ", systemImage: "hand.wave.fill")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1), in: Capsule())

                Label("マナー", systemImage: "heart.fill")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.12), in: Capsule())
            }
        }
    }
}

private struct PronunciationShortcutCard: View {
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.blue.opacity(0.16))
                    .frame(width: 58, height: 58)
                Image(systemName: "waveform.and.mic")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("日本語から英語＆カタカナを作成")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("文章を入力すると、英語フレーズと発音の目安をすぐ表示します。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 6)
    }
}

private struct WordMannerCategoryCard: View {
    let category: WordMannerCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: category.systemImage)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(category.accent.opacity(0.4))
                    )

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(category.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(category.subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .background(
            LinearGradient(colors: category.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: category.accent.opacity(0.2), radius: 8, x: 0, y: 6)
    }
}

private struct WordMannerDetailView: View {
    let category: WordMannerCategory

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero

                VStack(alignment: .leading, spacing: 16) {
                    Text("フレーズとマナー")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    ForEach(category.entries) { entry in
                        WordMannerEntryCard(entry: entry, accent: category.accent)
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: category.systemImage)
                    .font(.title)
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(
                        Circle().fill(category.accent.opacity(0.8))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(category.title)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                    Text(category.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }

                Spacer()
            }

            Text(category.overview)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.leading)
                .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: category.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct WordMannerEntryCard: View {
    let entry: WordMannerEntry
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.english)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(entry.romaji)
                        .font(.subheadline)
                        .foregroundStyle(accent)
                    Text(entry.japanese)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "speaker.wave.2.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(accent)
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Label(entry.scenario, systemImage: "hand.point.right.fill")
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .labelStyle(.titleAndIcon)

                Label(entry.etiquette, systemImage: "sparkles")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .labelStyle(.titleAndIcon)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accent.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 4)
    }
}

#Preview {
    WordMannerCatalogView()
}
