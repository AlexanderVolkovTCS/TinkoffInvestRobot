//
//  AccountListView.swift
//  Tinkoff2
//
//  Created by Никита Мелехин on 21.05.2022.
//

import UIKit
import SwiftUI
import TinkoffInvestSDK
import Introspect

class SettingPageModel: ObservableObject {
	@Published var accountList: AccountList = AccountList()
	@Published var activeAccount: Account? = nil

	@Published var onModeChange: ((Int) -> ())? = nil
	@Published var isBotRunning: Bool = false

	init() { }
}

struct SettingPageView: View {
	@ObservedObject var model: SettingPageModel

	var body: some View {
		ScrollView {
			VStack {
				ModePicker(model: model)
				Spacer(minLength: 24)
				AccountListView(model: model)
			}
		}
	}
}

struct ModePicker: View {
	@ObservedObject var model: SettingPageModel
	@State private var suggestedTopping = 0

	var body: some View {
		VStack {
			Picker("Topping", selection: $suggestedTopping) {
				Text("Эмулятор").tag(0)
				Text("Песочница").tag(1)
				Text("Тинькофф").tag(2)
			}
				.onChange(of: suggestedTopping) { tag in model.onModeChange?(tag) }
				.disabled(model.isBotRunning)
		}
			.padding(16)
			.pickerStyle(.segmented)
	}
}

struct CommonSettings: View {
	@ObservedObject var model: SettingPageModel
	@State private var suggestedTopping = 0

	var body: some View {
		VStack {
			Picker("Topping", selection: $suggestedTopping) {
				Text("Эмулятор").tag(0)
				Text("Песочница").tag(1)
				Text("Тинькофф").tag(2)
			}
				.onChange(of: suggestedTopping) { tag in model.onModeChange?(tag) }
				.disabled(model.isBotRunning)
		}
			.padding(16)
			.pickerStyle(.segmented)
	}
}

struct AccountListView: View {
	@ObservedObject var model: SettingPageModel

	@State private var contentHeight: CGFloat?

	var body: some View {
		VStack {
			Text("Ваши аккаунты")
				.font(.headline)
				.frame(maxWidth: .infinity, alignment: .leading)
				.padding(16)
			List {
				ForEach(model.accountList.accounts, id: \.self) { item in
					SelectionCell(account: item, model: self.model)
				}
			}
				.introspectTableView { tableView in
				contentHeight = tableView.contentSize.height
			}
				.frame(height: contentHeight)
		}
	}
}

struct SelectionCell: View {

	let account: Account
	@ObservedObject var model: SettingPageModel

	var body: some View {
		VStack {
			HStack {
				Text(account.name)
				Spacer()
				if account == model.activeAccount {
					Image(systemName: "checkmark")
						.foregroundColor(.accentColor)
				}
			}
		}
			.onTapGesture {
			self.model.activeAccount = account
		}

	}
}
