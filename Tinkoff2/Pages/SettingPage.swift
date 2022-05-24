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
	@Published var isAccountsLoading: Bool = false
	@Published var activeAccount: Account? = nil

	@Published var currentMode: BotMode = .Tinkoff;
	@Published var onModeChange: ((Int) -> ())? = nil
	@Published var isBotRunning: Bool = false
	@Published var isWaitingForStocks: Bool = false

	@Published var emuStartDate: Date = Date()

	@Published var tradingInstruments: [Instrument] = []

	@Published var figiData: [Instrument] = []
	@Published var sdk: TinkoffInvestSDK? = nil
	@Published var cancellables = Set<AnyCancellable>()

	@Published var algoConfig: AlgoConfig = AlgoConfig()

	@Published var errorInstrumentText: String? = nil
	@Published var errorAccountListText: String? = nil

	init() { }
}

struct SettingPage: View {
	@ObservedObject var model: SettingPageModel
	@ObservedObject var storage: TokenStorage

	var body: some View {
		if storage.token != nil {
			if !model.isWaitingForStocks {
				ScrollView {
					VStack {
						ModePicker(model: model)
						Spacer(minLength: 16)
						AccountListView(model: model)
						Spacer(minLength: 16)
						StockListView(model: model)
						Spacer(minLength: 16)
						BotSetting(model: model)
						Spacer(minLength: 16)
						EmuSettingsView(model: model)
						LogoutView(model: model, storage: storage)
					}
				}
			} else {
				VStack {
					ProgressView()
						.padding()
					Text("Загрузка")
				}
			}
		} else {
			LoginPage(storage: storage)
		}
	}
}

struct ModePicker: View {
	@ObservedObject var model: SettingPageModel
	@State private var suggestedMode = 0

	var descs = [
		"Режим Эмуляции позволяет запускать бота на исторических данных.",
		"Режим Песочницы позволяет запускать бота на реальном сервера, но испльзуются виртуальная валюта.",
		"Режим Тинькофф позволяет запускать бота в реальных условиях.",
	]

	var body: some View {
		VStack {
			Picker("Mode", selection: $suggestedMode) {
				Text("Эмулятор").tag(0)
				Text("Песочница").tag(1)
				Text("Тинькофф").tag(2)
			}
				.onChange(of: suggestedMode) { tag in model.onModeChange?(tag) }
				.disabled(model.isBotRunning)
			DescriptionTextView(text: self.descs[suggestedMode])
				.padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
		}
			.padding(16)
			.pickerStyle(.segmented)
	}
}


struct AccountCell: View {
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
			if account.accessLevel != .accountAccessLevelFullAccess {
				Image(systemName: "lock")
					.foregroundColor(.gray)
			}
		}
			.frame(maxWidth: .infinity, alignment: .leading)
			.listRowBackground(colorScheme == .dark ? Color(white: 50 / 255) : Color(white: 240 / 255))
			.onTapGesture {
			if (account.accessLevel == .accountAccessLevelFullAccess) {
				self.model.activeAccount = account
			}
		}
	}
}

struct AccountListView: View {
	@ObservedObject var model: SettingPageModel

	@State private var contentHeight: CGFloat?

