//
//  AccountListView.swift
//  Tinkoff2
//
//  Created by Никита Мелехин on 21.05.2022.
//

import UIKit
import SwiftUI
import TinkoffInvestSDK
import Combine
import Introspect

class SettingPageModel: ObservableObject {
	@Published var accountList: AccountList = AccountList()
	@Published var activeAccount: Account? = nil

	@Published var onModeChange: ((Int) -> ())? = nil
	@Published var isBotRunning: Bool = false

	@Published var figiData: [Instrument] = []
	@Published var sdk: TinkoffInvestSDK? = nil
	@Published var cancellables = Set<AnyCancellable>()

	@Published var algoConfig: AlgoConfig = AlgoConfig()

	@Published var errorText: String? = nil

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
				Spacer(minLength: 16)
				BotSetting(model: model)
				ErrorView(model: model)
			}
		}
	}
}

struct ErrorView: View {
	@ObservedObject var model: SettingPageModel

	var body: some View {
		if self.model.errorText == nil {
			EmptyView()
		} else {
			Text(self.model.errorText!)
				.font(.caption)
				.foregroundColor(.red)
		}
	}
}

struct BotSetting: View {
	@ObservedObject var model: SettingPageModel

	var body: some View {
		VStack {
			Text("Настройки бота")
				.font(.headline)
				.frame(maxWidth: .infinity, alignment: .leading)
				.padding(EdgeInsets(top: 8, leading: 16, bottom: -8, trailing: 16))
			DescriptionTextView(text: "Настройки алгоритма RSI")
				.padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

			VStack {
				Text("Период: \(Int(self.model.algoConfig.rsiPeriod))")
					.frame(maxWidth: .infinity, alignment: .leading)
					.padding(EdgeInsets(top: -8, leading: 0, bottom: -8, trailing: 0))
				Slider(value: Binding(get: {
					Double(self.model.algoConfig.rsiPeriod)
				}, set: { (newVal) in
						self.model.algoConfig.rsiPeriod = Int(newVal)
					}), in: 14...32)
					.disabled(model.isBotRunning)
			}.padding()

			VStack {
				Text("Верхняя граница: \(Int(self.model.algoConfig.upperRsiThreshold))")
					.frame(maxWidth: .infinity, alignment: .leading)
					.padding(EdgeInsets(top: -8, leading: 0, bottom: -8, trailing: 0))
				Slider(value: Binding(get: {
					Double(self.model.algoConfig.upperRsiThreshold)
				}, set: { (newVal) in
						self.model.algoConfig.upperRsiThreshold = Int(newVal)
					}), in: 65...85)
					.disabled(model.isBotRunning)
			}.padding()

			VStack {
				Text("Нижняя граница: \(Int(self.model.algoConfig.lowerRsiThreshold))")
					.frame(maxWidth: .infinity, alignment: .leading)
					.padding(EdgeInsets(top: -8, leading: 0, bottom: -8, trailing: 0))
				Slider(value: Binding(get: {
					Double(self.model.algoConfig.lowerRsiThreshold)
				}, set: { (newVal) in
						self.model.algoConfig.lowerRsiThreshold = Int(newVal)
					}), in: 20...40)
					.disabled(model.isBotRunning)
			}.padding()
		}
	}
}

struct ModePicker: View {
	@ObservedObject var model: SettingPageModel
	@State private var suggestedTopping = 0

	var descs = [
		"Режим Эмуляции позволяет запускать бота на исторических данных.",
		"Режим Песочницы позволяет запускать бота на реальном сервера, но испльзуются виртуальная валюта.",
		"Режим Тинькофф позволяет запускать бота в реальных условиях.",
	]

