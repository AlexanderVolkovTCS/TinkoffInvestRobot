//
//  LoginView.swift
//  Tinkoff2
//
//  Created by Никита Мелехин on 23.05.2022.
//

import SwiftUI

struct LoginPage: View {
	@ObservedObject var storage: TokenStorage

	@State private var newToken: String = ""

	var body: some View {
		List {
			VStack {
				DescriptionTextView(text: "Для пользования ботом требуется токен, для доступа к Вашему аккаунта. На сайте Тинькофф возможно предоставить выборочный доступ.")
					.padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
				TextField("Введите токен", text: $newToken)
					.padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
					.lineLimit(1)
				Button("Войти") {
					storage.save(token: newToken)
				}
					.foregroundColor(.accentColor)
					.disabled(newToken.count < 1)
			}
		}
			.listStyle(.plain)
	}
}

