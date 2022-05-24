//
//  TextViews.swift
//  Tinkoff2
//
//  Created by Никита Мелехин on 23.05.2022.
//

import SwiftUI

struct DescriptionTextView: View {
    var text: String = ""

    var body: some View {
        Text(text)
            .font(.caption2)
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct LogoutView: View {
    @ObservedObject var model: SettingPageModel
    @ObservedObject var storage: TokenStorage

    var body: some View {
        Button("Сменить аккаунт") {
            storage.remove()
        }
        .foregroundColor(.accentColor)
        .padding(EdgeInsets(top: 24, leading: 16, bottom: 8, trailing: 16))
        .frame(maxWidth: .infinity, alignment: .leading)
        .disabled(model.isBotRunning)
    }
}
