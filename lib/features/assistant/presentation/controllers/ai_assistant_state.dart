import 'package:equatable/equatable.dart';

class AiAssistantState extends Equatable {
  final bool isLoading;
  final String selectedCategory; // 'Taktik', 'Basın Açıklaması', 'Finans', 'Akademi'
  final String generatedResponse;
  final String displayedText; // Daktilo efekti için o an ekranda görünen kısım
  final bool isTypingCompleted;
  final String? error;

  const AiAssistantState({
    this.isLoading = false,
    this.selectedCategory = 'Taktik',
    this.generatedResponse = '',
    this.displayedText = '',
    this.isTypingCompleted = false,
    this.error,
  });

  AiAssistantState copyWith({
    bool? isLoading,
    String? selectedCategory,
    String? generatedResponse,
    String? displayedText,
    bool? isTypingCompleted,
    String? error,
  }) {
    return AiAssistantState(
      isLoading: isLoading ?? this.isLoading,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      generatedResponse: generatedResponse ?? this.generatedResponse,
      displayedText: displayedText ?? this.displayedText,
      isTypingCompleted: isTypingCompleted ?? this.isTypingCompleted,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        selectedCategory,
        generatedResponse,
        displayedText,
        isTypingCompleted,
        error,
      ];
}
