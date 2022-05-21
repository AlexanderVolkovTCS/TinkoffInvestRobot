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

	@Published var figiData: [String] = []

	init() { }
}

struct SettingPageView: View {
	@ObservedObject var model: SettingPageModel

	var body: some View {
		ScrollView {
			VStack {
				ModePicker(model: model)
				Spacer(minLength: 16)
				AccountListView(model: model)
				Spacer(minLength: 16)
				StockListView(model: model)
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

struct AccountListView: View {
	@ObservedObject var model: SettingPageModel

	@State private var contentHeight: CGFloat?

	var body: some View {
		VStack {
			if model.accountList.accounts.count == 0 {
				Text("Нет счетов")
					.font(.headline)
					.frame(maxWidth: .infinity, alignment: .leading)
					.padding(EdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16))
			} else {
				Text("Счета")
					.font(.headline)
					.frame(maxWidth: .infinity, alignment: .leading)
					.padding(EdgeInsets(top: 8, leading: 16, bottom: -24, trailing: 16))
				List {
					ForEach(model.accountList.accounts, id: \.self) { item in
						SelectionCell(account: item, model: self.model)
					}
				}
					.disabled(model.isBotRunning)
					.introspectTableView { tableView in
					tableView.backgroundColor = .clear
					contentHeight = tableView.contentSize.height
				}
					.frame(height: contentHeight)
			}
		}
	}
}

struct StockListView: View {
	@ObservedObject var model: SettingPageModel
	@State private var figifield: String = ""
	@State private var contentWidth: CGFloat = 0

	var body: some View {
		VStack {
			Text("Акции")
				.font(.headline)
				.frame(maxWidth: .infinity, alignment: .leading)
				.padding(EdgeInsets(top: 8, leading: 16, bottom: 0, trailing: 16))
				.readSize { size in contentWidth = size.width - 16 }
			TextField(
				"Введите FIGI",
                text: $figifield,
				onCommit: {
                    if figifield != "" {
                        model.figiData.append(figifield)
                    }
                    figifield = ""
				}
			)
				.textFieldStyle(.roundedBorder)
				.disabled(model.isBotRunning)
				.padding(EdgeInsets(top: 8, leading: 16, bottom: 0, trailing: 16))

			FlexibleView(
				availableWidth: contentWidth,
				data: model.figiData,
				spacing: 8,
				alignment: .leading
			) { item in
				HStack {
					Text(verbatim: item)
                        .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 0))
					Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 8))
						.onTapGesture {
						model.figiData.removeAll { name in
                            return name == item.codingKey.stringValue
						}
					}
				}
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.2)))
			}
				.padding(.horizontal, 16)
		}
	}
}

struct SelectionCell: View {
	let account: Account
	@ObservedObject var model: SettingPageModel

	var body: some View {

		HStack {
			Text(account.name)
				.foregroundColor(model.isBotRunning ? Color.gray : Color.black)
				.frame(maxWidth: .infinity, alignment: .leading)
			if account == model.activeAccount {
				Image(systemName: "checkmark")
					.foregroundColor(.accentColor)
			}
		}
			.frame(maxWidth: .infinity, alignment: .leading)
			.listRowBackground(Color(white: 240 / 255))
			.onTapGesture {
			self.model.activeAccount = account
		}
	}
}
