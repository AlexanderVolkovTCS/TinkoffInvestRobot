//
//  ErrorViews.swift
//  Tinkoff2
//
//  Created by Никита Мелехин on 24.05.2022.
//

import SwiftUI

struct ErrorAccountListView: View {
	@ObservedObject var model: SettingPageModel

	var body: some View {
		if self.model.errorAccountListText == nil {
			EmptyView()
		} else {
			Text(self.model.errorAccountListText!)
				.font(.caption)
				.foregroundColor(.red)
		}
	}
}

struct ErrorInstrumentView: View {
	@ObservedObject var model: SettingPageModel

	var body: some View {
		if self.model.errorInstrumentText == nil {
			EmptyView()
		} else {
			Text(self.model.errorInstrumentText!)
				.font(.caption)
				.foregroundColor(.red)
		}
	}
}
