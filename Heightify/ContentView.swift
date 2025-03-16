//
//  ContentView.swift
//  Heightify
//
//  Created by Soleil Yu on 2025/2/15.
//

import SwiftUI

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let width: CGFloat?
    @EnvironmentObject private var languageSettings: LanguageSettings
    
    var body: some View {
        #if os(iOS)
        TextField(title.localized(using: languageSettings), text: $text)
            .frame(minWidth: width ?? 80)
            .textFieldStyle(.roundedBorder)
            .keyboardType(.decimalPad)
            .submitLabel(.done)
        #else
        TextField(title.localized(using: languageSettings), text: $text)
            .frame(width: width)
            .textFieldStyle(.roundedBorder)
        #endif
    }
}

struct ContentView: View {
    @State private var personHeight: String = ""
    @State private var currentChairHeight: String = ""
    @State private var currentDeskHeight: String = ""
    @FocusState private var focusedField: Field?
    @EnvironmentObject private var languageSettings: LanguageSettings
    @State private var refreshID = UUID() // Used to force view refresh
    @State private var isChangingLanguage = false // Animation state
    @State private var flipDegree = 0.0 // 用于控制翻转动画
    
    private enum Field {
        case personHeight, chairHeight, deskHeight
    }
    
    private var personHeightValue: Double? {
        Double(personHeight)
    }
    
    private var currentChairHeightValue: Double? {
        Double(currentChairHeight)
    }
    