	var body: some View {
		VStack {
			Picker("Topping", selection: $suggestedTopping) {
				Text("Эмулятор").tag(0)
				Text("Песочница").tag(1)
				Text("Тинькофф").tag(2)
			}
				.onChange(of: suggestedTopping) { tag in model.onModeChange?(tag) }
				.disabled(model.isBotRunning)
			DescriptionTextView(text: self.descs[suggestedTopping])
				.padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
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
				DescriptionTextView(text: "Не удается найти счета. Используйте приложение Тинькофф, чтобы создать новые счета.")
			} else {
				Text("Счета")
					.font(.headline)
					.frame(maxWidth: .infinity, alignment: .leading)
					.padding(EdgeInsets(top: 8, leading: 16, bottom: -8, trailing: 16))
				DescriptionTextView(text: "Выберите один из счетов, который будет использоваться для торговли ботом. Внимание: Бот может использовать все средства на счету.")
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

struct DescriptionTextView: View {
	var text: String = ""

	var body: some View {
		Text(text)
			.font(.caption2)
			.foregroundColor(.gray)
			.frame(maxWidth: .infinity, alignment: .leading)
	}
}

struct StockListView: View {
	@ObservedObject var model: SettingPageModel
	@State private var figifield: String = ""
	@State private var instrument: Instrument? = nil
	@State private var contentWidth: CGFloat = 0

	func onrespfound(response: Instrument) {
		instrument = response
	}

	func autocomplete(string: String) {
		instrument = nil
		let string = string.uppercased()
		if string.count == 12 {
			model.sdk?.instrumentsService.getInstrumentBy(params: InstrumentParameters(idType: .figi, classCode: "", id: string)).sink { _ in
			} receiveValue: { resp in
				onrespfound(response: resp.instrument)
			}.store(in: &model.cancellables)
		}
		if string.count < 6 {
			model.sdk?.instrumentsService.getInstrumentBy(params: InstrumentParameters(idType: .ticker, classCode: "SPBXM", id: string)).sink { _ in
			} receiveValue: { resp in
				onrespfound(response: resp.instrument)
			}.store(in: &model.cancellables)

			model.sdk?.instrumentsService.getInstrumentBy(params: InstrumentParameters(idType: .ticker, classCode: "MOEX", id: string)).sink { _ in
			} receiveValue: { resp in
				onrespfound(response: resp.instrument)
			}.store(in: &model.cancellables)
		}
	}

	var body: some View {
		VStack {
			Text("Интсрументы")
				.font(.headline)
				.frame(maxWidth: .infinity, alignment: .leading)
				.padding(EdgeInsets(top: 8, leading: 16, bottom: -8, trailing: 16))
				.readSize { size in contentWidth = size.width - 16 }
			DescriptionTextView(text: "Выберите акции, которыми сможет торговать Бот.")
				.padding(EdgeInsets(top: 8, leading: 16, bottom: 0, trailing: 16))
			TextField(
				"Вводите Тикер или FIGI",
				text: $figifield,
				onCommit: {
					if instrument != nil && instrument!.apiTradeAvailableFlag {
						let idx = model.figiData.firstIndex { Instrument in
							Instrument.figi == instrument?.figi
						}

						if idx == nil {
							model.figiData.append(instrument!)
						}
						figifield = ""
						instrument = nil
					}
				}
			)
				.onChange(of: figifield) {
				self.autocomplete(string: $0)
			}
				.textFieldStyle(.roundedBorder)
				.disabled(model.isBotRunning)
				.padding(EdgeInsets(top: 8, leading: 16, bottom: 0, trailing: 16))
			if instrument != nil && !(instrument!.apiTradeAvailableFlag) {
				Text("\(instrument!.name) недоступен для торговли через API")
					.font(.caption)
					.frame(maxWidth: .infinity, alignment: .leading)
					.padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0))
			} else if instrument != nil {
				Text("Найдено \(instrument!.name)")
					.font(.caption)
					.frame(maxWidth: .infinity, alignment: .leading)
					.padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0))
			} else if figifield != "" {
				Text("Ничего не найдено...")
					.font(.caption)
					.frame(maxWidth: .infinity, alignment: .leading)
					.padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0))
			} else {
				Text("")
					.font(.caption)
					.frame(maxWidth: .infinity, alignment: .leading)
					.padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0))
			}

			FlexibleView(
				availableWidth: contentWidth,
				data: model.figiData,
				spacing: 8,
				alignment: .leading
			) { item in
				HStack {
					Text(verbatim: item.name)
						.padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 0))
					Image(systemName: "xmark.circle.fill")
						.foregroundColor(.gray)
						.padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 8))
						.disabled(model.isBotRunning)
						.onTapGesture {
						if model.isBotRunning {
							model.figiData.removeAll { instrument in
								return instrument.name == item.name
							}
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
	@Environment(\.colorScheme) var colorScheme

	var body: some View {

		HStack {
			Text(account.name)
				.foregroundColor(model.isBotRunning ? Color.gray : (colorScheme == .dark ? Color.white : Color.black))
				.frame(maxWidth: .infinity, alignment: .leading)
			if account == model.activeAccount {
				Image(systemName: "checkmark")
					.foregroundColor(.accentColor)
			}
		}
			.frame(maxWidth: .infinity, alignment: .leading)
			.listRowBackground(colorScheme == .dark ? Color(white: 50 / 255) : Color(white: 240 / 255))
			.onTapGesture {
			self.model.activeAccount = account
		}
	}
}
