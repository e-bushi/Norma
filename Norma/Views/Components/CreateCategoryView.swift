//
//  CreateCategoryView.swift
//  Norma
//
//  Created by Claude on 7/20/25.
//

import SwiftUI

struct CreateCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    
    // Form fields
    @State private var categoryName = ""
    @State private var selectedType: CategoryType = .expense
    @State private var selectedIcon = "questionmark.circle.fill"
    @State private var selectedColor = Color.blue
    @State private var parentCategory: Category?
    
    // UI state
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showIconPicker = false
    @State private var showColorPicker = false
    
    // Available icons for categories
    private let availableIcons = [
        "house.fill", "car.fill", "fork.knife", "bolt.fill", "heart.fill",
        "bag.fill", "tv.fill", "book.fill", "banknote.fill", "sparkles",
        "airplane", "questionmark.circle.fill", "briefcase.fill", "laptopcomputer",
        "chart.line.uptrend.xyaxis", "creditcard.fill", "graduationcap.fill",
        "gamecontroller.fill", "music.note", "camera.fill"
    ]
    
    // Available colors
    private let availableColors: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal, .cyan, .blue, 
        .indigo, .purple, .pink, .brown, .gray
    ]
    
    private var isFormValid: Bool {
        !categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Main category card
                    mainCategoryCard
                    
                    // Category details section
                    categoryDetailsSection
                    
                    // Visual customization section
                    visualCustomizationSection
                    
                    // Save button
                    saveButtonView
                }
                .padding()
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showIconPicker) {
                iconPickerSheet
            }
            .sheet(isPresented: $showColorPicker) {
                colorPickerSheet
            }
        }
    }
    
    // MARK: - View Sections
    
    @ViewBuilder
    private var mainCategoryCard: some View {
        VStack(spacing: 16) {
            // Header with icon preview and name input
            HStack {
                // Icon preview
                ZStack {
                    Circle()
                        .fill(selectedColor.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: selectedIcon)
                        .font(.title2)
                        .foregroundColor(selectedColor)
                }
                .onTapGesture {
                    showIconPicker.toggle()
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    TextField("Category Name", text: $categoryName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.trailing)
                    
                    HStack(spacing: 6) {
                        Image(systemName: selectedType == .income ? "arrow.down.circle.fill" : 
                                      selectedType == .expense ? "arrow.up.circle.fill" : 
                                      "arrow.up.arrow.down.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(selectedType == .income ? .green : 
                                           selectedType == .expense ? .red : .blue)
                        
                        Text(selectedType.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .tracking(0.5)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(UIColor.systemBackground),
                                Color.gray.opacity(0.02)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.gray.opacity(0.2),
                                        Color.gray.opacity(0.05)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
    }
    
    @ViewBuilder
    private var categoryDetailsSection: some View {
        VStack(spacing: 16) {
            Text("CATEGORY DETAILS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(1.2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                // Type selection
                DetailRow(label: "Type", value: "") {
                    Picker("Category Type", selection: $selectedType) {
                        ForEach(CategoryType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .labelsHidden()
                }
                
                // Parent category selection
                DetailRow(label: "Parent Category", value: "") {
                    Menu {
                        Button("None") {
                            parentCategory = nil
                        }
                        
                        ForEach(dataManager.getCategories(ofType: selectedType)) { category in
                            Button {
                                parentCategory = category
                            } label: {
                                Label(category.name, systemImage: category.icon)
                            }
                        }
                    } label: {
                        HStack {
                            if let parent = parentCategory {
                                HStack(spacing: 6) {
                                    Image(systemName: parent.icon)
                                        .foregroundColor(parent.color)
                                        .font(.system(size: 14))
                                    Text(parent.name)
                                        .foregroundColor(.primary)
                                }
                            } else {
                                Text("None")
                                    .foregroundColor(.secondary)
                            }
                            
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .font(.system(size: 14))
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
    
    @ViewBuilder
    private var visualCustomizationSection: some View {
        VStack(spacing: 16) {
            Text("VISUAL CUSTOMIZATION")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(1.2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 20) {
                // Icon selection button
                DetailRow(label: "Icon", value: "") {
                    Button(action: {
                        showIconPicker.toggle()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: selectedIcon)
                                .font(.system(size: 16))
                                .foregroundColor(selectedColor)
                            
                            Text("Tap to change")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Color selection button
                DetailRow(label: "Color", value: "") {
                    Button(action: {
                        showColorPicker.toggle()
                    }) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(selectedColor)
                                .frame(width: 24, height: 24)
                            
                            Text("Tap to change")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
    
    @ViewBuilder
    private var saveButtonView: some View {
        Button(action: {
            saveCategory()
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                }
                
                Text("Create Category")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isFormValid ? Color.blue : Color.gray)
            )
        }
        .disabled(!isFormValid || isLoading)
    }
    // MARK: - Icon and Color Picker Sheets
    
    @ViewBuilder
    private var iconPickerSheet: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                    ForEach(availableIcons, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                            showIconPicker = false
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(selectedIcon == icon ? selectedColor.opacity(0.2) : Color(.systemGray6))
                                    .frame(width: 48, height: 48)
                                
                                Image(systemName: icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(selectedIcon == icon ? selectedColor : .secondary)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Select Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showIconPicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    @ViewBuilder
    private var colorPickerSheet: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                    ForEach(availableColors, id: \.self) { color in
                        Button {
                            selectedColor = color
                            showColorPicker = false
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(color)
                                    .frame(width: 48, height: 48)
                                
                                if selectedColor == color {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Select Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showColorPicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Actions
    
    private func saveCategory() {
        guard let userId = sessionViewModel.currentUser?.userId else {
            showError(message: "No user found")
            return
        }
        
        let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            showError(message: "Category name is required")
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let newCategory = Category(
                    name: trimmedName,
                    type: selectedType,
                    icon: selectedIcon,
                    colorHex: selectedColor.toHex(),
                    isSystem: false,
                    isActive: true,
                    sortOrder: dataManager.categories.count + 1
                )
                
                try await dataManager.addCategory(newCategory)
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    showError(message: "Failed to create category: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Color Extension

extension Color {
    func toHex() -> String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)
        
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

// MARK: - Supporting Views

// Using DetailRow from CreateBudgetView instead of CategoryDetailRow

// MARK: - Preview

#Preview {
    let dataManager = DataManager()
    let sessionViewModel = SessionViewModel(dataManager: dataManager)
    
    return CreateCategoryView()
        .environmentObject(dataManager)
        .environmentObject(sessionViewModel)
}
