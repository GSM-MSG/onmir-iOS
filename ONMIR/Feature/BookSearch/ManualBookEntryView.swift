import SwiftUI
import PhotosUI

public struct ManualBookEntryView: View {
  @State private var viewModel = ManualBookEntryViewModel()
  @Environment(\.dismiss) private var dismiss
  
  private let completion: @MainActor (ManualBookRepresentation) -> Void
  
  init(completion: @MainActor @escaping (ManualBookRepresentation) -> Void) {
    self.completion = completion
  }
  
  public var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        coverImageSection
          .padding(.horizontal, 24)
          .padding(.top, 20)
        
        VStack(spacing: 20) {
          bookInfoSection
          readingStatusSection
          publishingInfoSection
          descriptionSection
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .padding(.bottom, 40)
      }
    }
    .background(Color(.secondarySystemBackground))
    .navigationTitle("Add Book Manually")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .navigationBarLeading) {
        Button("Cancel") {
          dismiss()
        }
      }
      
      ToolbarItem(placement: .navigationBarTrailing) {
        Button("Done") {
          handleDone()
        }
        .disabled(!viewModel.isValid)
        .fontWeight(.semibold)
      }
    }
    .photosPicker(
      isPresented: $viewModel.showPhotoPicker,
      selection: $viewModel.selectedPhoto
    )
    .alert("Missing Title", isPresented: $viewModel.showMissingTitleAlert) {
      Button("OK") { }
    } message: {
      Text("Please enter a book title.")
    }
  }
  
  private var coverImageSection: some View {
    VStack(spacing: 20) {
      if let coverImage = viewModel.coverImage {
        Image(uiImage: coverImage)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(width: 180, height: 240)
          .clipShape(RoundedRectangle(cornerRadius: 16))
          .shadow(color: .black.opacity(0.15), radius: 24, x: 0, y: 10)
      } else {
        RoundedRectangle(cornerRadius: 16)
          .fill(Color(.systemGray6))
          .frame(width: 180, height: 240)
          .shadow(color: .black.opacity(0.15), radius: 24, x: 0, y: 10)
          .overlay {
            VStack(spacing: 12) {
              Image(systemName: "photo")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.secondary)
              Text("Book Cover")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
      }
      
      Button(action: {
        viewModel.showPhotoPicker = true
      }) {
        HStack(spacing: 8) {
          Image(systemName: "camera.fill")
            .font(.system(size: 14, weight: .medium))
          Text(viewModel.coverImage == nil ? "Add Cover Photo" : "Change Cover Photo")
            .font(.system(size: 16, weight: .medium))
        }
        .foregroundStyle(.white)
        .frame(height: 44)
        .frame(maxWidth: 200)
        .background(Color.accentColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
      }
    }
    .frame(maxWidth: .infinity)
  }
  
  private var bookInfoSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Book Information")
        .font(.system(size: 20, weight: .semibold))
        .foregroundStyle(.primary)
      
      VStack(spacing: 16) {
        CustomTextField(
          title: "Book Title",
          text: $viewModel.title
        )
        .textInputAutocapitalization(.words)
        
        CustomTextField(
          title: "Author",
          text: $viewModel.author
        )
        .textInputAutocapitalization(.words)
        
        CustomTextField(
          title: "Page Count",
          text: $viewModel.pageCountText
        )
        .keyboardType(.numberPad)
      }
      .padding(20)
      .background(Color(.systemBackground))
      .clipShape(RoundedRectangle(cornerRadius: 16))
      .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
  }
  
  private var readingStatusSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Reading Status")
        .font(.system(size: 20, weight: .semibold))
        .foregroundStyle(.primary)
      
      VStack(alignment: .leading, spacing: 8) {
        Text("Status")
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(.secondary)
        
        Menu {
          ForEach([BookStatusType.toRead, .reading, .completed], id: \.self) { status in
            Button {
              viewModel.readingStatus = status
            } label: {
              Label(statusDisplayText(for: status), systemImage: statusIcon(for: status))
            }
          }
        } label: {
          HStack {
            Image(systemName: statusIcon(for: viewModel.readingStatus))
              .font(.system(size: 16))
              .foregroundStyle(Color.accentColor)
            
            Text(statusDisplayText(for: viewModel.readingStatus))
              .font(.system(size: 16))
              .foregroundStyle(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.down")
              .font(.system(size: 14, weight: .medium))
              .foregroundStyle(.secondary)
          }
          .padding(12)
          .background(Color(.secondarySystemBackground))
          .clipShape(RoundedRectangle(cornerRadius: 8))
        }
      }
      .padding(20)
      .background(Color(.systemBackground))
      .clipShape(RoundedRectangle(cornerRadius: 16))
      .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
  }
  
  private var publishingInfoSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Publishing Information")
        .font(.system(size: 20, weight: .semibold))
        .foregroundStyle(.primary)
      
      VStack(spacing: 16) {
        CustomTextField(
          title: "Publisher",
          text: $viewModel.publisher
        )
        .textInputAutocapitalization(.words)
        
        CustomTextField(
          title: "Published Date",
          text: $viewModel.publishedDate,
          placeholder: "YYYY or YYYY-MM-DD"
        )
        .keyboardType(.numbersAndPunctuation)
        
        HStack(spacing: 16) {
          CustomTextField(
            title: "ISBN",
            text: $viewModel.isbn
          )
          .keyboardType(.numberPad)
          
          CustomTextField(
            title: "ISBN-13",
            text: $viewModel.isbn13
          )
          .keyboardType(.numberPad)
        }
      }
      .padding(20)
      .background(Color(.systemBackground))
      .clipShape(RoundedRectangle(cornerRadius: 16))
      .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
  }
  
  private var descriptionSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Description")
        .font(.system(size: 20, weight: .semibold))
        .foregroundStyle(.primary)
      
      VStack(alignment: .leading, spacing: 8) {
        Text("Description (optional)")
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(.secondary)
        
        TextField("Enter book description...", text: $viewModel.description, axis: .vertical)
          .lineLimit(4...8)
          .padding(12)
          .background(Color(.secondarySystemBackground))
          .clipShape(RoundedRectangle(cornerRadius: 8))
      }
      .padding(20)
      .background(Color(.systemBackground))
      .clipShape(RoundedRectangle(cornerRadius: 16))
      .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
  }
  
  private func statusDisplayText(for status: BookStatusType) -> String {
    switch status {
    case .toRead:
      return "To Read"
    case .reading:
      return "Currently Reading"
    case .completed:
      return "Completed"
    }
  }
  
  private func statusIcon(for status: BookStatusType) -> String {
    switch status {
    case .toRead:
      return "book.closed"
    case .reading:
      return "book"
    case .completed:
      return "checkmark.circle.fill"
    }
  }
  
  private func handleDone() {
    guard viewModel.isValid else {
      viewModel.showMissingTitleAlert = true
      return
    }
    
    let manualBook = ManualBookRepresentation(
      title: viewModel.title.isEmpty ? nil : viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines),
      author: viewModel.author.isEmpty ? nil : viewModel.author.trimmingCharacters(in: .whitespacesAndNewlines),
      publisher: viewModel.publisher.isEmpty ? nil : viewModel.publisher.trimmingCharacters(in: .whitespacesAndNewlines),
      publishedDate: viewModel.publishedDate.isEmpty ? nil : viewModel.publishedDate.trimmingCharacters(in: .whitespacesAndNewlines),
      description: viewModel.description.isEmpty ? nil : viewModel.description.trimmingCharacters(in: .whitespacesAndNewlines),
      coverImage: viewModel.coverImage,
      isbn: viewModel.isbn.isEmpty ? nil : viewModel.isbn.trimmingCharacters(in: .whitespacesAndNewlines),
      isbn13: viewModel.isbn13.isEmpty ? nil : viewModel.isbn13.trimmingCharacters(in: .whitespacesAndNewlines),
      pageCount: Int64(viewModel.pageCountText) ?? 0,
      readingStatus: viewModel.readingStatus
    )
    
    dismiss()
    completion(manualBook)
  }
}

struct CustomTextField: View {
  let title: String
  @Binding var text: String
  let placeholder: String?
  let isRequired: Bool
  
  init(title: String, text: Binding<String>, placeholder: String? = nil, isRequired: Bool = false) {
    self.title = title
    self._text = text
    self.placeholder = placeholder ?? title.lowercased()
    self.isRequired = isRequired
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 2) {
        Text(title)
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(.secondary)
        
        if isRequired {
          Text("*")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.red)
        }
      }
      
      TextField(placeholder ?? "", text: $text)
        .font(.system(size: 16))
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(isRequired && text.isEmpty ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
  }
}

#Preview {
  ManualBookEntryView { _ in }
}
