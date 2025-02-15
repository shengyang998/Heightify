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
    
    var body: some View {
        #if os(iOS)
        TextField(title, text: $text)
            .frame(minWidth: width ?? 80)
            .textFieldStyle(.roundedBorder)
            .keyboardType(.decimalPad)
            .submitLabel(.done)
        #else
        TextField(title, text: $text)
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
                    Text("Heightify")
                        .font(.system(size: 36, weight: .bold))
                    
                    Text("Calculate optimal furniture heights for ergonomic comfort")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 20)
                .frame(maxWidth: .infinity)
                
                // Input Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your Measurements")
                        .font(.headline)
                    
                    HStack {
                        CustomTextField(title: "Your height", text: $personHeight, width: nil)
                            .focused($focusedField, equals: .personHeight)
                        
                        Text("cm")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(10)
                .shadow(radius: 2)
                
                // Optimal Heights Display
                if let height = personHeightValue {
                    let optimal = HeightCalculator.calculateOptimalHeights(personHeight: height)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recommended Heights")
                            .font(.headline)
                        
                        #if os(iOS)
                        // Mobile layout
                        VStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Chair Height")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("\(String(format: "%.1f", optimal.chairHeight)) cm")
                                    .font(.system(size: 28, weight: .medium))
                                Text("Range: \(String(format: "%.1f", optimal.chairHeight - 2)) - \(String(format: "%.1f", optimal.chairHeight + 2)) cm")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Desk Height")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("\(String(format: "%.1f", optimal.deskHeight)) cm")
                                    .font(.system(size: 28, weight: .medium))
                                Text("Range: \(String(format: "%.1f", optimal.deskHeight - 2.5)) - \(String(format: "%.1f", optimal.deskHeight + 2.5)) cm")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        #else
                        // Desktop layout
                        HStack(spacing: 40) {
                            VStack(alignment: .leading) {
                                Text("Chair Height")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("\(String(format: "%.1f", optimal.chairHeight)) cm")
                                    .font(.system(size: 24, weight: .medium))
                                Text("Range: \(String(format: "%.1f", optimal.chairHeight - 2)) - \(String(format: "%.1f", optimal.chairHeight + 2)) cm")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(alignment: .leading) {
                                Text("Desk Height")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("\(String(format: "%.1f", optimal.deskHeight)) cm")
                                    .font(.system(size: 24, weight: .medium))
                                Text("Range: \(String(format: "%.1f", optimal.deskHeight - 2.5)) - \(String(format: "%.1f", optimal.deskHeight + 2.5)) cm")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        #endif
                        
                        Text("Note: Adjust within these ranges for personal comfort.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: .systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 2)
                    
                    // Current Setup Analysis Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Analyze Your Current Setup")
                            .font(.headline)
                        
                        #if os(iOS)
                        // Mobile layout
                        VStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Current Chair Height")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                HStack {
                                    CustomTextField(title: "Height", text: $currentChairHeight, width: nil)
                                        .focused($focusedField, equals: .chairHeight)
                                    Text("cm")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Current Desk Height")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                HStack {
                                    CustomTextField(title: "Height", text: $currentDeskHeight, width: nil)
                                        .focused($focusedField, equals: .deskHeight)
                                    Text("cm")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        #else
                        // Desktop layout
                        HStack(spacing: 40) {
                            VStack(alignment: .leading) {
                                Text("Current Chair Height")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                HStack {
                                    CustomTextField(title: "Height", text: $currentChairHeight, width: 80)
                                    Text("cm")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(alignment: .leading) {
                                Text("Current Desk Height")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                HStack {
                                    CustomTextField(title: "Height", text: $currentDeskHeight, width: 80)
                                    Text("cm")
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
                                currentDeskHeight: deskHeight
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
    }
}

#Preview {
    ContentView()
}