	var body: some View {
		VStack {
			if model.isAccountsLoading {
				Text("Загрузка счетов")
					.font(.headline)
					.frame(maxWidth: .infinity, alignment: .leading)
					.padding(EdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16))
				ProgressView()
			} else if model.accountList.accounts.count == 0 {
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
				ErrorAccountListView(model: model)
					.padding(EdgeInsets(top: 16, leading: 16, bottom: -16, trailing: 16))
				List {
					ForEach(model.accountList.accounts, id: \.self) { item in
						AccountCell(account: item, model: self.model)
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
	@State private var instrument: Instrument? = nil
	@State private var contentWidth: CGFloat = 0

	func autocomplete(input: String) {
		let string = input.uppercased()
		var pretended: Instrument? = nil
		var maxAcc = 0.0

		for instr in self.model.tradingInstruments {
			if instr.figi == string {
				instrument = instr
				return
			}
			if instr.isin == string {
				instrument = instr
				return
			}
			if instr.ticker == string {
				instrument = instr
				return
			}

			// 66% of instrument name should be similar to input.
			if instr.name.uppercased().contains(string) {
				let newAcc = Double(string.count) / Double(instr.name.count)
				if maxAcc < newAcc {
					pretended = instr
					maxAcc = newAcc
				}
			}
		}

		if maxAcc < 0.5 || pretended == nil {
			instrument = nil
			return
		}

		instrument = pretended
	}

	var body: some View {
		VStack {
			Text("Инструменты")
				.font(.headline)
				.frame(maxWidth: .infinity, alignment: .leading)
				.padding(EdgeInsets(top: 8, leading: 16, bottom: -8, trailing: 16))
				.readSize { size in contentWidth = size.width - 16 }
			DescriptionTextView(text: "Выберите акции, которыми сможет торговать Бот.")
				.padding(EdgeInsets(top: 8, leading: 16, bottom: 0, trailing: 16))
			ErrorInstrumentView(model: model)
				.padding(EdgeInsets(top: 0, leading: 16, bottom: -8, trailing: 16))
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
				.disableAutocorrection(true)
				.onChange(of: figifield) {
				self.autocomplete(input: $0)
			}
				.textFieldStyle(.roundedBorder)
				.disabled(model.isBotRunning)
				.padding(EdgeInsets(top: 8, leading: 16, bottom: 0, trailing: 16))
			if instrument != nil {
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
						.opacity(model.isBotRunning ? 0.3 : 1.0)
						.disabled(model.isBotRunning)
						.padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 0))
					Image(systemName: "xmark.circle.fill")
						.foregroundColor(model.isBotRunning ? Color(white: 70 / 255, opacity: 0.3) : .gray)
						.padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 8))
						.disabled(model.isBotRunning)
						.onTapGesture {
						if !model.isBotRunning {
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

struct BotSetting: View {
	@ObservedObject var model: SettingPageModel
	@State private var presetId = 0

	var body: some View {
		VStack {
			Text("Настройки бота")
				.font(.headline)
				.frame(maxWidth: .infinity, alignment: .leading)
				.padding(EdgeInsets(top: 8, leading: 16, bottom: -8, trailing: 16))
			DescriptionTextView(text: "Настройки параметра алгоритма RSI")
				.padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

			VStack {
				Picker("Preset", selection: $presetId) {
					Text("Спокойный").tag(0)
					Text("Активный").tag(1)
					Text("Кастом").tag(2)
				}
					.onChange(of: presetId) { tag in
					switch tag {
					case 0:
						self.model.algoConfig.rsiPeriod = 14
						self.model.algoConfig.upperRsiThreshold = 80
						self.model.algoConfig.lowerRsiThreshold = 12
					case 1:
						self.model.algoConfig.rsiPeriod = 26
						self.model.algoConfig.upperRsiThreshold = 67
						self.model.algoConfig.lowerRsiThreshold = 29
					default:
						break
					}

				}
					.disabled(model.isBotRunning)
			}
				.padding(16)
				.pickerStyle(.segmented)

			VStack {
				Text("Стоп-лосс: \(Int(self.model.algoConfig.stopLoss * 100))%")
					.frame(maxWidth: .infinity, alignment: .leading)
					.padding(EdgeInsets(top: -8, leading: 0, bottom: -8, trailing: 0))
				DescriptionTextView(text: "Установите поручение для Бота автоматически продать акции, когда котировки упадут до определенного уровня")
					.padding(EdgeInsets(top: 8, leading: 0, bottom: 4, trailing: 0))
				Slider(value: Binding(get: {
					Double(self.model.algoConfig.stopLoss * 100)
				}, set: { (newVal) in
						self.model.algoConfig.stopLoss = newVal / 100
					}), in: 70...99)
					.disabled(model.isBotRunning)
			}
				.padding()

			if presetId == 2 {
				VStack {
					Text("Период: \(Int(self.model.algoConfig.rsiPeriod))")
						.frame(maxWidth: .infinity, alignment: .leading)
						.padding(EdgeInsets(top: -8, leading: 0, bottom: -8, trailing: 0))
					DescriptionTextView(text: "Установите глубину истории, которую Бот будет использовать для пересчета значения RSI")
						.padding(EdgeInsets(top: 8, leading: 0, bottom: 4, trailing: 0))
					Slider(value: Binding(get: {
						Double(self.model.algoConfig.rsiPeriod)
					}, set: { (newVal) in
							self.model.algoConfig.rsiPeriod = Int(newVal)
						}), in: 8...32)
						.disabled(model.isBotRunning)
				}
					.padding()

				VStack {
					Text("Верхняя граница: \(Int(self.model.algoConfig.upperRsiThreshold))")
						.frame(maxWidth: .infinity, alignment: .leading)
						.padding(EdgeInsets(top: -8, leading: 0, bottom: -8, trailing: 0))
					DescriptionTextView(text: "Установите границу, по которой Бот примет решение, что восходящий тренд закончился")
						.padding(EdgeInsets(top: 8, leading: 0, bottom: 4, trailing: 0))
					Slider(value: Binding(get: {
						Double(self.model.algoConfig.upperRsiThreshold)
					}, set: { (newVal) in
							self.model.algoConfig.upperRsiThreshold = Int(newVal)
						}), in: 35...85)
						.disabled(model.isBotRunning || presetId != 2)
				}
					.padding()

				VStack {
					Text("Нижняя граница: \(Int(self.model.algoConfig.lowerRsiThreshold))")
						.frame(maxWidth: .infinity, alignment: .leading)
						.padding(EdgeInsets(top: -8, leading: 0, bottom: -8, trailing: 0))
					DescriptionTextView(text: "Установите границу, по которой Бот примет решение, что нисходящий тренд закончился")
						.padding(EdgeInsets(top: 8, leading: 0, bottom: 4, trailing: 0))
					Slider(value: Binding(get: {
						Double(self.model.algoConfig.lowerRsiThreshold)
					}, set: { (newVal) in
							self.model.algoConfig.lowerRsiThreshold = Int(newVal)
						}), in: 10...60)
						.disabled(model.isBotRunning || presetId != 2)
				}
					.padding()
			}
		}
	}
}

struct DatePickerView: View {
	@ObservedObject var model: SettingPageModel

	@State private var date = Date()
	let dateRange: ClosedRange<Date> = {
		let calendar = Calendar.current
		let startComponents = DateComponents(year: 2021, month: 1, day: 1)
		let endComponents = DateComponents(year: Calendar.current.component(.year, from: Date()), month: Calendar.current.component(.month, from: Date()), day: Calendar.current.component(.day, from: Date()))
		return calendar.date(from: startComponents)!
			...
			calendar.date(from: endComponents)!
	}()

	var body: some View {
		DatePicker(
			"Начало эмуляции",
			selection: $date,
			in: dateRange,
			displayedComponents: [.date]
		)
			.onChange(of: date) { newValue in
			model.emuStartDate = newValue
		}
			.disabled(model.isBotRunning)
	}
}

struct EmuSettingsView: View {
	@ObservedObject var model: SettingPageModel
	@State private var date = Date()

	var body: some View {
		if model.currentMode == .Emu {
			Text("Настройки эмуляции")
				.font(.headline)
				.frame(maxWidth: .infinity, alignment: .leading)
				.padding(EdgeInsets(top: 8, leading: 16, bottom: -8, trailing: 16))
			DescriptionTextView(text: "Укажите параметры, которые будут использоваться для эмуляции")
				.padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
			DatePickerView(model: model)
				.padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
		} else {
			EmptyView()
		}
	}
}