    private var currentDeskHeightValue: Double? {
        Double(currentDeskHeight)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    HStack {
                        Spacer()
                        Button(action: {
                            // 使用单一的翻转动画
                            withAnimation(.easeInOut(duration: 0.5)) {
                                flipDegree += 180
                                isChangingLanguage = true
                            }
                            
                            // 在动画中间切换语言
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                languageSettings.switchLanguage()
                                
                                // 动画结束后重置状态
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isChangingLanguage = false
                                    }
                                }
                            }
                        }) {
                            HStack(spacing: 4) {
                                // 国旗图标使用3D翻转效果
                                ZStack {
                                    // 当翻转到背面时显示下一个图标，正面显示当前图标
                                    Group {
                                        if Int(flipDegree.truncatingRemainder(dividingBy: 360)) < 90 || Int(flipDegree.truncatingRemainder(dividingBy: 360)) >= 270 {
                                            Text(languageSettings.languageIcon)
                                        } else {
                                            Text(languageSettings.nextLanguageIcon)
                                        }
                                    }
                                }
                                .rotation3DEffect(
                                    .degrees(flipDegree),
                                    axis: (x: 0, y: 1, z: 0),
                                    perspective: 0.3
                                )
                                
                                // 语言名称使用淡入淡出效果
                                ZStack {
                                    // 当翻转到背面时显示下一个名称，正面显示当前名称
                                    Group {
                                        if Int(flipDegree.truncatingRemainder(dividingBy: 360)) < 90 || Int(flipDegree.truncatingRemainder(dividingBy: 360)) >= 270 {
                                            Text(languageSettings.languageName)
                                        } else {
                                            Text(languageSettings.nextLanguageName)
                                        }
                                    }
                                }
                                .font(.subheadline)
                                .animation(.easeInOut(duration: 0.3), value: flipDegree)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(8)
                            .scaleEffect(isChangingLanguage ? 0.95 : 1)
                            .animation(.easeInOut(duration: 0.3), value: isChangingLanguage)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                    
                    Text("Heightify".localized(using: languageSettings))
                        .font(.system(size: 36, weight: .bold))
                        .opacity(isChangingLanguage ? 0.5 : 1)
                        .animation(.easeInOut(duration: 0.3), value: isChangingLanguage)
                    
                    Text("Calculate optimal furniture heights for ergonomic comfort".localized(using: languageSettings))
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .opacity(isChangingLanguage ? 0.5 : 1)
                        .animation(.easeInOut(duration: 0.3), value: isChangingLanguage)
                }
                .padding(.top, 20)
                .frame(maxWidth: .infinity)
                
                // Input Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your Measurements".localized(using: languageSettings))
                        .font(.headline)
                    
                    HStack {
                        CustomTextField(title: "Your height", text: $personHeight, width: nil)
                            .focused($focusedField, equals: .personHeight)
                        
                        Text("cm".localized(using: languageSettings))
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(10)
                .shadow(radius: 2)
                .opacity(isChangingLanguage ? 0 : 1)
                .scaleEffect(isChangingLanguage ? 0.98 : 1)
                .animation(.easeInOut(duration: 0.3), value: isChangingLanguage)
                
                // Optimal Heights Display
                if let height = personHeightValue {
                    let optimal = HeightCalculator.calculateOptimalHeights(personHeight: height)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recommended Heights".localized(using: languageSettings))
                            .font(.headline)
                        
                        #if os(iOS)
                        // Mobile layout
                        VStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Chair Height".localized(using: languageSettings))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("\(String(format: "%.1f", optimal.chairHeight)) \("cm".localized(using: languageSettings))")
                                    .font(.system(size: 28, weight: .medium))
                                Text("\("Range: ".localized(using: languageSettings))\(String(format: "%.1f", optimal.chairHeight - 2)) - \(String(format: "%.1f", optimal.chairHeight + 2)) \("cm".localized(using: languageSettings))")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Desk Height".localized(using: languageSettings))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("\(String(format: "%.1f", optimal.deskHeight)) \("cm".localized(using: languageSettings))")
                                    .font(.system(size: 28, weight: .medium))
                                Text("\("Range: ".localized(using: languageSettings))\(String(format: "%.1f", optimal.deskHeight - 2.5)) - \(String(format: "%.1f", optimal.deskHeight + 2.5)) \("cm".localized(using: languageSettings))")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        #else
                        // Desktop layout
                        HStack(spacing: 40) {
                            VStack(alignment: .leading) {
                                Text("Chair Height".localized(using: languageSettings))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("\(String(format: "%.1f", optimal.chairHeight)) \("cm".localized(using: languageSettings))")
                                    .font(.system(size: 24, weight: .medium))
                                Text("\("Range: ".localized(using: languageSettings))\(String(format: "%.1f", optimal.chairHeight - 2)) - \(String(format: "%.1f", optimal.chairHeight + 2)) \("cm".localized(using: languageSettings))")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(alignment: .leading) {
                                Text("Desk Height".localized(using: languageSettings))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("\(String(format: "%.1f", optimal.deskHeight)) \("cm".localized(using: languageSettings))")
                                    .font(.system(size: 24, weight: .medium))
                                Text("\("Range: ".localized(using: languageSettings))\(String(format: "%.1f", optimal.deskHeight - 2.5)) - \(String(format: "%.1f", optimal.deskHeight + 2.5)) \("cm".localized(using: languageSettings))")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        #endif
                        
                        Text("Note: Adjust within these ranges for personal comfort.".localized(using: languageSettings))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: .systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 2)
                    .opacity(isChangingLanguage ? 0 : 1)
                    .scaleEffect(isChangingLanguage ? 0.98 : 1)
                    .animation(.easeInOut(duration: 0.3), value: isChangingLanguage)
                    
                    // Current Setup Analysis Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Analyze Your Current Setup".localized(using: languageSettings))
                            .font(.headline)
                        
                        #if os(iOS)
                        // Mobile layout
                        VStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Current Chair Height".localized(using: languageSettings))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                HStack {
                                    CustomTextField(title: "Height", text: $currentChairHeight, width: nil)
                                        .focused($focusedField, equals: .chairHeight)
                                    Text("cm".localized(using: languageSettings))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Current Desk Height".localized(using: languageSettings))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                HStack {
                                    CustomTextField(title: "Height", text: $currentDeskHeight, width: nil)
                                        .focused($focusedField, equals: .deskHeight)
                                    Text("cm".localized(using: languageSettings))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        #else
                        // Desktop layout
                        HStack(spacing: 40) {
                            VStack(alignment: .leading) {
                                Text("Current Chair Height".localized(using: languageSettings))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                HStack {
                                    CustomTextField(title: "Height", text: $currentChairHeight, width: 80)
                                    Text("cm".localized(using: languageSettings))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(alignment: .leading) {
                                Text("Current Desk Height".localized(using: languageSettings))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                HStack {
                                    CustomTextField(title: "Height", text: $currentDeskHeight, width: 80)
                                    Text("cm".localized(using: languageSettings))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        #endif
                        
                        if let chairHeight = currentChairHeightValue,
                           let deskHeight = currentDeskHeightValue {
                            Text(HeightCalculator.analyzeCurrentSetup(
                                personHeight: height,
                                currentChairHeight: chairHeight,
                                currentDeskHeight: deskHeight,
                                languageSettings: languageSettings
                            ))
                            .font(.subheadline)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: .systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 2)
                    .opacity(isChangingLanguage ? 0 : 1)
                    .scaleEffect(isChangingLanguage ? 0.98 : 1)
                    .animation(.easeInOut(duration: 0.3), value: isChangingLanguage)
                }
            }
            .padding()
            #if os(iOS)
            .padding(.horizontal, 16)
            .padding(.bottom, 32) // Extra padding for keyboard
            #else
            .frame(minWidth: 500, maxWidth: 700)
            #endif
        }
        .background(Color(uiColor: .systemBackground))
        #if os(iOS)
        .scrollDismissesKeyboard(.immediately)
        .onTapGesture {
            focusedField = nil
        }
        #endif
        .id(refreshID) // Force view to refresh when this ID changes
        .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
            // Create a new UUID to force the view to refresh
            refreshID = UUID()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LanguageSettings())
}
