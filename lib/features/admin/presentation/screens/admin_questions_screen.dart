import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/models/question_model.dart';
import '../../../../data/repositories/question_repository.dart';
import '../widgets/admin_layout.dart';

class AdminQuestionsScreen extends StatefulWidget {
  const AdminQuestionsScreen({super.key});

  static const String routePath = '/admin/questions';

  @override
  State<AdminQuestionsScreen> createState() => _AdminQuestionsScreenState();
}

class _AdminQuestionsScreenState extends State<AdminQuestionsScreen> {
  final questionRepository = QuestionRepository();
  final uuid = const Uuid();

  Future<void> _openQuestionDialog({QuestionModel? question}) async {
    final questionCont = TextEditingController(text: question?.question);
    final optACont = TextEditingController(text: question?.optionA ?? 'Evet');
    final optBCont = TextEditingController(text: question?.optionB ?? 'Hayır');
    bool isActive = question?.active ?? true;

    final isEdit = question != null;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: Text(
                isEdit ? 'Soruyu Düzenle' : 'Yeni Soru Ekle',
                style: const TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: questionCont,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Soru',
                        labelStyle: TextStyle(color: Color(0xFFB3B3B3)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: optACont,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Seçenek A',
                        labelStyle: TextStyle(color: Color(0xFFB3B3B3)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: optBCont,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Seçenek B',
                        labelStyle: TextStyle(color: Color(0xFFB3B3B3)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text(
                        'Aktif Soru Yap',
                        style: TextStyle(color: Colors.white),
                      ),
                      value: isActive,
                      activeThumbColor: const Color(0xFF0F6A3D),
                      onChanged: (val) => setDialogState(() => isActive = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Vazgeç'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (questionCont.text.isEmpty) return;

                    final newQuestion = QuestionModel(
                      id: question?.id ?? uuid.v4(),
                      question: questionCont.text,
                      optionA: optACont.text,
                      optionB: optBCont.text,
                      votesA: question?.votesA ?? 0,
                      votesB: question?.votesB ?? 0,
                      active: isActive,
                      createdAt: question?.createdAt ?? DateTime.now(),
                    );

                    if (isEdit) {
                      await questionRepository.updateQuestion(newQuestion);
                    } else {
                      await questionRepository.addQuestion(newQuestion);
                    }

                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F6A3D),
                  ),
                  child: Text(isEdit ? 'Güncelle' : 'Ekle'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      activeRoute: AdminQuestionsScreen.routePath,
      title: 'Bugünün Sorusu',
      subtitle: 'Ana sayfadaki günlük anketleri yönet.',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _openQuestionDialog(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('YENİ SORU'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F6A3D),
            foregroundColor: Colors.white,
          ),
        ),
      ],
      child: StreamBuilder<List<QuestionModel>>(
        stream: questionRepository.watchQuestions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE53935)),
            );
          }

          final questions = snapshot.data ?? [];

          if (questions.isEmpty) {
            return const Center(
              child: Text(
                'Henüz soru eklenmedi.',
                style: TextStyle(color: Color(0xFFB3B3B3)),
              ),
            );
          }

          return ListView.separated(
            itemCount: questions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final q = questions[index];
              return _QuestionTile(
                question: q,
                onEdit: () => _openQuestionDialog(question: q),
                onDelete: () => questionRepository.deleteQuestion(q.id),
              );
            },
          );
        },
      ),
    );
  }
}

class _QuestionTile extends StatelessWidget {
  final QuestionModel question;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _QuestionTile({
    required this.question,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final totalVotes = question.votesA + question.votesB;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: question.active ? const Color(0xFF0F6A3D) : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (question.active)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F6A3D).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'AKTİF',
                          style: TextStyle(
                            color: Color(0xFF0F6A3D),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    Text(
                      '${question.createdAt.day}.${question.createdAt.month}.${question.createdAt.year}',
                      style: const TextStyle(
                        color: Color(0xFF777777),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  question.question,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _VoteStat(
                      label: question.optionA,
                      votes: question.votesA,
                      total: totalVotes,
                      color: const Color(0xFF0F6A3D),
                    ),
                    const SizedBox(width: 24),
                    _VoteStat(
                      label: question.optionB,
                      votes: question.votesB,
                      total: totalVotes,
                      color: const Color(0xFFE53935),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded, color: Colors.white70),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_rounded, color: Color(0xFFE53935)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoteStat extends StatelessWidget {
  final String label;
  final int votes;
  final int total;
  final Color color;

  const _VoteStat({
    required this.label,
    required this.votes,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0 : (votes / total * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              '$votes',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '%$percent',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
