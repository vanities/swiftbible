//
//  FontSizeView.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/8/24.
//

import SwiftUI


struct FontSizeView: View {
    @AppStorage("fontSize") private var fontSize: Int = 20

    var body: some View {
        Form {
            Section(header: Text("Font Size")) {
                HStack(spacing: 0) {
                    Slider(value: Binding(get: {
                        Double(fontSize)
                    }, set: { newValue in
                        fontSize = Int(newValue)
                    }), in: 16...24, step: 1) {
                        Text("Font Size: \(fontSize)")
                    }
                }

                HStack(spacing: 0) {
                    ForEach(16...24, id: \.self) { value in
                        if value != 16 {
                            Spacer()
                        }
                        VStack {
                            Capsule()
                                .frame(width: 1, height: value % 2 == 0 ? 10 : 5)
                                .foregroundColor(.gray)
                            if value % 2 == 0 {
                                Text("\(value)")
                                    .font(.caption2)
                            }
                        }
                        if value != 24 {
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 5)
            }
        }
        .navigationBarTitle("Font Size")
    }
}

#Preview {
    FontSizeView()
        .environment(UserViewModel())
}

